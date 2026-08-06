// SPDX-License-Identifier: MIT

/// What inspecting a codestream's container structure established.
///
/// Three cases rather than a `Bool`, because "this is a JPEG 2000 codestream carrying
/// no toolkit-native container" and "this is not a JPEG 2000 codestream at all" are
/// different facts, and a caller deciding how to label a payload benefits from the
/// distinction.
public enum CodestreamContainerVerdict: Sendable, Equatable {
    /// The first tile's payload opens with the toolkit-native container magic.
    case toolkitNativeContainer
    /// A JPEG 2000 main header parsed and the first tile's payload does **not** open
    /// with the toolkit-native container magic.
    case noToolkitNativeContainer
    /// The bytes are not a JPEG 2000 codestream, so the question does not arise.
    case notAJPEG2000Codestream
}

/// Detects a toolkit-native container inside an otherwise standards-shaped JPEG 2000
/// codestream, per `ADR-0272` (`VOX-CMP-006`, `VOX-CMP-013`).
///
/// ## Why byte inspection is needed at all
///
/// `ADR-0257` made `VOX-CMP-013` structural for the *name*: a
/// ``CompressedRepresentation`` is either a UID-shaped standard transfer syntax or a
/// non-UID-shaped toolkit name, and the two are provably disjoint. That rule says
/// nothing about the *bytes*, and measurement showed the gap matters.
///
/// The codec's volumetric output is a standards-shaped JPEG 2000 main header
/// (`SOC → SIZ → COD → QCD`, plus `CAP`/`CPF` for the high-throughput mode) whose
/// tile payloads are a proprietary slice-stack container rather than conformant
/// tile data. The library documents this itself, describing the envelope as a
/// "standards-shaped JP3D wrapper".
///
/// The consequence is worse than a plain incompatibility: a standards-shaped decoder
/// **accepts** such a codestream, reports plausible dimensions, raises no error, and
/// returns pixel data unrelated to the source. So labelling one with a genuine,
/// well-formed transfer syntax UID — which ``CompressedRepresentation`` alone permits,
/// because the *name* is impeccable — is enough to produce an object that a receiving
/// system decodes silently and wrongly. `ADR-0272` records the measurements.
///
/// ## Why the main header is parsed rather than scanned
///
/// The magic could be searched for directly, and that would be wrong. In one measured
/// 988-byte codestream the marker pair `FF 93` (`SOD`) appeared at **five** offsets, of
/// which exactly one was a real marker; the other four were chance byte pairs inside
/// entropy-coded data. A scan for the container magic itself carries the same class of
/// risk over megabytes of compressed data.
///
/// So this walks marker segments from `SOC` to the first `SOD` and inspects only the
/// four bytes that begin that tile's payload. The container magic occurred exactly once
/// in the measured codestreams, at precisely that position.
///
/// ## Bounded by construction
///
/// Every read is bounds-checked and the walk advances by at least two bytes per
/// iteration, so it terminates on any input without a step limit. Malformed input
/// yields ``CodestreamContainerVerdict/notAJPEG2000Codestream`` rather than a trap or a
/// throw: this type answers a question and leaves failure policy to its caller.
public enum ToolkitNativeCodestream {
    /// `SOC`, which opens every JPEG 2000 codestream.
    private static let startOfCodestream: [UInt8] = [0xFF, 0x4F]
    /// `SOD`, which opens a tile's payload.
    private static let startOfData: UInt8 = 0x93
    /// `EOC`, which ends a codestream.
    private static let endOfCodestream: UInt8 = 0xD9
    /// Markers in this range carry no segment, so they are skipped two bytes at a time.
    private static let segmentlessMarkers: ClosedRange<UInt8> = 0x30...0x3F

    /// The toolkit-native slice-stack container magic, `J3DS`.
    private static let containerMagic: [UInt8] = [0x4A, 0x33, 0x44, 0x53]

    /// A marker segment's length field is two bytes and counts itself, so a
    /// well-formed length is never below two.
    private static let minimumSegmentLength = 2

