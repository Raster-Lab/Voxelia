// SPDX-License-Identifier: MIT

/// The closed half-ray parameter interval over which a ray intersects
/// axis-aligned bounds.
///
/// This is a transient value produced only by the validated
/// ``AxisAlignedBounds3D/intersection(with:)->RayAxisAlignedBoundsIntersection3D?``
/// query under the versioned reference operation
/// `ray-axis-aligned-bounds-intersection/binary64-v1`.
/// Parameters are coefficients of the supplied unnormalised direction in
/// `point(t) = origin + t * direction`, not physical distances. Both
/// parameters are finite, signed zero is canonicalised to positive zero and
/// `0 <= entryParameter <= exitParameter` always holds. The value is
/// deliberately not `Codable` and has no public initializer.
public struct RayAxisAlignedBoundsIntersection3D: Sendable, Hashable {
    /// The first half-ray parameter inside the closed bounds.
    public let entryParameter: Double

    /// The last half-ray parameter inside the closed bounds.
    public let exitParameter: Double

    init(entryParameter: Double, exitParameter: Double) {
        self.entryParameter = entryParameter == 0 ? 0 : entryParameter
        self.exitParameter = exitParameter == 0 ? 0 : exitParameter
    }
}

/// Why a selected intersection parameter could not be represented as a
/// finite binary64 value.
public enum RayIntersectionParameterFailureReason: Sendable, Equatable {
    /// The selected boundary quotient exceeded the finite binary64 range.
    case overflow

    /// The selected boundary quotient evaluated to zero although its
    /// boundary and origin differ.
    case underflow
}

extension AxisAlignedBounds3D {
    /// Computes the closed half-ray intersection interval with these bounds
    /// under `ray-axis-aligned-bounds-intersection/binary64-v1`.
    ///
    /// `nil` is a model-classified miss under the versioned binary64
    /// algorithm; it is not a guarantee that an exact-rational predicate
    /// over the same inputs would also miss. The direction is used exactly
    /// as supplied without normalisation, an exactly zero direction
    /// component is parallel and no epsilon or tolerance expansion is
    /// applied.
    ///
    /// - Throws:
    ///   ``SpatialBoundsError/coordinateSpaceMismatch(expected:actual:)``
    ///   before any numeric work when the ray uses a different coordinate
    ///   space,
    ///   ``SpatialBoundsError/rayIntersectionEntryParameterNotRepresentable(axis:reason:)``
    ///   when the selected entry parameter overflowed or underflowed, or
    ///   ``SpatialBoundsError/rayIntersectionExitParameterNotRepresentable(axis:reason:)``
    ///   when the selected exit parameter overflowed or underflowed.
    public func intersection(
        with ray: Ray3D
    ) throws -> RayAxisAlignedBoundsIntersection3D? {
        guard ray.origin.coordinateSpace == minimum.coordinateSpace else {
            throw SpatialBoundsError.coordinateSpaceMismatch(
                expected: minimum.coordinateSpace,
                actual: ray.origin.coordinateSpace
            )
        }

        let origins = [ray.origin.x, ray.origin.y, ray.origin.z]
        let directions = [ray.direction.x, ray.direction.y, ray.direction.z]
        let minimums = [minimum.x, minimum.y, minimum.z]
        let maximums = [maximum.x, maximum.y, maximum.z]

        for axis in 0..<3 where directions[axis] == 0 {
            if origins[axis] < minimums[axis] || origins[axis] > maximums[axis] {
                return nil
            }
        }

        var entry = RayParameterToken.initialEntry
        var exit = RayParameterToken.exitSentinel
        for axis in 0..<3 where directions[axis] != 0 {
            let lower = RayParameterToken.quotient(
                boundary: minimums[axis],
                origin: origins[axis],
                direction: directions[axis],
                axis: axis
            )
            let upper = RayParameterToken.quotient(
                boundary: maximums[axis],
                origin: origins[axis],
                direction: directions[axis],
                axis: axis
            )
            let near = directions[axis] > 0 ? lower : upper
            let far = directions[axis] > 0 ? upper : lower
            if near.isOrderedAfter(entry) {
                entry = near
            }
            if exit.isOrderedAfter(far) {
                exit = far
            }
        }

        if entry.isOrderedAfter(exit) {
            return nil
        }
        if let reason = entry.failureReason {
            throw SpatialBoundsError.rayIntersectionEntryParameterNotRepresentable(
                axis: entry.axis,
                reason: reason
            )
        }
        if let reason = exit.failureReason {
            throw SpatialBoundsError.rayIntersectionExitParameterNotRepresentable(
                axis: exit.axis,
                reason: reason
            )
        }
        return RayAxisAlignedBoundsIntersection3D(
            entryParameter: entry.finiteValue,
            exitParameter: exit.finiteValue
        )
    }
}

