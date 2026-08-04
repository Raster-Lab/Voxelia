// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaExecution

@Suite("ContentResultCache")
struct ContentResultCacheTests {
    @Test("[Unit][VOX-EXE-002][VOX-CON-006] admission verifies and accounts exactly")
    func admissionVerifiesAndAccountsExactly() async throws {
        let packed: [UInt8] = Array(0..<24)
        let packedIdentity = try ContentID.sampleBytesIdentity(
            overCanonicalPackedBytes: packed
        )
        let envelope = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: try MetadataCollection(entries: []),
            maximumOutputByteCount: 4_096
        )
        let envelopeIdentity = try ContentID.completeMetadataRecordIdentity(
            overCanonicalBytes: envelope
        )
        let cache = ContentResultCache(
            maximumEntryCount: 2,
            maximumTotalByteCount: 200
        )

        // A mismatched identity publishes nothing.
        do {
            try await cache.admit(bytes: packed, as: envelopeIdentity)
            #expect(Bool(false), "Expected a mismatched admission to be rejected.")
        } catch ContentResultCacheError.identityMismatch {}
        #expect(await cache.currentEntryCount == 0)
        #expect(await cache.currentTotalByteCount == 0)

        // Verified admission publishes and accounts exactly; duplicate
        // admission of a cached identity is idempotent.
        try await cache.admit(bytes: packed, as: packedIdentity)
        try await cache.admit(bytes: packed, as: packedIdentity)
        #expect(await cache.currentEntryCount == 1)
        #expect(await cache.currentTotalByteCount == 24)
        #expect(try await cache.lookup(packedIdentity) == packed)

        // Both registered tuples are admissible content-tier keys.
        try await cache.admit(bytes: envelope, as: envelopeIdentity)
        #expect(await cache.currentEntryCount == 2)
        #expect(await cache.currentTotalByteCount == 24 + UInt64(envelope.count))
        #expect(try await cache.lookup(envelopeIdentity) == envelope)

        // The entry-count ceiling rejects with unchanged state.
        let third = try ContentID.sampleBytesIdentity(overCanonicalPackedBytes: [7])
        do {
            try await cache.admit(bytes: [7], as: third)
            #expect(Bool(false), "Expected the entry ceiling to reject.")
        } catch ContentResultCacheError.resourceLimitExceeded {}
        #expect(await cache.currentEntryCount == 2)

        // Explicit removal frees the budget exactly once.
        try await cache.remove(packedIdentity)
        #expect(await cache.currentEntryCount == 1)
        #expect(await cache.currentTotalByteCount == UInt64(envelope.count))
        #expect(try await cache.lookup(packedIdentity) == nil)
        do {
            try await cache.remove(packedIdentity)
            #expect(Bool(false), "Expected an unknown removal to be rejected.")
        } catch ContentResultCacheError.unknownEntry {}

        // The byte ceiling rejects before publishing.
        let small = ContentResultCache(maximumEntryCount: 10, maximumTotalByteCount: 30)
        try await small.admit(bytes: packed, as: packedIdentity)
        do {
            try await small.admit(bytes: envelope, as: envelopeIdentity)
            #expect(Bool(false), "Expected the byte ceiling to reject.")
        } catch ContentResultCacheError.resourceLimitExceeded {}
        #expect(await small.currentEntryCount == 1)
        #expect(await small.currentTotalByteCount == 24)
    }

    @Test("[Unit][VOX-EXE-006][VOX-SEC-011] lookups revalidate and stay payload-free")
    func lookupsRevalidateAndStayPayloadFree() async throws {
        let packed: [UInt8] = Array(0..<24)
        let identity = try ContentID.sampleBytesIdentity(
            overCanonicalPackedBytes: packed
        )
        let cache = ContentResultCache(maximumEntryCount: 1, maximumTotalByteCount: 24)

        // A miss is a nil result, not an error.
        #expect(try await cache.lookup(identity) == nil)

        // Healthy admission and repeated revalidated hits never count a
        // revalidation failure.
        try await cache.admit(bytes: packed, as: identity)
        #expect(try await cache.lookup(identity) == packed)
        #expect(try await cache.lookup(identity) == packed)
        #expect(await cache.revalidationFailureCount == 0)

        // A returned copy is owned: mutating it cannot corrupt the cache.
        var copy = try #require(await cache.lookup(identity))
        copy[0] ^= 0xFF
        #expect(try await cache.lookup(identity) == packed)

        // Errors carry no payload.
        for error in [
            ContentResultCacheError.identityMismatch,
            .resourceLimitExceeded,
            .unknownEntry,
        ] {
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("0x"))
            #expect(!rendered.contains("digest"))
        }

        requireSendable(ContentResultCache.self)
        requireSendable(ContentResultCacheError.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
