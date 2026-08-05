// SPDX-License-Identifier: MIT

/// One comparable render generation per `ADR-0122` (`VOX-INT-007`).
///
/// A frame stamped with an earlier generation than the current one is
/// stale; equality is freshness. The presenter's check is one
/// comparison with no convention to misread.
public struct RenderGeneration: Sendable, Hashable, Comparable {
    public let value: UInt64

    init(value: UInt64) {
        self.value = value
    }

    public static func < (lhs: RenderGeneration, rhs: RenderGeneration) -> Bool {
        lhs.value < rhs.value
    }

    /// Reports whether a frame stamped with this generation is stale
    /// against the current generation.
    public func isStale(comparedTo current: RenderGeneration) -> Bool {
        value < current.value
    }
}

/// The actor-isolated render generation counter per `ADR-0122`.
///
/// Concurrent interaction updates mint strictly increasing,
/// never-duplicated generations; stamping frames and dropping stale
/// ones is the interactive draw loop's behaviour, which consumes this
/// contract through its own future decisions.
public actor RenderGenerationCounter {
    private var current: UInt64 = 0

    public init() {}

    /// The current generation.
    public var currentGeneration: RenderGeneration {
        RenderGeneration(value: current)
    }

    /// Mints the next generation atomically.
    public func advance() -> RenderGeneration {
        current += 1
        return RenderGeneration(value: current)
    }
}
