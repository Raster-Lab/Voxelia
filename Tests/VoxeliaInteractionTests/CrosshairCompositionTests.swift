// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaImaging
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaInteraction

/// The three-plane crosshair round trip `ADR-0248` demonstrated on real patient
/// data, guarded in CI over a synthetic affine (`ADR-0262`).
///
/// `ADR-0248` verified this composition against the owner's 899-slice series, but no
/// repository test may read that data, so nothing stopped a regression. This suite
/// closes that: it composes `MPRSliceCoordinator`'s world-point slice mapping with
/// `ViewportSyncGroup`'s crosshair broadcast, exactly as the real-data run did.
///
/// **The volume is anisotropic and its affine has three distinct spacings**, both on
/// purpose. Equal extents would let a transposed or duplicated plane pass, and equal
/// spacings would let a swapped axis in the world mapping pass.
@Suite("CrosshairComposition")
struct CrosshairCompositionTests {
    // MARK: - Fixture

    /// Columns 4, rows 3, slices 5 — all different.
    private let extents = [4, 3, 5]

    private func spaceID() throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: "patient"))
    }

    private func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try spaceID(),
            convention: .dicomPatientLPS,
            handedness: .rightHanded,
            unit: try MeasurementUnit(namespace: "ucum", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 0, minor: 1, patch: 1),
            commit: nil,
            buildIdentifier: nil
        )
    }

    /// `world = (10 + 2i, 20 + 3j, 30 + 5k)` — three distinct spacings and a
    /// non-zero origin, so a swapped axis or a dropped origin term is visible.
    private func world(_ i: Int, _ j: Int, _ k: Int) throws -> VoxeliaSpatial.Point3D {
        try VoxeliaSpatial.Point3D(
            x: 10 + 2 * Double(i),
            y: 20 + 3 * Double(j),
            z: 30 + 5 * Double(k),
            coordinateSpace: try spaceID()
        )
    }

    private func volumeGeometry() throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: try Matrix4x4Double(elements: [
                2, 0, 0, 10,
                0, 3, 0, 20,
                0, 0, 5, 30,
                0, 0, 0, 1,
            ]),
            coordinateSpace: try space()
        )
    }

    private func axis(_ id: String, _ semantic: AxisSemantic) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: semantic,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func volume() throws -> ImageData {
        let count = extents.reduce(1, *)
        // Distinct per-voxel values, so a wrong plane is visibly wrong.
        let bytes = (0..<count).map { UInt8($0 % 251) }
        let shape = try ImageShape(extents: ContiguousArray(extents))
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
                semantic: .intensity,
                axes: [
                    try axis("x", .spatialX),
                    try axis("y", .spatialY),
                    try axis("z", .spatialZ),
                ],
                spatialGeometry: .affine(try volumeGeometry()),
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
                id: try #require(ProvenanceID(rawValue: "xh-volume-record")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "xh-volume"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "xh-volume")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "synthetic",
                        identifier: "crosshair-composition",
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
            maximumPublishedObjectCount: 32,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 32,
                maximumParentEdgeCount: 32,
                maximumAncestryDepth: 16,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 4_096
            ),
            resultCache: nil
        )
    }

    private func extract(
        plane: MPRPlane,
        index: Int,
        prefix: String,
        publisher: PublicationCoordinator
    ) async throws -> ImageData {
        try await MPRSliceCoordinator.extractSlice(
            volumeID: try #require(DataObjectID(rawValue: "xh-volume")),
            plane: plane,
            sliceIndex: index,
            naming: { stage in
                let suffix = stage == .extracted ? "slab" : "slice"
                return (
                    outputObjectID: try #require(
                        DataObjectID(rawValue: "\(prefix)-\(suffix)")
                    ),
                    provenanceID: try #require(
                        ProvenanceID(rawValue: "rec-\(prefix)-\(suffix)")
                    ),
                    createdAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z")
                )
            },
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 4_096
            ),
            software: try software()
        )
    }

    private func presentation(
        for slice: ImageData,
        at crosshair: VoxeliaSpatial.Point3D
    ) throws -> PresentationProvenance {
        let sliceExtents = Array(slice.descriptor.shape.extents)
        return PresentationProvenance(
            camera: try RenderCamera(
                // Offset from the target: a camera at its own target is a
                // degenerate view direction. The camera plays no part in
                // ADR-0140's mapping, which reads only geometry and viewport.
                position: try VoxeliaSpatial.Point3D(
                    x: crosshair.x,
                    y: crosshair.y,
                    z: crosshair.z - 100,
                    coordinateSpace: try spaceID()
                ),
                target: crosshair,
                up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: try spaceID()),
                projection: .orthographic(planeHeight: 50)
            ),
            viewport: try ViewportSize(
                width: sliceExtents[0],
                height: sliceExtents[1]
            ),
            layers: [
                try RenderLayer(
                    imageObjectID: slice.identity.objectID,
                    transferFunction: .greyscaleWindow(
                        try GreyscaleWindowFunction(
                            center: 30,
                            width: 60,
                            polarity: .standard
                        )
                    ),
                    opacity: 1
                )
            ],
            crop: nil,
            geometry: slice.descriptor.spatialGeometry,
            scaling: .identity,
            renderMode: .slice,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil,
            accumulation: .none,
            denoising: .none
        )
    }

    // MARK: - The round trip

    @Test("[Unit][VOX-VS1-013][VOX-MPR-005] the crosshair round trips through all three planes")
    func crosshairRoundTripsThroughAllThreePlanes() async throws {
        // Voxel (2, 1, 3) of a 4x3x5 volume, at world (14, 23, 45).
        let column = 2
        let row = 1
        let slice = 3
        let crosshair = try world(column, row, slice)
        #expect(crosshair.x == 14)
        #expect(crosshair.y == 23)
        #expect(crosshair.z == 45)

        let coordinator = try publisher()
        _ = try await coordinator.publish(try volume(), mode: .complete)
        let volumeID = try #require(DataObjectID(rawValue: "xh-volume"))

        // Each plane's world-point mapping returns that plane's own component.
        for (plane, expected) in [
            (MPRPlane.axial, slice),
            (MPRPlane.coronal, row),
            (MPRPlane.sagittal, column),
        ] {
            let resolved = try await MPRSliceCoordinator.sliceIndex(
                forWorldPoint: crosshair,
                plane: plane,
                volumeID: volumeID,
                publisher: coordinator
            )
            #expect(resolved == expected, "\(plane)")
        }

        // Extract the three slices the crosshair selects, and broadcast to them.
        // Expected pixels follow ADR-0244's axis renumbering after the singleton
        // drop: axial presents (column, row), coronal (column, slice), sagittal
        // (row, slice). All three differ, so a transposed plane fails here.
        let cases: [(plane: MPRPlane, index: Int, x: Int, y: Int, width: Int, height: Int)] = [
            (.axial, slice, column, row, 4, 3),
            (.coronal, row, column, slice, 4, 5),
            (.sagittal, column, row, slice, 3, 5),
        ]

        var members: [SyncedViewport] = []
        var presentations: [Int: PresentationProvenance] = [:]
        for (offset, item) in cases.enumerated() {
            let extracted = try await extract(
                plane: item.plane,
                index: item.index,
                prefix: "xh-\(offset)",
                publisher: coordinator
            )
            let sliceExtents = Array(extracted.descriptor.shape.extents)
            #expect(sliceExtents == [item.width, item.height], "\(item.plane) extents")
            members.append(
                SyncedViewport(identifier: offset + 1, coordinateSpace: try spaceID())
            )
            presentations[offset + 1] = try presentation(
                for: extracted,
                at: crosshair
            )
        }

        let group = try ViewportSyncGroup(
            members: members,
            crosshair: CrosshairState(position: crosshair)
        )
        let resolutions = try group.crosshairTargets(presentations: presentations)
        #expect(resolutions.count == 3)

        for (offset, resolution) in resolutions.enumerated() {
            let item = cases[offset]
            let target = try #require(
                {
                    if case .target(let value) = resolution.outcome { return value }
                    return nil
                }(),
                "\(item.plane) resolved to \(resolution.outcome)"
            )
            #expect(target.viewportX == item.x, "\(item.plane) x")
            #expect(target.viewportY == item.y, "\(item.plane) y")
        }
    }

    // MARK: - The composition contract ADR-0248 found

    @Test("[Unit][VOX-VS1-013] the pixel mapping alone is not an in-volume test")
    func pixelMappingAloneIsNotAnInVolumeTest() async throws {
        // ADR-0248 decision 2, guarded. A crosshair outside the volume on the
        // column axis leaves the axial and coronal views -- both present the
        // column -- but the SAGITTAL view still reports a pixel, because it
        // presents row and slice and an out-of-range column cannot move its
        // in-plane projection.
        //
        // That is correct per unit and it means `crosshairTargets` is not an
        // in-volume test. The guard is the slice-index call, which refuses. A
        // regression that made either half disagree with this breaks here.
        let coordinator = try publisher()
        _ = try await coordinator.publish(try volume(), mode: .complete)
        let volumeID = try #require(DataObjectID(rawValue: "xh-volume"))

        let inside = try world(2, 1, 3)
        // Column 10 is outside [0, 4).
        let outside = try world(10, 1, 3)

        // The slice mapping refuses, never clamps.
        await #expect(throws: MPRError.crosshairOutsideVolume) {
            _ = try await MPRSliceCoordinator.sliceIndex(
                forWorldPoint: outside,
                plane: .sagittal,
                volumeID: volumeID,
                publisher: coordinator
            )
        }

        // Build the three presentations from slices selected by the INSIDE point,
        // then move the crosshair outside and rebroadcast.
        let cases: [(plane: MPRPlane, index: Int)] = [
            (.axial, 3), (.coronal, 1), (.sagittal, 2),
        ]
        var members: [SyncedViewport] = []
        var presentations: [Int: PresentationProvenance] = [:]
        for (offset, item) in cases.enumerated() {
            let extracted = try await extract(
                plane: item.plane,
                index: item.index,
                prefix: "out-\(offset)",
                publisher: coordinator
            )
            members.append(
                SyncedViewport(identifier: offset + 1, coordinateSpace: try spaceID())
            )
            presentations[offset + 1] = try presentation(for: extracted, at: inside)
        }

        let moved = try ViewportSyncGroup(
            members: members,
            crosshair: CrosshairState(position: inside)
        )
        .moving(crosshairTo: outside)
        let resolutions = try moved.crosshairTargets(presentations: presentations)

        // Axial and coronal present the column, so the crosshair left both.
        #expect(resolutions[0].outcome == .outsideViewport, "axial")
        #expect(resolutions[1].outcome == .outsideViewport, "coronal")
        // The sagittal view presents row and slice, so it still reports a pixel.
        let sagittal = try #require(
            {
                if case .target(let value) = resolutions[2].outcome { return value }
                return nil
            }(),
            "sagittal resolved to \(resolutions[2].outcome)"
        )
        #expect(sagittal.viewportX == 1)
        #expect(sagittal.viewportY == 3)
    }

    @Test("[Unit][VOX-VS1-013] an affine-only volume refuses the axis-value overload")
    func affineOnlyVolumeRefusesAxisValueOverload() async throws {
        // Why ADR-0138 added the world-point overload at all: this descriptor
        // declares `.indexOnly` sampling with an affine, so the `.regular`-only
        // axis-value path cannot serve it and must say so rather than guess.
        let coordinator = try publisher()
        _ = try await coordinator.publish(try volume(), mode: .complete)
        await #expect(throws: MPRError.unsupportedAxisSampling) {
            _ = try await MPRSliceCoordinator.sliceIndex(
                forAxisValue: 45,
                plane: .axial,
                volumeID: try #require(DataObjectID(rawValue: "xh-volume")),
                publisher: coordinator
            )
        }
    }
}
