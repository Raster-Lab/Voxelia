// SPDX-License-Identifier: MIT

import Testing
import VoxeliaRendering
import VoxeliaSpatial

@testable import VoxeliaInteraction

@Suite("InteractionCommand")
struct InteractionCommandTests {
    private func point(
        _ x: Double,
        _ y: Double,
        _ z: Double,
        space: String = "patient"
    ) throws -> Point3D {
        try Point3D(
            x: x,
            y: y,
            z: z,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: space))
        )
    }

    @Test("[Unit][VOX-INT-002][VOX-INT-009] the vocabulary constructs with validated payloads")
    func vocabularyConstructsWithValidatedPayloads() throws {
        // Every command case constructs over validated values, and the
        // registered ALG-0010 fixtures reproduce through measurement
        // construction with the exact input points preserved.
        let commands: [InteractionCommand] = [
            .windowLevel(try GreyscaleWindowFunction(center: 40, width: 400, polarity: .standard)),
            .pan(try PanDelta(deltaX: 12.5, deltaY: -4)),
            .zoom(try ZoomFactor(factor: 1.5)),
            .scroll(sliceDelta: -3),
            .rotate(try RotationAngle(radians: 0.25)),
            .crosshair(CrosshairState(position: try point(1, 2, 3))),
            .pick(try PickTarget(viewportX: 128, viewportY: 96)),
            .clip(
                try ClipBox(
                    minimum: try point(0, 0, 0),
                    maximum: try point(10, 10, 10)
                )
            ),
            .crop(try RenderCrop(lowerX: 1, lowerY: 0, upperX: 3, upperY: 2)),
            .measure(.begin),
            .measure(.addPoint(try point(3, 4, 0))),
            .measure(.complete),
        ]
        #expect(Set(commands).count == commands.count)

        let segment = try MeasurementConstruction(
            points: [try point(0, 0, 0), try point(3, 4, 0)]
        )
        #expect(segment.derivedLength == 5.0)
        #expect(segment.points.count == 2)
        let polyline = try MeasurementConstruction(
            points: [try point(0, 0, 0), try point(3, 4, 0), try point(3, 4, 12)]
        )
        #expect(polyline.derivedLength == 17.0)
        let single = try MeasurementConstruction(
            points: [try point(10.5, -2.25, 7)]
        )
        #expect(single.derivedLength == 0.0)
        #expect(single.points == [try point(10.5, -2.25, 7)])

        // The ADR-0120 angle fixtures: right angle, collinear
        // opposite, forty-five degrees, and the same-direction clamp,
        // each exact, with inputs preserved.
        let rightAngle = try AngleMeasurement(
            rayPoint: try point(1, 0, 0),
            vertex: try point(0, 0, 0),
            secondRayPoint: try point(0, 1, 0)
        )
        #expect(rightAngle.derivedRadians == 1.5707963267948966)
        #expect(rightAngle.vertex == (try point(0, 0, 0)))
        let collinear = try AngleMeasurement(
            rayPoint: try point(1, 0, 0),
            vertex: try point(0, 0, 0),
            secondRayPoint: try point(-2, 0, 0)
        )
        #expect(collinear.derivedRadians == 3.141592653589793)
        let diagonal = try AngleMeasurement(
            rayPoint: try point(1, 0, 0),
            vertex: try point(0, 0, 0),
            secondRayPoint: try point(1, 1, 0)
        )
        #expect(diagonal.derivedRadians == 0.7853981633974484)
        let sameDirection = try AngleMeasurement(
            rayPoint: try point(3, 0, 0),
            vertex: try point(0, 0, 0),
            secondRayPoint: try point(2, 0, 0)
        )
        #expect(sameDirection.derivedRadians == 0.0)

        requireSendable(InteractionCommand.self)
        requireSendable(MeasurementConstruction.self)
        requireSendable(AngleMeasurement.self)
        requireSendable(CrosshairState.self)
        requireSendable(InteractionError.self)
    }

    @Test("[Unit][VOX-INT-001][VOX-ERR-001] payloads reject invalid values typed")
    func payloadsRejectInvalidValuesTyped() throws {
        // Non-finite or non-positive payloads, unordered clip bounds,
        // and mixed-space or empty measurements reject typed.
        do {
            _ = try PanDelta(deltaX: .infinity, deltaY: 0)
            #expect(Bool(false), "Expected a non-finite pan to be rejected.")
        } catch InteractionError.invalidPanDelta {}
        for factor in [0.0, -1.0, Double.nan] {
            do {
                _ = try ZoomFactor(factor: factor)
                #expect(Bool(false), "Expected an invalid zoom to be rejected.")
            } catch InteractionError.invalidZoomFactor {}
        }
        do {
            _ = try RotationAngle(radians: .nan)
            #expect(Bool(false), "Expected a non-finite angle to be rejected.")
        } catch InteractionError.invalidRotationAngle {}
        do {
            _ = try PickTarget(viewportX: -1, viewportY: 0)
            #expect(Bool(false), "Expected a negative pick to be rejected.")
        } catch InteractionError.invalidPickTarget {}
        do {
            _ = try ClipBox(
                minimum: try point(0, 0, 5),
                maximum: try point(10, 10, 5)
            )
            #expect(Bool(false), "Expected unordered clip bounds to be rejected.")
        } catch InteractionError.invalidClipBounds {}
        do {
            _ = try ClipBox(
                minimum: try point(0, 0, 0),
                maximum: try point(10, 10, 10, space: "detector")
            )
            #expect(Bool(false), "Expected a mixed-space box to be rejected.")
        } catch InteractionError.coordinateSpaceMismatch {}
        do {
            _ = try MeasurementConstruction(points: [])
            #expect(Bool(false), "Expected an empty measurement to be rejected.")
        } catch InteractionError.emptyMeasurement {}
        do {
            _ = try MeasurementConstruction(
                points: [try point(0, 0, 0), try point(1, 1, 1, space: "detector")]
            )
            #expect(Bool(false), "Expected a mixed-space measurement to be rejected.")
        } catch InteractionError.coordinateSpaceMismatch {}

        // The ADR-0120 angle admissions: a zero-length ray and a
        // mixed-space triple reject typed.
        do {
            _ = try AngleMeasurement(
                rayPoint: try point(0, 0, 0),
                vertex: try point(0, 0, 0),
                secondRayPoint: try point(1, 0, 0)
            )
            #expect(Bool(false), "Expected a zero-length ray to be rejected.")
        } catch InteractionError.degenerateAngleRay {}
        do {
            _ = try AngleMeasurement(
                rayPoint: try point(1, 0, 0),
                vertex: try point(0, 0, 0),
                secondRayPoint: try point(0, 1, 0, space: "detector")
            )
            #expect(Bool(false), "Expected a mixed-space angle to be rejected.")
        } catch InteractionError.coordinateSpaceMismatch {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
