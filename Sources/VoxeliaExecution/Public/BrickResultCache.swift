// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaStorage

/// An error raised by brick cache admission, lookup or mutation.
///
/// Cases deliberately carry no payload: no identity, digest, byte
/// count, budget value or cached content is retained in diagnostics.
public enum BrickCacheError: Error, Sendable, Equatable {
    /// A stored entry failed digest revalidation and was removed.
    case corruptEntry
    /// Admission could not fit within the budgets without displacing
    /// a referenced entry.
    case resourceLimitExceeded
    /// The addressed entry is not cached.
    case unknownEntry
    /// A release without a matching retain.
    case invalidRelease
}

/// The actor-isolated instrumented brick cache per `ADR-0153`.
///
/// Entries are keyed by brick identity and representation and carry
/// their content digest; every lookup revalidates before returning,
/// eviction consults only the frozen `ADR-0152` ordering authority
/// among entries without active references, and the closed five-event
/// instrumentation emits through the explicit optional host-owned
/// sink — absent by default, so emission is off unless the host opts
/// in. Recency and insertion ordinals are the actor's own monotonic
/// counters; the cache mints no clock.
public actor BrickResultCache {
    private struct EntryKey: Hashable {
        let identity: BrickIdentity
        let representation: ExecutionClaimToken
    }

    private struct Entry {
        var bytes: ContiguousArray<UInt8>
        var digest: ContentID
        var reconstructionCost: UInt64
        var visible: Bool
        var activeReferenceCount: Int
        var lastAccessOrdinal: UInt64
        var insertionOrdinal: UInt64
    }

    /// The inclusive cached-entry-count ceiling.
    public let maximumEntryCount: UInt64
    /// The inclusive total retained-byte ceiling.
    public let maximumTotalByteCount: UInt64

    private let eventSink: BrickCacheEventSink?
    private var entries: [EntryKey: Entry] = [:]
    private var totalByteCount: UInt64 = 0
    private var nextOrdinal: UInt64 = 0

    /// Creates a cache with two explicit inclusive budgets and the
    /// explicit optional sink; there are no permissive defaults.
    public init(
        maximumEntryCount: UInt64,
        maximumTotalByteCount: UInt64,
        eventSink: BrickCacheEventSink?
    ) {
        self.maximumEntryCount = maximumEntryCount
        self.maximumTotalByteCount = maximumTotalByteCount
        self.eventSink = eventSink
    }

    /// Looks one entry up, revalidating its digest before returning.
    ///
    /// A miss returns nil and emits the miss event; a hit touches the
    /// recency ordinal and emits the hit event.
    ///
    /// - Throws: ``BrickCacheError/corruptEntry`` when revalidation
    ///   fails; the entry is removed first.
    public func lookup(
        identity: BrickIdentity,
        representation: ExecutionClaimToken
    ) throws -> ContiguousArray<UInt8>? {
        let key = EntryKey(identity: identity, representation: representation)
        guard var entry = entries[key] else {
            eventSink?(.miss(identity: identity))
            return nil
        }
        guard try Self.digest(of: entry.bytes) == entry.digest else {
            removeEntry(key)
            throw BrickCacheError.corruptEntry
        }
        entry.lastAccessOrdinal = takeOrdinal()
        entries[key] = entry
        eventSink?(.hit(identity: identity, byteCount: UInt64(entry.bytes.count)))
        return entry.bytes
    }

    /// Resolves one brick through the cache and the accepted broker.
    ///
    /// A revalidated hit returns directly; a miss emits the miss
    /// event, resolves through the broker's deduplicated computation,
    /// emits the decode event with the caller-measured cost and
    /// admits; a corrupt entry is removed and the recomputation event
    /// replaces the miss — the design's recomputation path.
    ///
    /// - Throws: ``BrickCacheError``, ``BrickRequestError``, or the
    ///   computation's own audited typed error.
    public func result(
        for identity: BrickIdentity,
        representation: ExecutionClaimToken,
        generation: UInt64,
        visible: Bool,
        reconstructionCost: UInt64,
        broker: BrickRequestBroker,
        compute: @escaping @Sendable () async throws -> ContiguousArray<UInt8>
    ) async throws -> ContiguousArray<UInt8> {
        let key = EntryKey(identity: identity, representation: representation)
        if var entry = entries[key] {
            if try Self.digest(of: entry.bytes) == entry.digest {
                entry.lastAccessOrdinal = takeOrdinal()
                entries[key] = entry
                eventSink?(
                    .hit(identity: identity, byteCount: UInt64(entry.bytes.count))
                )
                return entry.bytes
            }
            removeEntry(key)
            eventSink?(.recomputation(identity: identity))
        } else {
            eventSink?(.miss(identity: identity))
        }
        let bytes = try await broker.result(
            for: identity,
            representation: representation,
            generation: generation,
            compute: compute
        )
        eventSink?(
            .decode(
                identity: identity,
                byteCount: UInt64(bytes.count),
                costUnits: reconstructionCost
            )
        )
        // A reentrant duplicate may have admitted while the broker
        // computed; duplicate admission is idempotent.
        if entries[key] == nil {
            try admit(
                key: key,
                bytes: bytes,
                reconstructionCost: reconstructionCost,
                visible: visible
            )
        }
        return bytes
    }

    /// Marks one entry as referenced by an active operation; a
    /// referenced entry is never evictable.
    ///
    /// - Throws: ``BrickCacheError/unknownEntry``.
    public func retain(
        identity: BrickIdentity,
        representation: ExecutionClaimToken
    ) throws {
        let key = EntryKey(identity: identity, representation: representation)
        guard var entry = entries[key] else {
            throw BrickCacheError.unknownEntry
        }
        entry.activeReferenceCount += 1
        entries[key] = entry
    }

    /// Releases one active reference.
    ///
    /// - Throws: ``BrickCacheError/unknownEntry`` or
    ///   ``BrickCacheError/invalidRelease``.
    public func release(
        identity: BrickIdentity,
        representation: ExecutionClaimToken
    ) throws {
        let key = EntryKey(identity: identity, representation: representation)
        guard var entry = entries[key] else {
            throw BrickCacheError.unknownEntry
        }
        guard entry.activeReferenceCount > 0 else {
            throw BrickCacheError.invalidRelease
        }
        entry.activeReferenceCount -= 1
        entries[key] = entry
    }

    /// Updates one entry's visibility flag.
    ///
    /// - Throws: ``BrickCacheError/unknownEntry``.
    public func setVisibility(
        identity: BrickIdentity,
        representation: ExecutionClaimToken,
        visible: Bool
    ) throws {
        let key = EntryKey(identity: identity, representation: representation)
        guard var entry = entries[key] else {
            throw BrickCacheError.unknownEntry
        }
        entry.visible = visible
        entries[key] = entry
    }

    /// Tampers one stored entry so the suite can prove the typed
    /// corruption rejection; evidence seam only, never public.
    func tamperEntryForEvidence(
        identity: BrickIdentity,
        representation: ExecutionClaimToken
    ) {
        let key = EntryKey(identity: identity, representation: representation)
        guard var entry = entries[key], !entry.bytes.isEmpty else {
            return
        }
        entry.bytes[0] ^= 0xFF
        entries[key] = entry
    }

    private func admit(
        key: EntryKey,
        bytes: ContiguousArray<UInt8>,
        reconstructionCost: UInt64,
        visible: Bool
    ) throws {
        let byteCount = UInt64(bytes.count)
        while UInt64(entries.count) + 1 > maximumEntryCount
            || totalByteCount + byteCount > maximumTotalByteCount
        {
            guard let victim = try evictionVictim() else {
                throw BrickCacheError.resourceLimitExceeded
            }
            let victimBytes = UInt64(entries[victim]?.bytes.count ?? 0)
            let victimIdentity = victim.identity
            removeEntry(victim)
            eventSink?(
                .eviction(identity: victimIdentity, byteCount: victimBytes)
            )
        }
        let ordinal = takeOrdinal()
        entries[key] = Entry(
            bytes: bytes,
            digest: try Self.digest(of: bytes),
            reconstructionCost: reconstructionCost,
            visible: visible,
            activeReferenceCount: 0,
            lastAccessOrdinal: ordinal,
            insertionOrdinal: ordinal
        )
        totalByteCount += byteCount
    }

    /// The minimum of the one frozen ordering authority among entries
    /// without active references.
    private func evictionVictim() throws -> EntryKey? {
        var victimKey: EntryKey?
        var victimOrder: BrickEvictionConsideration?
        for (key, entry) in entries where entry.activeReferenceCount == 0 {
            let order = try BrickEvictionConsideration(
                lastAccessGeneration: entry.lastAccessOrdinal,
                reconstructionCost: entry.reconstructionCost,
                byteCount: UInt64(entry.bytes.count),
                visible: entry.visible,
                activeReferenceCount: entry.activeReferenceCount,
                insertionOrdinal: entry.insertionOrdinal
            )
            if let currentOrder = victimOrder {
                if order.evictsBefore(currentOrder) {
                    victimKey = key
                    victimOrder = order
                }
            } else {
                victimKey = key
                victimOrder = order
            }
        }
        return victimKey
    }

    private func removeEntry(_ key: EntryKey) {
        guard let entry = entries.removeValue(forKey: key) else {
            return
        }
        totalByteCount -= UInt64(entry.bytes.count)
    }

    private func takeOrdinal() -> UInt64 {
        nextOrdinal += 1
        return nextOrdinal
    }

    private static func digest(of bytes: ContiguousArray<UInt8>) throws -> ContentID {
        try ContentID.sampleBytesIdentity(overCanonicalPackedBytes: Array(bytes))
    }
}
