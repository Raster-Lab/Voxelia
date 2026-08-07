// SPDX-License-Identifier: MIT

import DICOMKit
import Testing
import VoxeliaCore
import VoxeliaGeometry
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaDICOMKit

/// Conforming doubles proving each `ADR-0378` capability is
/// implementable and that its output arrives through the canonical
/// admissions — the boundary works before any reader exists.
@Suite("DICOMAdapterCapability")
struct DICOMAdapterCapabilityTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func space(_ id: String = "patient") throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func image(
        name: String,
        semantic: ImageSemantic,
        bytes: [UInt8]
    ) throws -> ImageData {
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
                semantic: semantic,
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
                        identifier: "1.2.840.113619.32",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func stubSegmentation() throws -> VoxeliaCore.Segmentation {
        let id = try #require(SegmentID(rawValue: "seg-1"))
        let descriptor = try SegmentDescriptor(
            id: id,
            label: "liver",
            category: nil,
            type: nil,
            algorithm: SegmentAlgorithmDescriptor(
                type: .imported,
                name: nil,
                version: nil,
                modelIdentity: nil
            ),
            recommendedDisplay: nil,
            trackingIdentity: nil,
            metadata: try MetadataCollection(entries: [])
        )
        let field = try SegmentField(
            segmentID: id,
            image: try image(name: "dcm-seg", semantic: .mask, bytes: [0, 1, 1, 0]),
            interpretation: .binary,
            domainLowerBound: 0,
            domainUpperBound: 1,
            binaryConversionThreshold: nil
        )
        return try Segmentation(
            sourceSpace: try space(),
            geometry: .affine(
                try AffineGridGeometry(
                    spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
                    indexToWorld: Matrix4x4Double.identity,
                    coordinateSpace: try space()
                )
            ),
            representation: .segmentCollection(
                SegmentCollectionSegmentation(fields: [field])
            ),
            segments: [descriptor],
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-dcm-seg-agg")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "dcm-seg-agg"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "dcm-seg-agg")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [0, 1, 1, 0]
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.33",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    @Test("[Unit][VOX-DCM-012] every capability is implementable with admitted output")
    func everyCapabilityIsImplementableWithAdmittedOutput() throws {
        struct StubAdapter: DICOMSegmentationCapability, DICOMParametricMapCapability,
            DICOMSurfaceCapability, DICOMRegistrationCapability
        {
            let adapterIdentity = "org.voxelia.test.dicom-adapter/1.0.0"
            let stubSegmentation: VoxeliaCore.Segmentation
            let stubParametric: ImageData
            let stubSurface: TriangleMesh
            let stubTransform: RegistrationTransform

            func segmentation(
                from dataSet: DataSet
            ) throws -> VoxeliaCore.Segmentation {
                stubSegmentation
            }
            func parametricMap(from dataSet: DataSet) throws -> ImageData {
                stubParametric
            }
            func surface(from dataSet: DataSet) throws -> TriangleMesh {
                stubSurface
            }
            func registrationTransform(
                from dataSet: DataSet
            ) throws -> RegistrationTransform {
                stubTransform
            }
        }

        let adapter = StubAdapter(
            stubSegmentation: try stubSegmentation(),
            stubParametric: try image(
                name: "dcm-param",
                semantic: .parametric,
                bytes: [1, 2, 3, 4]
            ),
            stubSurface: try TriangleMesh(
                positions: try TriangleMeshPositionDomain(
                    coordinateSpace: try space(),
                    components: [0, 0, 0, 1, 0, 0, 0, 1, 0]
                ),
                topology: try TriangleMeshTopology(
                    vertexCount: 3,
                    indices: [0, 1, 2]
                ),
                vertexAttributes: []
            ),
            stubTransform: RegistrationTransform(
                sourceSpace: try space("dicom-frame"),
                destinationSpace: try space(),
                category: .rigid(
                    try RigidMotion(
                        quaternionW: 1,
                        quaternionX: 0,
                        quaternionY: 0,
                        quaternionZ: 0,
                        translationX: 1,
                        translationY: 2,
                        translationZ: 3
                    )
                )
            )
        )

        // The empty data set stands in for any parsed object: what is
        // proven here is the boundary's shape, not a reader.
        let dataSet = DataSet(elements: [])
        #expect(adapter.adapterIdentity == "org.voxelia.test.dicom-adapter/1.0.0")

        let segmentation = try adapter.segmentation(from: dataSet)
        #expect(segmentation.segments.count == 1)
        #expect(segmentation.segments[0].algorithm.type == .imported)

        let parametric = try adapter.parametricMap(from: dataSet)
        #expect(parametric.descriptor.semantic == .parametric)

        let surface = try adapter.surface(from: dataSet)
        #expect(surface.topology.triangleCount == 1)

        let transform = try adapter.registrationTransform(from: dataSet)
        guard case .rigid(let motion) = transform.category else {
            Issue.record("the registration capability lost its category")
            return
        }
        #expect(motion.translation == [1, 2, 3])
        #expect(transform.sourceSpace.id.rawValue == "dicom-frame")
    }
}
