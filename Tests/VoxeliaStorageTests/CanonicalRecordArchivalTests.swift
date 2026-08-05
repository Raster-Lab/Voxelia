// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaStorage

@Suite("CanonicalRecordArchival")
struct CanonicalRecordArchivalTests {
    private func freshDirectory(_ suffix: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voxelia-record-archival-\(suffix)")
        try? FileManager.default.removeItem(at: url)
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

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

    private func descriptor() throws -> ImageDescriptor {
        try ImageDescriptor(
            shape: try ImageShape(extents: [4, 3]),
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
            valueTransform: nil,
            units: nil
        )
    }

    private func storage(_ bytes: [UInt8]) throws -> AnyImageStorage {
        AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: try ImageShape(extents: [4, 3]),
                    scalarType: .uint8,
                    componentCount: 1
                ),
                bytes: bytes
            )
        )
    }

    private func originImage() throws -> ImageData {
        try ImageData(
            descriptor: try descriptor(),
            storage: try storage(Array(0..<12)),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-origin")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T05:30:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "series-7"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "series-7")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: Array(0..<12)
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.2",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func derivedImage() throws -> ImageData {
        let version = try SemanticVersion(major: 1, minor: 4, patch: 0)
        let operationToken = try DerivationOperationToken(
            rawValue: "org.voxelia.op.window-level"
        )
        let implementationToken = try DerivationOperationToken(
            rawValue: "org.voxelia.impl.window-level.cpu"
        )
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: 4_096
            )
        )
        let derivation = try DerivationIdentity(
            operationID: operationToken,
            operationVersion: version,
            implementation: DerivationImplementationReference(
                identifier: implementationToken,
                version: version
            ),
            inputs: [
                DerivationInput(
                    role: try DerivationInputRole(rawValue: "input"),
                    identity: .object(try #require(DataObjectID(rawValue: "series-7")))
                )
            ],
            parameterDigest: parameterDigest,
            declaresZeroInputGenerator: false
        )
        let claim = ExecutionProvenanceClaim(
            profile: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.profile.default"
                ),
                version: version
            ),
            backend: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.backend.cpu"
                ),
                version: version
            ),
            precisionPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.precision.binary64-strict"
            ),
            qualityPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.quality.full"
            ),
            approximationStatus: .exact,
            capabilityClass: nil,
            kernel: nil
        )
        let bytes: [UInt8] = [0, 0, 0, 36, 73, 109, 146, 182, 219, 255, 255, 255]
        return try ImageData(
            descriptor: try descriptor(),
            storage: try storage(bytes),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-derived")),
                kind: .transformed,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T05:31:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "series-8"))),
                software: try software(),
                activity: .operation(
                    try OperationProvenance(
                        operationID: operationToken,
                        operationVersion: version,
                        implementationID: implementationToken,
                        implementationVersion: version,
                        parameterDigest: parameterDigest
                    ),
                    claim
                ),
                inputs: [
                    try ProvenanceInput(
                        role: try ProvenanceInputRole(rawValue: "input"),
                        occurrence: 1,
                        identity: .object(
                            try #require(DataObjectID(rawValue: "series-7"))
                        ),
                        parent: .graphNode(
                            try #require(ProvenanceID(rawValue: "record-origin"))
                        )
                    )
                ],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "series-8")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [],
                derivation: derivation
            )
        )
    }

    @Test("[Unit][VOX-STO-004][VOX-CON-006] archived records round-trip verified")
    func archivedRecordsRoundTripVerified() async throws {
        let directory = try freshDirectory("round-trip")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try CanonicalDocumentStore(directoryURL: directory)
        let provenanceName = try CanonicalDocumentName(rawValue: "record-origin")

        // An origin bundle archives its provenance document only, and
        // the stored bytes decode through the strict ingress to the
        // exact record; same-content re-archive is idempotent.
        let origin = try originImage()
        let originReceipt = try await CanonicalRecordArchival.archive(
            origin,
            provenanceName: provenanceName,
            derivationName: nil,
            store: store,
            maximumDocumentByteCount: 65_536
        )
        #expect(originReceipt.derivationIdentity == nil)
        #expect(await store.contains(name: provenanceName))
        let loadedOrigin = try await store.load(
            name: provenanceName,
            expectedIdentity: originReceipt.provenanceIdentity,
            maximumDocumentByteCount: 65_536
        )
        #expect(
            try CanonicalProvenanceJSON.decodeRecordDocument(
                from: loadedOrigin,
                maximumInputByteCount: 65_536
            ) == origin.provenance
        )
        _ = try await CanonicalRecordArchival.archive(
            origin,
            provenanceName: provenanceName,
            derivationName: nil,
            store: store,
            maximumDocumentByteCount: 65_536
        )

        // A derived bundle archives both records, each verifiable and
        // ingress-exact.
        let derived = try derivedImage()
        let derivedProvenanceName = try CanonicalDocumentName(
            rawValue: "record-derived"
        )
        let derivationName = try CanonicalDocumentName(rawValue: "recipe-derived")
        let derivedReceipt = try await CanonicalRecordArchival.archive(
            derived,
            provenanceName: derivedProvenanceName,
            derivationName: derivationName,
            store: store,
            maximumDocumentByteCount: 65_536
        )
        let derivationIdentity = try #require(derivedReceipt.derivationIdentity)
        let loadedDerivation = try await store.load(
            name: derivationName,
            expectedIdentity: derivationIdentity,
            maximumDocumentByteCount: 65_536
        )
        #expect(
            try CanonicalDerivationJSON.decodeRecordDocument(
                from: loadedDerivation,
                maximumInputByteCount: 65_536
            ) == derived.identity.derivation
        )
        let loadedDerived = try await store.load(
            name: derivedProvenanceName,
            expectedIdentity: derivedReceipt.provenanceIdentity,
            maximumDocumentByteCount: 65_536
        )
        #expect(
            try CanonicalProvenanceJSON.decodeRecordDocument(
                from: loadedDerived,
                maximumInputByteCount: 65_536
            ) == derived.provenance
        )

        requireSendable(ArchivedRecordReceipt.self)
        requireSendable(CanonicalArchivalError.self)
    }

    @Test("[Unit][VOX-ERR-001] name presence must match record presence")
    func namePresenceMustMatchRecordPresence() async throws {
        let directory = try freshDirectory("presence")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try CanonicalDocumentStore(directoryURL: directory)
        let name = try CanonicalDocumentName(rawValue: "record-a")
        let extra = try CanonicalDocumentName(rawValue: "recipe-a")

        // A derivation without a name and a name without a derivation
        // both reject typed, and nothing touches the store.
        do {
            _ = try await CanonicalRecordArchival.archive(
                try derivedImage(),
                provenanceName: name,
                derivationName: nil,
                store: store,
                maximumDocumentByteCount: 65_536
            )
            #expect(Bool(false), "Expected a missing derivation name to be rejected.")
        } catch CanonicalArchivalError.missingDerivationName {}
        do {
            _ = try await CanonicalRecordArchival.archive(
                try originImage(),
                provenanceName: name,
                derivationName: extra,
                store: store,
                maximumDocumentByteCount: 65_536
            )
            #expect(
                Bool(false),
                "Expected an unexpected derivation name to be rejected."
            )
        } catch CanonicalArchivalError.unexpectedDerivationName {}
        #expect(await store.contains(name: name) == false)
        #expect(await store.contains(name: extra) == false)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
