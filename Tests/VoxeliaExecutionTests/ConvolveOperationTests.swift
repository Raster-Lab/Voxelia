// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("ConvolveOperation")
struct ConvolveOperationTests {
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
                subject: .object(try #require(DataObjectID(rawValue: "conv-in"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "conv-in")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.12",
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
        kernel: [Double],
        kernelExtents: [Int],
        boundary: ConvolutionBoundary
    ) async throws -> ImageData {
        try await ConvolveOperation.execute(
            input: input,
            kernel: kernel,
            kernelExtents: kernelExtents,
            boundary: boundary,
            outputObjectID: try #require(DataObjectID(rawValue: "conv-1")),
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

    @Test("[Operation][VOX-IMG-011] fixture 1: the boundary choice changes both edges")
    func boundaryChoiceChangesBothEdges() async throws {
        let input = try image(
            scalarType: .uint8,
            extents: [5, 1],
            bytes: [10, 20, 30, 40, 50]
        )
        let replicate = try await execute(
            input,
            kernel: [1, 2, 1],
            kernelExtents: [3, 1],
            boundary: .replicate
        )
        #expect(try read(replicate) == [50, 80, 120, 160, 190])
        let zero = try await execute(
            input,
            kernel: [1, 2, 1],
            kernelExtents: [3, 1],
            boundary: .zero
        )
        #expect(try read(zero) == [40, 80, 120, 160, 140])
        #expect(zero.provenance.warnings.isEmpty)
    }

    @Test("[Operation][VOX-IMG-011] fixture 2: the central difference goes negative at zero")
    func centralDifferenceGoesNegativeAtZero() async throws {
        let input = try image(
            scalarType: .int16,
            extents: [5, 1],
            bytes: [100, 0, 200, 0, 144, 1, 32, 3, 64, 6]
        )
        let replicate = try await execute(
            input,
            kernel: [-1, 0, 1],
            kernelExtents: [3, 1],
            boundary: .replicate
        )
        // 100, 300, 600, 1200, 800 little-endian.
        #expect(try read(replicate) == [100, 0, 44, 1, 88, 2, 176, 4, 32, 3])
        let zero = try await execute(
            input,
            kernel: [-1, 0, 1],
            kernelExtents: [3, 1],
            boundary: .zero
        )
        // 200, 300, 600, 1200, -800 little-endian.
        #expect(try read(zero) == [200, 0, 44, 1, 88, 2, 176, 4, 224, 252])
    }

    @Test("[Operation][VOX-IMG-011] fixture 3: saturation is counted per sample")
    func saturationIsCountedPerSample() async throws {
        let input = try image(
            scalarType: .uint8,
            extents: [5, 1],
            bytes: [100, 200, 250, 200, 100]
        )
        let output = try await execute(
            input,
            kernel: [1, 2, 1],
            kernelExtents: [3, 1],
            boundary: .zero
        )
        #expect(try read(output) == [255, 255, 255, 255, 255])
        let warning = try #require(output.provenance.warnings.first)
        #expect(warning.code.rawValue == ConvolveOperation.saturationWarningCode)
        #expect(warning.occurrenceCount == 5)
    }

    @Test("[Operation][VOX-IMG-011][VOX-R2D-004] fixture 4: float32 quarter kernel is exact")
    func float32QuarterKernelIsExact() async throws {
        let input = try image(
            scalarType: .float32,
            extents: [4, 1],
            bytes: [0, 0, 128, 63, 0, 0, 0, 64, 0, 0, 128, 64, 0, 0, 0, 65]
        )
        let output = try await execute(
            input,
            kernel: [0.25, 0.5, 0.25],
            kernelExtents: [3, 1],
            boundary: .replicate
        )
        #expect(
            try read(output) == [
                0, 0, 160, 63, 0, 0, 16, 64, 0, 0, 144, 64, 0, 0, 224, 64,
            ]
        )
    }

    @Test("[Unit][VOX-IMG-011] kernel admission rejects typed")
    func kernelAdmissionRejectsTyped() async throws {
        let input = try image(scalarType: .uint8, extents: [3, 1], bytes: [1, 2, 3])
        await #expect(throws: ConvolveError.invalidKernel) {
            _ = try await execute(
                input,
                kernel: [1, 1],
                kernelExtents: [2, 1],
                boundary: .zero
            )
        }
        await #expect(throws: ConvolveError.invalidKernel) {
            _ = try await execute(
                input,
                kernel: [1, .nan, 1],
                kernelExtents: [3, 1],
                boundary: .zero
            )
        }
        await #expect(throws: ConvolveError.invalidKernel) {
            _ = try await execute(
                input,
                kernel: [1, 1, 1],
                kernelExtents: [3],
                boundary: .zero
            )
        }
    }
}
