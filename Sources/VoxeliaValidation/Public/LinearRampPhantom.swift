// SPDX-License-Identifier: MIT

/// An error raised while constructing a linear ramp phantom.
///
/// Payload-free, like every other failure family in the project.
public enum LinearRampPhantomError: Error, Sendable, Equatable {
    /// The extents were not three positive values.
    case invalidExtents
    /// The formula's range over those extents is not representable in `Int16`.
    case valueNotRepresentable
}

/// The plan §55.1 linear ramp volume, per `ADR-0294` (`VOX-VAL-003`).
///
/// ```text
/// value(i, j, k) = 2i + 3j - 5k + 100
/// ```
///
/// ## Why this is a value and not a fixture file
///
/// `ADR-0293` decision 3 froze it: the formula is the artefact. A generated volume cannot
/// drift from its own definition, where a checked-in file can and would then need integrity
/// coverage to notice.
///
/// ## Why no algorithm specification governs it
///
/// `ADR-0293` decision considered this and declined. Every term is an integer product of
/// small constants and an index, and integer addition is associative and exact, so no
/// evaluation order can change the result and there is nothing for a specification to
/// freeze. Its sibling §55.2 is different — a binary64 sum whose order is observable — and
/// gets one.
///
/// ## The purposes the plan names
///
/// Trilinear interpolation, value transformation, multiplanar reconstruction and CPU–Metal
/// difference. The ramp is exactly linear in each axis, so an interpolator's expected value
/// at any continuous position is available in closed form rather than by comparison against
/// another implementation.
public struct LinearRampPhantom: Sendable, Hashable {
    /// Column, row and slice counts, in that order.
    public let columns: Int
    public let rows: Int
    public let slices: Int

    /// Builds a phantom over the given extents.
    ///
    /// The range is checked rather than the extents being bounded by a derived constant:
    /// the formula's minimum and maximum over the box are computed directly and refused if
    /// either falls outside `Int16`. That is exact, and it avoids a magic extent limit that
    /// would have to be re-derived if the coefficients ever changed.
    ///
    /// - Throws: ``LinearRampPhantomError``.
    public init(columns: Int, rows: Int, slices: Int) throws {
        guard columns >= 1, rows >= 1, slices >= 1 else {
            throw LinearRampPhantomError.invalidExtents
        }
        // The ramp increases in i and j and decreases in k, so the extremes sit at
        // opposite corners of the box.
        let highest = Self.formula(i: columns - 1, j: rows - 1, k: 0)
        let lowest = Self.formula(i: 0, j: 0, k: slices - 1)
        guard
            highest <= Int(Int16.max), highest >= Int(Int16.min),
            lowest <= Int(Int16.max), lowest >= Int(Int16.min)
        else {
            throw LinearRampPhantomError.valueNotRepresentable
        }
        self.columns = columns
        self.rows = rows
        self.slices = slices
    }

    /// The plan's formula, in `Int` so the intermediate cannot wrap before it is checked.
    private static func formula(i: Int, j: Int, k: Int) -> Int {
        2 * i + 3 * j - 5 * k + 100
    }

    /// The exact value at one index, in closed form.
    ///
    /// - Throws: ``LinearRampPhantomError/invalidExtents`` when the index is outside the
    ///   phantom, because a phantom that answered for a position it does not contain would
    ///   let a test assert against a value the volume never held.
    public func value(column: Int, row: Int, slice: Int) throws -> Int16 {
        guard
            (0..<columns).contains(column),
            (0..<rows).contains(row),
            (0..<slices).contains(slice)
        else {
            throw LinearRampPhantomError.invalidExtents
        }
        return Int16(Self.formula(i: column, j: row, k: slice))
    }

    /// The number of samples the phantom holds.
    public var sampleCount: Int {
        columns * rows * slices
    }

    /// The materialised samples, little-endian `int16`, in `VOXELIA-ALG-0050` order:
    /// slice-major, then row-major within a slice, so the column index varies fastest.
    ///
    /// The order is composed from that accepted specification rather than restated, which
    /// matters because `row * columns` and `row * rows` agree for every square frame and
    /// differ for every other one.
    public var storedBytes: ContiguousArray<UInt8> {
        var bytes = ContiguousArray<UInt8>()
        bytes.reserveCapacity(sampleCount * 2)
        for slice in 0..<slices {
            for row in 0..<rows {
                for column in 0..<columns {
                    let sample = Int16(Self.formula(i: column, j: row, k: slice))
                    let pattern = UInt16(bitPattern: sample)
                    bytes.append(UInt8(truncatingIfNeeded: pattern))
                    bytes.append(UInt8(truncatingIfNeeded: pattern >> 8))
                }
            }
        }
        return bytes
    }
}
