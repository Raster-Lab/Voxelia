// SPDX-License-Identifier: MIT

/// The unsigned scalar representation of mesh indices.
public enum IndexType: String, Sendable, Hashable, Codable {
    /// A 16-bit unsigned index.
    case uint16

    /// A 32-bit unsigned index.
    case uint32

    /// A 64-bit unsigned index.
    case uint64
}
