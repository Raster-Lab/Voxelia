// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaRendering
import VoxeliaSpatial

@testable import VoxeliaInteraction

/// `ADR-0292` (`VOX-MPR-014`): measurements made in reconstructed views use authoritative
/// physical geometry.
///
/// The plan states the hazard directly in §33.5 — "screen distance shall never be used as
/// the authoritative physical distance" — and §33.3 adds view independence: a measurement
/// created in one viewport stays spatially correct in another compatible one.
///
/// The chain under test is pixel → `PickResolver` → `Point3D` → `MeasurementConstruction`.
/// The resolver maps a viewport index through the presented geometry's own `indexToWorld`,
/// so the physical position is the view's claim rather than anything derived from pixel
/// counts, and an uncalibrated claim yields no position at all.
@Suite("ReconstructedMeasurementGeometry")
struct ReconstructedMeasurementGeometryTests {
    private func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    /// A reconstructed view whose in-plane sample spacing is `spacing` millimetres.
    private func reconstructed(spacing: Double) throws -> SpatialGeometry {
        .affine(
            try AffineGridGeometry(
                spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
                indexToWorld: try Matrix4x4Double(elements: [
                    spacing, 0, 0, 0,
                    0, spacing, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ]),
                coordinateSpace: try space()
            )
        )
    }

