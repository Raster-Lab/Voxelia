// SPDX-License-Identifier: MIT

import Synchronization
import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaImaging
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaMetal

/// The `ADR-0221` multiplanar render path: `VOX-VS1-009` and the Test half of
/// `VOX-VS1-010`.
@Suite("Multiplanar render coordinator")
struct MultiplanarRenderCoordinatorTests {
    @Test(
        "[Pipeline][VOX-VS1-009][VOX-VS1-010] all three planes render and genuinely differ"
    )
    func allThreePlanesRenderAndGenuinelyDiffer() async throws {
        // ANISOTROPIC on purpose. A cube would let a transposed or duplicated
        // plane pass, and a test that cannot fail is not evidence.
        let publisher = try publisher()
        _ = try await publisher.publish(
            try volume(extents: [2, 3, 4], name: "mpr-volume"),
            mode: .complete
        )
        let renderer = try makeRenderer(publisher: publisher)

        var outputs = [MPRPlane: [UInt8]]()
        let planes: [MPRPlane] = [.axial, .coronal, .sagittal]
        for (index, plane) in planes.enumerated() {
            let result = try await MultiplanarRenderCoordinator.renderPlane(
                volumeID: try #require(DataObjectID(rawValue: "mpr-volume")),
                plane: plane,
                sliceIndex: 0,
                transferFunction: .greyscaleWindow(
                    try GreyscaleWindowFunction(
                        center: 12,
                        width: 24,
                        polarity: .standard
                    )
                ),
                viewport: try viewport(for: plane),
                camera: try camera(),
                interpolation: .nearestNeighbour,
                quality: .full,
                colourOutput: .greyscale8,
                colourTransform: .none,
                outputColourSpace: nil,
                naming: naming(prefix: "plane-\(index)"),
                publisher: publisher,
                readCoordinator: StorageReadCoordinator(
                    maximumRetainedResultByteCount: 256
                ),
                software: try software(),
                renderer: renderer
            )

            // The render went through the backend-neutral protocol to the
            // Metal renderer, and reports what it did.
            #expect(result.presentation.renderMode == .slice)
            #expect(result.presentation.colourOutput == .greyscale8)
            #expect(result.presentation.colourTransform == .none)
            #expect(result.presentation.outputColourSpace == nil)

            let published = try #require(
                await publisher.publishedImage(for: result.outputObjectID)
            )
            let extents = published.descriptor.shape.extents
            outputs[plane] = try published.storage.read(
                region: try ImageRegion(
                    lowerBounds: [0, 0],
                    upperBounds: ContiguousArray(extents)
                )
            ).bytes
        }

