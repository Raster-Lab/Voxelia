// SPDX-License-Identifier: MIT

/// An error raised while decoding a data identity reference.
///
/// The single case deliberately carries no payload; audited typed errors
/// from the nested records are retained instead where they apply.
public enum DataIdentityReferenceError: Error, Sendable, Equatable {
    case invalidRecord
}

/// One closed, non-recursive data identity reference per `ADR-0037`,
/// `ADR-0053` and `ADR-0072`.
///
/// The cases carry deliberately different authority: `object` names a
/// local or explicitly resolved immutable record and is not a persistent
/// cache key; `content` is a content claim until associated assurance
/// verifies that exact tuple; `source` is admissible only under
/// explicit host source policy; and `derivation` identifies a canonical
/// derivation record by its registered content digest without proving
/// determinism or input assurance. The reference never embeds
/// `DataIdentity` or `DerivationIdentity`, so cycles and unbounded
/// decoding are structurally impossible.
public enum DataIdentityReference: Sendable, Hashable, Codable {
    case object(DataObjectID)
    case content(ContentID)
    case source(SourceIdentity)
    case derivation(DerivationRecordID)

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

    /// Decodes the strict one-member tagged record, retaining only
    /// audited payload-free project errors from the nested decoders.
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<ArbitraryCodingKey>
        do {
            container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        } catch {
            throw DataIdentityReferenceError.invalidRecord
        }
        guard container.allKeys.count == 1, let key = container.allKeys.first else {
            throw DataIdentityReferenceError.invalidRecord
        }
        switch key.stringValue {
        case "object":
            do {
                self = .object(try container.decode(DataObjectID.self, forKey: key))
            } catch {
                throw DataIdentityReferenceError.invalidRecord
            }
        case "content":
            do {
                self = .content(try container.decode(ContentID.self, forKey: key))
            } catch let error as ContentIdentityError {
                throw error
            } catch {
                throw DataIdentityReferenceError.invalidRecord
            }
        case "source":
            do {
                self = .source(try container.decode(SourceIdentity.self, forKey: key))
            } catch let error as SourceIdentityError {
                throw error
            } catch let error as ContentIdentityError {
                throw error
            } catch {
                throw DataIdentityReferenceError.invalidRecord
            }
        case "derivation":
            do {
                let nested = try container.nestedContainer(
                    keyedBy: ArbitraryCodingKey.self,
                    forKey: key
                )
                guard
                    nested.allKeys.count == 1,
                    nested.allKeys.first?.stringValue == "recordContentID"
                else {
                    throw DataIdentityReferenceError.invalidRecord
                }
                self = .derivation(
                    try DerivationRecordID(
                        recordContentID: try nested.decode(
                            ContentID.self,
                            forKey: ArbitraryCodingKey("recordContentID")
                        )
                    )
                )
            } catch let error as DataIdentityReferenceError {
                throw error
            } catch let error as ContentIdentityError {
                throw error
            } catch let error as DerivationIdentityError {
                throw error
            } catch {
                throw DataIdentityReferenceError.invalidRecord
            }
        default:
            throw DataIdentityReferenceError.invalidRecord
        }
    }

    /// Encodes exactly one tagged member.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ArbitraryCodingKey.self)
        switch self {
        case .object(let objectID):
            try container.encode(objectID, forKey: ArbitraryCodingKey("object"))
        case .content(let contentID):
            try container.encode(contentID, forKey: ArbitraryCodingKey("content"))
        case .source(let sourceIdentity):
            try container.encode(sourceIdentity, forKey: ArbitraryCodingKey("source"))
        case .derivation(let record):
            var nested = container.nestedContainer(
                keyedBy: ArbitraryCodingKey.self,
                forKey: ArbitraryCodingKey("derivation")
            )
            try nested.encode(
                record.recordContentID,
                forKey: ArbitraryCodingKey("recordContentID")
            )
        }
    }
}
