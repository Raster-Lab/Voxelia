// SPDX-License-Identifier: MIT

/// The closed failure family for surface scalar colour mapping.
///
/// Overflow is unreachable: the scalar is admitted finite, the span is a
/// difference of finite values under a strict inequality, and every colour
/// operand is a `UInt8` over 255.
enum SurfaceColourMapError: Error, Sendable, Equatable {
    /// The domain is not finite, or its minimum is not strictly less than its
    /// maximum.
    case invalidDomain

    /// The table holds no entries.
    ///
    /// Reachable only through the entry-count-parameterised reference. The
    /// `TransferFunction1D` overload cannot produce it, because that type
    /// admits exactly `TransferFunction1D.tableSize` entries.
    case invalidTable

    /// The interpolated scalar is NaN or infinite.
    ///
    /// Unlike positions, which `TriangleMesh` admits finite, a vertex
    /// attribute is raw bytes with no accepted finiteness guarantee, so this
    /// check is real rather than defensive.
    case scalarNotRepresentable

    /// Cancellation won the operation's fixed failure precedence.
    case cancelled
}

/// One fragment's mapped colour.
///
/// Components are straight — not premultiplied — in `[0, 1]`, matching the
/// accepted `VOXELIA-ALG-0023` convention. No colour space is declared: the
/// channels are the supplied table's own values.
struct SurfaceColour: Sendable, Equatable {
    let red: Double
    let green: Double
    let blue: Double

    /// The layer opacity multiplied by the entry opacity.
    let effectiveOpacity: Double
}

/// The exact `surface-scalar-colour-map/binary64-v1` reference.
///
/// This stateless internal mapper interpolates a fragment's scalar attribute,
/// selects a table entry, applies the shading intensity and produces the
/// fragment's colour. It produces no image.
enum SurfaceColourMapper {
    /// Maps one fragment using an accepted transfer function.
    ///
    /// `TransferFunction1D` admits exactly `tableSize` entries, so
    /// ``SurfaceColourMapError/invalidTable`` cannot arise here, and the
    /// table's own `entry(at:)` clamp is the same rule this model applies.
    static func evaluate(
        scalars: (Double, Double, Double),
        weights: (Double, Double, Double),
        swapped: Bool,
        domain: (minimum: Double, maximum: Double),
        table: TransferFunction1D,
        intensity: Double,
        layerOpacity: Double
    ) throws -> SurfaceColour {
        try evaluate(
            scalars: scalars,
            weights: weights,
            swapped: swapped,
            domain: domain,
            entries: table.entries,
            intensity: intensity,
            layerOpacity: layerOpacity
        )
    }

    /// The entry-count-parameterised reference the oracle exercises.
    static func evaluate(
        scalars: (Double, Double, Double),
        weights: (Double, Double, Double),
        swapped: Bool,
        domain: (minimum: Double, maximum: Double),
        entries: ContiguousArray<TransferFunctionEntry>,
        intensity: Double,
        layerOpacity: Double
    ) throws -> SurfaceColour {
        // Per-request admission precedes the per-fragment scalar check, so a
        // caller with a bad domain or table learns once rather than once per
        // pixel.
        guard
            domain.minimum.isFinite,
            domain.maximum.isFinite,
            domain.minimum < domain.maximum
        else {
            throw SurfaceColourMapError.invalidDomain
        }
        guard !entries.isEmpty else {
            throw SurfaceColourMapError.invalidTable
        }

        let value = interpolated(scalars: scalars, weights: weights, swapped: swapped)
        guard value.isFinite else {
            throw SurfaceColourMapError.scalarNotRepresentable
        }

        let entry = entries[index(of: value, domain: domain, count: entries.count)]
        // Shading modulates colour and NEVER opacity, composing the accepted
        // ALG-0023 shaded rule. That is what makes shading a lighting effect
        // rather than a transparency effect: a fully shadowed surface is black
        // but still occludes what is behind it.
        let entryOpacity = Double(entry.opacity) / 255
        return SurfaceColour(
            red: (Double(entry.red) * intensity) / 255,
            green: (Double(entry.green) * intensity) / 255,
            blue: (Double(entry.blue) * intensity) / 255,
            // Per-object and per-value opacity compose by multiplication, in
            // that order. Both are real and requirement-backed; dropping
            // either would discard a caller's stated intent.
            effectiveOpacity: layerOpacity * entryOpacity
        )
    }

    /// The frozen `((a * b + c * d) + e * f)` grouping, with the weights
    /// mapped back to original vertex order by the canonicalisation flag.
    static func interpolated(
        scalars: (Double, Double, Double),
        weights: (Double, Double, Double),
        swapped: Bool
    ) -> Double {
        let originalB = swapped ? weights.2 : weights.1
        let originalC = swapped ? weights.1 : weights.2
        return (weights.0 * scalars.0 + originalB * scalars.1)
            + originalC * scalars.2
    }

    /// Nearest-entry selection, clamped.
    ///
    /// The clamp is what makes the mapping total: an out-of-domain scalar
    /// yields an out-of-range index that clamps to an end entry, so there is
    /// no out-of-domain branch and no out-of-domain failure.
    static func index(
        of value: Double,
        domain: (minimum: Double, maximum: Double),
        count: Int
    ) -> Int {
        let span = domain.maximum - domain.minimum
        let normalised = (value - domain.minimum) / span
        let scaled = normalised * Double(count - 1)
        let rounded = roundHalfAway(scaled)
        return min(count - 1, max(0, rounded))
    }

    /// The round-half-away-from-zero rule accepted by `VOXELIA-ALG-0026`,
    /// reused rather than reinvented.
    private static func roundHalfAway(_ value: Double) -> Int {
        let shifted = value >= 0 ? (value + 0.5).rounded(.down) : (value - 0.5).rounded(.up)
        // A scalar far outside the domain can scale beyond the host integer
        // domain; the clamp above needs a representable input, so saturate
        // here rather than trapping the conversion.
        if shifted <= Double(Int.min) {
            return Int.min
        }
        if shifted >= Double(Int.max) {
            return Int.max
        }
        return Int(shifted)
    }
}
