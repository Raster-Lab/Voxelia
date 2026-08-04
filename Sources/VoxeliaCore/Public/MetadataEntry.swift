// SPDX-License-Identifier: MIT

/// A general metadata record pairing one key and value with one required,
/// immutable privacy classification.
///
/// Every general entry is explicitly classified; there is no valid
/// unclassified `MetadataEntry` in source or on the wire. The declared class
/// is an assertion from the constructing caller or adapter that trusted host
/// policy evaluates together with namespace, source, destination, purpose and
/// principal rules. It may require stricter treatment, but it never grants
/// logging, export or access, and no class makes the entry safe for direct
/// string interpolation.
///
/// The one declared class governs the complete entry record: both arbitrary
/// UTF-8 key fields and the entire recursive value subtree, including nested
/// object-member keys and values. Nested ``MetadataObject/Member`` values
/// remain privacy-neutral structural pairs; no implicit conversion exists
/// between an entry and a member, because projecting an entry to a member
/// erases privacy information.
///
/// `MetadataPrivacyClass` deliberately defines no severity order or
/// aggregation helper. Library-owned one-to-one transformations preserve the
/// exact stored class; combining differently classified inputs into one entry
/// requires an explicit trusted-host output class or fails. A declared
/// ``MetadataPrivacyClass/hostDefined`` remains unresolved without the
/// trusted originating policy and fails closed.
public struct MetadataEntry: Sendable, Hashable, Codable {
    /// The exact namespace/name key governed by the entry classification.
    public let key: AnyMetadataKey
    /// The semantic value payload governed by the entry classification.
    public let value: MetadataValue
    /// The single explicit, immutable privacy declaration for the whole
    /// entry record.
    public let privacyClass: MetadataPrivacyClass

    /// Creates a classified general entry from already validated inputs.
    ///
    /// The classification parameter is deliberately required: it has no
    /// default argument, optional form or two-argument overload.
    public init(
        key: AnyMetadataKey,
        value: MetadataValue,
        privacyClass: MetadataPrivacyClass
    ) {
        self.key = key
        self.value = value
        self.privacyClass = privacyClass
    }
}

extension MetadataEntry {
    private static let fieldNames = ["key", "value", "privacyClass"]

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

    /// A value-redacted entry failure whose model-relative context names at
    /// most one fixed field and never copies a caller-supplied coding path.
    private static func entryDecodingFailure(
        field: String? = nil,
        _ description: String,
        underlying: (any Error)? = nil
    ) -> DecodingError {
        .dataCorrupted(
            DecodingError.Context(
                codingPath: field.map { [ArbitraryCodingKey($0)] } ?? [],
                debugDescription: description,
                underlyingError: underlying
            )
        )
    }

    /// Retains only an audited payload-free project error from a child
    /// failure; arbitrary Foundation, adapter or decoder errors are dropped
    /// because they may reflect source text.
    private static func auditedUnderlyingError(_ error: any Error) -> (any Error)? {
        if let projectError = error as? MetadataValueError {
            return projectError
        }
        if let projectError = error as? MetadataKeyError {
            return projectError
        }
        if case DecodingError.dataCorrupted(let context) = error {
            if let projectError = context.underlyingError as? MetadataValueError {
                return projectError
            }
            if let projectError = context.underlyingError as? MetadataKeyError {
                return projectError
            }
        }
        return nil
    }

    /// Decodes the strict three-field representation, rejecting missing,
    /// distinct extra, unknown and wrong-shaped fields. Child failures are
    /// caught at each fixed field boundary and replaced with a value-redacted
    /// error; an unknown classification token is never mapped to
    /// ``MetadataPrivacyClass/hostDefined``.
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<ArbitraryCodingKey>
        do {
            container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        } catch {
            throw Self.entryDecodingFailure("Expected a three-field metadata entry.")
        }
        guard
            container.allKeys.count == Self.fieldNames.count,
            Set(container.allKeys.map(\.stringValue)) == Set(Self.fieldNames)
        else {
            throw Self.entryDecodingFailure("Expected a three-field metadata entry.")
        }

        do {
            self.key = try container.decode(
                AnyMetadataKey.self,
                forKey: ArbitraryCodingKey("key")
            )
        } catch {
            throw Self.entryDecodingFailure(
                field: "key",
                "The metadata entry key is invalid.",
                underlying: Self.auditedUnderlyingError(error)
            )
        }
        do {
            self.value = try container.decode(
                MetadataValue.self,
                forKey: ArbitraryCodingKey("value")
            )
        } catch {
            throw Self.entryDecodingFailure(
                field: "value",
                "The metadata entry value is invalid.",
                underlying: Self.auditedUnderlyingError(error)
            )
        }
        do {
            self.privacyClass = try container.decode(
                MetadataPrivacyClass.self,
                forKey: ArbitraryCodingKey("privacyClass")
            )
        } catch {
            throw Self.entryDecodingFailure(
                field: "privacyClass",
                "The metadata entry privacy classification is invalid."
            )
        }
    }

    /// Encodes exactly the three fixed fields. Encoding is storage
    /// representation, never export authorisation, and model-originated
    /// encoding never reflects `self`, a key or a payload into an error.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ArbitraryCodingKey.self)
        try container.encode(key, forKey: ArbitraryCodingKey("key"))
        try container.encode(value, forKey: ArbitraryCodingKey("value"))
        try container.encode(privacyClass, forKey: ArbitraryCodingKey("privacyClass"))
    }
}
