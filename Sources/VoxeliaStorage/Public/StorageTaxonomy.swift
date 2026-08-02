// SPDX-License-Identifier: MIT

/// The physical or logical organization of an image storage provider.
///
/// This vocabulary does not itself declare readable regions or capabilities.
public enum StorageKind: String, Sendable, Hashable, Codable {
    case contiguous
    case memoryMapped
    case tiled
    case bricked
    case compressed
    case remote
    case callback
    case view
}

/// The expected lifetime or external ownership of a storage provider.
///
/// This vocabulary does not establish retention, durability, or cache policy.
public enum StoragePersistence: String, Sendable, Hashable, Codable {
    case transient
    case processLifetime
    case mappedFile
    case persistentCache
    case external
}