        // Each plane fixes a different axis of a 2x3x4 volume, so the three
        // reconstructions have different extents and different contents. A
        // swapped or duplicated plane fails here.
        let axial = try #require(outputs[.axial])
        let coronal = try #require(outputs[.coronal])
        let sagittal = try #require(outputs[.sagittal])
        #expect(axial.count == 6)
        #expect(coronal.count == 8)
        #expect(sagittal.count == 12)
        #expect(axial != coronal)
        #expect(coronal != sagittal)
        #expect(axial != sagittal)
    }

    @Test(
        "[Pipeline][VOX-VS1-010][VOX-API-003] the caller's colour claim reaches the request unchanged"
    )
    func callersColourClaimReachesTheRequestUnchanged() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(
            try volume(extents: [2, 3, 4], name: "claim-volume"),
            mode: .complete
        )
        let space = try DisplayColourSpace(
            namespace: "IEC",
            code: "sRGB",
            displayName: nil
        )

        // The coordinator forwards the colour claim rather than choosing it;
        // choosing would be the permissive default the house rule forbids.
        let result = try await MultiplanarRenderCoordinator.renderPlane(
            volumeID: try #require(DataObjectID(rawValue: "claim-volume")),
            plane: .axial,
            sliceIndex: 0,
            transferFunction: .greyscaleWindow(
                try GreyscaleWindowFunction(
                    center: 12,
                    width: 24,
                    polarity: .standard
                )
            ),
            viewport: try ViewportSize(width: 2, height: 3),
            camera: try camera(),
            interpolation: .nearestNeighbour,
            quality: .full,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: space,
            naming: naming(prefix: "claim"),
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 256
            ),
            software: try software(),
            renderer: try makeRenderer(publisher: publisher)
        )
        #expect(result.presentation.outputColourSpace == space)

        // The plane is recoverable from the layer's own published ancestry, so
        // it is deliberately not restated in the presentation claim.
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        #expect(!published.provenance.inputs.isEmpty)
    }

    // MARK: - Helpers

    private func viewport(for plane: MPRPlane) throws -> ViewportSize {
        switch plane {
        case .axial: try ViewportSize(width: 2, height: 3)
        case .coronal: try ViewportSize(width: 2, height: 4)
        case .sagittal: try ViewportSize(width: 3, height: 4)
        }
    }

    private func camera() throws -> RenderCamera {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        return try RenderCamera(
            position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: space),
            target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
            up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
            projection: .orthographic(planeHeight: 250)
        )
    }

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func naming(prefix: String) -> MPRPublicationNaming {
        { stage in
            let suffix = stage == .extracted ? "extract" : "squeeze"
            return (
                outputObjectID: try #require(
                    DataObjectID(rawValue: "\(prefix)-\(suffix)")
                ),
                provenanceID: try #require(
                    ProvenanceID(rawValue: "record-\(prefix)-\(suffix)")
                ),
                createdAt: try CanonicalInstant(
                    utcString: "2026-08-06T09:00:00Z"
                )
            )
        }
    }

    private func publisher() throws -> PublicationCoordinator {
        PublicationCoordinator(
            maximumPublishedObjectCount: 32,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 32,
                maximumParentEdgeCount: 32,
                maximumAncestryDepth: 16,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 256
            ),
            resultCache: nil
        )
    }

    // MARK: - CPU/Metal three-view differential (ADR-0252)

    /// The CPU reference renderer, for differential comparison.
    ///
    /// `ExactSliceRenderer` composes the accepted CPU operations and references no
    /// Metal type; `MetalSliceRenderer` runs the GPU kernels. Both conform to
    /// `SliceRenderer`, which is what makes the comparison well posed.
    private func makeCPURenderer(
        publisher: PublicationCoordinator,
        prefix: String
    ) throws -> ExactSliceRenderer {
        ExactSliceRenderer(
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 256
            ),
            software: try software(),
            naming: { stage in
                let suffix: String
                switch stage {
                case .cropped(let layerIndex): suffix = "cr\(layerIndex)"
                case .inverted(let layerIndex): suffix = "iv\(layerIndex)"
                case .windowLevelled(let layerIndex): suffix = "wl\(layerIndex)"
                case .composited: suffix = "cp"
                case .resampled: suffix = "rs"
                }
                return (
                    outputObjectID: DataObjectID(rawValue: "\(prefix)-\(suffix)")!,
                    provenanceID: ProvenanceID(
                        rawValue: "record-\(prefix)-\(suffix)"
                    )!,
                    createdAt: try CanonicalInstant(
                        utcString: "2026-08-06T09:00:00Z"
                    )
                )
            }
        )
    }

    /// Renders one plane through `renderer` and returns the published bytes.
    private func planeBytes(
        plane: MPRPlane,
        volumeName: String,
        prefix: String,
        publisher: PublicationCoordinator,
        renderer: any SliceRenderer
    ) async throws -> [UInt8] {
        let result = try await MultiplanarRenderCoordinator.renderPlane(
            volumeID: try #require(DataObjectID(rawValue: volumeName)),
            plane: plane,
            sliceIndex: 0,
            transferFunction: .greyscaleWindow(
                try GreyscaleWindowFunction(
                    center: 12,
                    width: 24,
                    polarity: .standard
                )
            ),
            viewport: try viewport(for: plane),
            camera: try camera(),
            interpolation: .nearestNeighbour,
            quality: .full,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil,
            naming: naming(prefix: prefix),
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 256
            ),
            software: try software(),
            renderer: renderer
        )
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let extents = published.descriptor.shape.extents
        return try published.storage.read(
            region: try ImageRegion(
                lowerBounds: [0, 0],
                upperBounds: ContiguousArray(extents)
            )
        ).bytes
    }

    @Test(
        "[Pipeline][VOX-VS1-010] CPU and Metal agree exactly on all three planes"
    )
    func cpuAndMetalAgreeExactlyOnAllThreePlanes() async throws {
        // The differential the plan's §53 table requires and that no suite
        // performed: the same plane, the same request, both backends, compared
        // byte for byte.
        //
        // This adds evidence to a row ADR-0221 already discharged; it does not
        // re-discharge it. The plan permits "≤ 1 code value if the rounding path
        // is approved" for 8-bit output, but §54 is explicitly provisional and
        // awaits owner approval as voxelia.m4.ct.diagnostic 1.0.0 -- so this test
        // asserts EXACT equality, which is the plan's stated preference and needs
        // no tolerance. If the backends ever diverge by even one code value, this
        // fails and the tolerance becomes an owner question rather than something
        // a test quietly absorbed.
        //
        // Anisotropic extents on purpose, per the sibling test: a cube would let a
        // transposed plane pass.
        let cpuPublisher = try publisher()
        _ = try await cpuPublisher.publish(
            try volume(extents: [2, 3, 4], name: "diff-volume"),
            mode: .complete
        )
        let metalPublisher = try publisher()
        _ = try await metalPublisher.publish(
            try volume(extents: [2, 3, 4], name: "diff-volume"),
            mode: .complete
        )
        let metalRenderer = try makeRenderer(publisher: metalPublisher)

        let planes: [MPRPlane] = [.axial, .coronal, .sagittal]
        let expectedCounts = [6, 8, 12]

        for (index, plane) in planes.enumerated() {
            let cpuBytes = try await planeBytes(
                plane: plane,
                volumeName: "diff-volume",
                prefix: "cpu-\(index)",
                publisher: cpuPublisher,
                renderer: try makeCPURenderer(
                    publisher: cpuPublisher,
                    prefix: "cpu-r\(index)"
                )
            )
            let metalBytes = try await planeBytes(
                plane: plane,
                volumeName: "diff-volume",
                prefix: "gpu-\(index)",
                publisher: metalPublisher,
                renderer: metalRenderer
            )

            // Non-vacuity: each plane's own extent, so an empty read cannot pass.
            #expect(cpuBytes.count == expectedCounts[index])
            #expect(metalBytes.count == expectedCounts[index])
            #expect(cpuBytes == metalBytes)
        }
    }

    private func makeRenderer(
        publisher: PublicationCoordinator
    ) throws -> MetalSliceRenderer {
        let context = try MetalExecutionContext()
        let counter = NamingCounter()
        return MetalSliceRenderer(
            kernel: try MetalWindowLevelKernel(
                context: context,
                telemetrySink: nil
            ),
            invertKernel: try MetalInvertKernel(
                context: context,
                telemetrySink: nil
            ),
            compositeKernel: try MetalCompositeKernel(
                context: context,
                telemetrySink: nil
            ),
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 256
            ),
            software: try software(),
            naming: { _ in
                let index = counter.next()
                return (
                    outputObjectID: try #require(
                        DataObjectID(rawValue: "render-\(index)")
                    ),
                    provenanceID: try #require(
                        ProvenanceID(rawValue: "record-render-\(index)")
                    ),
                    createdAt: try CanonicalInstant(
                        utcString: "2026-08-06T09:00:00Z"
                    )
                )
            }
        )
    }

    private final class NamingCounter: Sendable {
        private let value = Mutex(0)

        func next() -> Int {
            value.withLock { current in
                current += 1
                return current
            }
        }
    }

    private func volume(extents: [Int], name: String) throws -> ImageData {
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        let names = ["x", "y", "z"]
        let count = extents.reduce(1, *)
        let bytes = (0..<count).map { UInt8($0 * 7 % 251) }
        var axes = ContiguousArray<AxisDescriptor>()
        for index in 0..<extents.count {
            axes.append(
                try AxisDescriptor(
                    id: try #require(AxisID(rawValue: names[index])),
                    name: names[index],
                    semantic: semantics[index],
                    unit: nil,
                    sampling: .indexOnly
                )
            )
        }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: ContiguousArray(extents)),
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
                axes: axes,
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: try ImageShape(extents: ContiguousArray(extents)),
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
                createdAt: try CanonicalInstant(
                    utcString: "2026-08-06T09:00:00Z"
                ),
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
}
