// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by segment-statistics admission.
public enum SegmentStatisticsError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case shapeMismatch
    case invalidMaskValue
    case invalidPaddingValue
}

/// One segment's statistics over authoritative stored data, per
/// `VOXELIA-ALG-0067`.
///
/// The exclusion counts are visible numbers, not warnings: a statistic
/// whose denominator quietly shrank is the dishonesty the row exists
/// to prevent. Intensity statistics are absent, never zero, when
/// nothing contributed; the volumes are absent when the image declares
/// no affine geometry.
public struct SegmentStatistics: Sendable, Equatable {
    /// Every sample the mask claims.
    public let maskSampleCount: Int
    /// The samples contributing to intensity statistics.
    public let includedSampleCount: Int
    /// Masked samples excluded by the declared padding sentinel.
    public let excludedPaddedCount: Int
    /// Masked `float32` NaN samples, excluded.
    public let excludedNonFiniteCount: Int
    /// The frozen left-to-right binary64 sum of included samples.
    public let sum: Double?
    /// `sum` divided by the included count.
    public let mean: Double?
    /// The exact minimum included sample.
    public let minimum: Double?
    /// The exact maximum included sample.
    public let maximum: Double?
    /// The magnitude of the geometry's spatial determinant.
    public let cellVolume: Double?
    /// `maskSampleCount` times ``cellVolume``: padding excludes a
    /// voxel's intensity, not its claimed extent.
    public let physicalVolume: Double?
}

/// Computes segment statistics from authoritative stored data, per
/// `ADR-0363`. Publishes nothing: a consumer persisting statistics
/// composes the accepted measurement-publication pattern in its own
/// record.
public enum SegmentStatisticsComputer {
    /// Computes one segment's statistics through the budgeted
    /// coordinated read boundary.
    ///
    /// - Throws: ``SegmentStatisticsError``, or the audited typed
    ///   errors of the storage and spatial contracts.
    public static func compute(
        image: ImageData,
        mask: ImageData,
        paddingValue: Double?,
        coordinator: StorageReadCoordinator
    ) async throws -> SegmentStatistics {
        let scalarType = image.descriptor.scalarFormat.type
        let extents = image.descriptor.shape.extents
        guard
            (2...3).contains(extents.count),
            scalarType == .uint8 || scalarType == .int16
                || scalarType == .uint16 || scalarType == .float32,
            image.descriptor.components.count == 1,
            image.descriptor.semantic == .intensity
                || image.descriptor.semantic == .parametric,
            mask.descriptor.scalarFormat.type == .uint8,
            mask.descriptor.semantic == .mask
        else {
            throw SegmentStatisticsError.unsupportedLayerFormat
        }
        guard mask.descriptor.shape.extents == extents else {
            throw SegmentStatisticsError.shapeMismatch
        }
        if let paddingValue, !paddingValue.isFinite {
            throw SegmentStatisticsError.invalidPaddingValue
        }

        let fullRegion = try ImageRegion(
            lowerBounds: [Int](repeating: 0, count: extents.count),
            upperBounds: extents
        )
        let imageRead = try await coordinator.read(from: image.storage, region: fullRegion)
        let storedBytes = imageRead.result.bytes
        try await coordinator.release(imageRead.retention)
        let maskRead = try await coordinator.read(from: mask.storage, region: fullRegion)
        let maskBytes = maskRead.result.bytes
        try await coordinator.release(maskRead.retention)
        guard maskBytes.allSatisfy({ $0 == 0 || $0 == 1 }) else {
            throw SegmentStatisticsError.invalidMaskValue
        }

        let samples = ArithmeticOperation.widen(
            storedBytes,
            scalarType: scalarType,
            byteOrder: image.descriptor.scalarFormat.byteOrder
        )

        var maskSampleCount = 0
        var includedSampleCount = 0
        var excludedPaddedCount = 0
        var excludedNonFiniteCount = 0
        var sum = 0.0
        var minimum = Double.infinity
        var maximum = -Double.infinity
        for index in 0..<maskBytes.count where maskBytes[index] == 1 {
            maskSampleCount += 1
            let value = samples[index]
            if let paddingValue, value == paddingValue {
                excludedPaddedCount += 1
                continue
            }
            if value.isNaN {
                excludedNonFiniteCount += 1
                continue
            }
            includedSampleCount += 1
            sum = sum + value
            minimum = min(minimum, value)
            maximum = max(maximum, value)
        }

        var cellVolume: Double? = nil
        var physicalVolume: Double? = nil
        if case .affine(let geometry)? = image.descriptor.spatialGeometry {
            // The VOXELIA-ALG-0016 determinant authority, composed
            // directly — the same value VOXELIA-ALG-0019's measurement
            // wraps, reached from below because the layering runs the
            // other way.
            let inverse = try AffineSpatialInverse(
                spatialPartOf: geometry.indexToWorld
            )
            let cell = inverse.determinant.magnitude
            cellVolume = cell
            physicalVolume = Double(maskSampleCount) * cell
        }

        let hasIncluded = includedSampleCount > 0
        return SegmentStatistics(
            maskSampleCount: maskSampleCount,
            includedSampleCount: includedSampleCount,
            excludedPaddedCount: excludedPaddedCount,
            excludedNonFiniteCount: excludedNonFiniteCount,
            sum: hasIncluded ? sum : nil,
            mean: hasIncluded ? sum / Double(includedSampleCount) : nil,
            minimum: hasIncluded ? minimum : nil,
            maximum: hasIncluded ? maximum : nil,
            cellVolume: cellVolume,
            physicalVolume: physicalVolume
        )
    }
}
