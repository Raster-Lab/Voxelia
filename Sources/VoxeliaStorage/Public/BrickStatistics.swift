// SPDX-License-Identifier: MIT

/// An error raised while computing brick statistics.
public enum BrickStatisticsError: Error, Sendable, Equatable {
    /// The core payload was empty.
    case emptyPayload
}

/// Exact per-brick statistics per `ADR-0162` (`VOX-BRK-011`).
///
/// Statistics derive from bytes through this pure computing
/// initializer — never stored beside them — so statistics and bytes
/// can never disagree. The included extremes are absent rather than
/// fabricated when every sample is excluded, and no emptiness verdict
/// exists here: whether a brick is skippable depends on the transfer
/// function, and that decision belongs to the consumer.
public struct BrickStatistics: Sendable, Hashable {
    /// The total sample count of the core payload.
    public let sampleCount: Int

    /// The count of samples included after the accepted
    /// sentinel-exclusion rule.
    public let includedSampleCount: Int

    /// The minimum included sample, absent when every sample is
    /// excluded.
    public let includedMinimum: UInt8?

    /// The maximum included sample, absent when every sample is
    /// excluded.
    public let includedMaximum: UInt8?

    /// The count of included samples greater than zero — the
    /// occupancy signal for intensity volumes.
    public let nonZeroIncludedCount: Int

    /// Computes the statistics in one ascending pass.
    ///
    /// - Throws: ``BrickStatisticsError/emptyPayload``.
    public init(overCorePayload payload: [UInt8], sentinel: UInt8?) throws {
        guard !payload.isEmpty else {
            throw BrickStatisticsError.emptyPayload
        }
        var includedCount = 0
        var minimum: UInt8 = 255
        var maximum: UInt8 = 0
        var nonZeroCount = 0
        for value in payload {
            if let sentinel, value == sentinel {
                continue
            }
            includedCount += 1
            minimum = min(minimum, value)
            maximum = max(maximum, value)
            if value > 0 {
                nonZeroCount += 1
            }
        }
        sampleCount = payload.count
        includedSampleCount = includedCount
        includedMinimum = includedCount > 0 ? minimum : nil
        includedMaximum = includedCount > 0 ? maximum : nil
        nonZeroIncludedCount = nonZeroCount
    }
}
