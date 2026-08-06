// SPDX-License-Identifier: MIT

import CryptoKit
import Testing
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("Surface annotation registrar")
struct SurfaceAnnotationRegistrarTests {
    private struct Fixture: Sendable {
        let name: String
        let column: Double
        let row: Double
        let depth: Double

        /// The nearest retained occluder depth at each pixel, keyed by
        /// `(column, row)`. Absent means nothing retained covers that pixel.
        let occluders: [Pixel: Double]
    }

    private struct Pixel: Hashable, Sendable {
        let column: Int
        let row: Int
    }

    @Test(
        "[Oracle][VOX-SUR-008][VOX-NUM-001] all ALG-0040 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in analyticalFixtures() {
            guard let registration = try register(fixture) else {
                records.append("\(fixture.name)|registration=off-viewport")
                continue
            }
            let occluded = registration.occluded ? 1 : 0
            records.append(
                "\(fixture.name)|column=\(registration.column)"
                    + "|row=\(registration.row)"
                    + "|depth=\(hexadecimal(registration.depth.bitPattern, width: 16))"
                    + "|occluded=\(occluded)"
            )
            payload.append(
                contentsOf: littleEndianBytes(
                    UInt64(bitPattern: Int64(registration.column))
                )
            )
            payload.append(
                contentsOf: littleEndianBytes(
                    UInt64(bitPattern: Int64(registration.row))
                )
            )
            payload.append(
                contentsOf: littleEndianBytes(registration.depth.bitPattern)
            )
            payload.append(UInt8(occluded))
        }

