// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("MaskEditOperation")
struct MaskEditOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func mask(name: String, bytes: [UInt8]) throws -> ImageData {
        let shape = try ImageShape(extents: [4, 1])
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
                axes: [
                    try AxisDescriptor(
                        id: try #require(AxisID(rawValue: "x")),
                        name: "x",
                        semantic: .spatialX,
                        unit: nil,
                        sampling: .indexOnly
                    ),
                    try AxisDescriptor(
                        id: try #require(AxisID(rawValue: "y")),
                        name: "y",
                        semantic: .spatialY,
                        unit: nil,
                        sampling: .indexOnly
                    ),
                ],
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
                        identifier: "1.2.840.113619.21",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func execute(
        base: ImageData,
        edit: ImageData,
        verb: MaskEditVerb
    ) async throws -> ImageData {
        try await MaskEditOperation.execute(
            base: base,
            edit: edit,
            verb: verb,
            outputObjectID: try #require(DataObjectID(rawValue: "edited-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func bytes(_ image: ImageData) throws -> [UInt8] {
        try image.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 1])
        ).bytes
    }

    @Test("[Operation][VOX-SEG-008] the three verbs match the oracle exactly")
    func threeVerbsMatchTheOracleExactly() async throws {
        let base = try mask(name: "base", bytes: [1, 1, 0, 0])
        let edit = try mask(name: "edit", bytes: [1, 0, 1, 0])
        #expect(try bytes(try await execute(base: base, edit: edit, verb: .union)) == [1, 1, 1, 0])
        #expect(
            try bytes(try await execute(base: base, edit: edit, verb: .subtract))
                == [0, 1, 0, 0]
        )
        #expect(
            try bytes(try await execute(base: base, edit: edit, verb: .intersect))
                == [1, 0, 0, 0]
        )
    }

    @Test("[Operation][VOX-SEG-008] the undo witness: editing never mutates the base")
    func undoWitnessEditingNeverMutatesTheBase() async throws {
        let base = try mask(name: "base", bytes: [1, 1, 0, 0])
        let edit = try mask(name: "edit", bytes: [1, 0, 1, 0])
        let output = try await execute(base: base, edit: edit, verb: .subtract)
        // The base is intact: undo is the host's re-reference of the
        // retained prior object.
        #expect(try bytes(base) == [1, 1, 0, 0])
        #expect(output.identity.objectID.rawValue == "edited-1")

        // Provenance carries both input edges and the verb.
        #expect(output.provenance.inputs.count == 2)
        let roles = Set(output.provenance.inputs.map(\.role.rawValue))
        #expect(roles == ["base", "edit"])
        guard case .operation(let operation, _) = output.provenance.activity else {
            #expect(Bool(false), "Expected an operation activity.")
            return
        }
        #expect(operation.operationID.rawValue == "org.voxelia.op.mask-edit")
    }

    @Test("[Unit][VOX-SEG-008] admissions reject typed")
    func admissionsRejectTyped() async throws {
        let base = try mask(name: "base", bytes: [1, 1, 0, 0])
        let corrupt = try mask(name: "corrupt", bytes: [1, 2, 0, 0])
        await #expect(throws: MaskEditError.invalidMaskValue) {
            _ = try await execute(base: base, edit: corrupt, verb: .union)
        }
    }
}
