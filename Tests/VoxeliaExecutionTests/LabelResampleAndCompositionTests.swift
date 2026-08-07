// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

/// Shared fixture builders for the ALG-0064 and composition suites.
private enum SegFixture {
    static func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    static func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    static func geometry(
        elements: [Double],
        imageAxes: [Int]
    ) throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: imageAxes),
            indexToWorld: try Matrix4x4Double(elements: elements),
            coordinateSpace: try space()
        )
    }

    static func identity3(_ scale: Double = 1, shift: Double = 0) -> [Double] {
        [
            scale, 0, 0, shift,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        ]
    }

    static func image(
        name: String,
        scalarType: ScalarType,
        semantic: ImageSemantic,
        extents: [Int],
        bytes: [UInt8],
        spatialGeometry: SpatialGeometry? = nil
    ) throws -> ImageData {
        let shape = try ImageShape(extents: ContiguousArray(extents))
        var axes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        for (index, axisName) in ["x", "y", "z"].prefix(extents.count).enumerated() {
            axes.append(
                try AxisDescriptor(
                    id: try #require(AxisID(rawValue: axisName)),
                    name: axisName,
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
                semantic: semantic,
                axes: axes,
                spatialGeometry: spatialGeometry,
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
                id: try #require(ProvenanceID(rawValue: "record-\(name)")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: name))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: name)),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.19",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }
}

@Suite("LabelResampleOperation")
struct LabelResampleOperationTests {
    /// Labels 1..6 on a 3 x 2 x 1 grid with identity geometry.
    private func labelVolume() throws -> ImageData {
        try SegFixture.image(
            name: "labels-in",
            scalarType: .uint16,
            semantic: .label,
            extents: [3, 2, 1],
            bytes: [1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0],
            spatialGeometry: .affine(
                try SegFixture.geometry(
                    elements: SegFixture.identity3(),
                    imageAxes: [0, 1, 2]
                )
            )
        )
    }

    private func execute(
        _ input: ImageData,
        elements: [Double],
        extents: [Int]
    ) async throws -> ImageData {
        try await LabelResampleOperation.execute(
            input: input,
            request: try SegFixture.geometry(elements: elements, imageAxes: [0, 1, 2]),
            outputExtents: extents,
            outputObjectID: try #require(DataObjectID(rawValue: "resampled-labels")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try SegFixture.software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func labels(_ image: ImageData) throws -> [UInt16] {
        let extents = image.descriptor.shape.extents
        let bytes = try image.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
        var out = [UInt16]()
        var offset = 0
        while offset + 1 < bytes.count {
            out.append(UInt16(bytes[offset + 1]) << 8 | UInt16(bytes[offset]))
            offset += 2
        }
        return out
    }

    @Test("[Operation][VOX-SEG-005] fixtures 1 and 2: identity and the half-spacing upscale")
    func identityAndHalfSpacingUpscale() async throws {
        let input = try labelVolume()
        let identical = try await execute(
            input,
            elements: SegFixture.identity3(),
            extents: [3, 2, 1]
        )
        #expect(try labels(identical) == [1, 2, 3, 4, 5, 6])
        #expect(identical.provenance.warnings.isEmpty)
        #expect(identical.descriptor.semantic == .label)

        let upscaled = try await execute(
            input,
            elements: SegFixture.identity3(0.5),
            extents: [6, 2, 1]
        )
        // Ties round away from zero; 2.5 rounds to 3, outside,
        // publishing background.
        #expect(try labels(upscaled) == [1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 0])
        let warning = try #require(upscaled.provenance.warnings.first)
        #expect(warning.code.rawValue == LabelResampleOperation.paddingWarningCode)
        #expect(warning.occurrenceCount == 2)
    }

    @Test("[Operation][VOX-SEG-005] fixtures 3 and 4: shifts and the boundary tie")
    func shiftsAndTheBoundaryTie() async throws {
        let input = try labelVolume()
        let shifted = try await execute(
            input,
            elements: SegFixture.identity3(1, shift: -1),
            extents: [3, 2, 1]
        )
        #expect(try labels(shifted) == [0, 1, 2, 0, 4, 5])

        let tie = try await execute(
            input,
            elements: SegFixture.identity3(1, shift: -0.5),
            extents: [3, 2, 1]
        )
        // -0.5 rounds away from zero to -1: outside, background.
        #expect(try labels(tie) == [0, 2, 3, 0, 5, 6])
    }

    @Test("[Unit][VOX-SEG-005] the structural default: the intensity resampler refuses masks")
    func structuralDefaultIntensityResamplerRefusesMasks() async throws {
        let mask = try SegFixture.image(
            name: "mask-in",
            scalarType: .uint8,
            semantic: .mask,
            extents: [2, 2, 1],
            bytes: [1, 0, 0, 1],
            spatialGeometry: .affine(
                try SegFixture.geometry(
                    elements: SegFixture.identity3(),
                    imageAxes: [0, 1, 2]
                )
            )
        )
        // The interpolating door is closed to masks: label semantics
        // route only to the nearest resampler.
        await #expect(throws: GridResampleError.unsupportedLayerFormat) {
            _ = try await GridResampleOperation.execute(
                input: mask,
                request: try SegFixture.geometry(
                    elements: SegFixture.identity3(),
                    imageAxes: [0, 1, 2]
                ),
                outputExtents: [2, 2, 1],
                outputObjectID: try #require(DataObjectID(rawValue: "refused")),
                outputProvenanceID: try #require(
                    ProvenanceID(rawValue: "record-refused")
                ),
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
                software: try SegFixture.software(),
                coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
            )
        }
        // And this door admits them.
        let resampled = try await LabelResampleOperation.execute(
            input: mask,
            request: try SegFixture.geometry(
                elements: SegFixture.identity3(),
                imageAxes: [0, 1, 2]
            ),
            outputExtents: [2, 2, 1],
            outputObjectID: try #require(DataObjectID(rawValue: "admitted")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-admitted")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try SegFixture.software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
        #expect(resampled.descriptor.semantic == .mask)
    }
}

@Suite("SegmentationComposition")
struct SegmentationCompositionTests {
    @Test("[Integration][VOX-SEG-006] threshold, erode and label compose into the model")
    func thresholdErodeAndLabelComposeIntoTheModel() async throws {
        // The composition witness: the foundations operations drive a
        // stored CT-like plane all the way into the CDMS section 52
        // aggregate — unit evidence of the halves does not prove they
        // meet, so this does.
        let coordinator = StorageReadCoordinator(maximumRetainedResultByteCount: 256)
        var values = [Int16](repeating: -1000, count: 16)
        for row in 0..<3 {
            for column in 0..<3 {
                values[column + 4 * row] = 40
            }
        }
        var bytes = [UInt8]()
        for value in values {
            let bits = UInt16(bitPattern: value)
            bytes.append(UInt8(bits & 0xFF))
            bytes.append(UInt8(bits >> 8))
        }
        let stored = try SegFixture.image(
            name: "ct-plane",
            scalarType: .int16,
            semantic: .intensity,
            extents: [4, 4],
            bytes: bytes
        )

        let mask = try await ThresholdOperation.execute(
            input: stored,
            lowerBound: -500,
            upperBound: 400,
            paddingValue: -1000,
            outputObjectID: try #require(DataObjectID(rawValue: "mask")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-mask")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try SegFixture.software(),
            coordinator: coordinator
        )
        let eroded = try await MorphologyOperation.execute(
            input: mask,
            element: [0, 1, 0, 1, 1, 1, 0, 1, 0],
            elementExtents: [3, 3],
            operator: .erode,
            boundary: .zero,
            outputObjectID: try #require(DataObjectID(rawValue: "eroded")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-eroded")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:02:00Z"),
            software: try SegFixture.software(),
            coordinator: coordinator
        )
        let labelled = try await ConnectedComponentsOperation.execute(
            input: eroded,
            connectivity: .faces,
            outputObjectID: try #require(DataObjectID(rawValue: "labelled")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-labelled")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:03:00Z"),
            software: try SegFixture.software(),
            coordinator: coordinator
        )

        // The eroded 3x3 block leaves exactly its centre: one
        // component, label one.
        let extents = labelled.descriptor.shape.extents
        let labelBytes = try labelled.storage.read(
            region: try ImageRegion(
                lowerBounds: [0, 0],
                upperBounds: extents
            )
        ).bytes
        var labels = [UInt16]()
        var offset = 0
        while offset + 1 < labelBytes.count {
            labels.append(
                UInt16(labelBytes[offset + 1]) << 8 | UInt16(labelBytes[offset])
            )
            offset += 2
        }
        #expect(labels.filter { $0 == 1 }.count == 1)
        #expect(labels.allSatisfy { $0 <= 1 })

        // The pipeline's product enters the CDMS section 52 aggregate.
        let segmentation = try Segmentation(
            sourceSpace: try SegFixture.space(),
            geometry: .affine(
                try SegFixture.geometry(
                    elements: [
                        1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1,
                    ],
                    imageAxes: [0, 1]
                )
            ),
            representation: .labelImage(
                LabelImageSegmentation(
                    image: labelled,
                    labelToSegment: [
                        1: try #require(SegmentID(rawValue: "segment-lesion"))
                    ],
                    backgroundValue: 0
                )
            ),
            segments: [
                try SegmentDescriptor(
                    id: try #require(SegmentID(rawValue: "segment-lesion")),
                    label: "lesion",
                    category: nil,
                    type: nil,
                    algorithm: SegmentAlgorithmDescriptor(
                        type: .automatic,
                        name: "threshold-erode-components",
                        version: "1.0.0",
                        modelIdentity: nil
                    ),
                    recommendedDisplay: nil,
                    trackingIdentity: nil,
                    metadata: try MetadataCollection(entries: [])
                )
            ],
            provenance: labelled.provenance,
            identity: labelled.identity
        )
        #expect(segmentation.segments.count == 1)
    }
}
