// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("ResampleCubicOperation")
struct ResampleCubicOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func input(
        extents: [Int],
        bytes: [UInt8],
        sampling: AxisSampling = .indexOnly
    ) throws -> ImageData {
        var axes = ContiguousArray<AxisDescriptor>()
        let names = ["x", "y", "z"]
        for index in 0..<extents.count {
            axes.append(
                try AxisDescriptor(
                    id: try #require(AxisID(rawValue: names[index])),
                    name: names[index],
                    semantic: .spatialX,
                    unit: nil,
                    sampling: index == 0 ? sampling : .indexOnly
                )
            )
        }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: ContiguousArray(extents)),
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
                semantic: .intensity,
                axes: axes,
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: try ImageShape(extents: ContiguousArray(extents)),
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
                createdAt: try CanonicalInstant(utcString: "2026-08-05T11:20:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "series-7"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "series-7")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.11",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func execute(
        input: ImageData,
        width: Int,
        height: Int
    ) async throws -> [UInt8] {
        let output = try await ResampleCubicOperation.execute(
            input: input,
            outputWidth: width,
            outputHeight: height,
            outputObjectID: try #require(DataObjectID(rawValue: "resampled-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T11:21:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
        return try output.storage.read(
            region: try ImageRegion(
                lowerBounds: [0, 0],
                upperBounds: [width, height]
            )
        ).bytes
    }

    @Test("[Operation][VOX-IMG-005] the frozen kernel reproduces the fixtures")
    func frozenKernelReproducesTheFixtures() async throws {
        // The ALG-0021 fixtures: the ramp upscale, the overshoot ray
        // whose raw interior value exceeds the domain before the
        // modelled clamp, its undershoot mirror, and the separable
        // two-dimensional upscale — with repetition bit-identical.
        let ramp = try input(extents: [4, 1], bytes: [0, 64, 128, 192])
        #expect(
            try await execute(input: ramp, width: 8, height: 1)
                == [0, 12, 46, 80, 112, 146, 180, 196]
        )
        let overshoot = try input(extents: [4, 1], bytes: [0, 255, 255, 0])
        #expect(
            try await execute(input: overshoot, width: 8, height: 1)
                == [0, 52, 203, 255, 255, 203, 52, 0]
        )
        let undershoot = try input(extents: [4, 1], bytes: [255, 0, 0, 255])
        #expect(
            try await execute(input: undershoot, width: 8, height: 1)
                == [255, 203, 52, 0, 0, 52, 203, 255]
        )
        let corner = try input(extents: [2, 2], bytes: [10, 20, 30, 40])
        let upscaled = try await execute(input: corner, width: 4, height: 4)
        #expect(
            upscaled == [
                8, 11, 17, 19, 13, 16, 22, 25,
                25, 28, 34, 37, 31, 33, 39, 42,
            ]
        )
        let repeated = try await execute(input: corner, width: 4, height: 4)
        #expect(repeated == upscaled)
    }

    @Test("[Operation][VOX-IMG-005] the identity mapping reproduces the input exactly")
    func identityMappingReproducesTheInputExactly() async throws {
        // Equal dimensions give t = 0 and weights (0, 1, 0, 0): the
        // interpolating kernel passes through the samples.
        let corner = try input(extents: [2, 2], bytes: [10, 20, 30, 40])
        #expect(
            try await execute(input: corner, width: 2, height: 2)
                == [10, 20, 30, 40]
        )
    }

    @Test("[Operation][VOX-ERR-001] cubic admissions reject typed")
    func cubicAdmissionsRejectTyped() async throws {
        let corner = try input(extents: [2, 2], bytes: [10, 20, 30, 40])
        await #expect(throws: ResampleCubicError.invalidOutputExtent) {
            _ = try await self.execute(input: corner, width: 0, height: 4)
        }
        let volume = try input(
            extents: [2, 2, 1],
            bytes: [10, 20, 30, 40]
        )
        await #expect(throws: ResampleCubicError.unsupportedLayerFormat) {
            _ = try await self.execute(input: volume, width: 4, height: 4)
        }
        let irregular = try input(
            extents: [4, 1],
            bytes: [0, 64, 128, 192],
            sampling: .irregular(coordinates: [1, 2, 4, 8])
        )
        await #expect(throws: ResampleCubicError.unsupportedAxisSampling) {
            _ = try await self.execute(input: irregular, width: 8, height: 1)
        }
    }
}
