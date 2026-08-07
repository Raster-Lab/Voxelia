// SPDX-License-Identifier: MIT

import Synchronization
import Testing
import VoxeliaCore
import VoxeliaStorage

@testable import VoxeliaExecution

/// A deterministic open-once gate so computations complete only when
/// the harness says so — no wall-clock timing anywhere.
private actor PlaneGate {
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

/// A lock-guarded synchronous progress collector.
private final class PlaneRecorder: Sendable {
    let observedProgress = Mutex<[StudyCacheProgress]>([])
}

@Suite("FirstUsefulImage")
struct FirstUsefulImageTests {
    private let recorder = PlaneRecorder()

    /// The oracle fixture grid: volume (5, 4, 3), bricks (2, 2, 2),
    /// no halo — edge bricks smaller than nominal on every axis.
    private func grid() throws -> BrickGridDescriptor {
        try BrickGridDescriptor(
            volumeExtents: [5, 4, 3],
            nominalBrickExtents: [2, 2, 2],
            haloExtents: [0, 0, 0]
        )
    }

    private func volumeID() throws -> DataObjectID {
        try #require(DataObjectID(rawValue: "volume-7"))
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

    /// The stored value `i0 + 5*i1 + 20*i2` — distinct axis strides so
    /// a transposed axis cannot hide.
    private static func value(_ i0: Int, _ i1: Int, _ i2: Int) -> UInt8 {
        UInt8(i0 + 5 * i1 + 20 * i2)
    }

    /// Decodes one brick's core region in canonical layout — the
    /// decoded-representation contract the assembly consumes.
    private func decode(
        _ identity: BrickIdentity,
        grid: BrickGridDescriptor
    ) throws -> ContiguousArray<UInt8> {
        let core = try grid.coreRegion(of: identity.coordinate)
        var bytes = ContiguousArray<UInt8>()
        for i2 in core.lowerBounds[2]..<core.upperBounds[2] {
            for i1 in core.lowerBounds[1]..<core.upperBounds[1] {
                for i0 in core.lowerBounds[0]..<core.upperBounds[0] {
                    bytes.append(Self.value(i0, i1, i2))
                }
            }
        }
        return bytes
    }

    private func plan(axis: Int, index: Int) throws -> FirstUsefulImagePlan {
        try FirstUsefulImagePlan(
            grid: try grid(),
            planeAxis: axis,
            planeIndex: index,
            volumeObjectID: try volumeID(),
            levelIndex: 0,
            reconstructionCost: 1
        )
    }

    private func coordinates(_ plan: FirstUsefulImagePlan) -> [[Int]] {
        plan.sweepBricks.map { Array($0.identity.coordinate) }
    }

    @Test("[Unit][VOX-PER-006] the axial plan keeps lexicographic order with the plane first")
    func axialPlanKeepsLexicographicOrderWithThePlaneFirst() throws {
        let plan = try plan(axis: 2, index: 1)
        #expect(plan.planeBrickCount == 6)
        #expect(plan.sweepBricks.count == 12)
        #expect(
            coordinates(plan) == [
                [0, 0, 0], [1, 0, 0], [2, 0, 0], [0, 1, 0], [1, 1, 0], [2, 1, 0],
                [0, 0, 1], [1, 0, 1], [2, 0, 1], [0, 1, 1], [1, 1, 1], [2, 1, 1],
            ]
        )
    }

    @Test("[Unit][VOX-PER-006] the sagittal plan reorders the sweep plane-first")
    func sagittalPlanReordersTheSweepPlaneFirst() throws {
        let plan = try plan(axis: 0, index: 3)
        #expect(plan.planeBrickCount == 4)
        #expect(
            coordinates(plan) == [
                [1, 0, 0], [1, 1, 0], [1, 0, 1], [1, 1, 1],
                [0, 0, 0], [2, 0, 0], [0, 1, 0], [2, 1, 0],
                [0, 0, 1], [2, 0, 1], [0, 1, 1], [2, 1, 1],
            ]
        )
    }

    @Test("[Concurrency][VOX-PER-006] the plane is available before generation completes")
    func planeIsAvailableBeforeGenerationCompletes() async throws {
        // The row itself, gate-driven: the sweep is blocked on its
        // first post-plane brick, and the nominated full-resolution
        // plane assembles exactly while total generation is provably
        // incomplete.
        let grid = try grid()
        let plan = try plan(axis: 0, index: 3)
        let broker = BrickRequestBroker()
        let cache = cache()
        let representation = try token()
        let generation = await broker.generation()
        let gate = PlaneGate()
        let planeIdentities = Set(
            plan.sweepBricks.prefix(plan.planeBrickCount).map(\.identity)
        )
        let sweep = Task(priority: .utility) {
            try await StudyCacheGenerator.generate(
                bricks: plan.sweepBricks,
                representation: representation,
                generation: generation,
                visible: true,
                cache: cache,
                broker: broker,
                progress: { progress in
                    self.recorder.observedProgress.withLock { $0.append(progress) }
                },
                compute: { identity in
                    if !planeIdentities.contains(identity) {
                        await gate.wait()
                    }
                    return try self.decode(identity, grid: grid)
                }
            )
        }
        while recorder.observedProgress.withLock({ $0.count }) < plan.planeBrickCount {
            await Task.yield()
        }

        let plane = try await FirstUsefulImageAssembly.plane(
            plan: plan,
            representation: representation,
            cache: cache
        )
        #expect(plane.extents == [4, 3])
        #expect(
            plane.bytes == [3, 8, 13, 18, 23, 28, 33, 38, 43, 48, 53, 58]
        )
        // Generation is provably incomplete at this moment: the first
        // post-plane brick is still gated.
        #expect(
            recorder.observedProgress.withLock { $0.count } == plan.planeBrickCount
        )
        #expect(plan.planeBrickCount < plan.sweepBricks.count)

        await gate.open()
        try await sweep.value
        #expect(
            recorder.observedProgress.withLock { $0.count } == plan.sweepBricks.count
        )
    }

    @Test("[Operation][VOX-PER-006] the completed store assembles the axial oracle plane")
    func completedStoreAssemblesTheAxialOraclePlane() async throws {
        let grid = try grid()
        let plan = try plan(axis: 2, index: 1)
        let broker = BrickRequestBroker()
        let cache = cache()
        let representation = try token()
        try await StudyCacheGenerator.generate(
            bricks: plan.sweepBricks,
            representation: representation,
            generation: await broker.generation(),
            visible: true,
            cache: cache,
            broker: broker,
            progress: nil,
            compute: { identity in
                try self.decode(identity, grid: grid)
            }
        )
        let plane = try await FirstUsefulImageAssembly.plane(
            plan: plan,
            representation: representation,
            cache: cache
        )
        #expect(plane.extents == [5, 4])
        #expect(
            plane.bytes
                == ContiguousArray((20...39).map { UInt8($0) })
        )
    }

    @Test("[Unit][VOX-PER-006] a missing plane brick rejects typed, nothing fabricated")
    func missingPlaneBrickRejectsTyped() async throws {
        let plan = try plan(axis: 2, index: 1)
        await #expect(throws: FirstUsefulImageError.planeBrickMissing) {
            _ = try await FirstUsefulImageAssembly.plane(
                plan: plan,
                representation: try token(),
                cache: cache()
            )
        }
    }

    @Test("[Unit][VOX-PER-006] a wrong-size decoded brick rejects typed")
    func wrongSizeDecodedBrickRejectsTyped() async throws {
        let plan = try plan(axis: 2, index: 1)
        let broker = BrickRequestBroker()
        let cache = cache()
        let representation = try token()
        let generation = await broker.generation()
        // Admit every plane brick, the first with a truncated payload.
        for (ordinal, brick) in plan.sweepBricks.prefix(plan.planeBrickCount)
            .enumerated()
        {
            let grid = try grid()
            _ = try await cache.result(
                for: brick.identity,
                representation: representation,
                generation: generation,
                visible: true,
                reconstructionCost: 1,
                broker: broker,
                compute: {
                    ordinal == 0
                        ? [0]
                        : (try self.decode(brick.identity, grid: grid))
                }
            )
        }
        await #expect(throws: FirstUsefulImageError.brickByteCountMismatch) {
            _ = try await FirstUsefulImageAssembly.plane(
                plan: plan,
                representation: representation,
                cache: cache
            )
        }
    }

    @Test("[Unit][VOX-PER-006] plan admission rejects rank, axis and index typed")
    func planAdmissionRejectsRankAxisAndIndexTyped() throws {
        #expect(throws: FirstUsefulImageError.invalidPlaneAxis) {
            _ = try plan(axis: 3, index: 0)
        }
        #expect(throws: FirstUsefulImageError.invalidPlaneIndex) {
            _ = try plan(axis: 2, index: 3)
        }
        #expect(throws: FirstUsefulImageError.invalidPlaneIndex) {
            _ = try plan(axis: 0, index: -1)
        }
        #expect(throws: FirstUsefulImageError.unsupportedRank) {
            _ = try FirstUsefulImagePlan(
                grid: try BrickGridDescriptor(
                    volumeExtents: [5, 4],
                    nominalBrickExtents: [2, 2],
                    haloExtents: [0, 0]
                ),
                planeAxis: 0,
                planeIndex: 0,
                volumeObjectID: try volumeID(),
                levelIndex: 0,
                reconstructionCost: 1
            )
        }
    }
}
