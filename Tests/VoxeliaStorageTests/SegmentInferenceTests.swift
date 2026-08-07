// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaCore

/// A conforming double proving the `ADR-0364` boundary is implementable
/// from outside: it touches only accepted model vocabulary and never
/// assembles a `Segmentation` itself.
private struct StubInferenceAdapter: SegmentInferenceAdapter {
    let adapterIdentity = "org.voxelia.test.stub-adapter/1.0.0"
    let result: SegmentInferenceResult

    func infer(image: ImageData) async throws -> SegmentInferenceResult {
        result
    }
}

@Suite("SegmentInference")
struct SegmentInferenceTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func geometry() throws -> SpatialGeometry {
        .affine(
            try AffineGridGeometry(
                spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
                indexToWorld: try Matrix4x4Double(elements: [
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ]),
                coordinateSpace: try space()
            )
        )
    }

    private func maskImage(name: String, bytes: [UInt8]) throws -> ImageData {
        let shape = try ImageShape(extents: [2, 2])
        var axes = ContiguousArray<AxisDescriptor>()
        for (index, axisName) in ["x", "y"].enumerated() {
            axes.append(
                try AxisDescriptor(
                    id: try #require(AxisID(rawValue: axisName)),
                    name: axisName,
                    semantic: index == 0 ? .spatialX : .spatialY,
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
                        identifier: "1.2.840.113619.23",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func automaticDescriptor(_ id: String) throws -> SegmentDescriptor {
        try SegmentDescriptor(
            id: try #require(SegmentID(rawValue: id)),
            label: "liver",
            category: nil,
            type: nil,
            algorithm: SegmentAlgorithmDescriptor(
                type: .automatic,
                name: "stub-model",
                version: "1.0.0",
                modelIdentity: "org.voxelia.test.stub-model/1.0.0"
            ),
            recommendedDisplay: nil,
            trackingIdentity: nil,
            metadata: try MetadataCollection(entries: [])
        )
    }

    @Test("[Unit][VOX-SEG-010] an adapter's output assembles through ordinary admission")
    func adapterOutputAssemblesThroughOrdinaryAdmission() async throws {
        let descriptor = try automaticDescriptor("seg-a")
        let field = try SegmentField(
            segmentID: try #require(SegmentID(rawValue: "seg-a")),
            image: try maskImage(name: "infer-a", bytes: [0, 1, 1, 0]),
            interpretation: .binary,
            domainLowerBound: 0,
            domainUpperBound: 1,
            binaryConversionThreshold: nil
        )
        let adapter = StubInferenceAdapter(
            result: SegmentInferenceResult(
                descriptors: [descriptor],
                fields: [field]
            )
        )
        let produced = try await adapter.infer(
            image: try maskImage(name: "infer-in", bytes: [0, 0, 0, 0])
        )

        // The HOST assembles and publishes: the adapter returned parts,
        // and the ordinary section 52.11 admission is what accepts them.
        let segmentation = try Segmentation(
            sourceSpace: try space(),
            geometry: try geometry(),
            representation: .segmentCollection(
                SegmentCollectionSegmentation(fields: produced.fields)
            ),
            segments: produced.descriptors,
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-infer-seg")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "infer-seg"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "infer-seg")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [0, 1, 1, 0]
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.24",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
        #expect(segmentation.segments.count == 1)
        #expect(segmentation.segments[0].algorithm.type == .automatic)
        #expect(
            segmentation.segments[0].algorithm.modelIdentity
                == "org.voxelia.test.stub-model/1.0.0"
        )
        #expect(adapter.adapterIdentity == "org.voxelia.test.stub-adapter/1.0.0")
    }

    @Test("[Unit][VOX-SEG-010] adapter output with an undeclared segment is refused")
    func adapterOutputWithUndeclaredSegmentIsRefused() async throws {
        // An adapter that returns a field for a segment it never
        // declared cannot smuggle it past the aggregate's admission.
        let field = try SegmentField(
            segmentID: try #require(SegmentID(rawValue: "seg-ghost")),
            image: try maskImage(name: "infer-b", bytes: [1, 0, 0, 0]),
            interpretation: .binary,
            domainLowerBound: 0,
            domainUpperBound: 1,
            binaryConversionThreshold: nil
        )
        let adapter = StubInferenceAdapter(
            result: SegmentInferenceResult(
                descriptors: [try automaticDescriptor("seg-a")],
                fields: [field]
            )
        )
        let produced = try await adapter.infer(
            image: try maskImage(name: "infer-in", bytes: [0, 0, 0, 0])
        )
        #expect(throws: SegmentationModelError.unresolvedSegmentReference) {
            _ = try Segmentation(
                sourceSpace: try space(),
                geometry: try geometry(),
                representation: .segmentCollection(
                    SegmentCollectionSegmentation(fields: produced.fields)
                ),
                segments: produced.descriptors,
                provenance: try ProvenanceRecord(
                    id: try #require(ProvenanceID(rawValue: "record-infer-bad")),
                    kind: .source,
                    createdAt: try CanonicalInstant(utcString: "2026-08-05T09:02:00Z"),
                    subject: .object(try #require(DataObjectID(rawValue: "infer-bad"))),
                    software: try software(),
                    activity: .origin,
                    inputs: [],
                    warnings: [],
                    validationClaim: .unknown,
                    declaresZeroInputGenerator: false
                ),
                identity: try DataIdentity(
                    objectID: try #require(DataObjectID(rawValue: "infer-bad")),
                    contentID: try ContentID.sampleBytesIdentity(
                        overCanonicalPackedBytes: [1, 0, 0, 0]
                    ),
                    sourceIdentities: [
                        try SourceIdentity(
                            namespace: "dicom.sop-instance-uid",
                            identifier: "1.2.840.113619.25",
                            version: nil,
                            contentID: nil
                        )
                    ],
                    derivation: nil
                )
            )
        }
    }
}
