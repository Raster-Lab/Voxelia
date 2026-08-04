// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// The registered `binary32` camera-relative transform per `ADR-0087`
/// and `VOXELIA-ALG-0007`, discharging the `VOX-SPA-004` gate for this
/// derivation.
///
/// The camera-relative subtraction happens in `binary64` before one
/// demotion rounding per element, removing the large-coordinate
/// cancellation that makes naive `binary32` world transforms unusable.
/// Every rendering float transform must use this derivation and carry
/// its verified bound; any other float transform remains gated until
/// registered likewise.
public struct CameraRelativeFloatTransform: Sendable, Hashable {
    /// The `binary32` unit roundoff.
    public static let unitRoundoff = 0x1p-24
    /// The specification's `γ5` forward-error factor.
    public static let errorFactor =
        (5 * unitRoundoff) / (1 - 5 * unitRoundoff)

    /// The sixteen row-major `binary32` elements; the bottom row is
    /// exactly (0, 0, 0, 1).
    public let elements: [Float]
    /// The exact `binary64` camera-relative translation retained for
    /// bound evaluation.
    public let cameraRelativeTranslation: [Double]
    /// The exact `binary64` rotation-scale block retained for bound
    /// evaluation, row-major, nine elements.
    public let rotationScale: [Double]

    /// Derives the transform from a validated affine geometry and a
    /// camera position in the geometry's coordinate space.
    ///
    /// - Throws: ``RenderModelError/coordinateSpaceMismatch``.
    public init(geometry: AffineGridGeometry, cameraPosition: Point3D) throws {
        guard
            geometry.coordinateSpace.id == cameraPosition.coordinateSpace
        else {
            throw RenderModelError.coordinateSpaceMismatch
        }
        let m = geometry.indexToWorld.elements
        let camera = [cameraPosition.x, cameraPosition.y, cameraPosition.z]
        var translation = [Double]()
        var rotation = [Double]()
        var floats = [Float](repeating: 0, count: 16)
        for row in 0...2 {
            for column in 0...2 {
                let value = m[4 * row + column]
                rotation.append(value)
                floats[4 * row + column] = Float(value)
            }
            let relative = m[4 * row + 3] - camera[row]
            translation.append(relative)
            floats[4 * row + 3] = Float(relative)
        }
        floats[15] = 1
        self.elements = floats
        self.cameraRelativeTranslation = translation
        self.rotationScale = rotation
    }

    /// Applies the transform to one index in `binary32` per the frozen
    /// association.
    public func apply(_ i0: Float, _ i1: Float, _ i2: Float) -> (Float, Float, Float) {
        var result = [Float](repeating: 0, count: 3)
        for row in 0...2 {
            let partial =
                (elements[4 * row] * i0 + elements[4 * row + 1] * i1)
                + elements[4 * row + 2] * i2
            result[row] = partial + elements[4 * row + 3]
        }
        return (result[0], result[1], result[2])
    }

    /// The exact `binary64` camera-relative reference for one index.
    public func reference(_ i0: Double, _ i1: Double, _ i2: Double) -> (
        Double, Double, Double
    ) {
        var result = [Double](repeating: 0, count: 3)
        let index = [i0, i1, i2]
        for row in 0...2 {
            var value = cameraRelativeTranslation[row]
            for column in 0...2 {
                value += rotationScale[3 * row + column] * index[column]
            }
            result[row] = value
        }
        return (result[0], result[1], result[2])
    }

    /// The specification's verified per-row error bound for one index:
    /// `γ5` times the row magnitude sum, evaluated in `binary64`.
    public func errorBound(_ i0: Double, _ i1: Double, _ i2: Double) -> [Double] {
        let index = [i0, i1, i2]
        var bounds = [Double]()
        bounds.reserveCapacity(3)
        for row in 0...2 {
            var magnitudeSum = abs(cameraRelativeTranslation[row])
            for column in 0...2 {
                magnitudeSum += abs(rotationScale[3 * row + column] * index[column])
            }
            bounds.append(Self.errorFactor * magnitudeSum)
        }
        return bounds
    }
}
