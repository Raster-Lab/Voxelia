// SPDX-License-Identifier: MIT

/// The closed presentation polarity per `ADR-0112`.
///
/// `standard` presents the minimum display value black — the
/// `MONOCHROME2` convention — and `inverted` presents it white, the
/// `MONOCHROME1` convention, evaluated as the registered
/// `VOXELIA-ALG-0011` exact involution independently of any
/// source-value transformation.
public enum PresentationPolarity: Sendable, Hashable {
    case standard
    case inverted
}

/// One validated greyscale display window per `ADR-0083`, with the
/// explicit presentation polarity added by `ADR-0112`.
///
/// The centre and width are expressed in the input's real value
/// domain — exactly the parameter semantics the registered
/// `VOXELIA-ALG-0002` model froze. The value describes presentation
/// intent; evaluation belongs to backends against the registered model
/// and its measured GPU approximation.
public struct GreyscaleWindowFunction: Sendable, Hashable {
    public let center: Double
    public let width: Double
    public let polarity: PresentationPolarity

    /// Creates a validated window description.
    ///
    /// - Throws: ``RenderModelError/invalidWindowParameter``.
    public init(
        center: Double,
        width: Double,
        polarity: PresentationPolarity
    ) throws {
        guard center.isFinite, width.isFinite, width >= 1 else {
            throw RenderModelError.invalidWindowParameter
        }
        self.center = center
        self.width = width
        self.polarity = polarity
    }
}

/// The closed backend-neutral transfer function per `ADR-0083`.
///
/// Version one holds exactly the greyscale window case; colour maps,
/// opacity curves and volume transfer functions are registered
/// extensions, each with its own evaluation model. Stable coding is
/// owned by the future presentation-provenance projection decision.
public enum TransferFunction: Sendable, Hashable {
    case greyscaleWindow(GreyscaleWindowFunction)
}
