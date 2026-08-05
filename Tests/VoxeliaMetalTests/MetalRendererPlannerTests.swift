// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaMetal

@Suite("MetalRendererPlanner")
struct MetalRendererPlannerTests {
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
                createdAt: try CanonicalInstant(utcString: "2026-08-05T06:00:00Z"),
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

    private func publisher() throws -> PublicationCoordinator {
        PublicationCoordinator(
            maximumPublishedObjectCount: 8,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 8,
                maximumParentEdgeCount: 8,
                maximumAncestryDepth: 8,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 64
            ),
            resultCache: nil
        )
    }

    private func request() throws -> RenderRequest {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        return RenderRequest(
            scene: try SceneSnapshot(
                layers: [
                    try RenderLayer(
                        imageObjectID: try #require(DataObjectID(rawValue: "series-7")),
                        transferFunction: .greyscaleWindow(
                            try GreyscaleWindowFunction(center: 6, width: 8)
                        ),
                        opacity: 1
                    )
                ],
                camera: try RenderCamera(
                    position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: space),
                    target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
                    up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
                    projection: .orthographic(planeHeight: 250)
                )
            ),
            viewport: try ViewportSize(width: 4, height: 3),
            crop: nil,
            quality: .full
        )
    }

    @Test("[Integration][VOX-CCH-002][VOX-CCH-003] every policy plans a reported backend")
    func everyPolicyPlansAReportedBackend() async throws {
        // The version-one selection rules on this device-bearing host,
        // with every selection reported through the plan — the plan is
        // the report.
        let expectations: [(BackendPolicy, RendererBackendSelection)] = [
            (.reference, .exactCPU),
            (.cpuPreferred, .exactCPU),
            (.gpuPreferred, .device),
            (.automatic, .device),
        ]
        for (index, expectation) in expectations.enumerated() {
            let publisher = try publisher()
            _ = try await publisher.publish(try originImage(), mode: .complete)
            let prefix = "plan-\(index)"
            let plan = MetalRendererPlanner.plan(
                policy: expectation.0,
                publisher: publisher,
                readCoordinator: StorageReadCoordinator(
                    maximumRetainedResultByteCount: 96
                ),
                software: try software(),
                naming: { stage in
                    let suffix: String
                    switch stage {
                    case .cropped(let layerIndex):
                        suffix = "cr\(layerIndex)"
                    case .windowLevelled(let layerIndex):
                        suffix = "wl\(layerIndex)"
                    case .composited:
                        suffix = "cp"
                    case .resampled:
                        suffix = "rs"
                    }
                    return (
                        outputObjectID: DataObjectID(rawValue: "\(prefix)-\(suffix)")!,
                        provenanceID: ProvenanceID(
                            rawValue: "record-\(prefix)-\(suffix)"
                        )!,
                        createdAt: try CanonicalInstant(
                            utcString: "2026-08-05T06:05:00Z"
                        )
                    )
                }
            )
            #expect(plan.policy == expectation.0)
            #expect(plan.selection == expectation.1)

            // A policy-selected renderer renders the registered
            // fixture through either backend.
            let result = try await plan.renderer.render(try request())
            let published = try #require(
                await publisher.publishedImage(for: result.outputObjectID)
            )
            let outputBytes = try published.storage.read(
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
            ).bytes
            #expect(
                outputBytes == [0, 0, 0, 36, 73, 109, 146, 182, 219, 255, 255, 255]
            )
        }

        requireSendable(BackendPolicy.self)
        requireSendable(RendererBackendSelection.self)
        requireSendable(RendererPlan.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
