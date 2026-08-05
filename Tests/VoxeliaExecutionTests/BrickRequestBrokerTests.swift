// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaStorage

@testable import VoxeliaExecution

/// A deterministic open-once gate so computations complete only when
/// the harness says so — no wall-clock timing anywhere.
private actor ComputationGate {
    private var opened = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func open() {
        opened = true
        for waiter in waiters {
            waiter.resume()
        }
        waiters = []
    }

    func wait() async {
        if opened {
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
}

@Suite("BrickRequestBroker")
struct BrickRequestBrokerTests {
    private func identity() throws -> BrickIdentity {
        try BrickIdentity(
            volumeObjectID: try #require(DataObjectID(rawValue: "volume-7")),
            levelIndex: 0,
            coordinate: [1, 2, 3]
        )
    }

    private func token(_ raw: String) throws -> ExecutionClaimToken {
        try ExecutionClaimToken(rawValue: raw)
    }

    private func awaitWaiters(
        _ broker: BrickRequestBroker,
        identity: BrickIdentity,
        representation: ExecutionClaimToken,
        count: Int
    ) async {
        while await broker.waiterCount(
            for: identity,
            representation: representation
        ) < count {
            await Task.yield()
        }
    }

    @Test("[Unit][VOX-BRK-007][VOX-CON-009] a same-key storm computes once")
    func sameKeyStormComputesOnce() async throws {
        // The first ADR-0149 obligation: sixty-four concurrent
        // requests for one brick and representation resolve to
        // exactly one computation, all receiving the same bytes; a
        // distinct representation computes separately.
        let broker = BrickRequestBroker()
        let gate = ComputationGate()
        let identity = try identity()
        let decoded = try token("org.voxelia.representation.decoded-u8")
        let generation = await broker.generation()
        let tasks = (0..<64).map { _ in
            Task {
                try await broker.result(
                    for: identity,
                    representation: decoded,
                    generation: generation
                ) {
                    await gate.wait()
                    return [1, 2, 3]
                }
            }
        }
        await awaitWaiters(
            broker,
            identity: identity,
            representation: decoded,
            count: 64
        )
        await gate.open()
        for task in tasks {
            #expect(try await task.value == [1, 2, 3])
        }
        #expect(await broker.startedComputationCount == 1)

        let compressed = try token("org.voxelia.representation.compressed")
        let other = try await broker.result(
            for: identity,
            representation: compressed,
            generation: generation
        ) {
            [9]
        }
        #expect(other == [9])
        #expect(await broker.startedComputationCount == 2)
    }

    @Test("[Unit][VOX-BRK-006][VOX-CON-009] cancelled awaiters release cleanly")
    func cancelledAwaitersReleaseCleanly() async throws {
        // The third obligation: thirty-two of sixty-four awaiters
        // cancel and release cleanly while the remainder complete
        // with the shared result and the computation count stays one.
        let broker = BrickRequestBroker()
        let gate = ComputationGate()
        let identity = try identity()
        let decoded = try token("org.voxelia.representation.decoded-u8")
        let generation = await broker.generation()
        let tasks = (0..<64).map { _ in
            Task {
                try await broker.result(
                    for: identity,
                    representation: decoded,
                    generation: generation
                ) {
                    await gate.wait()
                    return [4, 5]
                }
            }
        }
        await awaitWaiters(
            broker,
            identity: identity,
            representation: decoded,
            count: 64
        )
        for task in tasks.prefix(32) {
            task.cancel()
        }
        var cancelledCount = 0
        for task in tasks.prefix(32) {
            if case .failure(let error) = await task.result {
                #expect(error is CancellationError)
                cancelledCount += 1
            }
        }
        #expect(cancelledCount == 32)
        await gate.open()
        for task in tasks.dropFirst(32) {
            #expect(try await task.value == [4, 5])
        }
        #expect(await broker.startedComputationCount == 1)
    }

    @Test("[Unit][VOX-BRK-010][VOX-ERR-001] stale generations reject typed")
    func staleGenerationsRejectTyped() async throws {
        // The fourth obligation: every awaiter issued under an
        // obsolete generation rejects typed at publish with the
        // computation count still one, and an obsolete generation
        // rejects immediately at admission.
        let broker = BrickRequestBroker()
        let gate = ComputationGate()
        let identity = try identity()
        let decoded = try token("org.voxelia.representation.decoded-u8")
        let generation = await broker.generation()
        let tasks = (0..<8).map { _ in
            Task {
                try await broker.result(
                    for: identity,
                    representation: decoded,
                    generation: generation
                ) {
                    await gate.wait()
                    return [6]
                }
            }
        }
        await awaitWaiters(
            broker,
            identity: identity,
            representation: decoded,
            count: 8
        )
        _ = await broker.advanceGeneration()
        await gate.open()
        var staleCount = 0
        for task in tasks {
            if case .failure(let error) = await task.result {
                #expect(error as? BrickRequestError == .staleGeneration)
                staleCount += 1
            }
        }
        #expect(staleCount == 8)
        #expect(await broker.startedComputationCount == 1)

        do {
            _ = try await broker.result(
                for: identity,
                representation: decoded,
                generation: generation
            ) {
                [7]
            }
            #expect(Bool(false), "Expected an obsolete admission to be rejected.")
        } catch BrickRequestError.staleGeneration {}
        #expect(await broker.startedComputationCount == 1)
    }

    @Test("[Unit][VOX-BRK-007] a failed computation propagates identically")
    func failedComputationPropagatesIdentically() async throws {
        // Followers must not receive a different outcome than the
        // leader: every awaiter observes the same typed failure.
        let broker = BrickRequestBroker()
        let gate = ComputationGate()
        let identity = try identity()
        let decoded = try token("org.voxelia.representation.decoded-u8")
        let generation = await broker.generation()
        let tasks = (0..<8).map { _ in
            Task {
                try await broker.result(
                    for: identity,
                    representation: decoded,
                    generation: generation
                ) {
                    await gate.wait()
                    throw BrickVocabularyError.brickOutsideGrid
                }
            }
        }
        await awaitWaiters(
            broker,
            identity: identity,
            representation: decoded,
            count: 8
        )
        await gate.open()
        var failureCount = 0
        for task in tasks {
            if case .failure(let error) = await task.result {
                #expect(error as? BrickVocabularyError == .brickOutsideGrid)
                failureCount += 1
            }
        }
        #expect(failureCount == 8)
        #expect(await broker.startedComputationCount == 1)
    }
}
