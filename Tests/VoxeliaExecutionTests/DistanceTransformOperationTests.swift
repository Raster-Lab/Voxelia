// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("DistanceTransformOperation")
struct DistanceTransformOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func mask(extents: [Int], bytes: [UInt8]) throws -> ImageData {
        let shape = try ImageShape(extents: ContiguousArray(extents))
        var axes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        for (index, name) in ["x", "y", "z"].prefix(extents.count).enumerated() {
            axes.append(
                try AxisDescriptor(
                    id: try #require(AxisID(rawValue: name)),
                    name: name,
                    semantic: semantics[index],
                    unit: nil,
                    sampling: .indexOnly
                )
            )
        }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
                scalarFormat: try ScalarFormat(
                    type: .uint8,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 1,
                    interpretation: .scalar,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: .mask,
                axes: axes,
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: shape,
                        scalarType: .uint8,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "edt-in"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "edt-in")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.16",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func execute(_ input: ImageData) async throws -> ImageData {
        try await DistanceTransformOperation.execute(
            input: input,
            outputObjectID: try #require(DataObjectID(rawValue: "edt-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func distances(_ image: ImageData) throws -> [UInt32] {
        let extents = image.descriptor.shape.extents
        let bytes = try image.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
        var out = [UInt32]()
        var offset = 0
        while offset + 3 < bytes.count {
            out.append(
                UInt32(bytes[offset + 3]) << 24 | UInt32(bytes[offset + 2]) << 16
                    | UInt32(bytes[offset + 1]) << 8 | UInt32(bytes[offset])
            )
            offset += 4
        }
        return out
    }

    @Test("[Operation][VOX-IMG-014] fixture 1: the bar matches brute force")
    func barMatchesBruteForce() async throws {
        let bar = try mask(extents: [6, 1], bytes: [1, 1, 0, 1, 1, 1])
        let output = try await execute(bar)
        #expect(try distances(output) == [4, 1, 0, 1, 4, 9])
        #expect(output.descriptor.semantic == .parametric)
        #expect(output.descriptor.scalarFormat.type == .uint32)
    }

    @Test("[Operation][VOX-IMG-014] fixtures 2 and 3: the radial field and competing seeds")
    func radialFieldAndCompetingSeeds() async throws {
        var plane = [UInt8](repeating: 1, count: 25)
        plane[12] = 0
        let centre = try mask(extents: [5, 5], bytes: plane)
        #expect(
            try distances(try await execute(centre)) == [
                8, 5, 4, 5, 8,
                5, 2, 1, 2, 5,
                4, 1, 0, 1, 4,
                5, 2, 1, 2, 5,
                8, 5, 4, 5, 8,
            ]
        )

        var corners = [UInt8](repeating: 1, count: 9)
        corners[0] = 0
        corners[8] = 0
        let competing = try mask(extents: [3, 3], bytes: corners)
        #expect(
            try distances(try await execute(competing)) == [0, 1, 4, 1, 2, 1, 4, 1, 0]
        )
    }

    @Test("[Operation][VOX-IMG-014] fixture 4: the 3-D corner seed")
    func threeDimensionalCornerSeed() async throws {
        var cube = [UInt8](repeating: 1, count: 27)
        cube[0] = 0
        let volume = try mask(extents: [3, 3, 3], bytes: cube)
        #expect(
            try distances(try await execute(volume)) == [
                0, 1, 4, 1, 2, 5, 4, 5, 8,
                1, 2, 5, 2, 3, 6, 5, 6, 9,
                4, 5, 8, 5, 6, 9, 8, 9, 12,
            ]
        )
    }

    @Test("[Unit][VOX-IMG-014] fixture 5: all background is zero; no background rejects")
    func allBackgroundIsZeroNoBackgroundRejects() async throws {
        let empty = try mask(extents: [4, 1], bytes: [0, 0, 0, 0])
        #expect(try distances(try await execute(empty)) == [0, 0, 0, 0])

        let full = try mask(extents: [4, 1], bytes: [1, 1, 1, 1])
        await #expect(throws: DistanceTransformError.noBackground) {
            _ = try await execute(full)
        }
        let corrupt = try mask(extents: [4, 1], bytes: [1, 3, 0, 1])
        await #expect(throws: DistanceTransformError.invalidMaskValue) {
            _ = try await execute(corrupt)
        }
    }
}
