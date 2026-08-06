// SPDX-License-Identifier: MIT

import Synchronization
import Testing
import VoxeliaCore

@testable import VoxeliaCompression

/// Records the checkpoints a probe was consulted at.
private final class CheckpointRecorder: Sendable {
    private let storage = Mutex<[CompressedDecodeCheckpoint]>([])

    func record(_ checkpoint: CompressedDecodeCheckpoint) {
        storage.withLock { $0.append(checkpoint) }
    }

    var visited: [CompressedDecodeCheckpoint] {
        storage.withLock { $0 }
    }
}

/// Counts how many times the decode closure ran.
private final class DecodeCounter: Sendable {
    private let storage = Mutex<Int>(0)

    func increment() { storage.withLock { $0 += 1 } }
    var count: Int { storage.withLock { $0 } }
}

/// `ADR-0259` (`VOX-CMP-009`): a decode is cancellable and never publishes partial
/// data as complete output.
@Suite("CompressedDecodeSession")
struct CompressedDecodeSessionTests {
    private func format() throws -> ScalarFormat {
        try ScalarFormat(type: .uint16, validBitCount: nil, byteOrder: .littleEndian)
    }

    /// 4x3x2 uint16 single-component: 48 declared bytes.
    private func payload() throws -> CompressedPayload {
        try CompressedPayload(
            codestream: ContiguousArray([1, 2, 3, 4]),
            declaredExtents: ContiguousArray([4, 3, 2]),
            declaredScalarFormat: try format(),
            declaredComponentCount: 1
        )
    }

    private func samples(
        byteCount: Int = 48,
        actualBytes: Int? = nil,
        extents: [Int] = [4, 3, 2],
        components: Int = 1
    ) throws -> DecodedSamples {
        DecodedSamples(
            bytes: ContiguousArray(
                repeating: 7,
                count: actualBytes ?? byteCount
            ),
            claim: DecodedSampleClaim(
                byteCount: byteCount,
                extents: ContiguousArray(extents),
                scalarFormat: try format(),
                componentCount: components
            )
        )
    }

    /// Every checkpoint the session reaches, in order.
    private var everyCheckpoint: [CompressedDecodeCheckpoint] {
        [.destination, .decode, .validation, .final]
    }

    private func run(
        maximumDecodedByteCount: Int = 1_000,
        produce: @escaping (CompressedPayload) throws -> DecodedSamples,
        cancellation: CompressedDecodeCancellationProbe
    ) async throws -> DecodedSamples {
        try await CompressedDecodeSession.decode(
            payload: try payload(),
            maximumDecodedByteCount: maximumDecodedByteCount,
            decode: produce,
            cancellation: cancellation
        )
    }

    // MARK: - Baseline

    @Test("[Unit][VOX-CMP-009] an uncancelled decode returns validated samples")
    func uncancelledDecodeReturnsValidatedSamples() async throws {
        let result = try await run(
            produce: { _ in try self.samples() },
            cancellation: { _ in false }
        )
        #expect(result.bytes.count == 48)
        #expect(result.claim.byteCount == 48)
        #expect(Array(result.claim.extents) == [4, 3, 2])
    }

    @Test("[Unit][VOX-CMP-009] the probe is consulted at every named checkpoint in order")
    func everyCheckpointIsReachedInOrder() async throws {
        // A documented-but-unreached checkpoint would be a false claim about where
        // cancellation is honoured, so the visited sites must be exactly the sites
        // the record names.
        let recorder = CheckpointRecorder()
        _ = try await run(
            produce: { _ in try self.samples() },
            cancellation: { checkpoint in
                recorder.record(checkpoint)
                return false
            }
        )
        #expect(recorder.visited == everyCheckpoint)
    }

    // MARK: - Cancellation