    private func presentation(
        geometry: SpatialGeometry?
    ) throws -> PresentationProvenance {
        let id = try #require(CoordinateSpaceID(rawValue: "patient"))
        return PresentationProvenance(
            camera: try RenderCamera(
                position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: id),
                target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: id),
                up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: id),
                projection: .orthographic(planeHeight: 250)
            ),
            viewport: try ViewportSize(width: 64, height: 64),
            layers: [
                try RenderLayer(
                    imageObjectID: try #require(DataObjectID(rawValue: "series-7")),
                    transferFunction: .greyscaleWindow(
                        try GreyscaleWindowFunction(center: 40, width: 400, polarity: .standard)
                    ),
                    opacity: 1
                )
            ],
            crop: nil,
            geometry: geometry,
            scaling: .identity,
            renderMode: .slice,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil,
            accumulation: .none,
            denoising: .none
        )
    }

    /// Measures between two viewport pixels through the presented geometry.
    private func measuredLength(
        spacing: Double,
        from first: (Int, Int),
        to second: (Int, Int)
    ) throws -> Double {
        let view = try presentation(geometry: try reconstructed(spacing: spacing))
        let start = try #require(
            try PickResolver.resolve(
                try PickTarget(viewportX: first.0, viewportY: first.1), in: view
            ).worldPosition
        )
        let end = try #require(
            try PickResolver.resolve(
                try PickTarget(viewportX: second.0, viewportY: second.1), in: view
            ).worldPosition
        )
        return try MeasurementConstruction(points: [start, end]).derivedLength
    }

    // MARK: - Screen distance is never the physical distance

    @Test(
        "[Unit][VOX-MPR-014] equal pixel separations measure differently under spacing"
    )
    func samePixelSeparationMeasuresDifferentlyUnderDifferentSpacing() throws {
        // The direct falsification of §33.5. Identical pixels, two reconstructions whose
        // in-plane spacing differs by a factor of four. A pipeline measuring screen
        // distance would return the same length for both.
        let coarse = try measuredLength(spacing: 2.0, from: (10, 10), to: (30, 10))
        let fine = try measuredLength(spacing: 0.5, from: (10, 10), to: (30, 10))

        #expect(coarse == 40.0)
        #expect(fine == 10.0)
        #expect(coarse == fine * 4)
    }

    @Test("[Unit][VOX-MPR-014] the length is the spacing times the index separation")
    func lengthIsSpacingTimesIndexSeparation() throws {
        // Exact rather than approximate: the spacings and separations are chosen so every
        // product is representable, so no tolerance appears here.
        #expect(try measuredLength(spacing: 1.0, from: (0, 0), to: (16, 0)) == 16.0)
        #expect(try measuredLength(spacing: 0.25, from: (0, 0), to: (16, 0)) == 4.0)
        #expect(try measuredLength(spacing: 2.5, from: (0, 0), to: (0, 8)) == 20.0)
        // A diagonal, where a three-four-five triangle keeps the root exact.
        #expect(try measuredLength(spacing: 1.0, from: (0, 0), to: (3, 4)) == 5.0)
    }

    @Test("[Unit][VOX-MPR-014] an uncalibrated view yields no physical position")
    func uncalibratedViewYieldsNoPhysicalPosition() throws {
        // The structural half. Without a geometry claim there is no authoritative
        // mapping, so the resolver returns no world position rather than a pixel-derived
        // guess — and a measurement cannot be constructed from a view that has none.
        let resolution = try PickResolver.resolve(
            try PickTarget(viewportX: 10, viewportY: 10),
            in: try presentation(geometry: nil)
        )
        #expect(resolution.worldPosition == nil)
        // The pick still succeeds and still reports its source index, so the absence is
        // specific to the physical claim rather than a general failure.
        #expect(resolution.sourceX == 10)
        #expect(resolution.sourceY == 10)
    }

    // MARK: - View independence

    @Test("[Unit][VOX-MPR-014] the same physical points measure identically from any view")
    func samePhysicalPointsMeasureIdenticallyFromAnyView() throws {
        // Plan §33.3. The construction sees points, never a viewport, so a measurement
        // carried between compatible viewports cannot change value — and the two views
        // below produce the same physical points from different pixels.
        let coarse = try presentation(geometry: try reconstructed(spacing: 2.0))
        let fine = try presentation(geometry: try reconstructed(spacing: 0.5))

        // Pixel 8 at 2 mm and pixel 32 at 0.5 mm are both 16 mm from the origin.
        let fromCoarse = try #require(
            try PickResolver.resolve(
                try PickTarget(viewportX: 8, viewportY: 0), in: coarse
            ).worldPosition
        )
        let fromFine = try #require(
            try PickResolver.resolve(
                try PickTarget(viewportX: 32, viewportY: 0), in: fine
            ).worldPosition
        )
        #expect(fromCoarse == fromFine)

        let origin = try Point3D(
            x: 0, y: 0, z: 0,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: "patient"))
        )
        #expect(
            try MeasurementConstruction(points: [origin, fromCoarse]).derivedLength
                == MeasurementConstruction(points: [origin, fromFine]).derivedLength
        )
    }

    @Test("[Unit][VOX-MPR-014] a measurement spanning coordinate spaces is refused")
    func measurementSpanningCoordinateSpacesIsRefused() throws {
        // Mixing spaces would fabricate a calibration between them, which is the same
        // hazard as measuring in pixels wearing different clothes.
        let patient = try Point3D(
            x: 0, y: 0, z: 0,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: "patient"))
        )
        let other = try Point3D(
            x: 10, y: 0, z: 0,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: "table"))
        )
        #expect(throws: InteractionError.coordinateSpaceMismatch) {
            _ = try MeasurementConstruction(points: [patient, other])
        }
    }

    // MARK: - The trap this increment closed

    @Test("[Unit][VOX-MPR-014] a non-planar geometry claim is refused, not trapped")
    func nonPlanarGeometryClaimIsRefusedNotTrapped() throws {
        // Found by writing this suite. A viewport supplies two indices and
        // `SpatialAxisMapping` admits up to three axes, so a claim naming a third had no
        // index to read -- and `PickResolver` read out of range and **trapped**. Every
        // value here is constructible through public API, so this was reachable rather
        // than theoretical.
        for axes in [[0, 1, 2], [2, 0], [0, 2]] {
            let claim = SpatialGeometry.affine(
                try AffineGridGeometry(
                    spatialAxes: try SpatialAxisMapping(imageAxes: axes),
                    indexToWorld: try Matrix4x4Double(elements: [
                        1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1,
                    ]),
                    coordinateSpace: try space()
                )
            )
            #expect(throws: InteractionError.presentationGeometryNotPlanar) {
                _ = try PickResolver.resolve(
                    try PickTarget(viewportX: 1, viewportY: 1),
                    in: try presentation(geometry: claim)
                )
            }
        }
    }

    @Test("[Unit][VOX-MPR-014] planar claims of one and two axes still resolve")
    func planarClaimsStillResolve() throws {
        // The positive control. The refusal must discriminate on whether an index exists,
        // not reject every axis mapping -- a single-axis claim is legitimate and must
        // still produce a position.
        for axes in [[0], [1], [0, 1], [1, 0]] {
            let claim = SpatialGeometry.affine(
                try AffineGridGeometry(
                    spatialAxes: try SpatialAxisMapping(imageAxes: axes),
                    indexToWorld: try Matrix4x4Double(elements: [
                        2, 0, 0, 0,
                        0, 2, 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1,
                    ]),
                    coordinateSpace: try space()
                )
            )
            let resolution = try PickResolver.resolve(
                try PickTarget(viewportX: 3, viewportY: 5),
                in: try presentation(geometry: claim)
            )
            #expect(resolution.worldPosition != nil)
        }
    }

    @Test("[Unit][VOX-MPR-014] the measurement preserves its input points")
    func measurementPreservesItsInputPoints() throws {
        // A derived length whose inputs were discarded could not be re-derived or audited
        // against a corrected geometry, which `VOX-INT-009` requires and which matters
        // here because the geometry is the authority.
        let view = try presentation(geometry: try reconstructed(spacing: 2.0))
        let first = try #require(
            try PickResolver.resolve(try PickTarget(viewportX: 4, viewportY: 0), in: view)
                .worldPosition
        )
        let second = try #require(
            try PickResolver.resolve(try PickTarget(viewportX: 9, viewportY: 0), in: view)
                .worldPosition
        )
        let measurement = try MeasurementConstruction(points: [first, second])

        #expect(measurement.points == [first, second])
        #expect(measurement.derivedLength == 10.0)
    }
}