/// One boundary-parameter token of the `binary64-v1` evaluator, retaining
/// signed overflow/underflow provenance instead of clamped values.
struct RayParameterToken {
    enum Kind {
        case negativeOverflow
        case finite
        case negativeUnderflow
        case positiveUnderflow
        case positiveOverflow
        case positiveInfinitySentinel
    }

    let kind: Kind
    let value: Double
    let axis: Int

    static let initialEntry = RayParameterToken(kind: .finite, value: 0, axis: -1)
    static let exitSentinel = RayParameterToken(
        kind: .positiveInfinitySentinel,
        value: .infinity,
        axis: -1
    )

    var failureReason: RayIntersectionParameterFailureReason? {
        switch kind {
        case .negativeOverflow, .positiveOverflow:
            .overflow
        case .negativeUnderflow, .positiveUnderflow:
            .underflow
        case .finite, .positiveInfinitySentinel:
            nil
        }
    }

    var finiteValue: Double {
        value
    }

    /// The normative rank: negativeOverflow < finite negative <
    /// negativeUnderflow < finite(+0) < positiveUnderflow < finite positive
    /// < positiveOverflow < positiveInfinitySentinel.
    private var rank: Int {
        switch kind {
        case .negativeOverflow: 0
        case .finite: value < 0 ? 1 : (value == 0 ? 3 : 5)
        case .negativeUnderflow: 2
        case .positiveUnderflow: 4
        case .positiveOverflow: 6
        case .positiveInfinitySentinel: 7
        }
    }

    /// Strict order under the normative token order; same-category
    /// non-finite tokens compare equal, so equality never reorders and the
    /// existing candidate is retained on ties.
    func isOrderedAfter(_ other: RayParameterToken) -> Bool {
        if rank != other.rank {
            return rank > other.rank
        }
        if kind == .finite, other.kind == .finite {
            return value > other.value
        }
        return false
    }

    /// Evaluates `(boundary - origin) / direction` under `binary64-v1`,
    /// using the half-scaled fallback when the direct subtraction
    /// overflows and tagging non-representable quotients instead of
    /// clamping them.
    static func quotient(
        boundary: Double,
        origin: Double,
        direction: Double,
        axis: Int
    ) -> RayParameterToken {
        var numerator = boundary - origin
        var divisor = direction
        if numerator.isInfinite {
            numerator = boundary * 0.5 - origin * 0.5
            divisor = direction * 0.5
            if divisor == 0 {
                return RayParameterToken(
                    kind: (numerator > 0) == (direction > 0)
                        ? .positiveOverflow : .negativeOverflow,
                    value: 0,
                    axis: axis
                )
            }
        }

        let quotient = numerator / divisor
        if quotient.isInfinite {
            return RayParameterToken(
                kind: quotient > 0 ? .positiveOverflow : .negativeOverflow,
                value: 0,
                axis: axis
            )
        }
        if quotient == 0, boundary != origin {
            let positive = (boundary > origin) == (direction > 0)
            return RayParameterToken(
                kind: positive ? .positiveUnderflow : .negativeUnderflow,
                value: 0,
                axis: axis
            )
        }
        return RayParameterToken(
            kind: .finite,
            value: quotient == 0 ? 0 : quotient,
            axis: axis
        )
    }
}
