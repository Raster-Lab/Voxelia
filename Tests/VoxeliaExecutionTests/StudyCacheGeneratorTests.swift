// SPDX-License-Identifier: MIT

import Synchronization
import Testing
import VoxeliaCore
import VoxeliaStorage

@testable import VoxeliaExecution

/// A deterministic open-once gate so computations complete only when
/// the harness says so — no wall-clock timing anywhere, the broker
/// suite's idiom.
private actor SweepGate {
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

/// A lock-guarded synchronous collector for observed priorities and
/// progress, the cache suite's collector idiom.
private final class SweepRecorder: Sendable {
    let observedPriorities = Mutex<[String: TaskPriority]>([:])
    let observedProgress = Mutex<[StudyCacheProgress]>([])
}

@Suite("StudyCacheGenerator")
struct StudyCacheGeneratorTests {
    private let recorder = SweepRecorder()

    private func identity(_ ordinal: Int) throws -> BrickIdentity {
        try BrickIdentity(
            volumeObjectID: try #require(DataObjectID(rawValue: "volume-7")),
            levelIndex: 0,
            coordinate: [ordinal, 0, 0]
        )
    }

    private func bricks(_ count: Int) throws -> [StudyCacheBrick] {
        try (0..<count).map { ordinal in
            StudyCacheBrick(
                identity: try identity(ordinal),
                reconstructionCost: 1
            )
        }
    }

    private func token() throws -> ExecutionClaimToken {
        try ExecutionClaimToken(rawValue: "org.voxelia.representation.decoded-u8")
    }

    private func cache() -> BrickResultCache {
        BrickResultCache(
            maximumEntryCount: 64,
            maximumTotalByteCount: 65_536,
            eventSink: nil
        )
    }

    private func recordProgress(_ progress: StudyCacheProgress) {
        recorder.observedProgress.withLock { $0.append(progress) }
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

    @Test("[Concurrency][VOX-CON-008] the sweep generates the store with ordered progress")
    func sweepGeneratesTheStoreWithOrderedProgress() async throws {
        let broker = BrickRequestBroker()
        let cache = cache()
        let representation = try token()
        let generation = await broker.generation()
        let bricks = try bricks(3)
        try await StudyCacheGenerator.generate(
            bricks: bricks,
            representation: representation,
            generation: generation,
            visible: true,
            cache: cache,
            broker: broker,
            progress: { self.recordProgress($0) },
            compute: { identity in
                ContiguousArray([UInt8(identity.coordinate[0])])
            }
        )
        #expect(
            recorder.observedProgress.withLock { $0 } == [
                StudyCacheProgress(completedBrickCount: 1, totalBrickCount: 3),
                StudyCacheProgress(completedBrickCount: 2, totalBrickCount: 3),
                StudyCacheProgress(completedBrickCount: 3, totalBrickCount: 3),
            ]
        )
        for brick in bricks {
            let entry = try await cache.lookup(
                identity: brick.identity,
                representation: representation
            )
            #expect(entry == ContiguousArray([UInt8(brick.identity.coordinate[0])]))
        }
        #expect(await broker.startedComputationCount == 3)
    }

    @Test("[Concurrency][VOX-CON-008] the caller's priority propagates into every computation")
    func callersPriorityPropagatesIntoEveryComputation() async throws {
        // The propagation claim observed, not asserted: the background
        // sweep runs in a utility task and every brick computation
        // observes utility; an interactive request runs in a
        // user-initiated task and its computation observes that. The
        // carriage is structured concurrency through the broker's
        // computation start; the stage and the relationship are
        // Voxelia's (ADR-0341 decision 2).
        let broker = BrickRequestBroker()
        let cache = cache()
        let representation = try token()
        let generation = await broker.generation()
        let sweep = Task(priority: .utility) {
            try await StudyCacheGenerator.generate(
                bricks: try bricks(2),
                representation: representation,
                generation: generation,
                visible: true,
                cache: cache,
                broker: broker,
                progress: nil,
                compute: { identity in
                    self.recorder.observedPriorities.withLock {
                        $0["sweep-\(identity.coordinate[0])"] = Task.currentPriority
                    }
                    return [1]
                }
            )
        }
        try await sweep.value

        let interactiveIdentity = try identity(9)
        let interactive = Task(priority: .userInitiated) {
            try await cache.result(
                for: interactiveIdentity,
                representation: representation,
                generation: generation,
                visible: true,
                reconstructionCost: 1,
                broker: broker,
                compute: {
                    self.recorder.observedPriorities.withLock {
                        $0["interactive"] = Task.currentPriority
                    }
                    return [2]
                }
            )
        }
        #expect(try await interactive.value == [2])

        let observed = recorder.observedPriorities.withLock { $0 }
        #expect(observed["sweep-0"] == .utility)
        #expect(observed["sweep-1"] == .utility)
        #expect(observed["interactive"] == .userInitiated)
    }

    @Test("[Concurrency][VOX-CON-008] interactive work completes while the sweep is blocked")
    func interactiveWorkCompletesWhileTheSweepIsBlocked() async throws {
        // The outranking claim with no wall-clock anywhere: the sweep
        // is gated on its first brick, and an interactive request for
        // an unswept brick completes in full while the gate is still
        // closed — it was never queued behind the sweep.
        let broker = BrickRequestBroker()
        let cache = cache()
        let representation = try token()
        let generation = await broker.generation()
        let gate = SweepGate()
        let sweepBricks = try bricks(2)
        let sweep = Task(priority: .utility) {
            try await StudyCacheGenerator.generate(
                bricks: sweepBricks,
                representation: representation,
                generation: generation,
                visible: true,
                cache: cache,
                broker: broker,
                progress: { self.recordProgress($0) },
                compute: { _ in
                    await gate.wait()
                    return [1]
                }
            )
        }
        await awaitWaiters(
            broker,
            identity: sweepBricks[0].identity,
            representation: representation,
            count: 1
        )

        let interactiveIdentity = try identity(9)
        let interactiveBytes = try await Task(priority: .userInitiated) {
            try await cache.result(
                for: interactiveIdentity,
                representation: representation,
                generation: generation,
                visible: true,
                reconstructionCost: 1,
                broker: broker,
                compute: { [7] }
            )
        }.value
        // The interactive result is complete and admitted while the
        // sweep has produced nothing.
        #expect(interactiveBytes == [7])
        #expect(recorder.observedProgress.withLock { $0.isEmpty })
        let interactiveEntry = try await cache.lookup(
            identity: interactiveIdentity,
            representation: representation
        )
        #expect(interactiveEntry == [7])

        await gate.open()
        try await sweep.value
        #expect(recorder.observedProgress.withLock { $0.count } == 2)
    }

    @Test("[Concurrency][VOX-CON-008] racing on the sweep's brick computes once")
    func racingOnTheSweepsBrickComputesOnce() async throws {
        // An interactive request for the brick the sweep is computing
        // joins the in-flight computation through the accepted
        // deduplication: one computation, both receive the bytes.
        let broker = BrickRequestBroker()
        let cache = cache()
        let representation = try token()
        let generation = await broker.generation()
        let gate = SweepGate()
        let sweepBricks = try bricks(1)
        let sweep = Task(priority: .utility) {
            try await StudyCacheGenerator.generate(
                bricks: sweepBricks,
                representation: representation,
                generation: generation,
                visible: true,
                cache: cache,
                broker: broker,
                progress: nil,
                compute: { _ in
                    await gate.wait()
                    return [5]
                }
            )
        }
        await awaitWaiters(
            broker,
            identity: sweepBricks[0].identity,
            representation: representation,
            count: 1
        )
        let interactive = Task(priority: .userInitiated) {
            try await broker.result(
                for: sweepBricks[0].identity,
                representation: representation,
                generation: generation,
                compute: { [99] }
            )
        }
        await awaitWaiters(
            broker,
            identity: sweepBricks[0].identity,
            representation: representation,
            count: 2
        )
        await gate.open()
        #expect(try await interactive.value == [5])
        try await sweep.value
        #expect(await broker.startedComputationCount == 1)
    }

    @Test("[Concurrency][VOX-CON-008] cancelling the sweep stops it without a completion")
    func cancellingTheSweepStopsItWithoutACompletion() async throws {
        let broker = BrickRequestBroker()
        let cache = cache()
        let representation = try token()
        let generation = await broker.generation()
        let gate = SweepGate()
        let sweepBricks = try bricks(3)
        let sweep = Task(priority: .utility) {
            try await StudyCacheGenerator.generate(
                bricks: sweepBricks,
                representation: representation,
                generation: generation,
                visible: true,
                cache: cache,
                broker: broker,
                progress: { self.recordProgress($0) },
                compute: { _ in
                    await gate.wait()
                    return [1]
                }
            )
        }
        await awaitWaiters(
            broker,
            identity: sweepBricks[0].identity,
            representation: representation,
            count: 1
        )
        sweep.cancel()
        await #expect(throws: CancellationError.self) {
            try await sweep.value
        }
        // The gate never opened: the sweep completed nothing before
        // cancellation and reports nothing after it.
        #expect(recorder.observedProgress.withLock { $0.isEmpty })
        await gate.open()
    }

    @Test("[Unit][VOX-CON-008] an already-cached brick is a hit, not a recomputation")
    func alreadyCachedBrickIsAHitNotARecomputation() async throws {
        let broker = BrickRequestBroker()
        let cache = cache()
        let representation = try token()
        let generation = await broker.generation()
        let sweepBricks = try bricks(3)
        // An interactive caller admits the middle brick first.
        _ = try await cache.result(
            for: sweepBricks[1].identity,
            representation: representation,
            generation: generation,
            visible: true,
            reconstructionCost: 1,
            broker: broker,
            compute: { [42] }
        )
        try await StudyCacheGenerator.generate(
            bricks: sweepBricks,
            representation: representation,
            generation: generation,
            visible: true,
            cache: cache,
            broker: broker,
            progress: { self.recordProgress($0) },
            compute: { identity in
                ContiguousArray([UInt8(identity.coordinate[0])])
            }
        )
        // Progress still reports every brick; only two computations ran
        // in the sweep, and the pre-admitted bytes were preserved.
        #expect(recorder.observedProgress.withLock { $0.count } == 3)
        #expect(await broker.startedComputationCount == 3)
        let preserved = try await cache.lookup(
            identity: sweepBricks[1].identity,
            representation: representation
        )
        #expect(preserved == [42])
    }

    @Test("[Unit][VOX-CON-008] a stale generation rejects typed before any work")
    func staleGenerationRejectsTypedBeforeAnyWork() async throws {
        let broker = BrickRequestBroker()
        let cache = cache()
        let representation = try token()
        let generation = await broker.generation()
        _ = await broker.advanceGeneration()
        await #expect(throws: BrickRequestError.staleGeneration) {
            try await StudyCacheGenerator.generate(
                bricks: try bricks(1),
                representation: representation,
                generation: generation,
                visible: true,
                cache: cache,
                broker: broker,
                progress: { self.recordProgress($0) },
                compute: { _ in [1] }
            )
        }
        #expect(recorder.observedProgress.withLock { $0.isEmpty })
    }

    @Test("[Unit][VOX-CON-008] an empty sweep completes with no progress")
    func emptySweepCompletesWithNoProgress() async throws {
        let broker = BrickRequestBroker()
        try await StudyCacheGenerator.generate(
            bricks: [],
            representation: try token(),
            generation: await broker.generation(),
            visible: true,
            cache: cache(),
            broker: broker,
            progress: { self.recordProgress($0) },
            compute: { _ in [1] }
        )
        #expect(recorder.observedProgress.withLock { $0.isEmpty })
    }
}
