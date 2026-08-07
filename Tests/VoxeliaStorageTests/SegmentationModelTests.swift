// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaCore

@Suite("SegmentationModel")
struct SegmentationModelTests {
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

    private func geometry(scale: Double = 1) throws -> SpatialGeometry {
        .affine(
            try AffineGridGeometry(
                spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
                indexToWorld: try Matrix4x4Double(elements: [
                    scale, 0, 0, 0,
                    0, scale, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ]),
                coordinateSpace: try space()
            )
        )
    }

    private func maskImage(
        name: String,
        bytes: [UInt8],
        extents: [Int] = [2, 2],
        scalarType: ScalarType = .uint8,
        semantic: ImageSemantic = .mask,
        spatialGeometry: SpatialGeometry? = nil
    ) throws -> ImageData {
        let shape = try ImageShape(extents: ContiguousArray(extents))
        var axes = ContiguousArray<AxisDescriptor>()
        for (index, axisName) in ["x", "y"].prefix(extents.count).enumerated() {
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
                        identifier: "1.2.840.113619.17",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func descriptor(_ id: String, label: String = "organ") throws -> SegmentDescriptor {
        try SegmentDescriptor(
            id: try #require(SegmentID(rawValue: id)),
            label: label,
            category: nil,
            type: nil,
            algorithm: SegmentAlgorithmDescriptor(
                type: .manual,
                name: nil,
                version: nil,
                modelIdentity: nil
            ),
            recommendedDisplay: nil,
            trackingIdentity: nil,
            metadata: try MetadataCollection(entries: [])
        )
    }

    private func field(
        _ id: String,
        image: ImageData,
        interpretation: SegmentFieldInterpretation = .binary
    ) throws -> SegmentField {
        try SegmentField(
            segmentID: try #require(SegmentID(rawValue: id)),
            image: image,
            interpretation: interpretation,
            domainLowerBound: 0,
            domainUpperBound: 1,
            binaryConversionThreshold: nil
        )
    }

    private func aggregate(
        representation: SegmentationRepresentation,
        segments: [SegmentDescriptor]
    ) throws -> Segmentation {
        try Segmentation(
            sourceSpace: try space(),
            geometry: try geometry(),
            representation: representation,
            segments: ContiguousArray(segments),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-seg")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "seg-1"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "seg-1")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [1]
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.18",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    @Test("[Unit][VOX-SEG-001][VOX-SEG-002] overlapping fields are admitted structurally")
    func overlappingFieldsAreAdmittedStructurally() throws {
        // Both segments claim sample zero: the collection representation
        // admits overlap by construction — the structural discharge of
        // the overlap requirement.
        let liver = try maskImage(name: "liver", bytes: [1, 1, 0, 0])
        let lesion = try maskImage(name: "lesion", bytes: [1, 0, 0, 0])
        let segmentation = try aggregate(
            representation: .segmentCollection(
                SegmentCollectionSegmentation(fields: [
                    try field("segment-liver", image: liver),
                    try field("segment-lesion", image: lesion),
                ])
            ),
            segments: [
                try descriptor("segment-liver"),
                try descriptor("segment-lesion"),
            ]
        )
        #expect(segmentation.segments.count == 2)
    }

    @Test("[Unit][VOX-SEG-001] the label image admits with a resolving mapping")
    func labelImageAdmitsWithResolvingMapping() throws {
        let labels = try maskImage(
            name: "labels",
            bytes: [0, 1, 2, 0],
            semantic: .label
        )
        let segmentation = try aggregate(
            representation: .labelImage(
                LabelImageSegmentation(
                    image: labels,
                    labelToSegment: [
                        1: try #require(SegmentID(rawValue: "segment-liver")),
                        2: try #require(SegmentID(rawValue: "segment-lesion")),
                    ],
                    backgroundValue: 0
                )
            ),
            segments: [
                try descriptor("segment-liver"),
                try descriptor("segment-lesion"),
            ]
        )
        if case .labelImage(let representation) = segmentation.representation {
            #expect(representation.labelToSegment.count == 2)
        } else {
            #expect(Bool(false), "Expected the label-image representation.")
        }
    }

    @Test("[Unit][VOX-SEG-002][VOX-SEG-003] identity invariants reject typed")
    func identityInvariantsRejectTyped() throws {
        let mask = try maskImage(name: "m", bytes: [1, 0, 0, 0])
        #expect(throws: SegmentationModelError.duplicateSegmentID) {
            _ = try aggregate(
                representation: .segmentCollection(
                    SegmentCollectionSegmentation(fields: [
                        try field("segment-a", image: mask)
                    ])
                ),
                segments: [try descriptor("segment-a"), try descriptor("segment-a")]
            )
        }
        #expect(throws: SegmentationModelError.unresolvedSegmentReference) {
            _ = try aggregate(
                representation: .segmentCollection(
                    SegmentCollectionSegmentation(fields: [
                        try field("segment-ghost", image: mask)
                    ])
                ),
                segments: [try descriptor("segment-a")]
            )
        }
        let labels = try maskImage(name: "l", bytes: [0, 1, 0, 0], semantic: .label)
        #expect(throws: SegmentationModelError.duplicateLabelValue) {
            _ = try aggregate(
                representation: .labelImage(
                    LabelImageSegmentation(
                        image: labels,
                        labelToSegment: [
                            0: try #require(SegmentID(rawValue: "segment-a"))
                        ],
                        backgroundValue: 0
                    )
                ),
                segments: [try descriptor("segment-a")]
            )
        }
    }

    @Test("[Unit][VOX-SEG-004] geometry invariants reject typed and admit agreement")
    func geometryInvariantsRejectTypedAndAdmitAgreement() throws {
        let small = try maskImage(name: "small", bytes: [1, 0, 0, 0])
        let wide = try maskImage(
            name: "wide",
            bytes: [1, 0, 0, 0, 0, 0],
            extents: [3, 2]
        )
        #expect(throws: SegmentationModelError.incompatibleGeometry) {
            _ = try aggregate(
                representation: .segmentCollection(
                    SegmentCollectionSegmentation(fields: [
                        try field("segment-a", image: small),
                        try field("segment-b", image: wide),
                    ])
                ),
                segments: [try descriptor("segment-a"), try descriptor("segment-b")]
            )
        }

        // An image declaring its own geometry must agree with the
        // aggregate's declaration.
        let disagreeing = try maskImage(
            name: "disagreeing",
            bytes: [1, 0, 0, 0],
            spatialGeometry: try geometry(scale: 2)
        )
        #expect(throws: SegmentationModelError.incompatibleGeometry) {
            _ = try aggregate(
                representation: .segmentCollection(
                    SegmentCollectionSegmentation(fields: [
                        try field("segment-a", image: disagreeing)
                    ])
                ),
                segments: [try descriptor("segment-a")]
            )
        }
        let agreeing = try maskImage(
            name: "agreeing",
            bytes: [1, 0, 0, 0],
            spatialGeometry: try geometry()
        )
        let admitted = try aggregate(
            representation: .segmentCollection(
                SegmentCollectionSegmentation(fields: [
                    try field("segment-a", image: agreeing)
                ])
            ),
            segments: [try descriptor("segment-a")]
        )
        #expect(admitted.segments.count == 1)
    }

    @Test("[Unit][VOX-SEG-003] descriptor and field admissions reject typed")
    func descriptorAndFieldAdmissionsRejectTyped() throws {
        #expect(throws: SegmentationModelError.emptyLabel) {
            _ = try descriptor("segment-a", label: "   ")
        }
        #expect(throws: SegmentationModelError.invalidDisplayRecommendation) {
            _ = try SegmentDisplayRecommendation(
                rgba: SIMD4<Float>(1.5, 0, 0, 1),
                opacity: nil,
                visibleByDefault: nil
            )
        }
        let mask = try maskImage(name: "m", bytes: [1, 0, 0, 0])
        #expect(throws: SegmentationModelError.invalidFractionalDomain) {
            _ = try SegmentField(
                segmentID: try #require(SegmentID(rawValue: "segment-a")),
                image: mask,
                interpretation: .probability,
                domainLowerBound: 1,
                domainUpperBound: 1,
                binaryConversionThreshold: nil
            )
        }
        #expect(throws: SegmentationModelError.invalidThreshold) {
            _ = try SegmentField(
                segmentID: try #require(SegmentID(rawValue: "segment-a")),
                image: mask,
                interpretation: .probability,
                domainLowerBound: 0,
                domainUpperBound: 1,
                binaryConversionThreshold: 2
            )
        }
        #expect(SegmentID(rawValue: "   ") == nil)
    }
}
