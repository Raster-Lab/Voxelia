// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised while inspecting one sample of a published slice.
///
/// Cases deliberately carry no payload, so a refusal never discloses sample
/// values or extents in a diagnostic.
public enum CTSampleInspectionError: Error, Sendable, Equatable {
    /// The slice is not a rank-two image.
    case unsupportedRank
    /// The column or row is outside the slice.
    case indexOutOfRange
    /// The slice's value transform is a lookup table or a composed chain.
    ///
    /// Only `identity` and `linear` are evaluated here. A general evaluator would
    /// duplicate the model `VOXELIA-ALG-0005` already governs and
    /// `WindowLevelOperation` already implements privately — and `ADR-0237` records
    /// what re-freezing a governed boundary costs. Refusing is the honest position
    /// until that evaluator is shared.
    case unsupportedValueTransform
    /// The slice's scalar format is not one this inspection interprets.
    case unsupportedScalarFormat
    /// The coordinated read returned fewer bytes than one sample.
    case sampleUnavailable
}

/// One inspected sample of a published slice.
public struct CTSampleInspection: Sendable, Hashable {
    /// The column index inspected.
    public let column: Int
    /// The row index inspected.
    public let row: Int
    /// The stored integer value, after masking and sign extension.
    public let storedValue: Int64
    /// The interpreted value, or `padding` when it matched the supplied padding.
    public let value: CTInterpretedValue
}

/// Reads and interprets one sample of a published two-dimensional slice, giving
/// `VOX-VS1-014`'s quantitative half.
///
/// ## What this deliberately does not do
///
/// **It computes no world position.** `PickResolver` already resolves a viewport
/// pick to indices *and* an exact physical position, under the frozen rule
/// `ADR-0129` governs. Recomputing it here would re-freeze a boundary that already
/// has an owner, which is the mistake `ADR-0237` had to correct. A caller composes
/// the two: `PickResolver` says *where*, this says *what*.
public enum CTSampleInspector {
    /// Inspects one sample.
    ///
    /// - Parameters:
    ///   - slice: a published rank-two slice.
    ///   - column: the fastest-varying index, image axis 0.
    ///   - row: image axis 1.
    ///   - paddingValue: the stored value denoting padding, when the caller knows
    ///     one. Supplied rather than read from the descriptor, because
    ///     `ImageDescriptor` carries no padding slot and `WindowLevelOperation`
    ///     takes it as a parameter for the same reason.
    /// - Throws: ``CTSampleInspectionError``.
    public static func inspect(
        slice: ImageData,
        column: Int,
        row: Int,
        paddingValue: Int64?
    ) throws -> CTSampleInspection {
        let extents = slice.descriptor.shape.extents
        guard extents.count == 2 else {
            throw CTSampleInspectionError.unsupportedRank
        }
        guard column >= 0, column < extents[0], row >= 0, row < extents[1] else {
            throw CTSampleInspectionError.indexOutOfRange
        }

        let (slope, intercept) = try rescaleTerms(slice.descriptor.valueTransform)
        let interpreter: CTValueInterpreter
        do {
            interpreter = try CTValueInterpreter(
                scalarFormat: slice.descriptor.scalarFormat,
                slope: slope,
                intercept: intercept,
                paddingValue: paddingValue
            )
        } catch {
            throw CTSampleInspectionError.unsupportedScalarFormat
        }

        // One sample only: a 1x1 region rather than a whole-slice read.
        let region = try ImageRegion(
            lowerBounds: ContiguousArray([column, row]),
            upperBounds: ContiguousArray([column + 1, row + 1])
        )
        let bytes = try slice.storage.read(region: region).bytes
        guard bytes.count == interpreter.byteCount,
            let container = interpreter.container(bytes)
        else {
            throw CTSampleInspectionError.sampleUnavailable
        }

        let storedValue = interpreter.storedValue(container: container)
        return CTSampleInspection(
            column: column,
            row: row,
            storedValue: storedValue,
            value: interpreter.interpret(storedValue: storedValue)
        )
    }

    /// The slope and intercept of a value transform this inspection evaluates.
    ///
    /// `VOXELIA-ALG-0003` governs the linear mapping, and an identity transform is
    /// bit-identical to `scale = 1, offset = 0` under that same specification — so
    /// identity is expressed as those terms rather than as a separate path.
    private static func rescaleTerms(
        _ transform: ValueTransform?
    ) throws -> (Double, Double) {
        switch transform {
        case nil, .identity:
            return (1.0, 0.0)
        case .linear(let descriptor):
            return (descriptor.scale, descriptor.offset)
        case .lookupTable, .composed:
            throw CTSampleInspectionError.unsupportedValueTransform
        }
    }
}
