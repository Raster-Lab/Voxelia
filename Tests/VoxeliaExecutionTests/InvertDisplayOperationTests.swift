// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("InvertDisplayOperation")
struct InvertDisplayOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func axis(_ id: String) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: .spatialX,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func image(
        bytes: [UInt8],
        name: String,
        valueTransform: ValueTransform? = nil
    ) throws -> ImageData {
        try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: [3, 2]),
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
                semantic: .intensity,
                axes: [try axis("x"), try axis("y")],
                spatialGeometry: nil,
                valueTransform: valueTransform,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: try ImageShape(extents: [3, 2]),
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
                createdAt: try CanonicalInstant(utcString: "2026-08-05T06:30:00Z"),
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
                        identifier: "1.2.840.113619.\(name)",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func execute(_ input: ImageData, suffix: String) async throws -> ImageData {
        try await InvertDisplayOperation.execute(
            input: input,
            outputObjectID: try #require(DataObjectID(rawValue: "inverted-\(suffix)")),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "record-inverted-\(suffix)")
            ),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T06:35:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    @Test("[Unit][VOX-EXE-002][VOX-IMG-001] the exact involution reproduces the fixtures")
    func exactInvolutionReproducesTheFixtures() async throws {
        // The VOXELIA-ALG-0011 fixture and the involution: double
        // inversion reproduces the input exactly, with the accepted
        // recipe and provenance shape.
        let source = try image(bytes: [0, 1, 127, 128, 254, 255], name: "series-m1")
        let inverted = try await execute(source, suffix: "a")
        let region = try ImageRegion(lowerBounds: [0, 0], upperBounds: [3, 2])
        #expect(
            try inverted.storage.read(region: region).bytes
                == [255, 254, 128, 127, 1, 0]
        )
        let restored = try await execute(inverted, suffix: "b")
        #expect(
            try restored.storage.read(region: region).bytes
                == [0, 1, 127, 128, 254, 255]
        )
        #expect(
            inverted.identity.derivation?.operationID.rawValue
                == "org.voxelia.op.invert-display"
        )
        #expect(inverted.provenance.inputs.count == 1)

        requireSendable(InvertDisplayError.self)
    }

    @Test("[Unit][VOX-EXE-006][VOX-ERR-001] inversion admission rejects typed")
    func inversionAdmissionRejectsTyped() async throws {
        // A value transform rejects typed; scalar-format admission
        // mirrors the accepted pattern.
        do {
            let transformed = try image(
                bytes: [0, 1, 127, 128, 254, 255],
                name: "series-m2",
                valueTransform: .identity
            )
            _ = try await execute(transformed, suffix: "c")
            #expect(Bool(false), "Expected a value transform to be rejected.")
        } catch InvertDisplayError.unsupportedValueTransform {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
