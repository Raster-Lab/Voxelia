// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaImaging

/// Verifies the identity, provenance and image aggregate for an ingested volume.
///
/// The load-bearing test is ``assemblesImageData``: constructing an `ImageData`
/// exercises every accepted cross-field invariant at once — descriptor against
/// storage snapshot, representation byte order against the descriptor's,
/// provenance subject against the identity, and an origin's source claim — so a
/// value that exists has passed all of them.
@Suite("CTVolumePublicationBuilder")
struct CTVolumePublicationBuilderTests {
    private func space() throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: "patient"))
    }

    private func format() throws -> ScalarFormat {
        try ScalarFormat(type: .uint16, validBitCount: nil, byteOrder: .littleEndian)
    }

    private func frame(_ identifier: String) throws -> CTFrameDescription {
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
            rows: 2,
            columns: 3,
            scalarFormat: try format(),
            photometricInterpretation: .monochrome2,
            rowSpacingMillimetres: 0.7,
            columnSpacingMillimetres: 0.8,
            rowDirection: try Vector3D(x: 1, y: 0, z: 0, coordinateSpace: coordinateSpace),
            columnDirection: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: coordinateSpace),
            imagePosition: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: coordinateSpace),
            frameOfReference: nil,
            rescaleSlope: 1.0,
            rescaleIntercept: -8192.0,
            pixelPadding: nil,
            sourceMetadata: try MetadataCollection(entries: [])
        )
    }

    private func series(_ identifiers: [String]) throws -> CTSeries {
        let frames = try identifiers.map { try frame($0) }
        return try #require(CTSeriesAssembler.assemble(frames).first)
    }

    private func objectID() throws -> DataObjectID {
        try #require(DataObjectID(rawValue: "volume.ct.1"))
    }

    private func provenanceID() throws -> ProvenanceID {
        try #require(ProvenanceID(rawValue: "prov.ct.1"))
    }

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 0, minor: 1, patch: 1),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func instant() throws -> CanonicalInstant {
        try CanonicalInstant(utcString: "2026-08-06T12:00:00Z")
    }

    private func geometry() throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: try Matrix4x4Double(elements: [
                0.8, 0, 0, 0,
                0, 0.7, 0, 0,
                0, 0, 2.5, 0,
                0, 0, 0, 1,
            ]),
            coordinateSpace: try CoordinateSpaceDescriptor(
                id: try space(),
                convention: .dicomPatientLPS,
                handedness: .rightHanded,
                unit: try MeasurementUnit(
                    namespace: "ucum",
                    code: "mm",
                    displayName: nil,
                    dimension: .length,
                    scaleToCanonical: nil,
                    offsetToCanonical: nil
                ),
                externalReferences: []
            )
        )
    }

    /// The whole bridge, assembled from a two-frame series.
    private func assembled() throws -> (ImageData, DataIdentity, ProvenanceRecord) {
        let assembledSeries = try series(["instance.1", "instance.2"])
        let anchor = assembledSeries.members[0].frame
        let layout = try CTVolumeLayout(
            rows: anchor.rows,
            columns: anchor.columns,
            sliceCount: assembledSeries.members.count,
            scalarFormat: try format()
        )
        var buffer = CTVolumeByteBuffer(layout: layout)
        for (index, member) in assembledSeries.members.enumerated() {
            try buffer.write(
                frameBytes: ContiguousArray<UInt8>(
                    repeating: UInt8(index + 1),
                    count: buffer.bytesPerSlice
                ),
                at: try CTFramePlacement(
                    frame: member.frame,
                    sliceIndex: index,
                    layout: layout
                )
            )
        }
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: anchor,
            layout: layout,
            geometry: try geometry()
        )
        let storage = try CTVolumeStorageBuilder.storage(
            buffer: buffer,
            descriptor: descriptor
        )
        let identity = try CTVolumePublicationBuilder.identity(
            objectID: try objectID(),
            series: assembledSeries
        )
        let provenance = try CTVolumePublicationBuilder.provenance(
            provenanceID: try provenanceID(),
            identity: identity,
            software: try software(),
            ingestedAt: try instant()
        )
        let image = try CTVolumePublicationBuilder.imageData(
            descriptor: descriptor,
            storage: storage,
            metadata: try MetadataCollection(entries: []),
            provenance: provenance,
            identity: identity
        )
        return (image, identity, provenance)
    }

    // MARK: - The proof

    @Test("[Unit] A complete ingested volume assembles into a valid ImageData")
    func assemblesImageData() throws {
        let (image, identity, provenance) = try assembled()

        // Every accepted cross-field invariant passed for this value to exist.
        #expect(image.identity == identity)
        #expect(image.provenance == provenance)
        #expect(image.descriptor.shape.extents == [3, 2, 2])
        #expect(image.storage.snapshot.binding.shape == image.descriptor.shape)
        #expect(image.provenance.subject == .object(identity.objectID))
    }

    @Test("[Unit] The descriptor declares the platform byte order the storage speaks")
    func byteOrderAgrees() throws {
        // ADR-0240's original declaration was `.littleEndian` while
        // ContiguousImageStorage admits `.native`, and ImageData compares them as
        // enum cases. This test is the regression guard for that correction.
        let (image, _, _) = try assembled()
        #expect(image.descriptor.scalarFormat.byteOrder == .native)
        switch image.storage.snapshot.representation {
        case .decodedStrided(let decoded):
            #expect(decoded.byteOrder == image.descriptor.scalarFormat.byteOrder)
        case .decodedComposite(let composite):
            #expect(composite.byteOrder == image.descriptor.scalarFormat.byteOrder)
        case .opaque:
            Issue.record("an ingested volume must not be opaque")
        }
    }

    // MARK: - Where an origin's sources live

    @Test("[Unit] Every contributing frame becomes a source locator on the identity")
    func sourcesAreOnTheIdentity() throws {
        let assembledSeries = try series(["instance.1", "instance.2", "instance.3"])
        let identity = try CTVolumePublicationBuilder.identity(
            objectID: try objectID(),
            series: assembledSeries
        )

        // VOX-VS1-019's source-frame provenance lives here, because an origin
        // record is required to have empty inputs.
        #expect(identity.sourceIdentities.count == 3)
        #expect(
            identity.sourceIdentities.map(\.identifier).sorted()
                == ["instance.1", "instance.2", "instance.3"]
        )
        #expect(identity.derivation == nil)
    }

    @Test("[Unit] The origin record carries no inputs, by requirement rather than omission")
    func originHasNoInputs() throws {
        let (_, _, provenance) = try assembled()
        #expect(provenance.activity == .origin)
        #expect(provenance.kind == .source)
        #expect(provenance.inputs.isEmpty)
        #expect(provenance.warnings.isEmpty)
    }

    @Test("[Unit] An ingest claims no validation it has not performed")
    func defaultValidationClaimIsUnknown() throws {
        let (_, _, provenance) = try assembled()
        #expect(provenance.validationClaim == .unknown)
    }

    @Test("[Unit] The ingest instant is the caller's, not a clock's")
    func instantIsSupplied() throws {
        let (_, _, provenance) = try assembled()
        #expect(provenance.createdAt == (try instant()))
    }

    // MARK: - Admission

    @Test("[Unit] A duplicated source frame is refused rather than deduplicated")
    func refusesDuplicateSourceLocator() throws {
        // Two frames claiming one SOP Instance UID is a contradiction in the
        // input; collapsing it silently would hide a duplicated frame.
        let frames = [try frame("instance.1"), try frame("instance.1")]
        let assembledSeries = try #require(CTSeriesAssembler.assemble(frames).first)
        #expect(assembledSeries.members.count == 2)
        #expect(throws: CTVolumePublicationError.rejectedByAcceptedAdmission) {
            try CTVolumePublicationBuilder.identity(
                objectID: try objectID(),
                series: assembledSeries
            )
        }
    }

    @Test("[Unit] A series with no members yields no source claim")
    func refusesEmptySeries() throws {
        let empty = CTSeries(
            key: CTSeriesKey(
                seriesIdentity: try SourceIdentity(
                    namespace: "dicom",
                    identifier: "series.A",
                    version: nil,
                    contentID: nil
                ),
                coordinateSpace: try space(),
                frameOfReference: nil
            ),
            referenceNormal: CTReferenceNormal(x: 0, y: 0, z: 1),
            observations: [],
            members: []
        )
        #expect(throws: CTVolumePublicationError.noSourceFrames) {
            try CTVolumePublicationBuilder.identity(
                objectID: try objectID(),
                series: empty
            )
        }
    }

    @Test("[Unit] A provenance record for a different subject is refused by ImageData")
    func refusesSubjectMismatch() throws {
        let assembledSeries = try series(["instance.1", "instance.2"])
        let identity = try CTVolumePublicationBuilder.identity(
            objectID: try objectID(),
            series: assembledSeries
        )
        let otherIdentity = try DataIdentity(
            objectID: try #require(DataObjectID(rawValue: "volume.ct.other")),
            contentID: nil,
            sourceIdentities: CTVolumePublicationBuilder.sourceIdentities(
                for: assembledSeries
            ),
            derivation: nil
        )
        let provenance = try CTVolumePublicationBuilder.provenance(
            provenanceID: try provenanceID(),
            identity: otherIdentity,
            software: try software(),
            ingestedAt: try instant()
        )

        let anchor = assembledSeries.members[0].frame
        let layout = try CTVolumeLayout(
            rows: anchor.rows,
            columns: anchor.columns,
            sliceCount: 2,
            scalarFormat: try format()
        )
        var buffer = CTVolumeByteBuffer(layout: layout)
        for index in 0..<2 {
            try buffer.write(
                frameBytes: ContiguousArray<UInt8>(
                    repeating: 1,
                    count: buffer.bytesPerSlice
                ),
                at: try CTFramePlacement(frame: anchor, sliceIndex: index, layout: layout)
            )
        }
        let descriptor = try CTVolumeDescriptorBuilder.descriptor(
            frame: anchor,
            layout: layout,
            geometry: try geometry()
        )
        let storage = try CTVolumeStorageBuilder.storage(
            buffer: buffer,
            descriptor: descriptor
        )

        #expect(throws: CTVolumePublicationError.rejectedByAcceptedAdmission) {
            try CTVolumePublicationBuilder.imageData(
                descriptor: descriptor,
                storage: storage,
                metadata: try MetadataCollection(entries: []),
                provenance: provenance,
                identity: identity
            )
        }
    }

    @Test("[Unit] The platform byte-order guard is satisfied on a supported platform")
    func platformIsLittleEndian() throws {
        // PLATFORM_SUPPORT scopes Voxelia to Apple Silicon. The guard exists so a
        // big-endian port fails loudly rather than mis-declaring.
        #expect(CTVolumeDescriptorBuilder.isLittleEndianPlatform)
    }
}
