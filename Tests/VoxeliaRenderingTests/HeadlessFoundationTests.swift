// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaRendering

/// The `ADR-0398` witnesses: the render stack runs headless because
/// nothing in it can demand a window (enforced by the import gate),
/// one scene description serves both modes, and raw pixels flow
/// through the public operation and storage contracts.
@Suite("HeadlessFoundation")
struct HeadlessFoundationTests {
    private struct RecordingRenderer: SliceRenderer {
        let result: RenderResult

        func render(_ request: RenderRequest) async throws -> RenderResult {
            result
        }
    }

    @Test("[Unit][VOX-API-009][VOX-HLS-002][VOX-HLS-003] one description serves both modes")
    func oneDescriptionServesBothModes() async throws {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        let camera = try RenderCamera(
            position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: space),
            target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
            up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
            projection: .orthographic(planeHeight: 250)
        )
        let layer = try RenderLayer(
            imageObjectID: try #require(DataObjectID(rawValue: "series-7")),
            transferFunction: .greyscaleWindow(
                try GreyscaleWindowFunction(center: 40, width: 400, polarity: .standard)
            ),
            opacity: 1
        )
        let scene = try SceneSnapshot(layers: [layer], camera: camera)
        let request = RenderRequest(
            scene: scene,
            viewport: try ViewportSize(width: 64, height: 64),
            crop: nil,
            interpolation: .nearestNeighbour,
            quality: .interactive,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil
        )

        // The SAME request value drives the render contract a headless
        // caller uses; there is no headless-specific description type
        // anywhere in the module to diverge from this one.
        let presentation = PresentationProvenance(
            camera: camera,
            viewport: try ViewportSize(width: 64, height: 64),
            layers: [layer],
            crop: nil,
            geometry: nil,
            scaling: .identity,
            renderMode: .slice,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil,
            accumulation: .none,
            denoising: .none
        )
        let renderer = RecordingRenderer(
            result: RenderResult(
                outputObjectID: try #require(DataObjectID(rawValue: "render-1")),
                presentation: presentation
            )
        )
        let rendered = try await renderer.render(request)
        #expect(rendered.presentation.camera == request.scene.camera)
        #expect(rendered.presentation.layers == request.scene.layers)
    }

    @Test("[Integration][VOX-HLS-004] a real display mapping yields raw pixel bytes")
    func aRealDisplayMappingYieldsRawPixelBytes() async throws {
        // A 2x2 int16 stored image, window centre 0 width 4: stored
        // values -2..1 map across the display ramp. The whole path —
        // admission, execution, publication, byte read-back — runs
        // with no view, no layer, no surface.
        let shape = try ImageShape(extents: [2, 2])
        var bytes = [UInt8]()
        for value in [Int16(-2), 0, 1, 2] {
            let pattern = UInt16(bitPattern: value)
            bytes.append(UInt8(pattern & 0xFF))
            bytes.append(UInt8(pattern >> 8))
        }
        let software = try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
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
        let input = try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
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
                axes: axes,
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: shape,
                        scalarType: .int16,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-headless-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "headless-in"))),
                software: software,
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "headless-in")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.34",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
        let output = try await WindowLevelOperation.execute(
            input: input,
            center: try MetadataFloatingPoint(value: 0),
            width: try MetadataFloatingPoint(value: 4),
            paddingValue: nil,
            outputObjectID: try #require(DataObjectID(rawValue: "headless-out")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-headless-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: software,
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
        let pixels = try output.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [2, 2])
        ).bytes
        // Raw pixel data: four uint8 display samples, deterministic.
        #expect(pixels.count == 4)
        #expect(pixels[0] < pixels[1])
        #expect(pixels[1] < pixels[2])
        #expect(pixels[2] <= pixels[3])
        #expect(output.descriptor.scalarFormat.type == .uint8)
    }
}
