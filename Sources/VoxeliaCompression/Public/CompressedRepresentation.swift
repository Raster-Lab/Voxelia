// SPDX-License-Identifier: MIT

/// An error raised while admitting a compressed representation's identity.
///
/// Payload-free, like every other failure family in the project: a refused
/// identifier is not echoed back.
public enum CompressedRepresentationError: Error, Sendable, Equatable {
    /// A standard transfer syntax was declared with an identifier that is not
    /// UID-shaped.
    case standardIdentifierNotUIDShaped
    /// A toolkit-native representation was named with a UID-shaped identifier.
    ///
    /// This is the refusal `VOX-CMP-013` exists for: a toolkit-native cache whose
    /// name looks like a transfer syntax UID is one rename away from being
    /// presented as an interoperable object.
    case toolkitIdentifierIsUIDShaped
    /// The identifier is empty.
    case emptyIdentifier
}

/// A conservative DICOM UID **shape** test, frozen by `ADR-0257`.
///
/// ## What this is, and what it deliberately is not
///
/// It answers one question: *could this string be mistaken for a DICOM transfer
/// syntax UID?* It is **not** a UID validator and it is **not** a claim that a
/// passing string names a syntax Voxelia supports. Its only job is to keep the two
/// cases of ``CompressedRepresentation`` provably disjoint.
///
/// The frozen predicate: a string is UID-shaped when it is non-empty, at most 64
/// characters, contains only ASCII digits and full stops, has no empty component,
/// and has at least two components. Each clause is deliberate:
///
/// - **Only digits and full stops.** DICOM UIDs are numeric components; a
///   toolkit-native name containing any other character can never be mistaken for
///   one.
/// - **At least two components.** A bare `"1"` is not plausibly a transfer syntax,
///   and requiring a separator keeps single tokens like `"jp3d"` firmly outside the
///   shape.
/// - **At most 64 characters**, which is the DICOM length limit, so a longer string
///   cannot be a conformant UID.
/// - **No empty component**, which rejects `".1.2"`, `"1..2"` and `"1.2."`.
///
/// Leading zeros are **not** rejected, even though a conformant UID component may
/// not carry them. That is on purpose: the test is used to *refuse* toolkit names
/// that look UID-like, so being slightly over-inclusive is the safe direction —
/// `"01.02"` is rejected as a toolkit name rather than admitted. Being
/// over-inclusive would only be a hazard if this test also authorised the standard
/// case, and it does not: it gates the identifier's *shape*, never its meaning.
public enum DICOMUIDShape {
    /// The DICOM UID length limit.
    public static let maximumLength = 64

    /// Reports whether `identifier` could be mistaken for a transfer syntax UID.
    public static func isUIDShaped(_ identifier: String) -> Bool {
        guard !identifier.isEmpty, identifier.count <= maximumLength else {
            return false
        }
        guard identifier.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ".") })
        else {
            return false
        }
        let components = identifier.split(
            separator: ".",
            omittingEmptySubsequences: false
        )
        guard components.count >= 2 else { return false }
        return components.allSatisfy { !$0.isEmpty }
    }
}

