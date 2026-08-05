// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaMetal

@Suite("PipelineArchival")
struct PipelineArchivalTests {
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

    private func originImage() throws -> ImageData {
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .uint8,
            componentCount: 1
        )
        return try ImageData(
            descriptor: try ImageDescriptor(
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
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: binding,
                    bytes: Array(0..<12)
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-series-7")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T05:40:00Z"),
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

    @Test("[Integration][VOX-VAL-007][VOX-STO-004] a full render's history archives verified")
    func fullRenderHistoryArchivesVerified() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("voxelia-pipeline-archival")
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try CanonicalDocumentStore(directoryURL: directory)

        // Render a two-layer scene to a doubled viewport, producing
        // the full stage history: two window-levelled layers, one
        // composite and one resample.
        let publisher = PublicationCoordinator(
            maximumPublishedObjectCount: 8,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 16,
                maximumParentEdgeCount: 16,
                maximumAncestryDepth: 16,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 64
            ),
            resultCache: nil
        )
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let renderer = ExactSliceRenderer(
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 96
            ),
            software: try software(),
            naming: { stage in
                let suffix: String
                switch stage {
                case .windowLevelled(let layerIndex):
                    suffix = "wl\(layerIndex)"
                case .composited:
                    suffix = "cp"
                case .resampled:
                    suffix = "rs"
                }
                return (
                    outputObjectID: DataObjectID(rawValue: "stage-\(suffix)")!,
                    provenanceID: ProvenanceID(rawValue: "record-stage-\(suffix)")!,
                    createdAt: try CanonicalInstant(
                        utcString: "2026-08-05T05:45:00Z"
                    )
                )
            }
        )
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        let result = try await renderer.render(
            RenderRequest(
                scene: try SceneSnapshot(
                    layers: [
                        try RenderLayer(
                            imageObjectID: try #require(
                                DataObjectID(rawValue: "series-7")
                            ),
                            transferFunction: .greyscaleWindow(
                                try GreyscaleWindowFunction(center: 6, width: 8)
                            ),
                            opacity: 1
                        ),
                        try RenderLayer(
                            imageObjectID: try #require(
                                DataObjectID(rawValue: "series-7")
                            ),
                            transferFunction: .greyscaleWindow(
                                try GreyscaleWindowFunction(center: 3, width: 6)
                            ),
                            opacity: 0.5
                        ),
                    ],
                    camera: try RenderCamera(
                        position: try Point3D(
                            x: 0,
                            y: 0,
                            z: -100,
                            coordinateSpace: space
                        ),
                        target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
                        up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
                        projection: .orthographic(planeHeight: 250)
                    )
                ),
                viewport: try ViewportSize(width: 8, height: 6),
                quality: .full
            )
        )
        #expect(result.outputObjectID.rawValue == "stage-rs")
        #expect(await publisher.publishedObjectCount == 5)

        // Archive every published bundle — the origin without a
        // derivation name, every stage with one — and prove every
        // document ingress-exact against its published record.
        let bundles: [(object: String, derived: Bool)] = [
            ("series-7", false),
            ("stage-wl0", true),
            ("stage-wl1", true),
            ("stage-cp", true),
            ("stage-rs", true),
        ]
        for bundle in bundles {
            let objectID = try #require(DataObjectID(rawValue: bundle.object))
            let image = try #require(await publisher.publishedImage(for: objectID))
            let provenanceName = try CanonicalDocumentName(
                rawValue: "arch-\(bundle.object)"
            )
            let derivationName =
                bundle.derived
                ? try CanonicalDocumentName(rawValue: "recipe-\(bundle.object)")
                : nil
            let receipt = try await CanonicalRecordArchival.archive(
                image,
                provenanceName: provenanceName,
                derivationName: derivationName,
                store: store,
                maximumDocumentByteCount: 65_536
            )
            let provenanceBytes = try await store.load(
                name: provenanceName,
                expectedIdentity: receipt.provenanceIdentity,
                maximumDocumentByteCount: 65_536
            )
            #expect(
                try CanonicalProvenanceJSON.decodeRecordDocument(
                    from: provenanceBytes,
                    maximumInputByteCount: 65_536
                ) == image.provenance
            )
            if let derivationName {
                let derivationIdentity = try #require(receipt.derivationIdentity)
                let derivationBytes = try await store.load(
                    name: derivationName,
                    expectedIdentity: derivationIdentity,
                    maximumDocumentByteCount: 65_536
                )
                #expect(
                    try CanonicalDerivationJSON.decodeRecordDocument(
                        from: derivationBytes,
                        maximumInputByteCount: 65_536
                    ) == image.identity.derivation
                )
            } else {
                #expect(receipt.derivationIdentity == nil)
            }
        }
    }
}
