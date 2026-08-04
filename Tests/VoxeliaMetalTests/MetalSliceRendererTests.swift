// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaMetal

@Suite("MetalSliceRenderer")
struct MetalSliceRendererTests {
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

    private func originImage(
        _ objectName: String,
        valueTransform: ValueTransform? = nil
    ) throws -> ImageData {
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
                valueTransform: valueTransform,
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
                id: try #require(ProvenanceID(rawValue: "record-\(objectName)")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T05:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: objectName))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: objectName)),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: Array(0..<12)
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.\(objectName)",
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

    private func makeRenderer(
        publisher: PublicationCoordinator,
        prefix: String
    ) throws -> MetalSliceRenderer {
        let context = try MetalExecutionContext()
        return MetalSliceRenderer(
            kernel: try MetalWindowLevelKernel(context: context),
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
                    outputObjectID: DataObjectID(rawValue: "\(prefix)-\(suffix)")!,
                    provenanceID: ProvenanceID(rawValue: "record-\(prefix)-\(suffix)")!,
                    createdAt: try CanonicalInstant(
                        utcString: "2026-08-05T05:05:00Z"
                    )
                )
            }
        )
    }

    private func scene(
        _ objectName: String,
        opacity: Double = 1
    ) throws -> SceneSnapshot {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        return try SceneSnapshot(
            layers: [
                try RenderLayer(
                    imageObjectID: try #require(DataObjectID(rawValue: objectName)),
                    transferFunction: .greyscaleWindow(
                        try GreyscaleWindowFunction(center: 6, width: 8)
                    ),
                    opacity: opacity
                )
            ],
            camera: try RenderCamera(
                position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: space),
                target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
                up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
                projection: .orthographic(planeHeight: 250)
            )
        )
    }

    @Test("[Integration][VOX-VS1-017][VOX-PLT-013] the device path renders with honest claims")
    func devicePathRendersWithHonestClaims() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage("series-7"), mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "grender-1")

        // The device render reproduces the registered binary64 fixture
        // on this hardware — the measured differential for this
        // window — and publishes with the honest device claim.
        let result = try await renderer.render(
            RenderRequest(
                scene: try scene("series-7"),
                viewport: try ViewportSize(width: 4, height: 3),
                quality: .full
            )
        )
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let outputBytes = try published.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        ).bytes
        let reference: [UInt8] = [0, 0, 0, 36, 73, 109, 146, 182, 219, 255, 255, 255]
        let exactCount = zip(outputBytes, reference).count(where: ==)
        print(
            "ADR-0092 differential evidence: \(exactCount)/\(reference.count) "
                + "device samples exactly match the binary64 model on this device."
        )
        #expect(outputBytes == reference)

        guard
            case .operation(let operation, let claim) = published.provenance.activity
        else {
            #expect(Bool(false), "Expected an operation activity.")
            return
        }
        #expect(
            operation.implementationID.rawValue
                == "org.voxelia.impl.window-level.metal"
        )
        #expect(
            claim.precisionPolicy.rawValue == "org.voxelia.precision.binary32-device"
        )
        #expect(claim.approximationStatus == .approximate)
        #expect(claim.backend.identifier.rawValue == "org.voxelia.backend.metal")
        #expect(
            claim.kernel?.identifier.rawValue == "org.voxelia.kernel.window-level"
        )
        #expect(
            claim.capabilityClass?.rawValue == "org.voxelia.capability.metal3"
        )

        // Both implementations digest the one frozen parameter
        // authority, so the recipes differ only in implementation and
        // claim.
        let expectedDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try WindowLevelOperation.parameterCollection(
                    center: try MetadataFloatingPoint(value: 6),
                    width: try MetadataFloatingPoint(value: 8)
                ),
                maximumOutputByteCount: 65_536
            )
        )
        #expect(operation.parameterDigest == expectedDigest)

        requireSendable(MetalSliceRenderer.self)
    }

    @Test("[Integration][VOX-ERR-001] device admission rejects a value transform typed")
    func deviceAdmissionRejectsAValueTransformTyped() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(
            try originImage(
                "series-8",
                valueTransform: .linear(
                    try LinearValueTransformDescriptor(scale: 2, offset: -3)
                )
            ),
            mode: .complete
        )
        let renderer = try makeRenderer(publisher: publisher, prefix: "grender-2")

        // The kernel implements the plain registered model, so a
        // stored-to-real transform rejects typed on the device path
        // while the CPU path composes it.
        do {
            _ = try await renderer.render(
                RenderRequest(
                    scene: try scene("series-8"),
                    viewport: try ViewportSize(width: 4, height: 3),
                    quality: .full
                )
            )
            #expect(Bool(false), "Expected a value transform to be rejected.")
        } catch WindowLevelError.unsupportedValueTransform {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