    /// Inspects `codestream` and reports what its container structure is.
    public static func inspect<C: RandomAccessCollection<UInt8>>(
        _ codestream: C
    ) -> CodestreamContainerVerdict where C.Index == Int {
        let base = codestream.startIndex
        let count = codestream.count

        func byte(_ offset: Int) -> UInt8? {
            guard offset >= 0, offset < count else { return nil }
            return codestream[base + offset]
        }

        func matches(_ pattern: [UInt8], at offset: Int) -> Bool {
            for (index, expected) in pattern.enumerated() {
                guard byte(offset + index) == expected else { return false }
            }
            return true
        }

        guard matches(startOfCodestream, at: 0) else {
            return .notAJPEG2000Codestream
        }

        // Walk main-header marker segments to the first tile payload. `SOT` carries a
        // segment and is skipped like any other, which lands the walk on the `SOD`
        // that follows it.
        var offset = startOfCodestream.count
        while true {
            guard byte(offset) == 0xFF, let marker = byte(offset + 1) else {
                return .notAJPEG2000Codestream
            }
            if marker == startOfData {
                let payload = offset + 2
                return matches(containerMagic, at: payload)
                    ? .toolkitNativeContainer
                    : .noToolkitNativeContainer
            }
            if marker == endOfCodestream {
                // A codestream that ends before any tile payload carries no container.
                return .noToolkitNativeContainer
            }
            if segmentlessMarkers.contains(marker) {
                offset += 2
                continue
            }
            guard let high = byte(offset + 2), let low = byte(offset + 3) else {
                return .notAJPEG2000Codestream
            }
            let length = Int(high) << 8 | Int(low)
            guard length >= minimumSegmentLength else {
                return .notAJPEG2000Codestream
            }
            offset += 2 + length
        }
    }
}

/// An error raised while admitting a label against the bytes it describes.
public enum CodestreamLabellingError: Error, Sendable, Equatable {
    /// A codestream carrying a toolkit-native container was labelled as a standard
    /// DICOM transfer syntax.
    case toolkitNativeCodestreamLabelledStandard
}

/// Admits a ``CompressedRepresentation`` against the codestream it describes, per
/// `ADR-0272` (`VOX-CMP-013`).
///
/// ## The single refusal, and why it is the only one
///
/// The hazard measured in `ADR-0272` needs two things at once: a codestream whose
/// tile payload is toolkit-native, **and** a label claiming it is a standard transfer
/// syntax. Only that pairing lets a conformant receiver parse the header, decode
/// without error, and display wrong pixels. So only that pairing is refused.
///
/// Everything else is admitted, and each case is deliberate rather than an omission:
///
/// - **A toolkit-native label over any bytes** is admitted. Declining to present a
///   payload as interoperable is never the hazardous direction; at worst it forgoes
///   interoperability that was available.
/// - **A standard label over bytes that are not a JPEG 2000 codestream** is admitted.
///   JPEG-LS, RLE and uncompressed transfer syntaxes are standard and are not JPEG
///   2000, so refusing them here would reject entirely legitimate objects. This case
///   is called out because the tempting rule — treat anything unparseable as suspect —
///   would do exactly that.
/// - **A standard label over a JPEG 2000 codestream with no toolkit container** is
///   admitted, which is the ordinary interoperable case.
///
/// This rule stands alongside ``CompressedRepresentation`` rather than changing it.
/// A representation must remain constructible from a source's *declared* transfer
/// syntax when no codestream is in hand, so the byte-level check applies only where
/// bytes are available.
public enum CodestreamLabellingRule {
    /// Admits `representation` as a label for `codestream`.
    ///
    /// - Throws: ``CodestreamLabellingError`` when a toolkit-native codestream is
    ///   labelled as a standard DICOM transfer syntax.
    public static func admit<C: RandomAccessCollection<UInt8>>(
        representation: CompressedRepresentation,
        codestream: C
    ) throws where C.Index == Int {
        guard representation.isStandardDICOMTransferSyntax else { return }
        guard ToolkitNativeCodestream.inspect(codestream) == .toolkitNativeContainer
        else { return }
        throw CodestreamLabellingError.toolkitNativeCodestreamLabelledStandard
    }

    /// Admits a ``CompressedPayload``'s codestream under `representation`.
    ///
    /// A convenience for the common call site, so a caller holding a payload does not
    /// reach into it to reach this rule.
    public static func admit(
        representation: CompressedRepresentation,
        payload: CompressedPayload
    ) throws {
        try admit(representation: representation, codestream: payload.codestream)
    }
}
