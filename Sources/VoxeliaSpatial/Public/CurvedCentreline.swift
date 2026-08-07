// SPDX-License-Identifier: MIT

/// An error raised by centreline admission or lookup.
///
/// Payload-free, like every other failure family in the project.
public enum CurvedCentrelineError: Error, Sendable, Equatable {
    /// Fewer than two points were supplied.
    case insufficientPoints
    /// A point was not expressed in the declared coordinate space.
    case spaceMismatch
    /// Two consecutive points coincide exactly: a zero-length segment
    /// cannot parameterise, and silently dropping it would edit the
    /// supplied path.
    case zeroLengthSegment
    /// The requested arc length was NaN or outside `[0, total]`.
    case arcLengthOutOfRange
}

/// The explicit centreline of `VOX-MPR-012`, per `ADR-0375` and the
/// frozen `curved-centreline/binary64-v1` model of `VOXELIA-ALG-0074`:
/// an ordered polyline in one declared physical coordinate space with
/// its arc-length parameterisation computed once at admission.
///
/// A polyline, not a spline — smoothing the path is a processing
/// decision that changes where a reconstruction looks, so a consumer
/// wanting a smoothed path supplies the smoothed polyline explicitly.
public struct CurvedCentreline: Sendable {
    /// The space every point is validated to live in.
    public let coordinateSpace: CoordinateSpaceDescriptor
    /// The admitted points, in supplied order.
    public let points: ContiguousArray<Point3D>
    /// The frozen per-segment Euclidean lengths.
    public let segmentLengths: ContiguousArray<Double>
    /// The cumulative arc-length marks; the first is zero and the last
    /// is the total.
    public let cumulativeArcLengths: ContiguousArray<Double>

    /// The total arc length.
    public var totalArcLength: Double {
        cumulativeArcLengths[cumulativeArcLengths.count - 1]
    }

    /// Creates a validated centreline.
    ///
    /// - Throws: ``CurvedCentrelineError``.
    public init(
        coordinateSpace: CoordinateSpaceDescriptor,
        points: ContiguousArray<Point3D>
    ) throws {
        guard points.count >= 2 else {
            throw CurvedCentrelineError.insufficientPoints
        }
        for point in points where point.coordinateSpace != coordinateSpace.id {
            throw CurvedCentrelineError.spaceMismatch
        }
        var lengths = ContiguousArray<Double>()
        lengths.reserveCapacity(points.count - 1)
        var marks = ContiguousArray<Double>()
        marks.reserveCapacity(points.count)
        marks.append(0)
        for index in 0..<(points.count - 1) {
            let a = points[index]
            let b = points[index + 1]
            guard a.x != b.x || a.y != b.y || a.z != b.z else {
                throw CurvedCentrelineError.zeroLengthSegment
            }
            let dx = b.x - a.x
            let dy = b.y - a.y
            let dz = b.z - a.z
            let length = ((dx * dx + dy * dy) + dz * dz).squareRoot()
            lengths.append(length)
            marks.append(marks[index] + length)
        }
        self.coordinateSpace = coordinateSpace
        self.points = points
        self.segmentLengths = lengths
        self.cumulativeArcLengths = marks
    }

    /// The physical position at one arc length, per the frozen rule:
    /// the total returns the last point verbatim, a mark hit makes the
    /// local parameter exactly zero, and every interior evaluation is
    /// the frozen `a + t·(b − a)` per coordinate.
    ///
    /// - Throws: ``CurvedCentrelineError/arcLengthOutOfRange``.
    public func position(atArcLength arcLength: Double) throws -> Point3D {
        guard arcLength >= 0, arcLength <= totalArcLength else {
            throw CurvedCentrelineError.arcLengthOutOfRange
        }
        if arcLength == totalArcLength {
            return points[points.count - 1]
        }
        var index = 0
        for candidate in 0..<(points.count - 1)
        where cumulativeArcLengths[candidate] <= arcLength {
            index = candidate
        }
        let t = (arcLength - cumulativeArcLengths[index]) / segmentLengths[index]
        let a = points[index]
        let b = points[index + 1]
        let x = a.x + t * (b.x - a.x)
        let y = a.y + t * (b.y - a.y)
        let z = a.z + t * (b.z - a.z)
        guard
            let position = try? Point3D(
                x: x == 0 ? 0 : x,
                y: y == 0 ? 0 : y,
                z: z == 0 ? 0 : z,
                coordinateSpace: a.coordinateSpace
            )
        else {
            preconditionFailure("Interpolants of finite admitted points are finite.")
        }
        return position
    }
}
