// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore

/// An error raised by multi-dimensional transfer admission or lookup.
public enum MultiDimensionalTransferError: Error, Sendable, Equatable {
    /// A bin count was below two.
    case invalidBinCount
    /// A range bound was non-finite, or the range was not ordered.
    case invalidRange
    /// The entry count was not `intensityBins × gradientBins`.
    case entryCountMismatch
    /// An entry component was non-finite, or an opacity outside `[0, 1]`.
    case invalidEntry
    /// The sample fell outside the declared ranges — refused, never
    /// clamped: a silently clamped colour is a fabricated
    /// classification.
    case sampleOutOfRange
}

/// One RGBA table entry.
public struct TransferTableEntry: Sendable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let opacity: Double

    /// Creates a validated entry.
    ///
    /// - Throws: ``MultiDimensionalTransferError/invalidEntry``.
    public init(red: Double, green: Double, blue: Double, opacity: Double) throws {
        for component in [red, green, blue, opacity] where !component.isFinite {
            throw MultiDimensionalTransferError.invalidEntry
        }
        guard opacity >= 0, opacity <= 1 else {
            throw MultiDimensionalTransferError.invalidEntry
        }
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
}

/// The `multidimensional-transfer/v1` model of `VOXELIA-ALG-0082`,
/// accepted by `ADR-0395` (`VOX-DVR-006`): a declared two-dimensional
/// table over intensity and gradient magnitude, with the metric bin
/// rule and verbatim entry lookup — no interpolation in v1.
///
/// Material conditioning is one table per declared material class,
/// selected by exact index, sharing the declared-material vocabulary
/// of the photorealistic separation model.
public struct MultiDimensionalTransferFunction: Sendable {
    public let intensityBins: Int
    public let intensityLowerBound: Double
    public let intensityUpperBound: Double
    public let gradientBins: Int
    public let gradientLowerBound: Double
    public let gradientUpperBound: Double
    /// Row-major entries: `intensityBin × gradientBins + gradientBin`.
    public let entries: ContiguousArray<TransferTableEntry>

    /// Creates a validated table.
    ///
    /// - Throws: ``MultiDimensionalTransferError``.
    public init(
        intensityBins: Int,
        intensityLowerBound: Double,
        intensityUpperBound: Double,
        gradientBins: Int,
        gradientLowerBound: Double,
        gradientUpperBound: Double,
        entries: ContiguousArray<TransferTableEntry>
    ) throws {
        guard intensityBins >= 2, gradientBins >= 2 else {
            throw MultiDimensionalTransferError.invalidBinCount
        }
        for (lower, upper) in [
            (intensityLowerBound, intensityUpperBound),
            (gradientLowerBound, gradientUpperBound),
        ] {
            guard lower.isFinite, upper.isFinite, lower < upper else {
                throw MultiDimensionalTransferError.invalidRange
            }
        }
        guard entries.count == intensityBins * gradientBins else {
            throw MultiDimensionalTransferError.entryCountMismatch
        }
        self.intensityBins = intensityBins
        self.intensityLowerBound = intensityLowerBound
        self.intensityUpperBound = intensityUpperBound
        self.gradientBins = gradientBins
        self.gradientLowerBound = gradientLowerBound
        self.gradientUpperBound = gradientUpperBound
        self.entries = entries
    }

    private func binIndex(
        _ value: Double,
        lower: Double,
        width: Double,
        bins: Int
    ) -> Int? {
        let raw = floor((value - lower) / width)
        let count = Double(bins)
        if raw == count, value == lower + width * count {
            return bins - 1
        }
        guard raw >= 0, raw < count else { return nil }
        return Int(raw)
    }

    /// Looks up the stored entry for one sample, verbatim.
    ///
    /// - Throws: ``MultiDimensionalTransferError/sampleOutOfRange``.
    public func entry(
        intensity: Double,
        gradientMagnitude: Double
    ) throws -> TransferTableEntry {
        let intensityWidth =
            (intensityUpperBound - intensityLowerBound) / Double(intensityBins)
        let gradientWidth =
            (gradientUpperBound - gradientLowerBound) / Double(gradientBins)
        guard
            intensity.isFinite,
            gradientMagnitude.isFinite,
            let intensityBin = binIndex(
                intensity,
                lower: intensityLowerBound,
                width: intensityWidth,
                bins: intensityBins
            ),
            let gradientBin = binIndex(
                gradientMagnitude,
                lower: gradientLowerBound,
                width: gradientWidth,
                bins: gradientBins
            )
        else {
            throw MultiDimensionalTransferError.sampleOutOfRange
        }
        return entries[intensityBin * gradientBins + gradientBin]
    }
}

/// Material-conditioned tables: one per declared material class,
/// selected by exact index.
public struct MaterialConditionedTransfer: Sendable {
    public let tables: ContiguousArray<MultiDimensionalTransferFunction>

    /// Creates the conditioned set; at least one table.
    ///
    /// - Throws: ``MultiDimensionalTransferError/invalidBinCount``.
    public init(
        tables: ContiguousArray<MultiDimensionalTransferFunction>
    ) throws {
        guard !tables.isEmpty else {
            throw MultiDimensionalTransferError.invalidBinCount
        }
        self.tables = tables
    }

    /// Looks up in one material's table.
    ///
    /// - Throws: ``MultiDimensionalTransferError/sampleOutOfRange``.
    public func entry(
        material: Int,
        intensity: Double,
        gradientMagnitude: Double
    ) throws -> TransferTableEntry {
        guard material >= 0, material < tables.count else {
            throw MultiDimensionalTransferError.sampleOutOfRange
        }
        return try tables[material].entry(
            intensity: intensity,
            gradientMagnitude: gradientMagnitude
        )
    }
}
