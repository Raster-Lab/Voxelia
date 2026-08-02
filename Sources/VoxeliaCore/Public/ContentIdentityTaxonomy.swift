// SPDX-License-Identifier: MIT

/// A canonical category of content-digest algorithm.
///
/// This vocabulary does not compute or verify digests. The ``custom`` category
/// is not sufficient by itself for persistent or distributed identity; such a
/// use also requires an approved namespaced algorithm identifier.
public enum DigestAlgorithm: String, Sendable, Hashable, Codable {
    case sha256
    case sha512
    case blake3
    case custom
}

/// The logical or physical content covered by a content identity.
///
/// ``descriptorAndSamples`` is the preferred scope for authoritative immutable
/// image identity across systems. This vocabulary does not define an identity
/// record or canonical digest input bytes.
public enum ContentScope: String, Sendable, Hashable, Codable {
    case sampleBytes
    case descriptorAndSamples
    case storageObject
    case compressedRepresentation
    case serialisedObject
}
