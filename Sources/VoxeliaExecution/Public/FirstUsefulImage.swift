// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaStorage

/// An error raised by first-useful-image planning or assembly.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum FirstUsefulImageError: Error, Sendable, Equatable {
    case unsupportedRank
    case invalidPlaneAxis
    case invalidPlaneIndex
    case planeBrickMissing
    case brickByteCountMismatch
}

/// The plan that makes a nominated plane the first thing generation
/// decodes, per `ADR-0342`.
///
/// The plan computes the brick layer covering the plane and emits the
/// sweep order plane-bricks-first, each half in lexicographic
/// coordinate order. Because `StudyCacheGenerator` sweeps sequentially
/// in caller order with ordered progress, the first-useful-image
/// milestone is the progress callback reaching ``planeBrickCount`` —
/// one source of truth, no second callback surface. The plan owning
/// both the order and the count is what keeps them from drifting.
public struct FirstUsefulImagePlan: Sendable {
    /// The grid the plan was computed against.
    public let grid: BrickGridDescriptor
    /// The fixed axis of the nominated plane.
    public let planeAxis: Int
    /// The fixed full-resolution index of the nominated plane.
    public let planeIndex: Int
    /// The sweep order: plane bricks first, every brick exactly once.
    public let sweepBricks: [StudyCacheBrick]
    /// The milestone: the plane is complete when this many bricks have
    /// been processed. Strictly below the total for a proper subset,
    /// which is what makes "before completion" non-vacuous.
    public let planeBrickCount: Int

    /// Plans a plane-first sweep of the whole grid at full resolution.
    ///
    /// - Throws: ``FirstUsefulImageError`` for a non-rank-three grid,
    ///   an axis outside `0...2` or a plane index outside the volume,
    ///   or the audited brick vocabulary errors.
    public init(
        grid: BrickGridDescriptor,
        planeAxis: Int,
        planeIndex: Int,
        volumeObjectID: DataObjectID,
        levelIndex: Int,
        reconstructionCost: UInt64
    ) throws {
        guard grid.volumeExtents.count == 3 else {
            throw FirstUsefulImageError.unsupportedRank
        }
        guard (0...2).contains(planeAxis) else {
            throw FirstUsefulImageError.invalidPlaneAxis
        }
        guard
            planeIndex >= 0,
            planeIndex < grid.volumeExtents[planeAxis]
        else {
            throw FirstUsefulImageError.invalidPlaneIndex
        }

        let counts = grid.brickCounts
        let planeLayer = planeIndex / grid.nominalBrickExtents[planeAxis]
        var planeBricks = [StudyCacheBrick]()
        var remainingBricks = [StudyCacheBrick]()
        for c2 in 0..<counts[2] {
            for c1 in 0..<counts[1] {
                for c0 in 0..<counts[0] {
                    let coordinate: ContiguousArray<Int> = [c0, c1, c2]
                    let brick = StudyCacheBrick(
                        identity: try BrickIdentity(
                            volumeObjectID: volumeObjectID,
                            levelIndex: levelIndex,
                            coordinate: coordinate
                        ),
                        reconstructionCost: reconstructionCost
                    )
                    if coordinate[planeAxis] == planeLayer {
                        planeBricks.append(brick)
                    } else {
                        remainingBricks.append(brick)
                    }
                }
            }
        }

        self.grid = grid
        self.planeAxis = planeAxis
        self.planeIndex = planeIndex
        self.sweepBricks = planeBricks + remainingBricks
        self.planeBrickCount = planeBricks.count
    }
}

/// One assembled full-resolution presentation plane.
public struct FirstUsefulImagePlane: Sendable, Equatable {
    /// The two output extents: the non-plane axes in ascending axis
    /// order.
    public let extents: ContiguousArray<Int>
    /// The plane samples in canonical lower-axis-fastest order.
    public let bytes: ContiguousArray<UInt8>

    public init(extents: ContiguousArray<Int>, bytes: ContiguousArray<UInt8>) {
        self.extents = extents
        self.bytes = bytes
    }
}

/// Assembles the nominated plane from the decoded brick store, per
/// `ADR-0342`.
public enum FirstUsefulImageAssembly {
    /// Publishes the plane by slicing each plane brick's decoded core
    /// bytes into the two-dimensional output.
    ///
    /// The store's decoded representation supplies each brick's core
    /// region in canonical lower-axis-fastest layout; that contract is
    /// checked against the byte count, never assumed. Every plane
    /// brick must already be admitted — a missing brick rejects typed
    /// and nothing is fabricated.
    ///
    /// - Throws: ``FirstUsefulImageError``, or the audited cache and
    ///   vocabulary errors.
    public static func plane(
        plan: FirstUsefulImagePlan,
        representation: ExecutionClaimToken,
        cache: BrickResultCache
    ) async throws -> FirstUsefulImagePlane {
        let grid = plan.grid
        let axes = (0...2).filter { $0 != plan.planeAxis }
        let uAxis = axes[0]
        let vAxis = axes[1]
        let width = grid.volumeExtents[uAxis]
        let height = grid.volumeExtents[vAxis]
        var output = ContiguousArray<UInt8>(
            repeating: 0,
            count: width * height
        )

        for brick in plan.sweepBricks.prefix(plan.planeBrickCount) {
            let coordinate = brick.identity.coordinate
            let core = try grid.coreRegion(of: coordinate)
            let lower = core.lowerBounds
            let upper = core.upperBounds
            let coreExtents = [
                upper[0] - lower[0],
                upper[1] - lower[1],
                upper[2] - lower[2],
            ]
            guard
                let bytes = try await cache.lookup(
                    identity: brick.identity,
                    representation: representation
                )
            else {
                throw FirstUsefulImageError.planeBrickMissing
            }
            guard bytes.count == coreExtents[0] * coreExtents[1] * coreExtents[2]
            else {
                throw FirstUsefulImageError.brickByteCountMismatch
            }

            var local = [0, 0, 0]
            local[plan.planeAxis] = plan.planeIndex - lower[plan.planeAxis]
            for v in lower[vAxis]..<upper[vAxis] {
                for u in lower[uAxis]..<upper[uAxis] {
                    local[uAxis] = u - lower[uAxis]
                    local[vAxis] = v - lower[vAxis]
                    let offset =
                        local[0] + coreExtents[0] * (local[1] + coreExtents[1] * local[2])
                    output[u + width * v] = bytes[offset]
                }
            }
        }

        return FirstUsefulImagePlane(
            extents: [width, height],
            bytes: output
        )
    }
}
