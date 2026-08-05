// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised while validating the bricked-volume vocabulary.
///
/// Cases deliberately carry no payload; each names exactly one frozen
/// `ADR-0147` admission rule.
public enum BrickVocabularyError: Error, Sendable, Equatable {
    case invalidVolumeExtent
    case invalidBrickExtent
    case invalidHalo
    case invalidDownsamplingFactor
    case invalidLevelIndex
    case rankMismatch
    case brickOutsideGrid
}

/// One validated resolution level per `ADR-0147` (`VOX-BRK-005`).
///
/// The spatial relationship between levels is the accepted
/// `VOXELIA-ALG-0008` rescale applied with these factors through the
/// one shared rule implementation — referenced by consumers, never
/// re-derived here.
public struct BrickResolutionLevel: Sendable, Hashable {
    /// The nonnegative level index; zero is full resolution.
    public let index: Int

    /// The per-axis integer downsampling factors, each at least one.
    public let downsamplingFactors: ContiguousArray<Int>

    /// Creates a validated level.
    ///
    /// - Throws: ``BrickVocabularyError/invalidLevelIndex`` or
    ///   ``BrickVocabularyError/invalidDownsamplingFactor``.
    public init(index: Int, downsamplingFactors: ContiguousArray<Int>) throws {
        guard index >= 0 else {
            throw BrickVocabularyError.invalidLevelIndex
        }
        guard
            !downsamplingFactors.isEmpty,
            downsamplingFactors.allSatisfy({ $0 >= 1 })
        else {
            throw BrickVocabularyError.invalidDownsamplingFactor
        }
        self.index = index
        self.downsamplingFactors = downsamplingFactors
    }
}

/// The one brick layout authority for one volume at one level per
/// `ADR-0147` (`VOX-BRK-002/003/004`).
///
/// Volume extents, nominal brick extents and halo are caller-supplied
/// capability-and-workload policy inputs — never constants of the
/// public model — and every region derives from the frozen integer
/// arithmetic, so identity and layout can never disagree. The halo
/// clamps at the volume boundary: replicating edge voxels into the
/// halo would fabricate data at the vocabulary level, and a consumer
/// needing replication must claim it explicitly.
public struct BrickGridDescriptor: Sendable, Hashable {
    /// The positive per-axis volume extents at this grid's level.
    public let volumeExtents: ContiguousArray<Int>

    /// The positive per-axis nominal brick extents.
    public let nominalBrickExtents: ContiguousArray<Int>

    /// The per-axis halo, nonnegative and below the nominal extent.
    public let haloExtents: ContiguousArray<Int>

    /// Creates a validated layout.
    ///
    /// - Throws: ``BrickVocabularyError``.
    public init(
        volumeExtents: ContiguousArray<Int>,
        nominalBrickExtents: ContiguousArray<Int>,
        haloExtents: ContiguousArray<Int>
    ) throws {
        guard !volumeExtents.isEmpty, volumeExtents.allSatisfy({ $0 >= 1 })
        else {
            throw BrickVocabularyError.invalidVolumeExtent
        }
        guard
            nominalBrickExtents.count == volumeExtents.count,
            haloExtents.count == volumeExtents.count
        else {
            throw BrickVocabularyError.rankMismatch
        }
        guard nominalBrickExtents.allSatisfy({ $0 >= 1 }) else {
            throw BrickVocabularyError.invalidBrickExtent
        }
        for axis in haloExtents.indices {
            guard
                haloExtents[axis] >= 0,
                haloExtents[axis] < nominalBrickExtents[axis]
            else {
                throw BrickVocabularyError.invalidHalo
            }
        }
        self.volumeExtents = volumeExtents
        self.nominalBrickExtents = nominalBrickExtents
        self.haloExtents = haloExtents
    }

    /// The frozen per-axis brick counts: `(e + n - 1) / n`.
    public var brickCounts: ContiguousArray<Int> {
        var counts = ContiguousArray<Int>()
        counts.reserveCapacity(volumeExtents.count)
        for axis in volumeExtents.indices {
            counts.append(
                (volumeExtents[axis] + nominalBrickExtents[axis] - 1)
                    / nominalBrickExtents[axis]
            )
        }
        return counts
    }

