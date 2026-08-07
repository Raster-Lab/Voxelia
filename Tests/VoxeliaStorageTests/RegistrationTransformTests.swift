// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaCore

@Suite("RegistrationTransform")
struct RegistrationTransformTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func space(_ id: String) throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
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
                indexToWorld: Matrix4x4Double.identity,
                coordinateSpace: try space("patient")
            )
        )
    }

    private func vectorField(
        name: String,
        scalarType: ScalarType = .float32,
        componentCount: Int = 3,
        interpretation: ComponentInterpretation = .vector,
        semantic: ImageSemantic = .deformationField,
        withGeometry: Bool = true
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
        let scalarByteCount = scalarType == .float32 ? 4 : 1
        let bytes = [UInt8](repeating: 0, count: 4 * componentCount * scalarByteCount)
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
                scalarFormat: try ScalarFormat(
                    type: scalarType,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: componentCount,
                    interpretation: interpretation,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: semantic,
                axes: axes,
                spatialGeometry: withGeometry ? try geometry() : nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: shape,
                        scalarType: scalarType,
                        componentCount: componentCount
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
                        identifier: "1.2.840.113619.26",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    @Test("[Unit][VOX-REG-001][VOX-REG-003] the three categories admit distinctly with spaces")
    func theThreeCategoriesAdmitDistinctlyWithSpaces() throws {
        let rigid = RegistrationTransform(
            sourceSpace: try space("moving"),
            destinationSpace: try space("fixed"),
            category: .rigid(
                try RigidMotion(
                    quaternionW: 1,
                    quaternionX: 0,
                    quaternionY: 0,
                    quaternionZ: 0,
                    translationX: 5,
                    translationY: 0,
                    translationZ: 0
                )
            )
        )
        let affine = RegistrationTransform(
            sourceSpace: try space("moving"),
            destinationSpace: try space("fixed"),
            category: .affine(
                try AffineRegistrationTransform(
                    matrix: try Matrix4x4Double(elements: [
                        2, 0, 0, 1,
                        0, 3, 0, 2,
                        0, 0, 4, 3,
                        0, 0, 0, 1,
                    ])
                )
            )
        )
        let deformable = RegistrationTransform(
            sourceSpace: try space("moving"),
            destinationSpace: try space("fixed"),
            category: .deformable(
                try DeformableRegistrationTransform(
                    displacementField: try vectorField(name: "field-a")
                )
            )
        )
        // The categories are distinct by type: each admitted value sits
        // in its own case, and every transform names both spaces.
        guard case .rigid = rigid.category else {
            Issue.record("rigid admitted into the wrong category")
            return
        }
        guard case .affine = affine.category else {
            Issue.record("affine admitted into the wrong category")
            return
        }
        guard case .deformable = deformable.category else {
            Issue.record("deformable admitted into the wrong category")
            return
        }
        #expect(rigid.sourceSpace.id.rawValue == "moving")
        #expect(rigid.destinationSpace.id.rawValue == "fixed")
        // Identity registration within one space is legitimate.
        let identity = RegistrationTransform(
            sourceSpace: try space("patient"),
            destinationSpace: try space("patient"),
            category: affine.category
        )
        #expect(identity.sourceSpace.id == identity.destinationSpace.id)
    }

    @Test("[Unit][VOX-REG-001] affine admission composes the existing exact machinery")
    func affineAdmissionComposesTheExistingExactMachinery() throws {
        #expect(throws: RegistrationTransformError.nonAffineMatrix) {
            _ = try AffineRegistrationTransform(
                matrix: try Matrix4x4Double(elements: [
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 2,
                ])
            )
        }
        #expect(throws: RegistrationTransformError.singularAffineMatrix) {
            _ = try AffineRegistrationTransform(
                matrix: try Matrix4x4Double(elements: [
                    1, 0, 0, 0,
                    0, 0, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ])
            )
        }
    }

    @Test("[Unit][VOX-REG-001] displacement-field admission is structural")
    func displacementFieldAdmissionIsStructural() throws {
        #expect(throws: RegistrationTransformError.invalidDisplacementField) {
            _ = try DeformableRegistrationTransform(
                displacementField: try vectorField(name: "field-b", componentCount: 2)
            )
        }
        #expect(throws: RegistrationTransformError.invalidDisplacementField) {
            _ = try DeformableRegistrationTransform(
                displacementField: try vectorField(
                    name: "field-c",
                    interpretation: .scalar,
                    withGeometry: true
                )
            )
        }
        #expect(throws: RegistrationTransformError.invalidDisplacementField) {
            _ = try DeformableRegistrationTransform(
                displacementField: try vectorField(name: "field-d", withGeometry: false)
            )
        }
        #expect(throws: RegistrationTransformError.invalidDisplacementField) {
            _ = try DeformableRegistrationTransform(
                displacementField: try vectorField(name: "field-e", semantic: .parametric)
            )
        }
    }
}
