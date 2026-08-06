// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The closed failure family for VOI lookup display mapping.
///
/// Cases carry no payload so diagnostics disclose no values, table contents or
/// indices.
enum VOILookupError: Error, Sendable, Equatable {
    /// The table has no entries, so it defines no output.
    case emptyTable

    /// The input was NaN, which no clamp can decide.
    case valueNotRepresentable
}

/// The exact `voi-lookup-mapping/binary64-v1` reference.
///
/// This is the **tabular sibling of the linear window** `VOXELIA-ALG-0002`
/// froze: it occupies the same pipeline position, takes the same input and
/// produces the same eight-bit display output, so a caller chooses between a
/// window and a table rather than composing both.
///
/// It is emphatically **not** `VOXELIA-ALG-0004`, which is the DICOM-derived
/// table form of the *modality* mapping — one stage earlier, producing real
/// values in an optional measurement unit that then feed the window, and
/// indexing on a stored integer rather than on the modality stage's binary64
/// output.
enum VOILookup {
    /// Maps one value-of-interest input to the eight-bit display range.
    ///
    /// - Throws: ``VOILookupError``.
    static func map(
        value: Double,
        table: LookupTableDescriptor
    ) throws -> UInt8 {
        guard !table.values.isEmpty else {
            throw VOILookupError.emptyTable
        }
        // An infinite value is NOT a failure: it compares beyond an end of the
        // table and clamps there, which is total. Only NaN is undecidable,
        // because it compares false against everything — and a non-finite
        // input is genuinely reachable, since a linear modality transform with
        // a finite scale and a finite stored value can still overflow.
        guard !value.isNaN else {
            throw VOILookupError.valueNotRepresentable
        }

        let index = index(for: roundHalfAway(value), in: table)

        // The table's entries are display values, not physical ones, so
        // nothing is normalised and no unit travels with them. Quantisation
        // rounds TIES TO EVEN — the rule `ALG-0002` froze for the very stage
        // this replaces — and the clamp then saturates an out-of-range entry.
        //
        // `LookupTableDescriptor` already validates every entry finite, so no
        // non-finite output branch is carried here: the descriptor's own
        // admission discharges it.
        let quantised = table.values[index].rounded(.toNearestOrEven)
        return UInt8(min(255, max(0, quantised)))
    }

    /// Selects the table entry, clamping at both ends.
    ///
    /// The subtraction follows `VOXELIA-ALG-0004`'s frozen out-of-range
    /// reasoning unchanged: an overflowing difference lies beyond the
    /// representable range on the side opposite the origin's sign, so it
    /// clamps to that same end.
    private static func index(
        for rounded: Int64,
        in table: LookupTableDescriptor
    ) -> Int {
        let (difference, overflow) =
            rounded.subtractingReportingOverflow(table.firstMappedValue)
        guard !overflow else {
            return table.firstMappedValue < 0 ? table.values.count - 1 : 0
        }
        return Int(
            min(max(difference, 0), Int64(table.values.count - 1))
        )
    }

    /// The round-half-away-from-zero rule accepted by `VOXELIA-ALG-0026`,
    /// reused verbatim rather than reinvented.
    ///
    /// Selecting a table index is the job that rule was frozen for, and
    /// `VOXELIA-ALG-0037` already reuses it for choosing a colour-table entry.
    /// The output stage uses a *different* accepted rule, because quantising a
    /// display value is a different job.
    ///
    /// The behaviour on the double immediately below one half is inherited
    /// exactly: `0.49999999999999994 + 0.5` is representable as `1.0`, so the
    /// rule yields one rather than zero. Correcting that here would create a
    /// second, divergent rounding rule in the project.
    ///
    /// Saturation rather than a trap is what lets an infinite or huge value
    /// clamp instead of failing.
    private static func roundHalfAway(_ value: Double) -> Int64 {
        let shifted =
            value >= 0
            ? (value + 0.5).rounded(.down) : (value - 0.5).rounded(.up)
        if shifted <= Double(Int64.min) {
            return Int64.min
        }
        if shifted >= Double(Int64.max) {
            return Int64.max
        }
        return Int64(shifted)
    }
}
