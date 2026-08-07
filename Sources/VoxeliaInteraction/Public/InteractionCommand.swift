// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaRendering
import VoxeliaSpatial

/// An error raised while validating an interaction value.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// coordinates, deltas or parameters.
public enum InteractionError: Error, Sendable, Equatable {
    case invalidPanDelta
    case invalidZoomFactor
    case invalidRotationAngle
    case invalidPickTarget
    case invalidClipBounds
    case emptyMeasurement
    case coordinateSpaceMismatch
    case emptySyncGroup
    case syncGroupLimitExceeded
    case duplicateViewportIdentifier
    case degenerateAngleRay
    case pickOutsideViewport
    case presentationNotCalibrated
    case viewportAxisNotMapped
    /// The presented geometry's axis mapping references an image axis that a
    /// two-dimensional viewport index cannot supply.
    ///
    /// `PickResolver` maps a viewport target through the presented geometry, and a
    /// viewport supplies exactly two indices. `SpatialAxisMapping` admits one to three
    /// axes, so a claim naming a third — or naming axis two directly — has no index to
    /// read. Before `ADR-0292` that combination **trapped** on an out-of-range read
    /// rather than being refused, which is the one outcome this project's typed-refusal
    /// discipline exists to prevent.
    case presentationGeometryNotPlanar
    case crosshairOutsideViewport
    case presentationMembershipMismatch
    case insufficientVertices
    case invalidVoxelCount
}

/// One validated pan delta per `ADR-0111`, in viewport-relative units.
public struct PanDelta: Sendable, Hashable {
    public let deltaX: Double
    public let deltaY: Double

    /// Creates a validated delta.
    ///
    /// - Throws: ``InteractionError/invalidPanDelta``.
    public init(deltaX: Double, deltaY: Double) throws {
        guard deltaX.isFinite, deltaY.isFinite else {
            throw InteractionError.invalidPanDelta
        }
        self.deltaX = deltaX
        self.deltaY = deltaY
    }
}

/// One validated multiplicative zoom factor per `ADR-0111`.
public struct ZoomFactor: Sendable, Hashable {
    public let factor: Double

    /// Creates a validated factor.
    ///
    /// - Throws: ``InteractionError/invalidZoomFactor``.
    public init(factor: Double) throws {
        guard factor.isFinite, factor > 0 else {
            throw InteractionError.invalidZoomFactor
        }
        self.factor = factor
    }
}

/// One validated rotation angle per `ADR-0111`, in radians.
public struct RotationAngle: Sendable, Hashable {
    public let radians: Double

    /// Creates a validated angle.
    ///
    /// - Throws: ``InteractionError/invalidRotationAngle``.
    public init(radians: Double) throws {
        guard radians.isFinite else {
            throw InteractionError.invalidRotationAngle
        }
        self.radians = radians
    }
}

/// One validated viewport pick target per `ADR-0111`.
public struct PickTarget: Sendable, Hashable {
    public let viewportX: Int
    public let viewportY: Int

    /// Creates a validated target.
    ///
    /// - Throws: ``InteractionError/invalidPickTarget``.
    public init(viewportX: Int, viewportY: Int) throws {
        guard viewportX >= 0, viewportY >= 0 else {
            throw InteractionError.invalidPickTarget
        }
        self.viewportX = viewportX
        self.viewportY = viewportY
    }
}

/// One validated axis-aligned physical-space clip box per `ADR-0111`.
///
/// Both corners share one coordinate space with strictly ordered
/// bounds on every axis; clip semantics arrive with their consumer
/// through their own decisions.
public struct ClipBox: Sendable, Hashable {
    public let minimum: Point3D
    public let maximum: Point3D

    /// Creates a validated box.
    ///
    /// - Throws: ``InteractionError/invalidClipBounds`` or
    ///   ``InteractionError/coordinateSpaceMismatch``.
    public init(minimum: Point3D, maximum: Point3D) throws {
        guard minimum.coordinateSpace == maximum.coordinateSpace else {
            throw InteractionError.coordinateSpaceMismatch
        }
        guard
            minimum.x < maximum.x,
            minimum.y < maximum.y,
            minimum.z < maximum.z
        else {
            throw InteractionError.invalidClipBounds
        }
        self.minimum = minimum
        self.maximum = maximum
    }
}

