// SPDX-License-Identifier: MIT

/// An error raised while validating or decoding a source identity.
///
/// Cases deliberately carry no payload so diagnostics never disclose the
/// rejected namespace, identifier, version or record text.
public enum SourceIdentityError: Error, Sendable, Equatable {
    case fieldByteLimitExceeded
    case invalidField
    case invalidRecord
}

/// One immutable source-locator claim per `ADR-0037` and `ADR-0053`.
///
/// The locator names where an object came from in an external system.
/// Accepted spelling is preserved exactly — no case folding, Unicode
/// normalisation, URI resolution, filesystem standardisation, DICOM
/// canonicalisation or namespace aliasing — and identity is the exact
/// accepted UTF-8 tuple with an absent version distinct from every
/// present version. A locator proves neither authenticity nor
/// immutability: namespaces, DICOM UIDs, paths, URLs and object-store
/// keys never establish trust by themselves. The optional `contentID` is
/// a source-content claim covering the source system's bytes.
public struct SourceIdentity: Sendable, Hashable, Codable {
    /// The hard inclusive per-field byte ceiling selected by `ADR-0053`.
    public static let maximumFieldUTF8ByteCount: UInt64 = 255

    public let namespace: String
    public let identifier: String
    public let version: String?
    public let contentID: ContentID?

    /// Creates a validated locator with fixed byte-limit-before-content
    /// precedence per field: the byte ceiling first, control-scalar
    /// rejection next, and the frozen blank-text rule last.
    ///
    /// - Throws: ``SourceIdentityError/fieldByteLimitExceeded`` or
    ///   ``SourceIdentityError/invalidField``.
    public init(
        namespace: String,
        identifier: String,
        version: String?,
        contentID: ContentID?
    ) throws {
        try Self.validateField(namespace)
        try Self.validateField(identifier)
        if let version {
            try Self.validateField(version)
        }
        self.namespace = namespace
        self.identifier = identifier
        self.version = version
        self.contentID = contentID
    }

    static func validateField(_ field: String) throws {
        // Precedence step one: the byte ceiling, stopping at the first
        // byte past the maximum.
        var byteCount: UInt64 = 0
        for _ in field.utf8 {
            byteCount += 1
            if byteCount > Self.maximumFieldUTF8ByteCount {
                throw SourceIdentityError.fieldByteLimitExceeded
            }
        }

        // Precedence step two: control scalars; step three: blank text
        // under the frozen identity whitespace oracle.
        var hasNonWhitespaceScalar = false
        for scalar in field.unicodeScalars {
            switch scalar.value {
            case 0x00...0x1F, 0x7F, 0x80...0x9F:
                throw SourceIdentityError.invalidField
            default:
                if !isFrozenIdentityWhitespaceScalar(scalar) {
                    hasNonWhitespaceScalar = true
                }
            }
        }
        guard hasNonWhitespaceScalar else {
            throw SourceIdentityError.invalidField
        }
    }

    /// Compares the exact accepted UTF-8 locator tuple and the content
    /// claim; an absent version is distinct from every present version.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.namespace.utf8.elementsEqual(rhs.namespace.utf8)
            && lhs.identifier.utf8.elementsEqual(rhs.identifier.utf8)
            && exactOptionalEquals(lhs.version, rhs.version)
            && lhs.contentID == rhs.contentID
    }

    /// Hashes the exact accepted UTF-8 locator tuple and the content
    /// claim.
    public func hash(into hasher: inout Hasher) {
        Self.hashField(namespace, into: &hasher)
        Self.hashField(identifier, into: &hasher)
        if let version {
            hasher.combine(true)
            Self.hashField(version, into: &hasher)
        } else {
            hasher.combine(false)
        }
        hasher.combine(contentID)
    }

    private static func exactOptionalEquals(_ lhs: String?, _ rhs: String?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            true
        case (let lhsValue?, let rhsValue?):
            lhsValue.utf8.elementsEqual(rhsValue.utf8)
        default:
            false
        }
    }

    private static func hashField(_ field: String, into hasher: inout Hasher) {
        hasher.combine(field.utf8.count)
        for byte in field.utf8 {
            hasher.combine(byte)
        }
    }

    // MARK: - Manual type-level coding

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

    /// Decodes the strict four-field record with explicit nulls,
    /// revalidating through the constructing initializer.
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<ArbitraryCodingKey>
        do {
            container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        } catch {
            throw SourceIdentityError.invalidRecord
        }
        let expectedFields = Set(["namespace", "identifier", "version", "contentID"])
        guard
            container.allKeys.count == expectedFields.count,
            Set(container.allKeys.map(\.stringValue)) == expectedFields
        else {
            throw SourceIdentityError.invalidRecord
        }

        let namespace: String
        let identifier: String
        let version: String?
        let contentID: ContentID?
        do {
            namespace = try container.decode(
                String.self,
                forKey: ArbitraryCodingKey("namespace")
            )
            identifier = try container.decode(
                String.self,
                forKey: ArbitraryCodingKey("identifier")
            )
            version = try container.decodeIfPresent(
                String.self,
                forKey: ArbitraryCodingKey("version")
            )
            contentID = try container.decodeIfPresent(
                ContentID.self,
                forKey: ArbitraryCodingKey("contentID")
            )
        } catch let error as ContentIdentityError {
            throw error
        } catch {
            throw SourceIdentityError.invalidRecord
        }

        try self.init(
            namespace: namespace,
            identifier: identifier,
            version: version,
            contentID: contentID
        )
    }

    /// Encodes exactly the four fixed fields with explicit nulls.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ArbitraryCodingKey.self)
        try container.encode(namespace, forKey: ArbitraryCodingKey("namespace"))
        try container.encode(identifier, forKey: ArbitraryCodingKey("identifier"))
        if let version {
            try container.encode(version, forKey: ArbitraryCodingKey("version"))
        } else {
            try container.encodeNil(forKey: ArbitraryCodingKey("version"))
        }
        if let contentID {
            try container.encode(contentID, forKey: ArbitraryCodingKey("contentID"))
        } else {
            try container.encodeNil(forKey: ArbitraryCodingKey("contentID"))
        }
    }
}
