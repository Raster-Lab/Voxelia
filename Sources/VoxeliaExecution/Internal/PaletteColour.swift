// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The closed failure family for palette-colour display mapping.
///
/// There is deliberately no representability failure: the input is an integer
/// and `LookupTableDescriptor` validates every entry finite.
///
/// Cases carry no payload so diagnostics disclose no values, entries or
/// indices.
enum PaletteColourError: Error, Sendable, Equatable {
    /// A channel table has no entries, so it defines no output.
    case emptyTable

    /// The three tables do not share one first-mapped value and one entry
    /// count.
    case paletteShapeMismatch
}

/// One eight-bit straight-alpha display pixel.
///
/// Straight rather than premultiplied, composing the accepted representation
/// `VOXELIA-ALG-0023` already uses.
struct DisplayPixelRGBA8: Sendable, Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}

/// The exact `palette-colour-mapping/v1` reference.
///
/// **This model introduces no new rounding rule.** A palette indexes a stored
/// **integer**, so the index derivation is `VOXELIA-ALG-0004`'s clamped
/// subtraction verbatim. The round-half-away rule `VOXELIA-ALG-0042` froze
/// exists only to handle a fractional input, which this stage cannot receive;
/// reaching for it here out of symmetry would add a rounding step to a value
/// that needs none.
///
/// A scalar image is **not** palette-colour merely by being scalar. The palette
/// must be supplied, and supplying one is the explicit colour transform
/// `VOX-R2D-010` asks for — so the never-relabel-a-monochrome-source rule is
/// honoured structurally, with no inference to get wrong.
enum PaletteColour {
    /// Maps one stored integer sample through three palette tables.
    ///
    /// - Throws: ``PaletteColourError``.
    static func map(
        stored: Int64,
        red: LookupTableDescriptor,
        green: LookupTableDescriptor,
        blue: LookupTableDescriptor
    ) throws -> DisplayPixelRGBA8 {
        for table in [red, green, blue] where table.values.isEmpty {
            throw PaletteColourError.emptyTable
        }
        // Three differently shaped tables would mean three different index
        // derivations for one pixel, so a red channel could come from a
        // different stored value than its own green — a silently wrong colour
        // rather than a detected error.
        guard
            red.firstMappedValue == green.firstMappedValue,
            green.firstMappedValue == blue.firstMappedValue,
            red.values.count == green.values.count,
            green.values.count == blue.values.count
        else {
            throw PaletteColourError.paletteShapeMismatch
        }

        let index = index(stored: stored, in: red)
        return DisplayPixelRGBA8(
            red: channel(red.values[index]),
            green: channel(green.values[index]),
            blue: channel(blue.values[index]),
            // A palette-colour image is an image, not an overlay. Per-object
            // opacity is a separate accepted contract, and giving the palette
            // a transparency of its own would give it a second meaning no
            // source supplies.
            alpha: 255
        )
    }

    /// Selects the palette entry, clamping at both ends.
    ///
    /// `VOXELIA-ALG-0004`'s frozen out-of-range reasoning, inherited unchanged:
    /// an overflowing difference lies beyond the representable range on the
    /// side opposite the origin's sign, so it clamps to that same end.
    private static func index(
        stored: Int64,
        in table: LookupTableDescriptor
    ) -> Int {
        let (difference, overflow) =
            stored.subtractingReportingOverflow(table.firstMappedValue)
        guard !overflow else {
            return table.firstMappedValue < 0 ? table.values.count - 1 : 0
        }
        return Int(
            min(max(difference, 0), Int64(table.values.count - 1))
        )
    }

    /// Quantises one palette entry to the eight-bit display range.
    ///
    /// Entries are display values, so nothing is normalised: an entry outside
    /// the range saturates, because rescaling would rewrite a palette the
    /// source author already calibrated. The rule is round-ties-to-even, the
    /// accepted display-output rule — the same job `ALG-0002` and `ALG-0042`
    /// already do.
    private static func channel(_ value: Double) -> UInt8 {
        UInt8(min(255, max(0, value.rounded(.toNearestOrEven))))
    }
}
