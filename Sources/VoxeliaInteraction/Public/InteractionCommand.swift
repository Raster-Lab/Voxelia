// SPDX-License-Identifier: MIT

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
