// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised while constructing or sampling a physical-coordinate ramp phantom.
///
/// Payload-free, like every other failure family in the project.
public enum PhysicalRampPhantomError: Error, Sendable, Equatable {
    /// The extents were not three positive values, or their product overflowed.
    case invalidExtents
    /// The supplied index-to-patient matrix is not affine.
    case nonAffineGeometry
    /// A sample's quantised value is not representable in `Int16`.
    case valueNotRepresentable
    /// The index is outside the phantom.
    case indexOutsideExtents
}

/// The plan §55.2 physical-coordinate ramp, per `ADR-0296` and `VOXELIA-ALG-0053`
/// (`VOX-VAL-003`).
///
/// ```text
/// value(patientX, patientY, patientZ) = patientX + 2patientY - 0.5patientZ
/// ```
///
/// ## Why this one has a specification when the other two do not
///
/// `ADR-0293` distinguished them. §55.1's ramp is exact integer arithmetic and §55.4's
/// distances are certified by an integer identity, so neither has an evaluation order worth
/// freezing. This one is a binary64 sum over patient coordinates, and its association is
/// observable in the **published integer** rather than only in the bits — `VOXELIA-ALG-0053`
/// fixture D names two samples where a right-associated or reordered evaluation rounds to a
/// different value.
///
/// ## What is composed rather than restated
///
/// The index-to-patient step is `ADR-0138`'s frozen forward evaluation, translation first
/// then ascending slots. The rounding is `VOXELIA-ALG-0002`'s ties-to-even. The affine
/// admission is `VOXELIA-ALG-0052`'s exact structural test.
///
/// The **quantisation range is refused rather than clamped**, which is a deliberate departure
/// from `VOXELIA-ALG-0002`. Saturation is meaningful for a display window; for a phantom it
/// would publish an expected value that is not the ramp's value.
public struct PhysicalRampPhantom: Sendable, Hashable {
    public let columns: Int
    public let rows: Int
    public let slices: Int
    /// The index-to-patient affine the samples are evaluated through.
    public let indexToPatient: Matrix4x4Double
    /// The space the patient positions are expressed in.
    public let coordinateSpace: CoordinateSpaceID

    /// Builds a phantom over the given extents and geometry.
    ///
    /// Admission evaluates the eight corners. The ramp composed with an affine is itself
    /// affine in the indices, so in exact arithmetic its extremes over the box lie at
    /// corners; every sample is checked again when it is evaluated, because binary64
    /// rounding is not obliged to preserve that ordering at the last place.
    ///
    /// - Throws: ``PhysicalRampPhantomError``.
    public init(
        columns: Int,
        rows: Int,
        slices: Int,
        indexToPatient: Matrix4x4Double,
        coordinateSpace: CoordinateSpaceID
    ) throws {
        guard columns >= 1, rows >= 1, slices >= 1 else {
            throw PhysicalRampPhantomError.invalidExtents
        }
        let (frame, frameOverflowed) = columns.multipliedReportingOverflow(by: rows)
        let (samples, samplesOverflowed) = frame.multipliedReportingOverflow(by: slices)
        guard !frameOverflowed, !samplesOverflowed, samples >= 1 else {
            throw PhysicalRampPhantomError.invalidExtents
        }
        guard AffineTransformAlgebra.isAffine(indexToPatient) else {
            throw PhysicalRampPhantomError.nonAffineGeometry
        }
        self.columns = columns
        self.rows = rows
        self.slices = slices
        self.indexToPatient = indexToPatient
        self.coordinateSpace = coordinateSpace

        for slice in [0, slices - 1] {
            for row in [0, rows - 1] {
                for column in [0, columns - 1] {
                    _ = try value(column: column, row: row, slice: slice)
                }
            }
        }
    }

    /// The patient position of one sample, under `ADR-0138`'s frozen forward evaluation:
    /// the translation first, then the products in ascending slot order, accumulated left to
    /// right, with no fused multiply-add.
    ///
    /// - Throws: ``PhysicalRampPhantomError/indexOutsideExtents``.
    public func patientPosition(column: Int, row: Int, slice: Int) throws -> Point3D {
        let components = try patientComponents(column: column, row: row, slice: slice)
        return try Point3D(
            x: components.0,
            y: components.1,
            z: components.2,
            coordinateSpace: coordinateSpace
        )
    }

    /// The quantised sample value, per `VOXELIA-ALG-0053`.
    ///
    /// - Throws: ``PhysicalRampPhantomError/indexOutsideExtents`` or
    ///   ``PhysicalRampPhantomError/valueNotRepresentable``.
    public func value(column: Int, row: Int, slice: Int) throws -> Int16 {
        let position = try patientComponents(column: column, row: row, slice: slice)
        // The frozen step two: both scalings first, then a left-associative sum in the
        // order the plan writes the formula, and no fused multiply-add.
        let scaledY = 2.0 * position.1
        let scaledZ = 0.5 * position.2
        let ramp = (position.0 + scaledY) - scaledZ
        let quantised = ramp.rounded(.toNearestOrEven)
        // A not-a-number quantises to itself and fails both comparisons, so an overflowing
        // geometry is refused here rather than reaching the conversion below.
        guard quantised >= -32768.0, quantised <= 32767.0 else {
            throw PhysicalRampPhantomError.valueNotRepresentable
        }
        return Int16(quantised)
    }

    private func patientComponents(
        column: Int,
        row: Int,
        slice: Int
    ) throws -> (Double, Double, Double) {
        guard
            (0..<columns).contains(column),
            (0..<rows).contains(row),
            (0..<slices).contains(slice)
        else {
            throw PhysicalRampPhantomError.indexOutsideExtents
        }
        let elements = indexToPatient.elements
        let indices = [Double(column), Double(row), Double(slice)]
        var components = [0.0, 0.0, 0.0]
        for matrixRow in 0..<3 {
            var component = elements[4 * matrixRow + 3]
            for slot in 0..<3 {
                component = component + (elements[4 * matrixRow + slot] * indices[slot])
            }
            components[matrixRow] = component
        }
        return (components[0], components[1], components[2])
    }

    /// The number of samples the phantom holds.
    public var sampleCount: Int {
        columns * rows * slices
    }

    /// The materialised samples, little-endian `int16`, in `VOXELIA-ALG-0050` order:
    /// slice-major, then row-major within a slice, so the column index varies fastest.
    ///
    /// - Throws: ``PhysicalRampPhantomError/valueNotRepresentable`` for an interior sample
    ///   the corner admission did not reach.
    public func storedBytes() throws -> ContiguousArray<UInt8> {
        var bytes = ContiguousArray<UInt8>()
        bytes.reserveCapacity(sampleCount * 2)
        for slice in 0..<slices {
            for row in 0..<rows {
                for column in 0..<columns {
                    let sample = try value(column: column, row: row, slice: slice)
                    let pattern = UInt16(bitPattern: sample)
                    bytes.append(UInt8(truncatingIfNeeded: pattern))
                    bytes.append(UInt8(truncatingIfNeeded: pattern >> 8))
                }
            }
        }
        return bytes
    }
}
