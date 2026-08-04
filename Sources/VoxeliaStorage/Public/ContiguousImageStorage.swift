// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The strong owner retaining one immutable contiguous byte backing.
final class ContiguousByteOwner: Sendable {
    let bytes: [UInt8]

    init(bytes: [UInt8]) {
        self.bytes = bytes
    }
}

/// The first verified owned contiguous provider (`RFC-0001` step 7).
///
/// The provider owns one immutable process-local packed interleaved byte
/// backing admitted through Core's snapshot authority, and serves complete
/// owned region reads through the Core transaction. It never controls the
/// transaction's private result target and reports no integrity,
/// provenance or publication authority.
public struct ContiguousImageStorage: ImageStorageContract {
    public let snapshot: StorageSnapshotHandle
    private let owner: ContiguousByteOwner

    /// Admits one owned contiguous backing for the binding.
    ///
    /// - Throws: ``StorageContractError/incompatibleBinding`` when the
    ///   byte count is not exactly the binding's packed byte count.
    public init(binding: LogicalSampleBinding, bytes: [UInt8]) throws {
        guard bytes.count == binding.logicalByteCount else {
            throw StorageContractError.incompatibleBinding
        }
        let owner = ContiguousByteOwner(bytes: bytes)
        let representation = try DecodedStridedRepresentation.canonicalPacked(
            binding: binding,
            byteOrder: .native,
            locality: .processLocalOwned
        )
        self.snapshot = try StorageSnapshotHandle.admit(
            binding: binding,
            representation: .decodedStrided(representation),
            owner: owner,
            generation: 1
        )
        self.owner = owner
    }

    /// Reads one complete owned packed region through the Core
    /// transaction, copying contiguous axis-zero runs monotonically.
    public func read(region: ImageRegion) throws -> RegionReadResult {
        let transaction = try RegionReadTransaction(handle: snapshot, region: region)
        let extents = snapshot.binding.shape.extents
        let valueStride =
            snapshot.binding.scalarType.byteCount * snapshot.binding.componentCount
        let backing = owner.bytes

        try transaction.fill { fill in
            guard !extents.isEmpty else {
                try fill.write(backing)
                return
            }
            let runByteCount =
                (region.upperBounds[0] - region.lowerBounds[0]) * valueStride
            var odometer = Array(region.lowerBounds.dropFirst())
            let lowerTail = Array(region.lowerBounds.dropFirst())
            let upperTail = Array(region.upperBounds.dropFirst())
            while true {
                var linearElement = region.lowerBounds[0]
                var multiplier = extents[0]
                for axis in odometer.indices {
                    linearElement += odometer[axis] * multiplier
                    multiplier *= extents[axis + 1]
                }
                let start = linearElement * valueStride
                try fill.write(backing[start..<(start + runByteCount)])

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
