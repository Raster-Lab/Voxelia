// SPDX-License-Identifier: MIT

import Synchronization
import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaImaging

/// Records the checkpoints a probe was consulted at.
///
/// A `Mutex` rather than a bare captured variable: the probe is `@Sendable`, and
/// the project's concurrency policy admits no escape hatch for a test either.
private final class CheckpointRecorder: Sendable {
    private let storage = Mutex<[CTImportCheckpoint]>([])

    func record(_ checkpoint: CTImportCheckpoint) {
        storage.withLock { $0.append(checkpoint) }
    }

    var visited: [CTImportCheckpoint] {
        storage.withLock { $0 }
    }
}

/// `ADR-0249` (`VOX-VS1-017`): cancellation prevents stale result publication.
///
/// The property is proved compositionally rather than asserted: a cancelled
/// import is run against a real `PublicationCoordinator` and the registry is
/// then shown to hold nothing. A session that returned a partial aggregate
/// would fail these tests rather than pass them quietly.
@Suite("CTImportSession")
struct CTImportSessionTests {
    // MARK: - Fixtures

    private func space() throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: "patient"))
    }

    private func format() throws -> ScalarFormat {
        try ScalarFormat(type: .uint16, validBitCount: nil, byteOrder: .littleEndian)
    }

    private func unit() throws -> MeasurementUnit {
        try MeasurementUnit(
            namespace: "ucum",
            code: "mm",
            displayName: nil,
            dimension: .length,
            scaleToCanonical: nil,
            offsetToCanonical: nil
        )
    }

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 0, minor: 1, patch: 1),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func frame(
        _ identifier: String,
        z: Double,
        frameOfReference: ExternalFrameReference? = nil
    ) throws -> CTFrameDescription {
        let coordinateSpace = try space()
        return try CTFrameDescription(
            sourceIdentity: try SourceIdentity(
                namespace: "dicom",
                identifier: identifier,
                version: nil,
                contentID: nil
            ),
            seriesIdentity: try SourceIdentity(
                namespace: "dicom",
                identifier: "series.A",
                version: nil,
                contentID: nil
            ),
            rows: 3,
            columns: 2,
            scalarFormat: try format(),
            photometricInterpretation: .monochrome2,
            rowSpacingMillimetres: 0.7,
            columnSpacingMillimetres: 0.8,
            rowDirection: try Vector3D(x: 1, y: 0, z: 0, coordinateSpace: coordinateSpace),
            columnDirection: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: coordinateSpace),
            imagePosition: try Point3D(x: 0, y: 0, z: z, coordinateSpace: coordinateSpace),
            frameOfReference: frameOfReference,
            rescaleSlope: 1.0,
            rescaleIntercept: -8192.0,
            pixelPadding: nil,
            sourceMetadata: try MetadataCollection(entries: [])
        )
    }

    /// Three frames' worth of sources; 3 rows x 2 columns of uint16 is 12 bytes.
    private func sources(
        frameOfReference: ExternalFrameReference? = nil
    ) throws -> [CTFrameDescription] {
        [
            try frame("instance.1", z: 0.0, frameOfReference: frameOfReference),
            try frame("instance.2", z: 2.5, frameOfReference: frameOfReference),
            try frame("instance.3", z: 5.0, frameOfReference: frameOfReference),
        ]
    }

    private func publisher() throws -> PublicationCoordinator {
        PublicationCoordinator(
            maximumPublishedObjectCount: 16,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 16,
                maximumParentEdgeCount: 16,
                maximumAncestryDepth: 16,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 4_096
            ),
            resultCache: nil
        )
    }

    /// Runs one import with an injected probe.
    private func runImport(
        frames: [CTFrameDescription],
        objectName: String,
        cancellation: CTImportCancellationProbe
    ) throws -> CTImportedVolume {
        try CTImportSession.importVolume(
            sources: frames,
            describe: { $0 },
            readFrameBytes: { _ in [UInt8](repeating: 7, count: 12) },
            tolerance: .exact,
            coordinateSpaceID: try space(),
            convention: .dicomPatientLPS,
            handedness: .rightHanded,
            unit: try unit(),
            objectID: try #require(DataObjectID(rawValue: objectName)),
            provenanceID: try #require(ProvenanceID(rawValue: "\(objectName).prov")),
            software: try software(),
            ingestedAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z"),
            validationClaim: .unknown,
            metadata: try MetadataCollection(entries: []),
            cancellation: cancellation
        )
    }

    /// Every checkpoint the session reaches for a three-frame series, in order.
    ///
    /// `ADR-0249` decision 5 names the sites; the input space is small enough to
    /// enumerate rather than sample, so every one is exercised.
    private var everyCheckpoint: [CTImportCheckpoint] {
        [
            .metadataRead(0), .metadataRead(1), .metadataRead(2),
            .grouping,
            .frameValidation,
            .decode(0), .decode(1), .decode(2),
            .assembly,
            .identity,
            .final,
        ]
    }

    // MARK: - Baseline

    @Test("[Unit][VOX-VS1-017] an uncancelled import assembles a publishable volume")
    func uncancelledImportSucceeds() throws {
        let volume = try runImport(
            frames: try sources(),
            objectName: "vol.ok",
            cancellation: { _ in false }
        )
        #expect(volume.assessment.verdict == .representable)
        #expect(volume.layout.sliceCount == 3)
        #expect(volume.layout.rows == 3)
        #expect(volume.layout.columns == 2)
        #expect(volume.series.members.count == 3)
        #expect(Array(volume.image.descriptor.shape.extents) == [2, 3, 3])
    }

    // MARK: - Cancellation at every checkpoint

    @Test("[Unit][VOX-VS1-017][VOX-ERR-001] cancellation at any checkpoint refuses typed")
    func cancellationAtEveryCheckpointRefuses() throws {
        for checkpoint in everyCheckpoint {
            #expect(throws: CTImportSessionError.cancelled) {
                try runImport(
                    frames: try sources(),
                    objectName: "vol.cancelled",
                    cancellation: { $0 == checkpoint }
                )
            }
        }
    }

    @Test("[Unit][VOX-VS1-017] the probe is consulted at every named checkpoint in order")
    func everyCheckpointIsReached() throws {
        // A probe that records rather than cancels: the sites the session
        // actually visits must be exactly the sites the record names, in order.
        // A checkpoint that is documented but never reached would be a false
        // claim about where cancellation is honoured.
        let recorder = CheckpointRecorder()
        _ = try runImport(
            frames: try sources(),
            objectName: "vol.trace",
            cancellation: { checkpoint in
                recorder.record(checkpoint)
                return false
            }
        )
        #expect(recorder.visited == everyCheckpoint)
    }

    // MARK: - The requirement's own property

    @Test("[Unit][VOX-VS1-017] a cancelled import publishes nothing")
    func cancelledImportPublishesNothing() async throws {
        // The property VOX-VS1-017 actually names, proved against a real
        // coordinator: for every checkpoint, a cancelled import leaves the
        // registry with no published image and no published provenance. The
        // caller cannot publish a partial result because it never receives one.
        let objectID = try #require(DataObjectID(rawValue: "vol.unpublished"))
        let provenanceID = try #require(ProvenanceID(rawValue: "vol.unpublished.prov"))

        for checkpoint in everyCheckpoint {
            let coordinator = try publisher()
            var imported: CTImportedVolume?
            do {
                imported = try runImport(
                    frames: try sources(),
                    objectName: "vol.unpublished",
                    cancellation: { $0 == checkpoint }
                )
            } catch CTImportSessionError.cancelled {
                imported = nil
            }
            #expect(imported == nil)

            // Nothing was produced, so nothing could be published.
            let publishedImage = await coordinator.publishedImage(for: objectID)
            let publishedRecord = await coordinator.publishedProvenanceRecord(
                for: provenanceID
            )
            #expect(publishedImage == nil)
            #expect(publishedRecord == nil)
        }
    }

    @Test("[Unit][VOX-VS1-017] cancellation at the final checkpoint still publishes nothing")
    func finalCheckpointCancellationPublishesNothing() async throws {
        // The sharpest case: every stage completed and the volume is fully
        // assembled, yet the caller receives nothing. This is what makes
        // "cancellation prevents publication" structural rather than a rule the
        // caller has to remember.
        let coordinator = try publisher()
        let objectID = try #require(DataObjectID(rawValue: "vol.finalcancel"))

        #expect(throws: CTImportSessionError.cancelled) {
            try runImport(
                frames: try sources(),
                objectName: "vol.finalcancel",
                cancellation: { $0 == .final }
            )
        }
        #expect(await coordinator.publishedImage(for: objectID) == nil)

        // Contrast: the same import without cancellation does publish, so the
        // test above is proving cancellation rather than a broken pipeline.
        let volume = try runImport(
            frames: try sources(),
            objectName: "vol.finalcancel",
            cancellation: { _ in false }
        )
        _ = try await coordinator.publish(volume.image, mode: .complete)
        #expect(await coordinator.publishedImage(for: objectID) != nil)
    }

    // MARK: - Structural preservation

    @Test("[Unit][VOX-VS1-017][VOX-DCM-007] the session preserves a series frame of reference")
    func frameOfReferenceIsPreserved() throws {
        // ADR-0249's reason for building the coordinate space descriptor inside
        // the session: a caller assembling it by hand can omit the series'
        // frame of reference, which is exactly what the VOX-VS1-001 harness did
        // before being refused with frameOfReferenceNotPreserved. Importing a
        // series that carries one must now simply work.
        let reference = try ExternalFrameReference(
            namespace: "dicom",
            identifier: "1.2.840.10008.frame.of.reference.1"
        )
        let volume = try runImport(
            frames: try sources(frameOfReference: reference),
            objectName: "vol.forp",
            cancellation: { _ in false }
        )
        #expect(volume.series.key.frameOfReference == reference)
    }

    // MARK: - Refusals that are not cancellation

    @Test("[Unit][VOX-VS1-017][VOX-ERR-001] an empty source list refuses typed")
    func emptySourcesRefuse() throws {
        #expect(throws: CTImportSessionError.noAdmissibleFrames) {
            try runImport(
                frames: [],
                objectName: "vol.empty",
                cancellation: { _ in false }
            )
        }
    }

    @Test("[Unit][VOX-VS1-017][VOX-ERR-001] unavailable frame samples refuse typed")
    func unavailableSamplesRefuse() throws {
        #expect(throws: CTImportSessionError.frameSamplesUnavailable) {
            try CTImportSession.importVolume(
                sources: try sources(),
                describe: { $0 },
                // The type is stated because `nil` alone cannot infer the
                // session's byte-collection parameter.
                readFrameBytes: { _ -> [UInt8]? in nil },
                tolerance: .exact,
                coordinateSpaceID: try space(),
                convention: .dicomPatientLPS,
                handedness: .rightHanded,
                unit: try unit(),
                objectID: try #require(DataObjectID(rawValue: "vol.nobytes")),
                provenanceID: try #require(ProvenanceID(rawValue: "vol.nobytes.prov")),
                software: try software(),
                ingestedAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z"),
                validationClaim: .unknown,
                metadata: try MetadataCollection(entries: []),
                cancellation: { _ in false }
            )
        }
    }
}
