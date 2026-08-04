// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore

/// An error raised by canonical document persistence.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// names, paths, digests or document content.
public enum CanonicalDocumentStoreError: Error, Sendable, Equatable {
    case invalidStoreDirectory
    case invalidDocumentName
    case identityMismatch
    case documentByteLimitExceeded
    case documentNotFound
    case corruptedDocument
    case storageFailure
}

/// One bounded, traversal-free canonical document name per `ADR-0075`.
///
/// A name is a single lowercase label of 1 through 64 bytes — `a` to
/// `z`, `0` to `9` or `-`, alphanumeric at both ends — so it can never
/// escape the store directory and never discloses digest material; the
/// caller owns the name-to-record mapping.
public struct CanonicalDocumentName: Sendable, Hashable {
    /// The hard inclusive name byte ceiling.
    public static let maximumNameUTF8ByteCount: UInt64 = 64

    public let rawValue: String

    /// Creates a validated name with the byte ceiling checked before
    /// the grammar.
    ///
    /// - Throws: ``CanonicalDocumentStoreError/invalidDocumentName``.
    public init(rawValue: String) throws {
        var byteCount: UInt64 = 0
        for _ in rawValue.utf8 {
            byteCount += 1
            if byteCount > Self.maximumNameUTF8ByteCount {
                throw CanonicalDocumentStoreError.invalidDocumentName
            }
        }
        var previousByte: UInt8?
        for byte in rawValue.utf8 {
            let isAlphanumeric =
                (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z"))
                || (byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9"))
            let isHyphen = byte == UInt8(ascii: "-")
            guard isAlphanumeric || isHyphen else {
                throw CanonicalDocumentStoreError.invalidDocumentName
            }
            if previousByte == nil && isHyphen {
                throw CanonicalDocumentStoreError.invalidDocumentName
            }
            previousByte = byte
        }
        guard let last = previousByte, last != UInt8(ascii: "-") else {
            throw CanonicalDocumentStoreError.invalidDocumentName
        }
        self.rawValue = rawValue
    }
}

/// The actor-isolated durable canonical document store selected by
/// `ADR-0075`.
///
/// The store persists exact canonical bytes under validated names with
/// verify-on-write and verify-on-read discipline: it never persists an
/// unverified claim, never returns unverified bytes, never repairs or
/// overwrites, and never places digest material in the filesystem
/// namespace. It is append-only — retention and deletion governance
/// remain deferred — and it interprets no document, resolves no
/// reference and authors no history. Atomicity relies on the
/// platform's documented atomic data write; independent power-fail
/// evidence remains an open recorded gap.
public actor CanonicalDocumentStore {
    private static let fileExtension = "voxelia-canonical"

    private let directoryURL: URL

    /// Creates a store over one existing writable directory; the
    /// directory is never created implicitly.
    ///
    /// - Throws:
    ///   ``CanonicalDocumentStoreError/invalidStoreDirectory``.
    public init(directoryURL: URL) throws {
        var isDirectory: ObjCBool = false
        guard
            FileManager.default.fileExists(
                atPath: directoryURL.path,
                isDirectory: &isDirectory
            ),
            isDirectory.boolValue
        else {
            throw CanonicalDocumentStoreError.invalidStoreDirectory
        }
        self.directoryURL = directoryURL
    }

    /// Persists one verified canonical document atomically.
    ///
    /// The identity is verified against the exact bytes before anything
    /// touches disk. Storing a name that already exists verifies the
    /// existing bytes: identical content is an idempotent success and
    /// different content is typed corruption, never overwrite.
    ///
    /// - Throws: ``CanonicalDocumentStoreError``, or the audited typed
    ///   cause of a failed or cancelled verification.
    public func store(
        canonicalBytes: [UInt8],
        identity: ContentID,
        name: CanonicalDocumentName
    ) async throws {
        guard try identity.matchesDigest(ofCanonicalBytes: canonicalBytes) else {
            throw CanonicalDocumentStoreError.identityMismatch
        }
        let fileURL = url(for: name)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let existing: [UInt8]
            do {
                existing = [UInt8](try Data(contentsOf: fileURL))
            } catch {
                throw CanonicalDocumentStoreError.storageFailure
            }
            guard existing == canonicalBytes else {
                throw CanonicalDocumentStoreError.corruptedDocument
            }
            return
        }
        do {
            try Data(canonicalBytes).write(to: fileURL, options: [.atomic])
        } catch {
            throw CanonicalDocumentStoreError.storageFailure
        }
    }

    /// Loads one canonical document, verifying it against the expected
    /// identity before returning any byte.
    ///
    /// - Throws: ``CanonicalDocumentStoreError``, or the audited typed
    ///   cause of a failed or cancelled verification.
    public func load(
        name: CanonicalDocumentName,
        expectedIdentity: ContentID,
        maximumDocumentByteCount: UInt64
    ) async throws -> [UInt8] {
        let fileURL = url(for: name)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw CanonicalDocumentStoreError.documentNotFound
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(
                atPath: fileURL.path
            )
            if let size = attributes[.size] as? UInt64,
                size > maximumDocumentByteCount
            {
                throw CanonicalDocumentStoreError.documentByteLimitExceeded
            }
        } catch let error as CanonicalDocumentStoreError {
            throw error
        } catch {
            throw CanonicalDocumentStoreError.storageFailure
        }
        let bytes: [UInt8]
        do {
            bytes = [UInt8](try Data(contentsOf: fileURL))
        } catch {
            throw CanonicalDocumentStoreError.storageFailure
        }
        guard UInt64(bytes.count) <= maximumDocumentByteCount else {
            throw CanonicalDocumentStoreError.documentByteLimitExceeded
        }
        guard try expectedIdentity.matchesDigest(ofCanonicalBytes: bytes) else {
            throw CanonicalDocumentStoreError.corruptedDocument
        }
        return bytes
    }

    /// Reports whether a document exists under one name; existence is
    /// not an integrity claim.
    public func contains(name: CanonicalDocumentName) -> Bool {
        FileManager.default.fileExists(atPath: url(for: name).path)
    }

    private func url(for name: CanonicalDocumentName) -> URL {
        directoryURL
            .appendingPathComponent(name.rawValue)
            .appendingPathExtension(Self.fileExtension)
    }
}
