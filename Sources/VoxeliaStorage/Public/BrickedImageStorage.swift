// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by bricked storage construction.
///
/// Cases deliberately carry no payload; each names exactly one frozen
/// `ADR-0154` admission rule.
public enum BrickedStorageError: Error, Sendable, Equatable {
    /// The grid's rank or volume extents differ from the binding's
    /// shape.
    case gridMismatch
    /// A grid coordinate has no payload.
    case missingBrick
    /// A payload was supplied for a coordinate outside the grid.
    case foreignBrick
    /// A payload's byte count is not exactly its core region's.
    case invalidBrickByteCount
}

/// The strong owner retaining the immutable per-brick payloads.
private final class BrickPayloadOwner: Sendable {
    let payloads: [ContiguousArray<Int>: [UInt8]]

    init(payloads: [ContiguousArray<Int>: [UInt8]]) {
        self.payloads = payloads
    }
}

/// The bricked provider per `ADR-0155` (`VOX-STO-005`).
///
/// The provider serves the accepted region-read contract from
/// write-once per-brick core payloads — brickedness is invisible at
/// the boundary, and no complete contiguous copy exists anywhere. The
/// halo is a fetch policy for processing and deliberately absent from
/// storage. The snapshot admits the decoded composite representation:
/// the samples are fully decoded and readable, but the layout is
/// provider-internal fragments, so neither the canonical strided
/// profile nor the not-directly-readable opaque case describes it.
public struct BrickedImageStorage: ImageStorageContract {
    /// The composite representation tag of the version-one layout.
    public static let representationTag = "org.voxelia.storage.bricked-v1"

    public let snapshot: StorageSnapshotHandle
    private let grid: BrickGridDescriptor
    private let owner: BrickPayloadOwner

    /// Admits one write-once complete brick set for the binding.
    ///
    /// - Throws: ``BrickedStorageError``, or the audited typed errors
    ///   of the snapshot and representation contracts.
    public init(
        binding: LogicalSampleBinding,
        grid: BrickGridDescriptor,
        bricks: [ContiguousArray<Int>: [UInt8]]
    ) throws {
        guard grid.volumeExtents == binding.shape.extents else {
            throw BrickedStorageError.gridMismatch
        }
        let valueStride =
            binding.scalarType.byteCount * binding.componentCount
        let counts = grid.brickCounts
        var coordinateCount = 1
        for axis in counts.indices {
            coordinateCount *= counts[axis]
        }
        var coordinate = ContiguousArray<Int>(
            repeating: 0,
            count: counts.count
        )
        for _ in 0..<coordinateCount {
            guard let payload = bricks[coordinate] else {
                throw BrickedStorageError.missingBrick
            }
            let core = try grid.coreRegion(of: coordinate)
            var expectedByteCount = valueStride
            for axis in core.lowerBounds.indices {
                expectedByteCount *=
                    core.upperBounds[axis] - core.lowerBounds[axis]
            }
            guard payload.count == expectedByteCount else {
                throw BrickedStorageError.invalidBrickByteCount
            }
            var axis = 0
            while axis < counts.count {
                coordinate[axis] += 1
                if coordinate[axis] < counts[axis] {
                    break
                }
                coordinate[axis] = 0
                axis += 1
            }
        }
        guard bricks.count == coordinateCount else {
            throw BrickedStorageError.foreignBrick
        }

        let owner = BrickPayloadOwner(payloads: bricks)
        self.snapshot = try StorageSnapshotHandle.admit(
            binding: binding,
            representation: .decodedComposite(
                try DecodedCompositeRepresentation(
                    formatTag: Self.representationTag,
                    fragmentCount: coordinateCount,
                    byteOrder: .native,
                    knownByteCount: binding.logicalByteCount
                )
            ),
            owner: owner,
            generation: 1
        )
        self.grid = grid
        self.owner = owner
    }

    /// Reads one complete owned packed region through the Core
    /// transaction, splitting each axis-zero run across consecutive
    /// bricks through the grid authority's core regions.
    public func read(region: ImageRegion) throws -> RegionReadResult {
        let transaction = try RegionReadTransaction(handle: snapshot, region: region)
        let valueStride =
            snapshot.binding.scalarType.byteCount
            * snapshot.binding.componentCount

        try transaction.fill { fill in
            var odometer = Array(region.lowerBounds.dropFirst())
            let lowerTail = Array(region.lowerBounds.dropFirst())
            let upperTail = Array(region.upperBounds.dropFirst())
            while true {
                var position = region.lowerBounds[0]
                let runEnd = region.upperBounds[0]
                while position < runEnd {
                    var coordinate = ContiguousArray<Int>()
                    coordinate.reserveCapacity(odometer.count + 1)
                    coordinate.append(position / grid.nominalBrickExtents[0])
                    for axis in odometer.indices {
                        coordinate.append(
                            odometer[axis] / grid.nominalBrickExtents[axis + 1]
                        )
                    }
                    let core = try grid.coreRegion(of: coordinate)
                    let subRunEnd = min(runEnd, core.upperBounds[0])
                    var localLinear = position - core.lowerBounds[0]
                    var multiplier = core.upperBounds[0] - core.lowerBounds[0]
                    for axis in odometer.indices {
                        localLinear +=
                            (odometer[axis] - core.lowerBounds[axis + 1])
                            * multiplier
                        multiplier *=
                            core.upperBounds[axis + 1]
                            - core.lowerBounds[axis + 1]
                    }
                    guard let payload = owner.payloads[coordinate] else {
                        throw StorageContractError.contractViolation
                    }
                    let start = localLinear * valueStride
                    let byteCount = (subRunEnd - position) * valueStride
                    try fill.write(payload[start..<(start + byteCount)])
                    position = subRunEnd
                }

                var axis = 0
                while axis < odometer.count {
                    odometer[axis] += 1
                    if odometer[axis] < upperTail[axis] {
                        break
                    }
                    odometer[axis] = lowerTail[axis]
                    axis += 1
                }
                if odometer.isEmpty || axis == odometer.count {
                    break
                }
            }
        }
        return try transaction.commit()
    }
}