    /// Validates one brick coordinate against the grid.
    ///
    /// - Throws: ``BrickVocabularyError/rankMismatch`` or
    ///   ``BrickVocabularyError/brickOutsideGrid``.
    public func validate(coordinate: ContiguousArray<Int>) throws {
        guard coordinate.count == volumeExtents.count else {
            throw BrickVocabularyError.rankMismatch
        }
        let counts = brickCounts
        for axis in coordinate.indices {
            guard coordinate[axis] >= 0, coordinate[axis] < counts[axis] else {
                throw BrickVocabularyError.brickOutsideGrid
            }
        }
    }

    /// The frozen core region of one brick: `lower = i * n`,
    /// `upper = min(lower + n, e)` — the final brick's smaller extent
    /// is structural.
    ///
    /// - Throws: ``BrickVocabularyError``, or the audited region
    ///   admission.
    public func coreRegion(
        of coordinate: ContiguousArray<Int>
    ) throws -> ImageRegion {
        try validate(coordinate: coordinate)
        var lowerBounds = ContiguousArray<Int>()
        var upperBounds = ContiguousArray<Int>()
        lowerBounds.reserveCapacity(coordinate.count)
        upperBounds.reserveCapacity(coordinate.count)
        for axis in coordinate.indices {
            let lower = coordinate[axis] * nominalBrickExtents[axis]
            lowerBounds.append(lower)
            upperBounds.append(
                min(lower + nominalBrickExtents[axis], volumeExtents[axis])
            )
        }
        return try ImageRegion(lowerBounds: lowerBounds, upperBounds: upperBounds)
    }

    /// The frozen haloed region of one brick, clamped at the volume
    /// boundary — never fabricated.
    ///
    /// - Throws: ``BrickVocabularyError``, or the audited region
    ///   admission.
    public func haloedRegion(
        of coordinate: ContiguousArray<Int>
    ) throws -> ImageRegion {
        let core = try coreRegion(of: coordinate)
        var lowerBounds = ContiguousArray<Int>()
        var upperBounds = ContiguousArray<Int>()
        lowerBounds.reserveCapacity(coordinate.count)
        upperBounds.reserveCapacity(coordinate.count)
        for axis in coordinate.indices {
            lowerBounds.append(max(0, core.lowerBounds[axis] - haloExtents[axis]))
            upperBounds.append(
                min(
                    volumeExtents[axis],
                    core.upperBounds[axis] + haloExtents[axis]
                )
            )
        }
        return try ImageRegion(lowerBounds: lowerBounds, upperBounds: upperBounds)
    }

    /// The frozen level extents for one resolution level:
    /// `(e + f - 1) / f` per axis.
    ///
    /// - Throws: ``BrickVocabularyError/rankMismatch``.
    public func levelExtents(
        for level: BrickResolutionLevel
    ) throws -> ContiguousArray<Int> {
        guard level.downsamplingFactors.count == volumeExtents.count else {
            throw BrickVocabularyError.rankMismatch
        }
        var extents = ContiguousArray<Int>()
        extents.reserveCapacity(volumeExtents.count)
        for axis in volumeExtents.indices {
            extents.append(
                (volumeExtents[axis] + level.downsamplingFactors[axis] - 1)
                    / level.downsamplingFactors[axis]
            )
        }
        return extents
    }
}

/// One minimal brick name per `ADR-0147` (`VOX-BRK-002`).
///
/// The identity carries only what names the brick — the volume's
/// object identifier, the level index and the coordinate — and every
/// region is derived from the grid authority rather than stored.
public struct BrickIdentity: Sendable, Hashable {
    public let volumeObjectID: DataObjectID
    public let levelIndex: Int
    public let coordinate: ContiguousArray<Int>

    /// Creates a validated identity.
    ///
    /// - Throws: ``BrickVocabularyError/invalidLevelIndex`` or
    ///   ``BrickVocabularyError/brickOutsideGrid`` for a negative
    ///   coordinate component.
    public init(
        volumeObjectID: DataObjectID,
        levelIndex: Int,
        coordinate: ContiguousArray<Int>
    ) throws {
        guard levelIndex >= 0 else {
            throw BrickVocabularyError.invalidLevelIndex
        }
        guard !coordinate.isEmpty, coordinate.allSatisfy({ $0 >= 0 }) else {
            throw BrickVocabularyError.brickOutsideGrid
        }
        self.volumeObjectID = volumeObjectID
        self.levelIndex = levelIndex
        self.coordinate = coordinate
    }
}