    @Test("[Unit][VOX-CMP-009][VOX-ERR-001] cancellation at any checkpoint refuses typed")
    func cancellationAtEveryCheckpointRefuses() async throws {
        for checkpoint in everyCheckpoint {
            await #expect(throws: CompressedDecodeSessionError.cancelled) {
                try await run(
                    produce: { _ in try self.samples() },
                    cancellation: { $0 == checkpoint }
                )
            }
        }
    }

    @Test("[Unit][VOX-CMP-009] cancelling before the decode does not run the decode")
    func cancellingBeforeDecodeDoesNotRunIt() async throws {
        // The `.decode` checkpoint sits immediately before the call, so cancelling
        // there must cost nothing. If it were checked after the call, the work
        // would already be spent -- which is the difference between a cancellation
        // point and a discard.
        let counter = DecodeCounter()
        await #expect(throws: CompressedDecodeSessionError.cancelled) {
            try await run(
                produce: { _ in
                    counter.increment()
                    return try self.samples()
                },
                cancellation: { $0 == .decode }
            )
        }
        #expect(counter.count == 0)

        // The control: without cancellation the same closure does run, so the zero
        // above is cancellation rather than a closure that never fires.
        _ = try await run(
            produce: { _ in
                counter.increment()
                return try self.samples()
            },
            cancellation: { _ in false }
        )
        #expect(counter.count == 1)
    }

    @Test("[Unit][VOX-CMP-009] cancellation at the final checkpoint yields nothing usable")
    func finalCheckpointCancellationYieldsNothing() async throws {
        // The sharpest case, and the half of VOX-CMP-009 about partial data: the
        // decode completed and every check passed, yet the caller receives
        // nothing. There is no partial aggregate for a caller to publish by
        // mistake, because the throw replaces the return.
        var received: DecodedSamples?
        do {
            received = try await run(
                produce: { _ in try self.samples() },
                cancellation: { $0 == .final }
            )
        } catch CompressedDecodeSessionError.cancelled {
            received = nil
        }
        #expect(received == nil)
    }

    // MARK: - The report must agree with itself

    @Test("[Unit][VOX-CMP-009][VOX-SEC-001] a report disagreeing with its own bytes refuses")
    func reportDisagreeingWithItsOwnBytesRefuses() async throws {
        // A decode claiming forty-eight bytes while returning forty. The claim
        // matches the payload's declarations exactly, so ADR-0258's validator
        // admits it -- this refusal is the session's own, and it is why the check
        // exists here.
        await #expect(
            throws: CompressedDecodeSessionError.reportedByteCountDisagreesWithBytes
        ) {
            try await run(
                produce: { _ in try self.samples(byteCount: 48, actualBytes: 40) },
                cancellation: { _ in false }
            )
        }
        // The over-long direction too: forty-eight claimed, sixty returned.
        await #expect(
            throws: CompressedDecodeSessionError.reportedByteCountDisagreesWithBytes
        ) {
            try await run(
                produce: { _ in try self.samples(byteCount: 48, actualBytes: 60) },
                cancellation: { _ in false }
            )
        }
    }

    @Test("[Unit][VOX-CMP-009] the validator's refusals still apply through the session")
    func validatorRefusalsApplyThroughTheSession() async throws {
        // ADR-0258's checks are composed, not restated: a self-consistent report
        // that disagrees with the payload's declarations is refused with the
        // validator's own case rather than the session's.
        await #expect(throws: CompressedDecodeError.decodedExtentsMismatch) {
            try await run(
                produce: { _ in try self.samples(byteCount: 72, extents: [4, 3, 3]) },
                cancellation: { _ in false }
            )
        }
        await #expect(throws: CompressedDecodeError.decodedComponentCountMismatch) {
            try await run(
                produce: { _ in try self.samples(byteCount: 144, components: 3) },
                cancellation: { _ in false }
            )
        }
        // And the ceiling, which the session admits before decoding at all.
        await #expect(throws: CompressedDecodeError.declaredByteCountExceedsCeiling) {
            try await run(
                maximumDecodedByteCount: 47,
                produce: { _ in try self.samples() },
                cancellation: { _ in false }
            )
        }
    }

    @Test("[Unit][VOX-CMP-009] a refused ceiling does not run the decode")
    func refusedCeilingDoesNotRunTheDecode() async throws {
        // The ceiling's whole purpose is to refuse before work happens, so the
        // decode closure must not have run.
        let counter = DecodeCounter()
        await #expect(throws: CompressedDecodeError.declaredByteCountExceedsCeiling) {
            try await run(
                maximumDecodedByteCount: 47,
                produce: { _ in
                    counter.increment()
                    return try self.samples()
                },
                cancellation: { _ in false }
            )
        }
        #expect(counter.count == 0)
    }
}