/// The shared physical-space crosshair state per `ADR-0111`
/// (`VOX-INT-004`); the coordinate space travels with the point.
public struct CrosshairState: Sendable, Hashable {
    public let position: Point3D

    public init(position: Point3D) {
        self.position = position
    }
}

/// One measurement construction per `ADR-0111` (`VOX-INT-009`).
///
/// The exact ordered input points are preserved — non-empty, one
/// shared coordinate space — beside the derived physical length,
/// computed once under the registered `VOXELIA-ALG-0010` model in the
/// space's length unit.
public struct MeasurementConstruction: Sendable, Hashable {
    public let points: [Point3D]
    public let derivedLength: Double

    /// Creates a validated construction with its derived length.
    ///
    /// - Throws: ``InteractionError/emptyMeasurement`` or
    ///   ``InteractionError/coordinateSpaceMismatch``.
    public init(points: [Point3D]) throws {
        guard let first = points.first else {
            throw InteractionError.emptyMeasurement
        }
        guard points.allSatisfy({ $0.coordinateSpace == first.coordinateSpace })
        else {
            throw InteractionError.coordinateSpaceMismatch
        }
        self.points = points
        // The frozen VOXELIA-ALG-0010 evaluation: per-segment squared
        // components summed in declared order then rooted, segments
        // accumulated left to right, no fused multiply-add.
        var total = 0.0
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let deltaX = current.x - previous.x
            let deltaY = current.y - previous.y
            let deltaZ = current.z - previous.z
            let squared = ((deltaX * deltaX) + (deltaY * deltaY)) + (deltaZ * deltaZ)
            total += squared.squareRoot()
        }
        self.derivedLength = total
    }
}

/// One angle measurement per `ADR-0120` (`VOX-SPA-014`).
///
/// The exact ray point, vertex and second ray point are preserved —
/// one shared coordinate space — beside the derived radians, computed
/// once at construction under the registered `VOXELIA-ALG-0014` model
/// with its modelled cosine clamp.
public struct AngleMeasurement: Sendable, Hashable {
    public let rayPoint: Point3D
    public let vertex: Point3D
    public let secondRayPoint: Point3D
    public let derivedRadians: Double

    /// Creates a validated measurement with its derived angle.
    ///
    /// - Throws: ``InteractionError/coordinateSpaceMismatch`` or
    ///   ``InteractionError/degenerateAngleRay``.
    public init(rayPoint: Point3D, vertex: Point3D, secondRayPoint: Point3D) throws {
        let space = vertex.coordinateSpace
        guard
            rayPoint.coordinateSpace == space,
            secondRayPoint.coordinateSpace == space
        else {
            throw InteractionError.coordinateSpaceMismatch
        }
        // The frozen VOXELIA-ALG-0014 evaluation: componentwise ray
        // subtraction, declared-order dot and norms, the modelled
        // clamp, no fused multiply-add.
        let uX = rayPoint.x - vertex.x
        let uY = rayPoint.y - vertex.y
        let uZ = rayPoint.z - vertex.z
        let vX = secondRayPoint.x - vertex.x
        let vY = secondRayPoint.y - vertex.y
        let vZ = secondRayPoint.z - vertex.z
        let normU = (((uX * uX) + (uY * uY)) + (uZ * uZ)).squareRoot()
        let normV = (((vX * vX) + (vY * vY)) + (vZ * vZ)).squareRoot()
        guard normU > 0, normV > 0 else {
            throw InteractionError.degenerateAngleRay
        }
        let dot = ((uX * vX) + (uY * vY)) + (uZ * vZ)
        let cosine = min(1.0, max(-1.0, dot / (normU * normV)))
        self.rayPoint = rayPoint
        self.vertex = vertex
        self.secondRayPoint = secondRayPoint
        self.derivedRadians = acos(cosine)
    }
}

/// One planar polygon area measurement per `ADR-0144`
/// (`VOX-SPA-014`).
///
/// The exact ordered vertices are preserved — one shared coordinate
/// space — beside the derived value, computed once at construction
/// under the registered `VOXELIA-ALG-0018` model. The measured
/// quantity is the declared vector-area magnitude of the
/// first-vertex-anchored fan: exactly the enclosed area for planar
/// simple polygons, the algebraic magnitude otherwise, with no
/// epsilon planarity test. A degenerate cycle measures exactly zero
/// rather than erroring.
public struct PolygonAreaMeasurement: Sendable, Hashable {
    public let vertices: [Point3D]
    public let derivedArea: Double

