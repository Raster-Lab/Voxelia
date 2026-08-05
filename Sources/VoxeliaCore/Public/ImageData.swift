// SPDX-License-Identifier: MIT

/// An error raised while validating an image data aggregate.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// shapes, identifiers, subjects or metadata content.
public enum ImageDataError: Error, Sendable, Equatable {
    case shapeMismatch
    case scalarTypeMismatch
    case componentCountMismatch
    case unsupportedRepresentation
    case byteOrderMismatch
    case provenanceSubjectMismatch
    case originDerivationConflict
    case missingOriginSource
    case duplicateMetadataKey
}

/// The immutable image data aggregate per CDMS section 37 and
/// `ADR-0063`.
///
/// The aggregate binds the descriptor, the storage-erased provider, the
/// unique-keyed metadata record, the subject-bound provenance record
/// and the claim-bearing data identity as one validated value.
/// Construction proves structural coherence only: no verification,
/// trust or cache authority is granted, and the storage may lazily load
/// immutable content but must never change the logical data associated
/// with the identity. The aggregate deliberately conforms to `Sendable`
/// only — storage is a reference-holding erasure, so comparison
/// composes explicitly from the exposed exact claims rather than
/// through a blanket conformance. Persistence composes the accepted
/// canonical projections; the atomic staging and publication
/// coordinator remains an Execution/host decision per `ADR-0038`.
public struct ImageData: Sendable {
    public let descriptor: ImageDescriptor
    public let storage: AnyImageStorage
    public let metadata: MetadataCollection
    public let provenance: ProvenanceRecord
    public let identity: DataIdentity

    /// Creates a validated aggregate.
    ///
    /// - Throws: ``ImageDataError`` for a descriptor-storage mismatch,
    ///   an opaque representation, a mismatched provenance subject, an
    ///   incoherent origin or a repeated metadata key.
    public init(
        descriptor: ImageDescriptor,
        storage: AnyImageStorage,
        metadata: MetadataCollection,
        provenance: ProvenanceRecord,
        identity: DataIdentity
    ) throws {
        let binding = storage.snapshot.binding
        guard descriptor.shape == binding.shape else {
            throw ImageDataError.shapeMismatch
        }
        guard descriptor.scalarFormat.type == binding.scalarType else {
            throw ImageDataError.scalarTypeMismatch
        }
        guard descriptor.components.count == binding.componentCount else {
            throw ImageDataError.componentCountMismatch
        }
        // ADR-0156: an image is decoded samples — the strided and
        // composite representations both qualify, with the byte-order
        // coherence read from each descriptor's own declaration;
        // opaque means not directly readable and stays outside.
        let representationByteOrder: ByteOrder
        switch storage.snapshot.representation {
        case .decodedStrided(let decoded):
            representationByteOrder = decoded.byteOrder
        case .decodedComposite(let composite):
            representationByteOrder = composite.byteOrder
        case .opaque:
            throw ImageDataError.unsupportedRepresentation
        }
        guard representationByteOrder == descriptor.scalarFormat.byteOrder else {
            throw ImageDataError.byteOrderMismatch
        }

        guard provenance.subject == .object(identity.objectID) else {
            throw ImageDataError.provenanceSubjectMismatch
        }
        if case .origin = provenance.activity {
            guard identity.derivation == nil else {
                throw ImageDataError.originDerivationConflict
            }
            guard !identity.sourceIdentities.isEmpty else {
                throw ImageDataError.missingOriginSource
            }
        }

        var keys = Set<AnyMetadataKey>()
        keys.reserveCapacity(metadata.entries.count)
        for entry in metadata.entries {
            guard keys.insert(entry.key).inserted else {
                throw ImageDataError.duplicateMetadataKey
            }
        }

        self.descriptor = descriptor
        self.storage = storage
        self.metadata = metadata
        self.provenance = provenance
        self.identity = identity
    }
}
