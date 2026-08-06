// SPDX-License-Identifier: MIT

/// An error raised while admitting a progress sequence.
///
/// There is no other failure, because the sequence is generated rather than
/// supplied.
///
/// Cases carry no payload so diagnostics disclose no counts.
public enum ProgressReportingError: Error, Sendable, Equatable {
    /// The total work count was negative.
    case negativeTotal

    /// The reporting cadence was below one.
    case invalidCadence
}

/// One progress observation per `ADR-0222` (`VOX-EXE-008`).
///
/// Progress is **counts, never a fraction**. A fraction would force a division
/// and a rounding decision at every checkpoint — two more numeric boundaries —
/// discard what a consumer needs to show "3 of 128", and leave the zero-work
/// case ill-defined, since `0/0` has no value to publish. A caller that wants a
/// percentage divides once, where it displays, with its own rounding.
public struct ProgressObservation: Sendable, Hashable {
    /// Units of work finished, never decreasing and never above ``total``.
    public let completed: Int

    /// Total units of work, fixed for the whole operation.
    public let total: Int

    public init(completed: Int, total: Int) {
        self.completed = completed
        self.total = total
    }
}

/// Receives progress observations from a long-running operation.
///
/// **The return type carries the guarantee.** `Void` means an observer cannot
/// influence control flow, so an operation's output is bit-identical whether or
/// not one is attached. This is the deliberate asymmetry with a cancellation
/// probe, which returns `Bool` precisely because it *is* allowed to stop the
/// work.
public typealias ProgressObserver = @Sendable (ProgressObservation) -> Void

/// An observer that discards every observation.
///
/// Supplied explicitly at a call site that wants no reporting; it is **not** a
/// default parameter, because a default would let a caller acquire a progress
/// claim it never considered.
public let discardingProgressObserver: ProgressObserver = { _ in }

/// The exact `progress-observation/v1` sequence.
///
/// Observations are emitted at the **cancellation-checkpoint cadence** the
/// accepted algorithms already froze — every sixty-four facets or triangles,
/// every four thousand and ninety-six vertices, attributes or fragments.
/// Inventing a second cadence would mean two places for one decision to drift,
/// and would make progress density a tunable nobody asked for.
public enum ProgressSequence {
    /// The accepted facet and triangle checkpoint cadence.
    public static let facetCadence = 64

    /// The accepted vertex, attribute and fragment checkpoint cadence.
    public static let vertexCadence = 4_096

    /// Generates the frozen observation sequence for one bounded traversal.
    ///
    /// The final observation is emitted **unconditionally**, so a consumer
    /// never infers completion and a progress display always terminates. Zero
    /// work therefore reports exactly one observation, and no consumer needs a
    /// "nothing happened" special case.
    ///
    /// An exact multiple of the cadence does **not** duplicate the final count:
    /// the loop stops strictly before the total.
    ///
    /// - Throws: ``ProgressReportingError``.
    public static func observations(
        total: Int,
        cadence: Int
    ) throws -> [ProgressObservation] {
        guard total >= 0 else {
            throw ProgressReportingError.negativeTotal
        }
        guard cadence >= 1 else {
            throw ProgressReportingError.invalidCadence
        }
        var sequence = [ProgressObservation]()
        sequence.reserveCapacity(total / cadence + 1)
        var completed = 0
        while completed < total {
            sequence.append(
                ProgressObservation(completed: completed, total: total)
            )
            completed += cadence
        }
        sequence.append(ProgressObservation(completed: total, total: total))
        return sequence
    }
}
