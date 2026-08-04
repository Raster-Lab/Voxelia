// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaExecution

@Suite("MetadataIdentityCoordinator")
struct MetadataIdentityCoordinatorTests {
    private func collection() throws -> MetadataCollection {
        try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(namespace: "org.example.ct", name: "sliceCount"),
                value: .unsignedInteger(120),
                privacyClass: .technical
            )
        ])
    }

    @Test("[Unit][VOX-EXE-002][VOX-CON-006] identity pairs publish atomically")
    func identityPairsPublishAtomically() async throws {
        let coordinator = MetadataIdentityCoordinator()

        // The empty collection reproduces the registered golden pair.
        let empty = try MetadataCollection(entries: [MetadataEntry]())
        let golden = try await coordinator.identity(
            for: empty,
            maximumOutputByteCount: 4_096
        )
        #expect(golden.canonicalBytes.count == 148)
        let expectedHex = "8dde6fa088cd4b1e676fca392a6d24fdeed93fc93bdc43c94cfbc75f362e7432"
        let expectedBytes = stride(from: 0, to: expectedHex.count, by: 2).map { offset in
            let start = expectedHex.index(expectedHex.startIndex, offsetBy: offset)
            let end = expectedHex.index(start, offsetBy: 2)
            return UInt8(expectedHex[start..<end], radix: 16) ?? 0
        }
        #expect(Array(golden.identity.digest) == expectedBytes)

        // The pair is self-consistent: the identity verifies its bytes.
        let pair = try await coordinator.identity(
            for: try collection(),
            maximumOutputByteCount: 100_000
        )
        #expect(try pair.identity.matchesDigest(ofCanonicalBytes: pair.canonicalBytes))
        #expect(await coordinator.currentInFlightCount == 0)

        // Typed failures propagate: an impossible output ceiling.
        do {
            _ = try await coordinator.identity(
                for: empty,
                maximumOutputByteCount: 10
            )
            #expect(Bool(false), "Expected the output ceiling to fail typed.")
        } catch MetadataJSONEmissionError.resourceLimitExceeded {}
        #expect(await coordinator.currentInFlightCount == 0)
    }

    @Test("[Unit][VOX-EXE-006][VOX-PER-007] concurrent identical requests coalesce")
    func concurrentIdenticalRequestsCoalesce() async throws {
        let coordinator = MetadataIdentityCoordinator()
        let payload = try collection()

        // Many concurrent identical requests produce equal pairs; the
        // in-flight table drains afterwards.
        let results = try await withThrowingTaskGroup(
            of: CoordinatedMetadataIdentity.self
        ) { group in
            for _ in 0..<16 {
                group.addTask {
                    try await coordinator.identity(
                        for: payload,
                        maximumOutputByteCount: 100_000
                    )
                }
            }
            var collected = [CoordinatedMetadataIdentity]()
            for try await result in group {
                collected.append(result)
            }
            return collected
        }
        #expect(results.count == 16)
        let first = results[0]
        for result in results {
            #expect(result.identity == first.identity)
            #expect(result.canonicalBytes == first.canonicalBytes)
        }
        #expect(await coordinator.currentInFlightCount == 0)

        // Coalescing started strictly fewer computations than requests.
        let started = await coordinator.startedComputationCount
        #expect(started >= 1)
        #expect(started < 16)

        // A distinct ceiling is a distinct work key.
        _ = try await coordinator.identity(
            for: payload,
            maximumOutputByteCount: 90_000
        )
        #expect(await coordinator.startedComputationCount == started + 1)
    }
}
