// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaCore

@testable import VoxeliaStorage

@Suite("CanonicalDocumentStore")
struct CanonicalDocumentStoreTests {
    private func freshDirectory(_ suffix: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voxelia-document-store-\(suffix)")
        try? FileManager.default.removeItem(at: url)
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    private func canonicalDocument() throws -> (bytes: [UInt8], identity: ContentID) {
        let bytes = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: try MetadataCollection(entries: []),
            maximumOutputByteCount: 4_096
        )
        return (
            bytes,
            try ContentID.completeMetadataRecordIdentity(overCanonicalBytes: bytes)
        )
    }

    @Test("[Unit][VOX-STO-004][VOX-CON-006] documents persist verified and bounded")
    func documentsPersistVerifiedAndBounded() async throws {
        let directory = try freshDirectory("round-trip")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try CanonicalDocumentStore(directoryURL: directory)
        let (bytes, identity) = try canonicalDocument()
        let name = try CanonicalDocumentName(rawValue: "metadata-record-1")

        // Verified round trip through a real directory.
        #expect(await store.contains(name: name) == false)
        try await store.store(canonicalBytes: bytes, identity: identity, name: name)
        #expect(await store.contains(name: name))
        let loaded = try await store.load(
            name: name,
            expectedIdentity: identity,
            maximumDocumentByteCount: 4_096
        )
        #expect(loaded == bytes)

        // Re-storing identical content is idempotent; the exact byte
        // ceiling binds on load.
        try await store.store(canonicalBytes: bytes, identity: identity, name: name)
        #expect(
            try await store.load(
                name: name,
                expectedIdentity: identity,
                maximumDocumentByteCount: UInt64(bytes.count)
            ) == bytes
        )
        do {
            _ = try await store.load(
                name: name,
                expectedIdentity: identity,
                maximumDocumentByteCount: UInt64(bytes.count - 1)
            )
            #expect(Bool(false), "Expected the byte ceiling to reject.")
        } catch CanonicalDocumentStoreError.documentByteLimitExceeded {}

        // An unverified store claim never touches disk, and names and
        // directories validate typed.
        do {
            try await store.store(
                canonicalBytes: [9, 9, 9],
                identity: identity,
                name: try CanonicalDocumentName(rawValue: "unverified")
            )
            #expect(Bool(false), "Expected an unverified claim to be rejected.")
        } catch CanonicalDocumentStoreError.identityMismatch {}
        #expect(
            await store.contains(
                name: try CanonicalDocumentName(rawValue: "unverified")
            ) == false
        )
        for invalid in ["", "-a", "a-", "A", "a.b", "a/b", String(repeating: "a", count: 65)] {
            do {
                _ = try CanonicalDocumentName(rawValue: invalid)
                #expect(Bool(false), "Expected an invalid name to be rejected.")
            } catch CanonicalDocumentStoreError.invalidDocumentName {}
        }
        do {
            _ = try CanonicalDocumentStore(
                directoryURL: directory.appendingPathComponent("missing")
            )
            #expect(Bool(false), "Expected a missing directory to be rejected.")
        } catch CanonicalDocumentStoreError.invalidStoreDirectory {}

        requireSendable(CanonicalDocumentName.self)
        requireSendable(CanonicalDocumentStoreError.self)
    }

    @Test("[Unit][VOX-STO-004][VOX-ERR-001] on-disk corruption is surfaced, never repaired")
    func onDiskCorruptionIsSurfacedNeverRepaired() async throws {
        let directory = try freshDirectory("corruption")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try CanonicalDocumentStore(directoryURL: directory)
        let (bytes, identity) = try canonicalDocument()
        let name = try CanonicalDocumentName(rawValue: "record")
        let fileURL =
            directory
            .appendingPathComponent("record")
            .appendingPathExtension("voxelia-canonical")
        try await store.store(canonicalBytes: bytes, identity: identity, name: name)

        // A missing document is a typed miss.
        do {
            _ = try await store.load(
                name: try CanonicalDocumentName(rawValue: "absent"),
                expectedIdentity: identity,
                maximumDocumentByteCount: 4_096
            )
            #expect(Bool(false), "Expected a missing document to be rejected.")
        } catch CanonicalDocumentStoreError.documentNotFound {}

        // A byte flipped on disk is surfaced as corruption on load and
        // on re-store, and the store never repairs it.
        var flipped = bytes
        flipped[flipped.count / 2] ^= 0xFF
        try Data(flipped).write(to: fileURL, options: [.atomic])
        do {
            _ = try await store.load(
                name: name,
                expectedIdentity: identity,
                maximumDocumentByteCount: 4_096
            )
            #expect(Bool(false), "Expected flipped bytes to be rejected.")
        } catch CanonicalDocumentStoreError.corruptedDocument {}
        do {
            try await store.store(
                canonicalBytes: bytes,
                identity: identity,
                name: name
            )
            #expect(Bool(false), "Expected re-store over corruption to be rejected.")
        } catch CanonicalDocumentStoreError.corruptedDocument {}
        #expect([UInt8](try Data(contentsOf: fileURL)) == flipped)

        // A truncated document is likewise surfaced.
        try Data(bytes.prefix(bytes.count - 10)).write(to: fileURL, options: [.atomic])
        do {
            _ = try await store.load(
                name: name,
                expectedIdentity: identity,
                maximumDocumentByteCount: 4_096
            )
            #expect(Bool(false), "Expected a truncated document to be rejected.")
        } catch CanonicalDocumentStoreError.corruptedDocument {}

        // A wrong expected identity over intact bytes is also typed.
        try Data(bytes).write(to: fileURL, options: [.atomic])
        do {
            _ = try await store.load(
                name: name,
                expectedIdentity: try ContentID.completeMetadataRecordIdentity(
                    overCanonicalBytes: [1, 2, 3]
                ),
                maximumDocumentByteCount: 4_096
            )
            #expect(Bool(false), "Expected a wrong expected identity to be rejected.")
        } catch CanonicalDocumentStoreError.corruptedDocument {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
