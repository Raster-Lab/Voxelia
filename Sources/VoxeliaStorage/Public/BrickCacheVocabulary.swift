// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised while validating the brick cache vocabulary.
public enum BrickCacheVocabularyError: Error, Sendable, Equatable {
    /// The active-reference count was negative.
    case invalidActiveReferenceCount
}

/// One entry's eviction inputs per `ADR-0151` (`VOX-BRK-008`).
///
/// Recency is a generation ordinal because cache values mint no
/// clock; the reconstruction cost is caller-measured in declared cost
/// units; unsigned fields make negativity structurally
/// unrepresentable. An entry with active references is never
/// evictable — that is correctness, not policy — and the frozen
/// version-one order among evictable entries is lexicographic with no
/// numeric weights.
public struct BrickEvictionConsideration: Sendable, Hashable {
    /// The generation ordinal of the last access.
    public let lastAccessGeneration: UInt64

    /// The caller-measured reconstruction cost in declared cost units.
    public let reconstructionCost: UInt64

    /// The entry's retained byte count.
    public let byteCount: UInt64

    /// Whether the entry is currently visible.
    public let visible: Bool

    /// The nonnegative count of active operation references.
    public let activeReferenceCount: Int

    /// The cache-assigned insertion ordinal — the deterministic
    /// tie-break.
    public let insertionOrdinal: UInt64

    /// Creates a validated consideration.
    ///
    /// - Throws: ``BrickCacheVocabularyError/invalidActiveReferenceCount``.
    public init(
        lastAccessGeneration: UInt64,
        reconstructionCost: UInt64,
        byteCount: UInt64,
        visible: Bool,
        activeReferenceCount: Int,
        insertionOrdinal: UInt64
    ) throws {
        guard activeReferenceCount >= 0 else {
            throw BrickCacheVocabularyError.invalidActiveReferenceCount
        }
        self.lastAccessGeneration = lastAccessGeneration
        self.reconstructionCost = reconstructionCost
        self.byteCount = byteCount
        self.visible = visible
        self.activeReferenceCount = activeReferenceCount
        self.insertionOrdinal = insertionOrdinal
    }

    /// Whether eviction may consider this entry at all.
    public var isEvictable: Bool {
        activeReferenceCount == 0
    }

    /// The one frozen ordering authority among evictable entries:
    /// invisible before visible, then oldest access generation, then
    /// cheapest reconstruction, then largest byte count, then the
    /// insertion ordinal. Defined for evictable entries; the
    /// never-evict rule is the consuming cache's filter.
    public func evictsBefore(_ other: BrickEvictionConsideration) -> Bool {
        if visible != other.visible {
            return !visible
        }
        if lastAccessGeneration != other.lastAccessGeneration {
            return lastAccessGeneration < other.lastAccessGeneration
        }
        if reconstructionCost != other.reconstructionCost {
            return reconstructionCost < other.reconstructionCost
        }
        if byteCount != other.byteCount {
            return byteCount > other.byteCount
        }
        return insertionOrdinal < other.insertionOrdinal
    }
}

/// A validated persistent cache format identifier per `VOX-CCH-007`.
public struct CacheFormatID: Sendable, Hashable {
    public let rawValue: String

    /// Creates an identifier when `rawValue` is not blank.
    public init?(rawValue: String) {
        guard rawValue.contains(where: { !$0.isWhitespace }) else {
            return nil
        }
        self.rawValue = rawValue
    }
}

/// One persistent cache format version per `ADR-0151`
/// (`VOX-CCH-007`): every persisted cache artifact is stamped with an
/// independent format identity and semantic version.
public struct CacheFormatVersion: Sendable, Hashable {
    public let format: CacheFormatID
    public let version: SemanticVersion

    public init(format: CacheFormatID, version: SemanticVersion) {
        self.format = format
        self.version = version
    }
}

/// The closed brick-cache instrumentation event set per `ADR-0151`
/// (`VOX-CCH-009`).
///
/// Payloads carry brick identities, byte counts and caller-measured
/// cost units only — no image bytes, no metadata values and no
/// content-derived digests, per the recorded exclusion rules.
public enum BrickCacheEvent: Sendable, Hashable {
    case hit(identity: BrickIdentity, byteCount: UInt64)
    case miss(identity: BrickIdentity)
    case eviction(identity: BrickIdentity, byteCount: UInt64)
    case decode(identity: BrickIdentity, byteCount: UInt64, costUnits: UInt64)
    case recomputation(identity: BrickIdentity)
}

/// The host-owned brick-cache event sink per `ADR-0151`: an explicit
/// optional at every consuming surface, absent by default, so
/// emission is off unless the host opts in.
public typealias BrickCacheEventSink = @Sendable (BrickCacheEvent) -> Void
