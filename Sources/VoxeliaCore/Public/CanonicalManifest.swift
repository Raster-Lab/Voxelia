// SPDX-License-Identifier: MIT

import CryptoKit
import Foundation

/// An error raised while emitting or verifying a record manifest.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// digests, keys or signature material.
public enum RecordManifestError: Error, Sendable, Equatable {
    case emptyManifest
    case duplicateManifestRecord
    case outputByteLimitExceeded
    case invalidPublicKeyEncoding
    case invalidSignatureEncoding
    case cancelled
}

/// The `VCRM-1` canonical record manifest and its verify-side
/// signature contract per `ADR-0078`.
///
/// A manifest attests one non-empty set of accepted record identities:
/// the emitter sorts entries into ascending digest-byte order and
/// rejects duplicates, so exactly one canonical form exists per record
/// set. The signature subject is the manifest's domain-separated
/// identity — an Ed25519 detached signature over the manifest
/// `ContentID`'s exact 32 digest bytes — so a signature can never be
/// replayed against another projection domain. Voxelia ships the
/// verify side only: no key is ever generated, stored or seen as a
/// private value here, and a valid signature proves custody of a key,
/// never trust, authorship authority or record truth.
public enum CanonicalManifest {
    /// Emits the exact canonical `VCRM-1` document for one record set.
    ///
    /// - Throws: ``RecordManifestError``.
    public static func encodeManifestDocument(
        records: [ContentID],
        maximumOutputByteCount: UInt64
    ) throws -> [UInt8] {
        guard !records.isEmpty else {
            throw RecordManifestError.emptyManifest
        }
        let sorted = records.sorted { left, right in
            for (leftByte, rightByte) in zip(left.digest, right.digest)
            where leftByte != rightByte {
                return leftByte < rightByte
            }
            return false
        }
        for index in 1..<sorted.count where sorted[index - 1] == sorted[index] {
            throw RecordManifestError.duplicateManifestRecord
        }
        if Task.isCancelled {
            throw RecordManifestError.cancelled
        }

        var output = [UInt8]()
        func write(_ text: String) throws {
            output.append(contentsOf: Array(text.utf8))
            guard UInt64(output.count) <= maximumOutputByteCount else {
                throw RecordManifestError.outputByteLimitExceeded
            }
        }
        try write(
            #"{"documentSchema":{"identifier":"org.voxelia.record-manifest","#
                + #""version":{"major":1,"minor":0}},"payload":{"records":["#
        )
        for (index, record) in sorted.enumerated() {
            if index > 0 {
                try write(",")
            }
            try write(#"{"algorithm":"#)
            try write(
                String(
                    decoding: CanonicalMetadataJSON.canonicalStringToken(
                        record.algorithm.rawValue
                    ),
                    as: UTF8.self
                )
            )
            try write(#","digest":""#)
            try write(ContentID.hexDigestText(record.digest))
            try write(#"","projection":{"identifier":"#)
            try write(
                String(
                    decoding: CanonicalMetadataJSON.canonicalStringToken(
                        record.projection.identifier
                    ),
                    as: UTF8.self
                )
            )
            try write(#","version":{"major":"#)
            try write(String(record.projection.version.major))
            try write(#","minor":"#)
            try write(String(record.projection.version.minor))
            try write(#"}},"scope":"#)
            try write(
                String(
                    decoding: CanonicalMetadataJSON.canonicalStringToken(
                        record.scope.rawValue
                    ),
                    as: UTF8.self
                )
            )
            try write("}")
        }
        try write("]}}")
        return output
    }

    /// Verifies one host-supplied Ed25519 detached signature over the
    /// manifest identity's exact digest bytes.
    ///
    /// A mismatch is a boolean result, not an error; malformed key and
    /// signature encodings reject typed. A `true` result proves custody
    /// of the corresponding key and nothing else.
    ///
    /// - Throws: ``RecordManifestError``.
    public static func verifySignature(
        _ signatureBytes: [UInt8],
        manifestIdentity: ContentID,
        publicKeyBytes: [UInt8]
    ) throws -> Bool {
        guard publicKeyBytes.count == 32 else {
            throw RecordManifestError.invalidPublicKeyEncoding
        }
        guard signatureBytes.count == 64 else {
            throw RecordManifestError.invalidSignatureEncoding
        }
        let publicKey: Curve25519.Signing.PublicKey
        do {
            publicKey = try Curve25519.Signing.PublicKey(
                rawRepresentation: publicKeyBytes
            )
        } catch {
            throw RecordManifestError.invalidPublicKeyEncoding
        }
        return publicKey.isValidSignature(
            Data(signatureBytes),
            for: Data(manifestIdentity.digest)
        )
    }
}
