// SPDX-License-Identifier: MIT

/// A typed, immutable string identifier used at Voxelia public API boundaries.
///
/// Concrete conforming types remain distinct even when their raw strings are
/// equal. Implementations preserve supplied spelling and compare using Swift's
/// case-sensitive `String` equality. A conforming `init?(rawValue:)` must
/// reject empty and whitespace-only strings.
public protocol VoxeliaStringIdentifier:
    RawRepresentable,
    Sendable,
    Hashable,
    Codable
where RawValue == String {}

/// An error raised while validating a Voxelia string identifier.
public enum VoxeliaStringIdentifierError: Error, Sendable, Equatable {
    case emptyOrWhitespaceOnly
    case rejectedByConcreteType
}

extension VoxeliaStringIdentifier {
    /// Creates an identifier with a typed validation failure.
    ///
    /// - Throws: ``VoxeliaStringIdentifierError/emptyOrWhitespaceOnly`` when
    ///   `rawValue` is empty or contains only Unicode whitespace, or
    ///   ``VoxeliaStringIdentifierError/rejectedByConcreteType`` when a
    ///   conforming type applies an additional raw-value restriction.
    public init(validating rawValue: String) throws {
        guard isValidStringIdentifier(rawValue) else {
            throw VoxeliaStringIdentifierError.emptyOrWhitespaceOnly
        }
        guard let identifier = Self(rawValue: rawValue) else {
            throw VoxeliaStringIdentifierError.rejectedByConcreteType
        }
        self = identifier
    }

    /// Decodes the stable keyed representation and revalidates its raw value.
    public init(from decoder: any Decoder) throws {
        let rawValueKey = StringIdentifierCodingKey("rawValue")
        let container = try decoder.container(keyedBy: StringIdentifierCodingKey.self)
        guard container.allKeys.map(\.stringValue) == [rawValueKey.stringValue] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "A string identifier requires exactly one rawValue field."
                )
            )
        }
        let decodedRawValue = try container.decode(String.self, forKey: rawValueKey)

        do {
            try self.init(validating: decodedRawValue)
        } catch let error as VoxeliaStringIdentifierError {
            let description =
                switch error {
                case .emptyOrWhitespaceOnly:
                    "A string identifier cannot be empty or whitespace-only."
                case .rejectedByConcreteType:
                    "The concrete identifier type rejected its raw value."
                }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [rawValueKey],
                    debugDescription: description,
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes the identifier as `{ "rawValue": "..." }`.
    public func encode(to encoder: any Encoder) throws {
        let rawValueKey = StringIdentifierCodingKey("rawValue")
        var container = encoder.container(keyedBy: StringIdentifierCodingKey.self)
        try container.encode(rawValue, forKey: rawValueKey)
    }
}

/// A stable identity for a physical or logical coordinate space.
public struct CoordinateSpaceID: VoxeliaStringIdentifier {
    public let rawValue: String

    /// Creates an identifier when `rawValue` is not blank.
    public init?(rawValue: String) {
        guard isValidStringIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
}

/// A stable identity for an axis in an image or spatial descriptor.
public struct AxisID: VoxeliaStringIdentifier {
    public let rawValue: String

    /// Creates an identifier when `rawValue` is not blank.
    public init?(rawValue: String) {
        guard isValidStringIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
}

private struct StringIdentifierCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

private func isValidStringIdentifier(_ rawValue: String) -> Bool {
    rawValue.contains(where: { !$0.isWhitespace })
}
