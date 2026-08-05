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
            kernel: try MetalWindowLevelKernel(context: context, telemetrySink: nil),
            invertKernel: try MetalInvertKernel(context: context, telemetrySink: nil),
            compositeKernel: try MetalCompositeKernel(context: context, telemetrySink: nil),
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
                case .inverted(let layerIndex):
                    suffix = "iv\(layerIndex)"
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
                        try GreyscaleWindowFunction(center: 6, width: 8, polarity: .standard)
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
                crop: nil,
                interpolation: .nearestNeighbour,
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
                    width: try MetadataFloatingPoint(value: 8),
                    paddingValue: nil
                ),
                maximumOutputByteCount: 65_536
            )
        )
        #expect(operation.parameterDigest == expectedDigest)

        requireSendable(MetalSliceRenderer.self)
    }

    @Test("[Integration][VOX-VS1-017][VOX-PLT-013] both device stages render end to end")
    func bothDeviceStagesRenderEndToEnd() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage("series-7"), mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "grender-3")

        // A two-layer scene runs the window and composite stages on
        // the device per ADR-0099; the result stays within one display
        // level of the registered binary64 fixture, measured on this
        // hardware.
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
                                try GreyscaleWindowFunction(
                                    center: 6, width: 8, polarity: .standard)
                            ),
                            opacity: 1
                        ),
                        try RenderLayer(
                            imageObjectID: try #require(
                                DataObjectID(rawValue: "series-7")
                            ),
                            transferFunction: .greyscaleWindow(
                                try GreyscaleWindowFunction(
                                    center: 3, width: 6, polarity: .standard)
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
                viewport: try ViewportSize(width: 4, height: 3),
                crop: nil,
                interpolation: .nearestNeighbour,
                quality: .full
            )
        )
        #expect(result.outputObjectID.rawValue == "grender-3-cp")
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let outputBytes = try published.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        ).bytes
        let reference: [UInt8] = [0, 26, 51, 94, 138, 182, 200, 218, 237, 255, 255, 255]
        let exactCount = zip(outputBytes, reference).count(where: ==)
        for (produced, expected) in zip(outputBytes, reference) {
            #expect(abs(Int(produced) - Int(expected)) <= 1)
        }
        print(
            "ADR-0099 differential evidence: \(exactCount)/\(reference.count) "
                + "fully-device samples exactly match the binary64 model on this device."
        )

        // Both stage records carry their honest device claims.
        let windowRecordID = try #require(
            ProvenanceID(rawValue: "record-grender-3-wl0")
        )
        let windowRecord = try #require(
            await publisher.publishedProvenanceRecord(for: windowRecordID)
        )
        guard case .operation(let windowOperation, let windowClaim) = windowRecord.activity
        else {
            #expect(Bool(false), "Expected a window operation activity.")
            return
        }
        #expect(
            windowOperation.implementationID.rawValue
                == "org.voxelia.impl.window-level.metal"
        )
        #expect(
            windowClaim.kernel?.identifier.rawValue == "org.voxelia.kernel.window-level"
        )
        guard
            case .operation(let compositeOperation, let compositeClaim) =
                published.provenance.activity
        else {
            #expect(Bool(false), "Expected a composite operation activity.")
            return
        }
        #expect(
            compositeOperation.implementationID.rawValue
                == "org.voxelia.impl.composite-layers.metal"
        )
        #expect(
            compositeClaim.kernel?.identifier.rawValue
                == "org.voxelia.kernel.composite-layers"
        )
        #expect(
            compositeClaim.precisionPolicy.rawValue
                == "org.voxelia.precision.binary32-device"
        )
        #expect(compositeClaim.approximationStatus == .approximate)
        #expect(
            compositeClaim.capabilityClass?.rawValue == "org.voxelia.capability.metal3"
        )
    }

    private func int16Origin(_ objectName: String) throws -> ImageData {
        let stored: [Int16] = [
            -1024, -200, -100, 0, 20, 40, 60, 80, 120, 200, 1000, 3000,
        ]
        var bytes = [UInt8]()
        for value in stored {
            withUnsafeBytes(of: value.littleEndian) { bytes.append(contentsOf: $0) }
        }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: [4, 3]),
                scalarFormat: try ScalarFormat(
                    type: .int16,
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
                    binding: try LogicalSampleBinding(
                        shape: try ImageShape(extents: [4, 3]),
                        scalarType: .int16,
                        componentCount: 1
                    ),
                    bytes: bytes
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
                    overCanonicalPackedBytes: bytes
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

    @Test("[Integration][VOX-VAL-007][VOX-PLT-011] a sixteen-bit scene renders on the device")
    func sixteenBitSceneRendersOnTheDevice() async throws {
        let publisher = try publisher()
        let origin = try int16Origin("series-ct")
        _ = try await publisher.publish(origin, mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "grender-4")

        // The ADR-0093 sixteen-bit device path proves itself inside
        // the full pipeline: an int16 origin renders end to end and
        // stays within one display level of the CPU implementation,
        // measured on this hardware.
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        let result = try await renderer.render(
            RenderRequest(
                scene: try SceneSnapshot(
                    layers: [
                        try RenderLayer(
                            imageObjectID: origin.identity.objectID,
                            transferFunction: .greyscaleWindow(
                                try GreyscaleWindowFunction(
                                    center: 40, width: 400, polarity: .standard)
                            ),
                            opacity: 1
                        )
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
                viewport: try ViewportSize(width: 4, height: 3),
                crop: nil,
                interpolation: .nearestNeighbour,
                quality: .full
            )
        )
        #expect(result.outputObjectID.rawValue == "grender-4-wl0")
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let outputBytes = try published.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        ).bytes
        let reference = try await WindowLevelOperation.execute(
            input: origin,
            center: try MetadataFloatingPoint(value: 40),
            width: try MetadataFloatingPoint(value: 400),
            paddingValue: nil,
            outputObjectID: try #require(DataObjectID(rawValue: "reference-ct")),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "record-reference-ct")
            ),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T05:05:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
        let referenceBytes = try reference.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        ).bytes
        let exactCount = zip(outputBytes, referenceBytes).count(where: ==)
        for (produced, expected) in zip(outputBytes, referenceBytes) {
            #expect(abs(Int(produced) - Int(expected)) <= 1)
        }
        print(
            "ADR-0093 pipeline evidence: \(exactCount)/\(referenceBytes.count) "
                + "sixteen-bit device samples exactly match the CPU implementation."
        )
        guard case .operation(let operation, _) = published.provenance.activity
        else {
            #expect(Bool(false), "Expected an operation activity.")
            return
        }
        #expect(
            operation.implementationID.rawValue
                == "org.voxelia.impl.window-level.metal"
        )
    }

    @Test("[Integration][VOX-R2D-005][VOX-PLT-013] inverted scenes run fully on the device")
    func invertedScenesRunFullyOnTheDevice() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage("series-7"), mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "grender-5")

        // The ADR-0133 device inversion: the integer-exact kernel
        // produces exactly the inverted registered fixture, and the
        // stage record carries the exact device claim.
        let result = try await renderer.render(
            RenderRequest(
                scene: try SceneSnapshot(
                    layers: [
                        try RenderLayer(
                            imageObjectID: try #require(
                                DataObjectID(rawValue: "series-7")
                            ),
                            transferFunction: .greyscaleWindow(
                                try GreyscaleWindowFunction(
                                    center: 6,
                                    width: 8,
                                    polarity: .inverted
                                )
                            ),
                            opacity: 1
                        )
                    ],
                    camera: try RenderCamera(
                        position: try Point3D(
                            x: 0,
                            y: 0,
                            z: -100,
                            coordinateSpace: try #require(
                                CoordinateSpaceID(rawValue: "patient")
                            )
                        ),
                        target: try Point3D(
                            x: 0,
                            y: 0,
                            z: 0,
                            coordinateSpace: try #require(
                                CoordinateSpaceID(rawValue: "patient")
                            )
                        ),
                        up: try Vector3D(
                            x: 0,
                            y: 1,
                            z: 0,
                            coordinateSpace: try #require(
                                CoordinateSpaceID(rawValue: "patient")
                            )
                        ),
                        projection: .orthographic(planeHeight: 250)
                    )
                ),
                viewport: try ViewportSize(width: 4, height: 3),
                crop: nil,
                interpolation: .nearestNeighbour,
                quality: .full
            )
        )
        #expect(result.outputObjectID.rawValue == "grender-5-iv0")
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        #expect(
            try published.storage.read(
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
            ).bytes == [255, 255, 255, 219, 182, 146, 109, 73, 36, 0, 0, 0]
        )
        guard case .operation(let operation, let claim) = published.provenance.activity
        else {
            #expect(Bool(false), "Expected an operation activity.")
            return
        }
        #expect(
            operation.implementationID.rawValue
                == "org.voxelia.impl.invert-display.metal"
        )
        #expect(claim.precisionPolicy.rawValue == "org.voxelia.precision.exact")
        #expect(claim.approximationStatus == .exact)
        #expect(
            claim.kernel?.identifier.rawValue == "org.voxelia.kernel.invert-display"
        )
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
                    crop: nil,
                    interpolation: .nearestNeighbour,
                    quality: .full
                )
            )
            #expect(Bool(false), "Expected a value transform to be rejected.")
        } catch WindowLevelError.unsupportedValueTransform {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
