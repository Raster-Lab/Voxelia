// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial

/// An error raised while assembling an ingested volume's identity, provenance or
/// image aggregate.
///
/// Cases deliberately carry no payload, so a refusal never discloses source
/// identifiers or geometry in a diagnostic.
public enum CTVolumePublicationError: Error, Sendable, Equatable {
    /// The series contributed no frames, so there is no source to claim.
    case noSourceFrames
    /// The supplied object or provenance identifier was not admissible.
    case invalidIdentifier
    /// The accepted identity, provenance or image admission refused the value.
    ///
    /// Its own reason is not surfaced: those diagnostics can name source
    /// locators.
    case rejectedByAcceptedAdmission
}

/// Assembles the identity, provenance and `ImageData` for an ingested CT volume,
/// per `ADR-0238` increments (d) and (e).
///
/// ## Where an origin's source provenance lives
///
/// Not in the provenance record's inputs. `ProvenanceRecord` **requires
/// `inputs.isEmpty` for an `.origin` activity**, and `ImageData` separately
/// **requires an origin's identity to carry at least one source identity**. The
/// accepted model is therefore explicit: provenance inputs describe
/// Voxelia-to-Voxelia derivation, while an origin's sources are the source
/// locators on its `DataIdentity`.
///
/// So every contributing frame's `SourceIdentity` goes into
/// `DataIdentity.sourceIdentities`, which is what `VOX-VS1-019` asks for.
public enum CTVolumePublicationBuilder {
    /// The source locators for a series, in the series' own member order.
    ///
    /// A repeated locator is refused by `DataIdentity` rather than deduplicated
    /// here: two frames claiming one SOP Instance UID is a contradiction in the
    /// input, and silently collapsing it would hide a duplicated frame.
    public static func sourceIdentities(
        for series: CTSeries
    ) -> ContiguousArray<SourceIdentity> {
        ContiguousArray(series.members.map(\.frame.sourceIdentity))
    }

    /// Builds the volume's data identity.
    ///
    /// - Parameters:
    ///   - objectID: the identifier this volume is published under.
    ///   - series: the assembled series whose frames become the source locators.
    /// - Throws: ``CTVolumePublicationError``.
    public static func identity(
        objectID: DataObjectID,
        series: CTSeries
    ) throws -> DataIdentity {
        let sources = sourceIdentities(for: series)
        guard !sources.isEmpty else {
            throw CTVolumePublicationError.noSourceFrames
        }
        do {
            return try DataIdentity(
                objectID: objectID,
                contentID: nil,
                sourceIdentities: sources,
                // An origin has no derivation, and `ImageData` enforces it.
                derivation: nil
            )
        } catch {
            throw CTVolumePublicationError.rejectedByAcceptedAdmission
        }
    }

    /// Builds the volume's origin provenance record.
    ///
    /// - Parameters:
    ///   - provenanceID: the record's identifier.
    ///   - identity: the volume's identity, whose object ID becomes the subject.
    ///   - software: the identity of the software performing the ingest.
    ///   - ingestedAt: the ingest instant. **Required**, because there is no clock
    ///     in this project and a self-stamping ingest would make every published
    ///     volume's identity depend on the wall clock.
    ///   - validationClaim: what the caller is willing to claim. Defaults to
    ///     `.unknown`, because an ingest has run no validation and claiming
    ///     otherwise would be the kind of unearned assertion these records exist
    ///     to prevent.
    /// - Throws: ``CTVolumePublicationError``.
    public static func provenance(
        provenanceID: ProvenanceID,
        identity: DataIdentity,
        software: SoftwareIdentity,
        ingestedAt: CanonicalInstant,
        validationClaim: ProvenanceValidationClaim = .unknown
    ) throws -> ProvenanceRecord {
        do {
            return try ProvenanceRecord(
                id: provenanceID,
                // `.origin` requires `.source`, and this volume is the first
                // Voxelia object in its chain.
                kind: .source,
                createdAt: ingestedAt,
                subject: .object(identity.objectID),
                software: software,
                activity: .origin,
                // Empty by requirement, not by omission: see the type's note.
                inputs: [],
                warnings: [],
                validationClaim: validationClaim,
                // An origin is not a zero-input generator; that flag qualifies an
                // `.operation` with no inputs.
                declaresZeroInputGenerator: false
            )
        } catch {
            throw CTVolumePublicationError.rejectedByAcceptedAdmission
        }
    }

    /// Assembles the complete image aggregate for a volume.
    ///
    /// Constructing this is the increment's proof: `ImageData`'s admission checks
    /// the descriptor against the storage snapshot, the representation's byte
    /// order against the descriptor's, the provenance subject against the
    /// identity, and an origin's source claim — so a value that exists has passed
    /// every one of them.
    ///
    /// - Throws: ``CTVolumePublicationError``.
    public static func imageData(
        descriptor: ImageDescriptor,
        storage: AnyImageStorage,
        metadata: MetadataCollection,
        provenance: ProvenanceRecord,
        identity: DataIdentity
    ) throws -> ImageData {
        do {
            return try ImageData(
                descriptor: descriptor,
                storage: storage,
                metadata: metadata,
                provenance: provenance,
                identity: identity
            )
        } catch {
            throw CTVolumePublicationError.rejectedByAcceptedAdmission
        }
    }
}
