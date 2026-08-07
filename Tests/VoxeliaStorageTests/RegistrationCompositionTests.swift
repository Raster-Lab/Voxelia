// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaCore

@Suite("RegistrationComposition")
struct RegistrationCompositionTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func space(
        _ id: String,
        convention: CoordinateConvention = .dicomPatientLPS
    ) throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: convention,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func rigid(
        from source: String,
        to destination: String,
        translationX: Double = 0
    ) throws -> RegistrationTransform {
        RegistrationTransform(
            sourceSpace: try space(source),
            destinationSpace: try space(destination),
            category: .rigid(
                try RigidMotion(
                    quaternionW: 1,
                    quaternionX: 0,
                    quaternionY: 0,
                    quaternionZ: 0,
                    translationX: translationX,
                    translationY: 0,
                    translationZ: 0
                )
            )
        )
    }

    private func deformable(
        from source: String,
        to destination: String
    ) throws -> RegistrationTransform {
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
        let bytes = [UInt8](repeating: 0, count: 4 * 3 * 4)
        let field = try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
                scalarFormat: try ScalarFormat(
                    type: .float32,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 3,
                    interpretation: .vector,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: .deformationField,
                axes: axes,
                spatialGeometry: .affine(
                    try AffineGridGeometry(
                        spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
                        indexToWorld: Matrix4x4Double.identity,
                        coordinateSpace: try space(source)
                    )
                ),
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: shape,
                        scalarType: .float32,
                        componentCount: 3
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-compose-field")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "compose-field"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "compose-field")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.28",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
        return RegistrationTransform(
            sourceSpace: try space(source),
            destinationSpace: try space(destination),
            category: .deformable(
                try DeformableRegistrationTransform(displacementField: field)
            )
        )
    }

    @Test("[Unit][VOX-REG-004] a compatible chain composes and spans it")
    func aCompatibleChainComposesAndSpansIt() throws {
        let composed = try RegistrationTransformComposition.compose(
            try rigid(from: "atlas", to: "template", translationX: 2),
            after: try rigid(from: "subject", to: "atlas", translationX: 3)
        )
        #expect(composed.sourceSpace.id.rawValue == "subject")
        #expect(composed.destinationSpace.id.rawValue == "template")
        guard case .rigid(let motion) = composed.category else {
            Issue.record("rigid pair left the rigid category")
            return
        }
        #expect(motion.translation == [5, 0, 0])
    }

    @Test("[Unit][VOX-REG-004] mixed pairs widen honestly to affine")
    func mixedPairsWidenHonestlyToAffine() throws {
        let affine = RegistrationTransform(
            sourceSpace: try space("atlas"),
            destinationSpace: try space("template"),
            category: .affine(
                try AffineRegistrationTransform(
                    matrix: try Matrix4x4Double(elements: [
                        2, 0, 0, 0,
                        0, 2, 0, 0,
                        0, 0, 2, 0,
                        0, 0, 0, 1,
                    ])
                )
            )
        )
        let composed = try RegistrationTransformComposition.compose(
            affine,
            after: try rigid(from: "subject", to: "atlas", translationX: 1)
        )
        guard case .affine(let widened) = composed.category else {
            Issue.record("mixed pair did not widen to affine")
            return
        }
        #expect(
            widened.matrix.elements == [
                2, 0, 0, 2,
                0, 2, 0, 0,
                0, 0, 2, 0,
                0, 0, 0, 1,
            ]
        )
    }

    @Test("[Unit][VOX-REG-004] seam validation is full-descriptor equality")
    func seamValidationIsFullDescriptorEquality() throws {
        // Different identifiers refuse.
        #expect(throws: RegistrationCompositionError.incompatibleSpaces) {
            _ = try RegistrationTransformComposition.compose(
                try rigid(from: "atlas", to: "template"),
                after: try rigid(from: "subject", to: "somewhere-else")
            )
        }
        // The same identifier with a different convention refuses too:
        // a matching name over disagreeing meaning is not compatibility.
        let renamedAtlas = RegistrationTransform(
            sourceSpace: try space("atlas", convention: .neuroimagingRAS),
            destinationSpace: try space("template"),
            category: (try rigid(from: "atlas", to: "template")).category
        )
        #expect(throws: RegistrationCompositionError.incompatibleSpaces) {
            _ = try RegistrationTransformComposition.compose(
                renamedAtlas,
                after: try rigid(from: "subject", to: "atlas")
            )
        }
    }

    @Test("[Unit][VOX-REG-004] deformable operands refuse composition typed")
    func deformableOperandsRefuseCompositionTyped() throws {
        #expect(throws: RegistrationCompositionError.unsupportedComposition) {
            _ = try RegistrationTransformComposition.compose(
                try rigid(from: "atlas", to: "template"),
                after: try deformable(from: "subject", to: "atlas")
            )
        }
    }
}
