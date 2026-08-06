// SPDX-License-Identifier: MIT

/// An error raised while admitting a display colour-space declaration.
///
/// There is deliberately no invalid-code case: this project holds no registry
/// of colour-space codes, and pretending to validate against one would be a
/// claim with no basis.
///
/// Cases carry no payload so diagnostics disclose no namespace or code content.
public enum DisplayColourSpaceError: Error, Sendable, Equatable {
    /// The namespace was empty or blank.
    case emptyNamespace

    /// The code was empty or blank.
    case emptyCode
}

/// One declared output colour space per `ADR-0209` (`VOX-R2D-015`).
///
/// **Declaring is not converting.** This value says what an output *is*; it
/// grants no authority to turn it into anything else. It carries no gamma, no
/// primaries, no white point and no transfer characteristic, because those are
/// the inputs to a conversion and carrying them would invite one to be written
/// without a record. Display calibration — DICOM Part 14 GSDF, ICC profile
/// handling, measured characterisation — is out of scope for this arc entirely.
///
/// The shape follows `MeasurementUnit`: a namespace paired with a code, so
/// naming is deferred to whoever owns the namespace rather than frozen into an
/// enumeration this project cannot maintain.
///
/// Wherever this value is optional, absence means **undeclared** — never sRGB,
/// and never "the usual one".
public struct DisplayColourSpace: Sendable, Hashable {
    /// The authority owning the code's spelling.
    public let namespace: String

    /// The colour-space code within that namespace.
    public let code: String

    /// Human-readable text, excluded from equality.
    public let displayName: String?

    /// Creates a validated colour-space declaration.
    ///
    /// - Throws: ``DisplayColourSpaceError/emptyNamespace`` or
    ///   ``DisplayColourSpaceError/emptyCode``.
    public init(
        namespace: String,
        code: String,
        displayName: String?
    ) throws {
        guard !displayColourIdentityFieldIsBlank(namespace) else {
            throw DisplayColourSpaceError.emptyNamespace
        }
        guard !displayColourIdentityFieldIsBlank(code) else {
            throw DisplayColourSpaceError.emptyCode
        }
        self.namespace = namespace
        self.code = code
        self.displayName = displayName
    }

    /// Compares semantic declarations while ignoring human-readable text.
    ///
    /// The comparison is exact and byte-for-byte: there is no case folding and
    /// no Unicode normalisation. A code is an identifier drawn from an external
    /// namespace, and folding case would silently merge two distinct registry
    /// entries into one, so two declarations differing only in case are two
    /// declarations.
    public static func == (
        lhs: DisplayColourSpace,
        rhs: DisplayColourSpace
    ) -> Bool {
        lhs.namespace == rhs.namespace && lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(namespace)
        hasher.combine(code)
    }
}

/// The closed colour transform that produced an output, per `ADR-0209`.
///
/// Each case names something the pipeline does **today**. Carrying only
/// ``none`` would force the volume renderer to declare that no colour transform
/// ran while it demonstrably applies one, putting a false claim into
/// provenance.
///
/// The set is widened additively by later increments of the `ADR-0208` arc —
/// palette-colour and RGB source presentation — never rewritten, following the
/// way `ADR-0174` widened the render mode and colour output configuration.
public enum DisplayColourTransform: Sendable, Hashable {
    /// The values are presented as produced, which is what the slice path does
    /// when it emits eight-bit greyscale.
    case none

    /// An accepted one-dimensional transfer function mapped the values to
    /// colour, which is what the volume compositor does under
    /// `VOXELIA-ALG-0023`.
    case transferFunction

    /// Stored values indexed a palette under `VOXELIA-ALG-0043`.
    ///
    /// Added additively by `ADR-0214` once `ADR-0211` built the model.
    case palette

    /// An RGB or RGBA source was presented under `VOXELIA-ALG-0044`.
    ///
    /// Added additively by `ADR-0214` once `ADR-0212` built the model.
    case rgb
}

/// Reports whether an identity field holds nothing but Unicode whitespace.
///
/// The scalar set is the one `MeasurementUnit` already admits against, so a
/// namespace or code blank here is blank there too.
private func displayColourIdentityFieldIsBlank(_ value: String) -> Bool {
    !value.unicodeScalars.contains { scalar in
        switch scalar.value {
        case 0x09...0x0D, 0x20, 0x85, 0xA0, 0x1680, 0x2000...0x200A, 0x2028,
            0x2029, 0x202F, 0x205F, 0x3000:
            false
        default:
            true
        }
    }
}