    /// Creates a validated measurement with its derived area.
    ///
    /// - Throws: ``InteractionError/insufficientVertices`` or
    ///   ``InteractionError/coordinateSpaceMismatch``.
    public init(vertices: [Point3D]) throws {
        guard vertices.count >= 3 else {
            throw InteractionError.insufficientVertices
        }
        let space = vertices[0].coordinateSpace
        guard vertices.allSatisfy({ $0.coordinateSpace == space }) else {
            throw InteractionError.coordinateSpaceMismatch
        }
        self.vertices = vertices
        // The frozen VOXELIA-ALG-0018 evaluation: first-vertex
        // anchoring, the fan of cross products accumulated
        // componentwise left to right, the accepted norm form, no
        // fused multiply-add.
        let anchor = vertices[0]
        let relative = vertices.dropFirst().map { vertex in
            (x: vertex.x - anchor.x, y: vertex.y - anchor.y, z: vertex.z - anchor.z)
        }
        var sumX = 0.0
        var sumY = 0.0
        var sumZ = 0.0
        for index in 0..<(relative.count - 1) {
            let p = relative[index]
            let q = relative[index + 1]
            sumX += (p.y * q.z) - (p.z * q.y)
            sumY += (p.z * q.x) - (p.x * q.z)
            sumZ += (p.x * q.y) - (p.y * q.x)
        }
        let norm = (((sumX * sumX) + (sumY * sumY)) + (sumZ * sumZ)).squareRoot()
        derivedArea = 0.5 * norm
    }
}

/// One calibrated voxel volume measurement per `ADR-0144`
/// (`VOX-SPA-014`).
///
/// The exact calibration and count are preserved beside the derived
/// value, computed once at construction under the registered
/// `VOXELIA-ALG-0019` model: the typed count bound guarantees an
/// exact binary64 conversion, and the cell volume is the magnitude
/// of the accepted `VOXELIA-ALG-0016` determinant authority's value,
/// never re-derived.
public struct VoxelVolumeMeasurement: Sendable, Hashable {
    /// The inclusive count ceiling guaranteeing exact conversion.
    public static let maximumVoxelCount = 1 << 53

    public let geometry: AffineGridGeometry
    public let voxelCount: Int
    public let cellVolume: Double
    public let derivedVolume: Double

    /// Creates a validated measurement with its derived volume.
    ///
    /// - Throws: ``InteractionError/invalidVoxelCount``, or the
    ///   spatial inverse admission — unreachable for a validated
    ///   geometry, whose own admission computes the identical frozen
    ///   determinant.
    public init(geometry: AffineGridGeometry, voxelCount: Int) throws {
        guard voxelCount >= 0, voxelCount <= Self.maximumVoxelCount else {
            throw InteractionError.invalidVoxelCount
        }
        let inverse = try AffineSpatialInverse(
            spatialPartOf: geometry.indexToWorld
        )
        self.geometry = geometry
        self.voxelCount = voxelCount
        cellVolume = inverse.determinant.magnitude
        derivedVolume = Double(voxelCount) * cellVolume
    }
}

/// The closed measurement command set per `ADR-0111`.
public enum MeasurementCommand: Sendable, Hashable {
    case begin
    case addPoint(Point3D)
    case complete
}

/// The closed UI-framework-neutral interaction command vocabulary per
/// `ADR-0111` (`VOX-INT-001`, `VOX-INT-002`).
///
/// Commands are vocabulary, not behaviour: every payload is an
/// already-validated Voxelia value, and the state machine that
/// consumes them arrives with its own decisions.
public enum InteractionCommand: Sendable, Hashable {
    case windowLevel(GreyscaleWindowFunction)
    case pan(PanDelta)
    case zoom(ZoomFactor)
    case scroll(sliceDelta: Int)
    case rotate(RotationAngle)
    case crosshair(CrosshairState)
    case pick(PickTarget)
    case clip(ClipBox)
    case crop(RenderCrop)
    case measure(MeasurementCommand)
}
