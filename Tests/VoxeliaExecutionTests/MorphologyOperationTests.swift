// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("MorphologyOperation")
struct MorphologyOperationTests {
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
                subject: .object(try #require(DataObjectID(rawValue: "morph-in"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "morph-in")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.14",
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
        element: [UInt8],
        elementExtents: [Int],
        op: MorphologyOperator,
        boundary: ConvolutionBoundary
    ) async throws -> ImageData {
        try await MorphologyOperation.execute(
            input: input,
            element: element,
            elementExtents: elementExtents,
            operator: op,
            boundary: boundary,
            outputObjectID: try #require(DataObjectID(rawValue: "morph-1")),
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

    @Test("[Operation][VOX-IMG-012] fixtures 1 and 2: dilate the impulse, erode the bar")
    func dilateTheImpulseErodeTheBar() async throws {
        let impulse = try mask(extents: [5, 1], bytes: [0, 0, 1, 0, 0])
        let dilated = try await execute(
            impulse,
            element: [1, 1, 1],
            elementExtents: [3, 1],
            op: .dilate,
            boundary: .zero
        )
        #expect(try read(dilated) == [0, 1, 1, 1, 0])
        #expect(dilated.descriptor.semantic == .mask)

        let bar = try mask(extents: [5, 1], bytes: [0, 1, 1, 1, 0])
        let eroded = try await execute(
            bar,
            element: [1, 1, 1],
            elementExtents: [3, 1],
            op: .erode,
            boundary: .zero
        )
        #expect(try read(eroded) == [0, 0, 1, 0, 0])
    }

    @Test("[Operation][VOX-IMG-012] fixture 3: the boundary decides the border erosion")
    func boundaryDecidesTheBorderErosion() async throws {
        let full = try mask(extents: [5, 1], bytes: [1, 1, 1, 1, 1])
        let replicated = try await execute(
            full,
            element: [1, 1, 1],
            elementExtents: [3, 1],
            op: .erode,
            boundary: .replicate
        )
        #expect(try read(replicated) == [1, 1, 1, 1, 1])
        let zeroed = try await execute(
            full,
            element: [1, 1, 1],
            elementExtents: [3, 1],
            op: .erode,
            boundary: .zero
        )
        #expect(try read(zeroed) == [0, 1, 1, 1, 0])
    }

    @Test("[Operation][VOX-IMG-012] fixtures 4 and 5: border dilation and the 2-D cross")
    func borderDilationAndTheCross() async throws {
        let border = try mask(extents: [5, 1], bytes: [1, 0, 0, 0, 0])
        let dilated = try await execute(
            border,
            element: [1, 1, 1],
            elementExtents: [3, 1],
            op: .dilate,
            boundary: .zero
        )
        #expect(try read(dilated) == [1, 1, 0, 0, 0])

        let centre = try mask(
            extents: [3, 3],
            bytes: [0, 0, 0, 0, 1, 0, 0, 0, 0]
        )
        let cross: [UInt8] = [0, 1, 0, 1, 1, 1, 0, 1, 0]
        let crossDilated = try await execute(
            centre,
            element: cross,
            elementExtents: [3, 3],
            op: .dilate,
            boundary: .zero
        )
        #expect(try read(crossDilated) == [0, 1, 0, 1, 1, 1, 0, 1, 0])

        let fullPlane = try mask(
            extents: [3, 3],
            bytes: [UInt8](repeating: 1, count: 9)
        )
        let crossEroded = try await execute(
            fullPlane,
            element: cross,
            elementExtents: [3, 3],
            op: .erode,
            boundary: .zero
        )
        #expect(try read(crossEroded) == [0, 0, 0, 0, 1, 0, 0, 0, 0])
    }

    @Test("[Unit][VOX-IMG-012] admission rejects corrupt inputs typed")
    func admissionRejectsCorruptInputsTyped() async throws {
        let corrupt = try mask(extents: [3, 1], bytes: [1, 2, 0])
        await #expect(throws: MorphologyError.invalidMaskValue) {
            _ = try await execute(
                corrupt,
                element: [1, 1, 1],
                elementExtents: [3, 1],
                op: .erode,
                boundary: .zero
            )
        }
        let valid = try mask(extents: [3, 1], bytes: [1, 1, 0])
        await #expect(throws: MorphologyError.invalidStructuringElement) {
            _ = try await execute(
                valid,
                element: [0, 0, 0],
                elementExtents: [3, 1],
                op: .erode,
                boundary: .zero
            )
        }
        await #expect(throws: MorphologyError.invalidStructuringElement) {
            _ = try await execute(
                valid,
                element: [1, 1],
                elementExtents: [2, 1],
                op: .erode,
                boundary: .zero
            )
        }
    }
}
