// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("GaussianFilterOperation")
struct GaussianFilterOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func image(
        scalarType: ScalarType,
        extents: [Int],
        bytes: [UInt8]
    ) throws -> ImageData {
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
                    type: scalarType,
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
                        shape: shape,
                        scalarType: scalarType,
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
                subject: .object(try #require(DataObjectID(rawValue: "gauss-in"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "gauss-in")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.13",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func execute(
        _ input: ImageData,
        sigmas: [Double],
        boundary: ConvolutionBoundary
    ) async throws -> ImageData {
        try await GaussianFilterOperation.execute(
            input: input,
            sigmas: sigmas,
            boundary: boundary,
            outputObjectID: try #require(DataObjectID(rawValue: "gauss-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func read(_ image: ImageData) throws -> [UInt8] {
        let extents = image.descriptor.shape.extents
        return try image.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
    }

    @Test("[Operation][VOX-IMG-011] fixtures 1 and 2: the impulse responses are exact")
    func impulseResponsesAreExact() async throws {
        let impulse = try image(
            scalarType: .uint8,
            extents: [7, 1],
            bytes: [0, 0, 255, 0, 0, 0, 0]
        )
        let wide = try await execute(impulse, sigmas: [1.0, 1.0], boundary: .replicate)
        #expect(try read(wide) == [14, 62, 102, 62, 14, 1, 0])
        #expect(wide.provenance.warnings.isEmpty)

        let narrow = try await execute(impulse, sigmas: [0.5, 0.5], boundary: .replicate)
        #expect(try read(narrow) == [0, 27, 201, 27, 0, 0, 0])
    }

    @Test("[Operation][VOX-IMG-011][VOX-R2D-004] fixture 3: the separable product structure")
    func separableProductStructure() async throws {
        var bytes = [UInt8](repeating: 0, count: 36)
        // 16.0 at the centre of a 3x3 float32 plane.
        bytes[16] = 0
        bytes[17] = 0
        bytes[18] = 128
        bytes[19] = 65
        let input = try image(scalarType: .float32, extents: [3, 3], bytes: bytes)
        let output = try await execute(input, sigmas: [1.0, 1.0], boundary: .zero)
        #expect(
            try read(output) == [
                49, 243, 111, 63, 41, 206, 197, 63, 49, 243, 111, 63,
                41, 206, 197, 63, 27, 16, 35, 64, 41, 206, 197, 63,
                49, 243, 111, 63, 41, 206, 197, 63, 49, 243, 111, 63,
            ]
        )
    }

    @Test("[Operation][VOX-IMG-011] fixture 4: the constant image is a fixed point")
    func constantImageIsAFixedPoint() async throws {
        let constant = try image(
            scalarType: .uint8,
            extents: [5, 1],
            bytes: [200, 200, 200, 200, 200]
        )
        let output = try await execute(constant, sigmas: [2.0, 1.0], boundary: .replicate)
        // The convexity witness: no saturation is possible under a
        // normalised kernel, and the constant survives exactly.
        #expect(try read(output) == [200, 200, 200, 200, 200])
        #expect(output.provenance.warnings.isEmpty)
    }

    @Test("[Unit][VOX-IMG-011] fixture 5: the deviation ceiling admits five and rejects above")
    func deviationCeilingAdmitsFiveAndRejectsAbove() async throws {
        let input = try image(
            scalarType: .uint8,
            extents: [3, 1],
            bytes: [1, 2, 3]
        )
        _ = try await execute(input, sigmas: [5.0, 1.0], boundary: .replicate)
        await #expect(throws: GaussianFilterError.invalidSigma) {
            _ = try await execute(input, sigmas: [5.1, 1.0], boundary: .replicate)
        }
        await #expect(throws: GaussianFilterError.invalidSigma) {
            _ = try await execute(input, sigmas: [0, 1.0], boundary: .replicate)
        }
        await #expect(throws: GaussianFilterError.invalidSigma) {
            _ = try await execute(input, sigmas: [1.0], boundary: .replicate)
        }
    }
}