/// How a compressed payload is identified, per `ADR-0257` (`VOX-CMP-013`).
///
/// ## The requirement, made structural
///
/// `VOX-CMP-013` requires that toolkit-native representations are never
/// represented as standard DICOM transfer syntaxes. This type enforces that by
/// making the two **provably disjoint** rather than by asking callers to be
/// careful:
///
/// - ``standardTransferSyntax(declaredUID:)`` admits only UID-shaped identifiers.
/// - ``toolkit(name:)`` admits only identifiers that are **not** UID-shaped.
///
/// One predicate used in both directions, so `standard ⟹ UID-shaped` and
/// `toolkitNative ⟹ not UID-shaped`. Disjointness is therefore a consequence of
/// the admissions rather than a convention, and a test asserts it over the same
/// identifier set from both sides.
///
/// The storage is **private**, so those admissions are the only way to build a
/// value. That matters: while the kinds were public enum cases, a caller could
/// construct a toolkit-native value with a UID-shaped name directly and the
/// disjointness held only for callers who used the factories.
///
/// ## There is no accessor that yields a transfer syntax UID for a toolkit case
///
/// ``declaredTransferSyntaxUID`` returns `nil` for a toolkit-native value. That
/// is the second half of the enforcement: a caller writing a DICOM header cannot obtain a UID
/// for a toolkit-native cache even by mistake, because none exists to obtain.
///
/// ## Voxelia does not claim to support what it can name
///
/// A standard representation records **what a source declared**, not that Voxelia
/// can decode it. No codec is linked (`ADR-0255`), and naming a syntax is not
/// supporting it. The property is called ``declaredTransferSyntaxUID`` for that
/// reason.
public struct CompressedRepresentation: Sendable, Hashable {
    /// The two disjoint kinds.
    ///
    /// **Private, and that is the enforcement.** An earlier version of this type
    /// was a public enum, which meant a caller could write
    /// `.toolkitNative(name: "1.2.840.10008.1.2.4.201")` directly and bypass the
    /// admissions entirely — the disjointness was a property of the factory
    /// methods rather than of the type. That hole was found by compiling the
    /// bypass rather than by review, and closing it is why this is a struct with
    /// private storage whose only construction paths are the factories below.
    private enum Kind: Sendable, Hashable {
        case standard(declaredTransferSyntaxUID: String)
        case toolkitNative(name: String)
    }

    private let kind: Kind

    private init(kind: Kind) {
        self.kind = kind
    }

    /// Creates a standard transfer syntax representation.
    ///
    /// - Throws: ``CompressedRepresentationError/emptyIdentifier`` or
    ///   ``CompressedRepresentationError/standardIdentifierNotUIDShaped``.
    public static func standardTransferSyntax(
        declaredUID: String
    ) throws -> CompressedRepresentation {
        guard !declaredUID.isEmpty else {
            throw CompressedRepresentationError.emptyIdentifier
        }
        guard DICOMUIDShape.isUIDShaped(declaredUID) else {
            throw CompressedRepresentationError.standardIdentifierNotUIDShaped
        }
        return CompressedRepresentation(
            kind: .standard(declaredTransferSyntaxUID: declaredUID)
        )
    }

    /// Creates a toolkit-native representation.
    ///
    /// - Throws: ``CompressedRepresentationError/emptyIdentifier`` or
    ///   ``CompressedRepresentationError/toolkitIdentifierIsUIDShaped``.
    public static func toolkit(name: String) throws -> CompressedRepresentation {
        guard !name.isEmpty else {
            throw CompressedRepresentationError.emptyIdentifier
        }
        guard !DICOMUIDShape.isUIDShaped(name) else {
            throw CompressedRepresentationError.toolkitIdentifierIsUIDShaped
        }
        return CompressedRepresentation(kind: .toolkitNative(name: name))
    }

    /// The declared transfer syntax UID, or `nil` for a toolkit-native
    /// representation.
    ///
    /// `nil` is the enforcement, not a convenience: a caller writing a DICOM
    /// header cannot obtain a UID for a toolkit-native cache, because none exists.
    public var declaredTransferSyntaxUID: String? {
        switch kind {
        case .standard(let uid): uid
        case .toolkitNative: nil
        }
    }

    /// The toolkit-native name, or `nil` for a standard transfer syntax.
    public var toolkitName: String? {
        switch kind {
        case .standard: nil
        case .toolkitNative(let name): name
        }
    }

    /// Whether this representation may be written into a DICOM object as its
    /// transfer syntax.
    ///
    /// Stated as its own property so a caller's intent reads explicitly at the
    /// call site rather than as an incidental `nil` check.
    public var isStandardDICOMTransferSyntax: Bool {
        switch kind {
        case .standard: true
        case .toolkitNative: false
        }
    }
}
