// SPDX-License-Identifier: MIT

/// An error raised while validating a frame anchor index.
public enum FrameAnchorIndexError: Error, Sendable, Equatable {
    /// The component collection was empty.
    case emptyRank

    /// A component was outside `0..<Int.max` and therefore impossible for
    /// every valid image shape.
    case componentOutsidePossibleImageRange(axis: Int, value: Int)
}

/// One full logical parent-image coordinate at the origin of a positioned
/// full frame's local index coordinates.
///
/// The anchor is not a frame ordinal, a DICOM or source frame number,
/// provenance identity, a physical point, a storage offset or a substitute
/// for Core's general `ImageIndex`. Component order is logical image-axis
/// order; count, order and every component participate in exact equality,
/// hashing and serialised value identity. The type performs no rank
/// inference, upper-bound lookup, stride calculation, offset arithmetic,
/// axis sorting or source-identity conversion; only a later shape-bound
/// check can prove a component valid for a concrete image.
public struct FrameAnchorIndex: Sendable, Hashable {
    /// The anchor components in logical image-axis order.
    public let components: ContiguousArray<Int>

    /// The number of components.
    public var rank: Int { components.count }

    /// Creates a validated anchor from any integer collection.
    ///
    /// - Throws: ``FrameAnchorIndexError/emptyRank`` when `components` is
    ///   empty, or
    ///   ``FrameAnchorIndexError/componentOutsidePossibleImageRange(axis:value:)``
    ///   for the first component outside `0..<Int.max` in axis order.
    ///   `Int.max` is rejected because an extent is itself an `Int` and
    ///   index validity requires `component < extent`.
    public init<Components: Collection>(
        components: Components
    ) throws where Components.Element == Int {
        let materialized = ContiguousArray(components)
        guard !materialized.isEmpty else {
            throw FrameAnchorIndexError.emptyRank
        }
        for (axis, value) in materialized.enumerated() {
            guard value >= 0, value < Int.max else {
                throw FrameAnchorIndexError.componentOutsidePossibleImageRange(
                    axis: axis,
                    value: value
                )
            }
        }
        self.components = materialized
    }
}

extension FrameAnchorIndex: Codable {
    private enum CodingKeys: String, CodingKey {
        case components
    }

    private struct ArbitraryCodingKey: CodingKey {
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

    /// Decodes the strict one-key representation and revalidates it so
    /// serialized input cannot bypass anchor invariants. The derived rank is
    /// never encoded.
    public init(from decoder: any Decoder) throws {
        let componentsKey = ArbitraryCodingKey("components")
        let container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        guard container.allKeys.map(\.stringValue) == [componentsKey.stringValue] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                        "A frame anchor requires exactly one components field."
                )
            )
        }
        let decodedComponents = try container.decode(
            ContiguousArray<Int>.self,
            forKey: componentsKey
        )

        do {
            try self.init(components: decodedComponents)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [componentsKey],
                    debugDescription: "Frame anchor contains impossible components.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes only the ordered components.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(components, forKey: .components)
    }
}
