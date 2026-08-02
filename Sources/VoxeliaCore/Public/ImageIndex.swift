// SPDX-License-Identifier: MIT

/// An immutable, dynamic-rank integer coordinate in image index space.
///
/// Voxelia uses zero-based index coordinates located at pixel or voxel centres.
/// Axis zero changes fastest in canonical contiguous storage. An `ImageIndex`
/// records coordinates but does not, by itself, prove that they are within a
/// particular ``ImageShape``; shape-aware access must validate every component
/// before calculating an offset or reading storage.
public struct ImageIndex: Sendable, Hashable, Codable {
    /// One integer coordinate for each logical image axis.
    public let components: ContiguousArray<Int>

    /// The number of logical axes represented by this index.
    public var rank: Int { components.count }

    /// Creates an index from a variable-length collection of integer
    /// coordinates.
    ///
    /// This initializer intentionally performs no bounds validation because an
    /// index has no associated shape. Consumers must validate the index against
    /// the relevant shape before using it for data access.
    ///
    /// - Parameter components: One integer coordinate for each logical axis.
    public init<Components: Collection>(components: Components)
    where Components.Element == Int {
        self.components = ContiguousArray(components)
    }
}