        #expect(records.count == 19)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "8950824148a6fd801296f2114328d198bf613c8c10dcb95422e23f82d0b97615"
        )
        #expect(
            sha256(payload)
                == "53ee6d24ef61d5b57f2c13d1ac4f8f647d83907b1b88534718ba9dc0f0a1ea93"
        )
    }

    @Test(
        "[Unit][VOX-SUR-008][VOX-NUM-001] the pixel is the floor and the bound is exact"
    )
    func pixelIsFloorAndBoundIsExact() throws {
        let viewport = try ViewportSize(width: 4, height: 4)

        // Pixel k covers [k, k+1). Rounding would put 2.6 in pixel 3, and
        // would place a pixel-centre anchor exactly on the rounding boundary.
        #expect(place(2.6, 0.5, viewport)?.column == 2)
        #expect(place(2.5, 0.5, viewport)?.column == 2)
        // An exact integer belongs to the pixel it opens, not the one it
        // closes.
        #expect(place(3.0, 0.5, viewport)?.column == 3)
        #expect(place(3.0.nextDown, 0.5, viewport)?.column == 2)

        // Inclusive at zero, exclusive at the dimension, on both axes.
        #expect(place(0.0, 0.0, viewport).map { [$0.column, $0.row] } == [0, 0])
        #expect(
            place(4.0.nextDown, 4.0.nextDown, viewport).map {
                [$0.column, $0.row]
            } == [3, 3]
        )
        for outside in [(4.0, 0.5), (0.5, 4.0), (-1e-7, 0.5), (0.5, -1e-7)] {
            #expect(place(outside.0, outside.1, viewport) == nil)
        }
        // Negative zero needs no special case: it compares equal to zero and
        // floors to zero.
        #expect(
            place(-0.0, -0.0, viewport).map { [$0.column, $0.row] } == [0, 0]
        )
    }

    @Test(
        "[Unit][VOX-SUR-008][VOX-GEO-002] occlusion is strict, unbiased and per pixel"
    )
    func occlusionIsStrictUnbiasedAndPerPixel() throws {
        let viewport = try ViewportSize(width: 4, height: 4)
        let anchor = AnnotationAnchor(column: 1.5, row: 2.5, depth: 2.0)

        func occluded(by depth: Double?) -> Bool? {
            SurfaceAnnotationRegistrar.register(
                anchor: anchor,
                viewport: viewport,
                occluder: depth
            )?.occluded
        }

        #expect(occluded(by: nil) == false)
        #expect(occluded(by: 1.0) == true)
        #expect(occluded(by: 9.0) == false)
        // THE tie decision: an exactly equal depth leaves the annotation
        // visible, so an anchor placed on the surface it annotates is not
        // hidden by that surface.
        #expect(occluded(by: 2.0) == false)
        // No bias and no epsilon: one unit in the last place decides it.
        #expect(occluded(by: 2.0.nextDown) == true)
        #expect(occluded(by: 2.0.nextUp) == false)

        // The comparison is on the signed depth axis, not on magnitude, so a
        // behind-camera anchor registers and a more negative occluder occludes.
        let behind = AnnotationAnchor(column: 1.5, row: 2.5, depth: -3.0)
        #expect(
            SurfaceAnnotationRegistrar.register(
                anchor: behind,
                viewport: viewport,
                occluder: nil
            )?.occluded == false
        )
        #expect(
            SurfaceAnnotationRegistrar.register(
                anchor: behind,
                viewport: viewport,
                occluder: -5.0
            )?.occluded == true
        )
    }

    @Test(
        "[Unit][VOX-SUR-008][VOX-API-003] one anchor registers correctly at two camera poses"
    )
    func oneAnchorRegistersCorrectlyAtTwoCameraPoses() throws {
        // The registration claim, proven against the accepted projector rather
        // than hand-written coordinates: one anchor fixed in world space, two
        // camera poses, each evaluated from the anchor and the pose alone.
        let viewport = try ViewportSize(width: 8, height: 8)
        let anchorWorld = (2.0, 0.0, 0.0)

        let front = try project(anchorWorld, from: (0, 0, 10), up: (0, 1, 0))
        let side = try project(anchorWorld, from: (10, 0, 0), up: (0, 1, 0))

        let fromFront = try #require(
            SurfaceAnnotationRegistrar.register(
                anchor: front,
                viewport: viewport,
                occluder: nil
            )
        )
        let fromSide = try #require(
            SurfaceAnnotationRegistrar.register(
                anchor: side,
                viewport: viewport,
                occluder: nil
            )
        )

        // Viewed head-on the anchor sits right of centre; viewed from its own
        // axis it collapses onto the centre column. The pixel therefore moves
        // with the camera, which is what "registered" means.
        #expect(fromFront.column > 4)
        #expect(fromSide.column == 4)
        #expect(fromFront.row == fromSide.row)
        // Depth follows the pose too: eight units away from the front, and
        // eight from the side, both positive.
        #expect(fromFront.depth == 10.0)
        #expect(fromSide.depth == 8.0)

        // Statelessness is the registration claim: re-evaluating a pose after
        // the other one gives a bit-identical answer, so no order of camera
        // movement can drift.
        #expect(
            SurfaceAnnotationRegistrar.register(
                anchor: front,
                viewport: viewport,
                occluder: nil
            ) == fromFront
        )

        // The same anchor is occluded or not purely by what lies nearer at its
        // own pixel under that pose.
        #expect(
            SurfaceAnnotationRegistrar.register(
                anchor: front,
                viewport: viewport,
                occluder: front.depth.nextDown
            )?.occluded == true
        )
    }

    // MARK: - Fixtures

    private func analyticalFixtures() -> [Fixture] {
        let anchorPixel = Pixel(column: 1, row: 2)
        func at(
            _ name: String,
            _ column: Double,
            _ row: Double,
            _ depth: Double = 1.0,
            occluders: [Pixel: Double] = [:]
        ) -> Fixture {
            Fixture(
                name: name,
                column: column,
                row: row,
                depth: depth,
                occluders: occluders
            )
        }
        let elsewhere: [Pixel: Double] = [
            Pixel(column: 0, row: 0): -100.0,
            Pixel(column: 3, row: 3): -100.0,
        ]
        return [
            at("inside-unoccluded", 1.5, 2.5, 2.0),
            at(
                "nearer-occludes",
                1.5,
                2.5,
                2.0,
                occluders: [anchorPixel: 1.0]
            ),
            at(
                "farther-does-not-occlude",
                1.5,
                2.5,
                2.0,
                occluders: [anchorPixel: 9.0]
            ),
            at(
                "equal-depth-visible",
                1.5,
                2.5,
                2.0,
                occluders: [anchorPixel: 2.0]
            ),
            at("floor-not-round", 2.6, 0.5),
            at("integer-boundary", 3.0, 0.5),
            at("just-below-boundary", 3.0.nextDown, 0.5),
            at("first-pixel", 0.0, 0.0),
            at("last-pixel", 4.0.nextDown, 4.0.nextDown),
            at("column-at-width-off", 4.0, 0.5),
            at("row-at-height-off", 0.5, 4.0),
            at("negative-column-off", -1e-7, 0.5),
            at("negative-row-off", 0.5, -1e-7),
            at("negative-zero", -0.0, -0.0),
            at("behind-camera-visible", 1.5, 2.5, -3.0),
            at(
                "behind-camera-occluded",
                1.5,
                2.5,
                -3.0,
                occluders: [anchorPixel: -5.0]
            ),
            at("occluder-elsewhere", 1.5, 2.5, 2.0, occluders: elsewhere),
            at(
                "pose-a",
                0.5,
                0.5,
                4.0,
                occluders: [Pixel(column: 0, row: 0): 9.0]
            ),
            at(
                "pose-b",
                3.5,
                3.5,
                4.0,
                occluders: [Pixel(column: 3, row: 3): 1.0]
            ),
        ]
    }

    // MARK: - Helpers

    private func register(
        _ fixture: Fixture
    ) throws -> AnnotationRegistration? {
        let viewport = try ViewportSize(width: 4, height: 4)
        let anchor = AnnotationAnchor(
            column: fixture.column,
            row: fixture.row,
            depth: fixture.depth
        )
        // The caller selects the occluder with the registrar's OWN pixel rule,
        // so the placement and the lookup cannot disagree.
        let occluder =
            SurfaceAnnotationRegistrar.pixel(
                column: fixture.column,
                row: fixture.row,
                viewport: viewport
            )
            .flatMap { placed in
                fixture.occluders[
                    Pixel(column: placed.column, row: placed.row)
                ]
            }
        return SurfaceAnnotationRegistrar.register(
            anchor: anchor,
            viewport: viewport,
            occluder: occluder
        )
    }

    private func place(
        _ column: Double,
        _ row: Double,
        _ viewport: ViewportSize
    ) -> (column: Int, row: Int)? {
        SurfaceAnnotationRegistrar.pixel(
            column: column,
            row: row,
            viewport: viewport
        )
    }

    private func project(
        _ world: (Double, Double, Double),
        from position: (Double, Double, Double),
        up: (Double, Double, Double)
    ) throws -> AnnotationAnchor {
        let space = try coordinateSpace()
        let domain = try TriangleMeshPositionDomain(
            coordinateSpace: space,
            components: [world.0, world.1, world.2]
        )
        let mesh = try TriangleMesh(
            positions: domain,
            topology: try TriangleMeshTopology(vertexCount: 1, indices: []),
            vertexAttributes: []
        )
        let layer = try SurfaceLayer(
            mesh: mesh,
            objectToWorld: try Matrix4x4Double(
                elements: [
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ]
            ),
            worldSpace: space,
            opacity: 1,
            material: .diagnostic
        )
        let camera = try RenderCamera(
            position: try Point3D(
                x: position.0,
                y: position.1,
                z: position.2,
                coordinateSpace: space.id
            ),
            target: try Point3D(
                x: 0,
                y: 0,
                z: 0,
                coordinateSpace: space.id
            ),
            up: try Vector3D(
                x: up.0,
                y: up.1,
                z: up.2,
                coordinateSpace: space.id
            ),
            projection: .orthographic(planeHeight: 8)
        )
        let projected = try SurfaceVertexProjector.project(
            layer: layer,
            camera: camera,
            viewport: try ViewportSize(width: 8, height: 8),
            cancellation: { _ in false }
        )
        let vertex = try #require(projected.first)
        return AnnotationAnchor(
            column: vertex.column,
            row: vertex.row,
            depth: vertex.depth
        )
    }

    private func coordinateSpace() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "annotation-world")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                dimension: .length
            ),
            externalReferences: []
        )
    }

    private func littleEndianBytes(_ bitPattern: UInt64) -> [UInt8] {
        (0..<8).map { byteIndex in
            UInt8(truncatingIfNeeded: bitPattern >> UInt64(byteIndex * 8))
        }
    }

    private func sha256(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: bytes).map {
            hexadecimal(UInt64($0), width: 2)
        }.joined()
    }

    private func hexadecimal(_ value: UInt64, width: Int) -> String {
        let text = String(value, radix: 16)
        return String(repeating: "0", count: width - text.count) + text
    }
}
