// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial

/// One named cancellation site in a CT import, frozen by `ADR-0249`.
///
/// The First Vertical Slice Plan's §22.1 lists nine import stages. The cases
/// here are the ones this session actually performs: it does **not** discover
/// sources — the caller supplies them — and it reaches no viewport, so claiming
/// checkpoints for either would misreport where cancellation is honoured.
///
/// The two per-item cases carry an ordinal so a caller can report progress and a
/// test can cancel at a chosen item rather than by racing.
public enum CTImportCheckpoint: Sendable, Equatable {
    /// Before reading source number `n`'s frame description.
    case metadataRead(UInt64)
    /// After every description is read, before grouping them into series.
    case grouping
    /// After grouping, before assessing the chosen series' geometry.
    case frameValidation
    /// Before copying frame number `n`'s samples into the volume.
    case decode(UInt64)
    /// After the bytes are in place, before building descriptor and storage.
    case assembly
    /// Before minting identity and provenance.
    case identity
    /// The last site, immediately before the aggregate is returned.
    ///
    /// `ADR-0249` decision 7: a caller cannot publish what it never receives, so
    /// checking here is what makes "cancellation prevents publication"
    /// structural rather than a rule the caller must remember.
    case final
}

/// The injected cancellation probe per `ADR-0249` decision 4.
///
/// A probe rather than a direct `Task.isCancelled` read, so a test can cancel
/// deterministically at one checkpoint instead of racing. A production caller
/// passes `{ _ in Task.isCancelled }`, which is how the accepted `VoxeliaCPU`
/// operations already bridge the two.
public typealias CTImportCancellationProbe =
    @Sendable (CTImportCheckpoint) -> Bool

/// An error raised while importing a CT volume.
///
/// Cases deliberately carry no payload, so a refused import never discloses
/// extents, counts or offsets in a diagnostic.
public enum CTImportSessionError: Error, Sendable, Equatable {
    /// The probe reported cancellation at one of the named checkpoints.
    case cancelled
    /// No source yielded an admissible CT frame description.
    case noAdmissibleFrames
    /// The sources yielded frames of more than one series.
    ///
    /// An import assembles one volume, and silently choosing among several
    /// series would publish a volume the caller did not ask for.
    case ambiguousSeries
    /// The chosen series' geometry was refused by the accepted assessment.
    case geometryRejected
    /// A frame's samples were unavailable, so the volume is incomplete.
    case frameSamplesUnavailable
    /// The assembled volume is missing at least one slice.
    ///
    /// Retained even though the decode loop writes every ordered member: it is
    /// the one check standing between a silently short series and a published
    /// volume with zero-filled gaps, and `ADR-0235` decision 7 is why the buffer
    /// can answer the question at all.
    case incompleteVolume
}

/// One imported CT volume and the evidence behind it.
///
/// The assessment travels with the image because a caller that must report a
/// warned verdict cannot recover it from the published object.
public struct CTImportedVolume: Sendable {
    /// The publishable volume.
    public let image: ImageData

    /// The series the volume was assembled from.
    public let series: CTSeries

    /// The geometry assessment that admitted it.
    public let assessment: CTGeometryAssessment

    /// The volume's byte layout.
    public let layout: CTVolumeLayout
}

