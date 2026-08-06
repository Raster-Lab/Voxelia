// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The closed failure family for RGB source presentation.
///
/// There is deliberately no representability failure, because no arithmetic
/// occurs.
///
/// Cases carry no payload so diagnostics disclose no channel values or counts.
enum RGBSourceError: Error, Sendable, Equatable {
    /// The component interpretation is neither `rgb` nor `rgba`.
    case unsupportedInterpretation

    /// The sample type is wider than eight bits.
    case unsupportedSampleType

    /// The channel count does not match the interpretation.
    case channelCountMismatch
}

/// The exact `rgb-source-presentation/v1` reference.
///
/// **There is no arithmetic here, and that is the finding.** An eight-bit RGB
/// source already holds display values in the output representation, so
/// presenting it is a byte pass-through. A normalisation, a gamma or a rescale
/// would invent a transform the source never asked for and would silently alter
/// data its author calibrated.
///
/// "Explicit colour transform" is therefore a statement about **declaration**:
/// the transform is the identity, and what matters is that it is named in the
/// request and the provenance rather than assumed.
///
/// The relabelling question is discharged one level up. `ImageDescriptor`
/// already binds `.rgb` and `.rgba` to the `.colour` semantic and rejects the
/// mismatch in both directions, so a monochrome source cannot arrive here
/// claiming to be colour; this reference restates none of that.
enum RGBSourcePresentation {
    /// Presents one sample of an eight-bit colour source.
    ///
    /// - Throws: ``RGBSourceError``.
    static func present(
        interpretation: ComponentInterpretation,
        sampleType: ScalarType,
        channels: [UInt8]
    ) throws -> DisplayPixelRGBA8 {
        let expected: Int
        switch interpretation {
        case .rgb: expected = 3
        case .rgba: expected = 4
        default: throw RGBSourceError.unsupportedInterpretation
        }
        // Eight bits only. Reducing a wider channel is a real choice between
        // taking the high byte and scaling, with no consumer to settle it —
        // the same reason `ALG-0043` excludes sixteen-bit palette entries.
        guard sampleType == .uint8 else {
            throw RGBSourceError.unsupportedSampleType
        }
        guard channels.count == expected else {
            throw RGBSourceError.channelCountMismatch
        }

        return DisplayPixelRGBA8(
            red: channels[0],
            green: channels[1],
            blue: channels[2],
            // A source with no alpha channel is opaque, as a palette pixel is
            // and for the same reason: an image is not an overlay. A source
            // that HAS one keeps it unchanged, including a fully transparent
            // one — overwriting it would discard what the source said. The
            // alpha is straight, not premultiplied, composing the accepted
            // representation `ALG-0023` uses.
            alpha: interpretation == .rgba ? channels[3] : 255
        )
    }
}
