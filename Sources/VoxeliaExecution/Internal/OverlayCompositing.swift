// SPDX-License-Identifier: MIT

/// The closed failure family for overlay alpha compositing.
///
/// There is deliberately no representability failure: every intermediate is a
/// convex combination of values in `[0, 255]`.
///
/// Cases carry no payload so diagnostics disclose no colours, labels or
/// opacities.
enum OverlayCompositingError: Error, Sendable, Equatable {
    /// An opacity was outside `[0, 1]` or not a number.
    case invalidOpacity

    /// A label had no entry in its table.
    case unmappedLabel
}

/// One straight-alpha overlay colour.
struct OverlayEntry: Sendable, Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}

/// How one overlay produces its colour and alpha.
///
/// **A mask is a segmentation with two labels**, so there is no separate mask
/// case: carrying one would be two places for a single rule, and they would
/// drift. A "background" label is simply an entry whose alpha is zero, so no
/// background convention is invented — hard-coding label zero is a habit
/// rather than a guarantee.
enum OverlaySource: Sendable {
    /// A segmentation or mask: one label resolved through a table.
    case labelled(label: Int, table: [OverlayEntry])

    /// An image overlay supplying its own straight-alpha colour.
    case image(OverlayEntry)
}

/// One overlay awaiting compositing.
struct Overlay: Sendable {
    let source: OverlaySource
    let opacity: Double
}

/// The exact `overlay-alpha-compositing/binary64-v1` reference.
///
/// The per-channel arithmetic is `VOXELIA-ALG-0009`'s frozen sequence
/// **inherited verbatim**, so the two records cannot disagree about what `over`
/// means. What differs is the model around it: alpha is per pixel rather than
/// per layer, the background is the base image rather than black, and colour is
/// present rather than greyscale. Any one of those would have required a
/// separate record; together they are conclusive.
enum OverlayCompositing {
    /// Composites an ordered list of overlays onto one base display pixel.
    ///
    /// - Throws: ``OverlayCompositingError``.
    static func composite(
        base: DisplayPixelRGBA8,
        overlays: [Overlay]
    ) throws -> DisplayPixelRGBA8 {
        // The accumulator stays binary64 across every overlay and is quantised
        // exactly ONCE at the end. Rounding between overlays would drift: two
        // overlays at opacity 0.3 over a base of 10 give 58 rounded once and
        // 59 rounded in between, and a registered fixture pins that.
        var lanes = [Double(base.red), Double(base.green), Double(base.blue)]

        for overlay in overlays {
            let (colour, alpha) = try resolve(overlay)
            for lane in lanes.indices {
                // `ALG-0009`'s ordered sequence, correctly rounded, with no
                // fused multiply-add — fusing changes the rounding count.
                let t = 1 - alpha
                let p = lanes[lane] * t
                let q = colour[lane] * alpha
                lanes[lane] = p + q
            }
        }

        return DisplayPixelRGBA8(
            red: quantise(lanes[0]),
            green: quantise(lanes[1]),
            blue: quantise(lanes[2]),
            // The base is an opaque display image, so the result is opaque and
            // no alpha accumulation is needed.
            alpha: 255
        )
    }

    /// Resolves one overlay to a colour and an effective alpha.
    ///
    /// Both source kinds reduce to the same pair, which is the model's central
    /// finding: the three overlays the requirement names differ only in how
    /// they produce that pair, never in how it is composited.
    private static func resolve(
        _ overlay: Overlay
    ) throws -> ([Double], Double) {
        guard overlay.opacity >= 0, overlay.opacity <= 1 else {
            throw OverlayCompositingError.invalidOpacity
        }
        let entry: OverlayEntry
        switch overlay.source {
        case .labelled(let label, let table):
            // An unmapped label is REJECTED, not clamped. Clamping is right
            // for a palette, where an out-of-range value is a display
            // artefact; here it would paint a label nobody assigned a colour
            // to with the last colour in the table.
            guard label >= 0, label < table.count else {
                throw OverlayCompositingError.unmappedLabel
            }
            entry = table[label]
        case .image(let supplied):
            entry = supplied
        }

        // The entry's alpha is normalised by /255.0, the accepted `ALG-0023`
        // rule, then multiplied by the layer opacity in one correctly rounded
        // multiplication. Alpha is straight, not premultiplied.
        let alpha = (Double(entry.alpha) / 255.0) * overlay.opacity
        return (
            [Double(entry.red), Double(entry.green), Double(entry.blue)],
            alpha
        )
    }

    /// Quantises one accumulated channel to the eight-bit display range.
    private static func quantise(_ value: Double) -> UInt8 {
        UInt8(min(255, max(0, value.rounded(.toNearestOrEven))))
    }
}