/// The cancellable CT import session per `ADR-0249` (`VOX-VS1-017`).
///
/// This is the owner of the multi-frame loop that callers previously wrote by
/// hand. It is **source-agnostic**: sources are opaque and two caller-supplied
/// closures turn them into frame descriptions and frame bytes, so the session is
/// testable without the optional DICOM product and without patient data.
///
/// Cancellation is honoured at every ``CTImportCheckpoint`` and always by the
/// same rule — throw ``CTImportSessionError/cancelled`` and return nothing. A
/// cancelled import therefore publishes nothing, because it produces nothing to
/// publish.
///
/// The session mints no clock and no identifiers: `ingestedAt`, `objectID` and
/// `provenanceID` are the caller's, following the `ADR-0117` naming discipline.
public enum CTImportSession {
    /// Imports one CT volume from `sources`, cancellably.
    ///
    /// The coordinate space descriptor is built **here** rather than taken from
    /// the caller, and that is deliberate: `ADR-0230` decision 8 requires any
    /// frame-of-reference the series carries to appear among the descriptor's
    /// external references, and a caller assembling the descriptor itself can
    /// omit it — the `VOX-VS1-001` harness did exactly that and was correctly
    /// refused with `frameOfReferenceNotPreserved`. Building it from the chosen
    /// series makes `VOX-DCM-007` preservation structural.
    ///
    /// - Parameters:
    ///   - sources: the opaque sources to read, in caller order.
    ///   - describe: yields one source's frame description, or `nil` when the
    ///     source is not an admissible CT frame.
    ///   - readFrameBytes: yields one frame's samples, or `nil` when they are
    ///     unavailable.
    ///   - tolerance: the geometry tolerance to assess against.
    ///   - coordinateSpaceID: the patient space's identifier.
    ///   - convention: the space's axis convention.
    ///   - handedness: the space's handedness.
    ///   - unit: the space's length unit.
    ///   - objectID: the volume's caller-minted object identifier.
    ///   - provenanceID: the volume's caller-minted provenance identifier.
    ///   - software: the importing software's identity.
    ///   - ingestedAt: the caller's ingest instant.
    ///   - validationClaim: the provenance validation claim to record.
    ///   - metadata: the metadata to attach.
    ///   - cancellation: the probe consulted at every checkpoint.
    /// - Throws: ``CTImportSessionError``, or the audited typed errors of the
    ///   assembly, validation, layout, transfer and publication contracts.
    public static func importVolume<Source: Sendable>(
        sources: [Source],
        describe: @Sendable (Source) throws -> CTFrameDescription?,
        readFrameBytes: @Sendable (CTFrameDescription) throws -> [UInt8]?,
        tolerance: CTGeometryTolerance,
        coordinateSpaceID: CoordinateSpaceID,
        convention: CoordinateConvention,
        handedness: CoordinateHandedness,
        unit: MeasurementUnit,
        objectID: DataObjectID,
        provenanceID: ProvenanceID,
        software: SoftwareIdentity,
        ingestedAt: CanonicalInstant,
        validationClaim: ProvenanceValidationClaim,
        metadata: MetadataCollection,
        cancellation: CTImportCancellationProbe
    ) throws -> CTImportedVolume {
        // Stage: metadata read. One checkpoint per source, because this is a
        // per-file read over a whole series and a caller cancelling during a
        // long scan should not wait for it to finish.
        var frames: [CTFrameDescription] = []
        for (offset, source) in sources.enumerated() {
            if cancellation(.metadataRead(UInt64(offset))) {
                throw CTImportSessionError.cancelled
            }
            if let frame = try describe(source) {
                frames.append(frame)
            }
        }
        guard !frames.isEmpty else {
            throw CTImportSessionError.noAdmissibleFrames
        }

        // Stage: candidate grouping.
        if cancellation(.grouping) { throw CTImportSessionError.cancelled }
        let assembled = CTSeriesAssembler.assemble(frames)
        guard assembled.count == 1, let series = assembled.first else {
            throw CTImportSessionError.ambiguousSeries
        }

        // Stage: frame validation.
        if cancellation(.frameValidation) {
            throw CTImportSessionError.cancelled
        }
        let assessment = CTGeometryValidator.assess(series, tolerance: tolerance)
        guard assessment.verdict != .rejected else {
            throw CTImportSessionError.geometryRejected
        }

        // ADR-0230 decision 8: the series' frame of reference must reach the
        // descriptor's external references.
        var externalReferences = ContiguousArray<ExternalFrameReference>()
        if let reference = series.key.frameOfReference {
            externalReferences.append(reference)
        }
        let space = try CoordinateSpaceDescriptor(
            id: coordinateSpaceID,
            convention: convention,
            handedness: handedness,
            unit: unit,
            externalReferences: externalReferences
        )
        let construction = try CTAffineVolumeBuilder.build(
            series: series,
            assessment: assessment,
            coordinateSpace: space
        )

        let anchor = series.members[0].frame
        let layout = try CTVolumeLayout(
            rows: anchor.rows,
            columns: anchor.columns,
            sliceCount: series.members.count,
            scalarFormat: anchor.scalarFormat
        )

        // Stage: decode and volume copy. One checkpoint per frame -- this is
        // where the measured time goes (about 3.77 s for a real 899-frame
        // series), so it is the cadence that makes cancellation responsive.
        var buffer = CTVolumeByteBuffer(layout: layout)
        for (sliceIndex, member) in series.members.enumerated() {
            if cancellation(.decode(UInt64(sliceIndex))) {
                throw CTImportSessionError.cancelled
            }
            guard let bytes = try readFrameBytes(member.frame) else {
                throw CTImportSessionError.frameSamplesUnavailable
            }
            try buffer.write(
                frameBytes: bytes,
                at: try CTFramePlacement(
                    frame: member.frame,
                    sliceIndex: sliceIndex,
                    layout: layout
                )
            )
        }
        guard buffer.isComplete else {
            throw CTImportSessionError.incompleteVolume
        }

        // Stage: assembly.
        if cancellation(.assembly) { throw CTImportSessionError.cancelled }
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: anchor,
            layout: layout,
            geometry: construction.geometry
        )
        let storage = try CTVolumeStorageBuilder.storage(
            buffer: buffer,
            descriptor: descriptor
        )

        // Stage: identity.
        if cancellation(.identity) { throw CTImportSessionError.cancelled }
        let identity = try CTVolumePublicationBuilder.identity(
            objectID: objectID,
            series: series
        )
        let provenance = try CTVolumePublicationBuilder.provenance(
            provenanceID: provenanceID,
            identity: identity,
            software: software,
            ingestedAt: ingestedAt,
            validationClaim: validationClaim
        )
        let image = try CTVolumePublicationBuilder.imageData(
            descriptor: descriptor,
            storage: storage,
            metadata: metadata,
            provenance: provenance,
            identity: identity
        )

        // The last checkpoint, before the caller receives anything publishable.
        if cancellation(.final) { throw CTImportSessionError.cancelled }
        return CTImportedVolume(
            image: image,
            series: series,
            assessment: assessment,
            layout: layout
        )
    }
}
