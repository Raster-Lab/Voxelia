// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// The closed failure family for powered-length-unit admission.
///
/// Cases deliberately carry no payload so diagnostics cannot disclose the
/// supplied unit namespace, code, dimension or conversion metadata.
public enum PoweredLengthUnitError: Error, Sendable, Equatable {
    /// The supplied base unit does not carry ``UnitDimension/length``.
    case nonLengthBase

    /// The supplied exponent is zero.
    case nonPositiveExponent
}

/// One immutable length unit raised to an explicit positive integer power.
///
/// Accepted `ADR-0194` selects this representation for derived geometric
/// quantities whose unit is a power of a coordinate space's own length unit.
/// The base and the exponent stay separate published fields: there is no
/// derived code string, no new unit-registry entry and no synthesized display
/// name, because a squared or cubed spelling belongs to whichever external
/// system defines it rather than to Voxelia.
///
/// The value grants **no conversion authority**. ``MeasurementUnit`` may carry
/// `scaleToCanonical` and `offsetToCanonical`, and this type deliberately does
/// not raise, combine or otherwise reinterpret them; an offset in particular
/// has no meaning under exponentiation. A consumer that needs a canonical
/// powered quantity must derive its own conversion from the declared base and
/// exponent under its own accepted rule.
public struct PoweredLengthUnit: Sendable, Equatable {
    /// The exact length unit being raised, preserved as supplied.
    public let base: MeasurementUnit

    /// The positive integer power applied to ``base``.
    public let exponent: UInt8

    /// Creates an admitted powered length unit.
    ///
    /// - Parameters:
    ///   - base: A unit whose dimension is exactly ``UnitDimension/length``.
    ///   - exponent: A non-zero power; two denotes an area, three a volume.
    /// - Throws: ``PoweredLengthUnitError/nonLengthBase`` when the base is not
    ///   a length, and ``PoweredLengthUnitError/nonPositiveExponent`` when the
    ///   exponent is zero.
    public init(base: MeasurementUnit, exponent: UInt8) throws {
        guard base.dimension == .length else {
            throw PoweredLengthUnitError.nonLengthBase
        }
        guard exponent > 0 else {
            throw PoweredLengthUnitError.nonPositiveExponent
        }
        self.base = base
        self.exponent = exponent
    }
}
