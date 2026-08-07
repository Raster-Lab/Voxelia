// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaImaging

/// Closes the `ADR-0238` bridge arc: an ingested CT volume is published through
/// `PublicationCoordinator` and reconstructed in all three planes through
/// `MPRSliceCoordinator`.
///
/// This is the first time the ingest arc's output meets code written in earlier
/// milestones. Nothing here is new capability — it is the proof that the two
/// halves compose, which is what `VOX-VS1-009` needs.
@Suite("CTVolumeBridgeComposition")
struct CTVolumeBridgeCompositionTests {
    private func space() throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: "patient"))
    }

    private func format() throws -> ScalarFormat {
        try ScalarFormat(type: .uint16, validBitCount: nil, byteOrder: .littleEndian)
    }

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 0, minor: 1, patch: 1),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func frame(_ identifier: String, z: Double) throws -> CTFrameDescription {
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
            frameOfReference: nil,
            rescaleSlope: 1.0,
            rescaleIntercept: -8192.0,
            pixelPadding: nil,
            sourceMetadata: try MetadataCollection(entries: [])
        )
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

    /// Ingests two frames into a published-ready `ImageData`, mirroring the real
    /// pipeline's stages in order.
    private func ingestedVolume(objectName: String) throws -> ImageData {
        let frames = [
            try frame("instance.1", z: 0.0),
            try frame("instance.2", z: 2.5),
        ]
        let series = try #require(CTSeriesAssembler.assemble(frames).first)
        let assessment = CTGeometryValidator.assess(series, tolerance: .exact)
        #expect(assessment.verdict == .representable)

        let descriptorSpace = try CoordinateSpaceDescriptor(
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
        let construction = try CTAffineVolumeBuilder.build(
            series: series,
            assessment: assessment,
            coordinateSpace: descriptorSpace
        )

        let anchor = series.members[0].frame
        let layout = try CTVolumeLayout(
            rows: anchor.rows,
            columns: anchor.columns,
            sliceCount: series.members.count,
            scalarFormat: try format()
        )
        var buffer = CTVolumeByteBuffer(layout: layout)
        // Samples 0...11 with axis zero fastest, so each plane's expected values
        // are computable by hand.
        var sample: UInt16 = 0
        for (index, member) in series.members.enumerated() {
            var sliceBytes = ContiguousArray<UInt8>()
            for _ in 0..<layout.samplesPerSlice {
                sliceBytes.append(UInt8(sample & 0xFF))
                sliceBytes.append(UInt8((sample >> 8) & 0xFF))
                sample += 1
            }
            try buffer.write(
                frameBytes: sliceBytes,
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
            geometry: construction.geometry
        )
        let storage = try CTVolumeStorageBuilder.storage(
            buffer: buffer,
            descriptor: descriptor
        )
        let objectID = try #require(DataObjectID(rawValue: objectName))
        let recordID = try #require(ProvenanceID(rawValue: objectName + ".prov"))
        let identity = try CTVolumePublicationBuilder.identity(
            objectID: objectID,
            series: series
        )
        let provenance = try CTVolumePublicationBuilder.provenance(
            provenanceID: recordID,
            identity: identity,
            software: try software(),
            ingestedAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z")
        )
        return try CTVolumePublicationBuilder.imageData(
            descriptor: descriptor,
            storage: storage,
            metadata: try MetadataCollection(entries: []),
            provenance: provenance,
            identity: identity
        )
    }

    // MARK: - Publication

    @Test("[Integration] An ingested volume publishes through the coordinated pipeline")
    func publishes() async throws {
        let coordinator = try publisher()
        let volume = try ingestedVolume(objectName: "ct.volume.1")

        _ = try await coordinator.publish(volume, mode: .complete)

        let identifier = try #require(DataObjectID(rawValue: "ct.volume.1"))
        let published = try #require(await coordinator.publishedImage(for: identifier))
        #expect(published.descriptor.shape.extents == [2, 3, 2])
        #expect(published.identity.sourceIdentities.count == 2)
        #expect(published.provenance.activity == .origin)
    }

    @Test("[Integration] The published volume keeps its patient-space affine and rescale")
    func publishedVolumeKeepsGeometryAndTransform() async throws {
        let coordinator = try publisher()
        _ = try await coordinator.publish(
            try ingestedVolume(objectName: "ct.volume.2"),
            mode: .complete
        )
        let identifier = try #require(DataObjectID(rawValue: "ct.volume.2"))
        let published = try #require(await coordinator.publishedImage(for: identifier))

        guard case .affine(let affine) = try #require(published.descriptor.spatialGeometry)
        else {
            Issue.record("expected an affine geometry")
            return
        }
        let elements = Array(affine.indexToWorld.elements)
        // Column index steps by columnSpacing 0.8 along rowDirection; row index by
        // rowSpacing 0.7 along columnDirection; slice by the 2.5 mm position step.
        #expect(elements[0] == 0.8)
        #expect(elements[5] == 0.7)
        #expect(elements[10] == 2.5)

        guard case .linear(let linear) = try #require(published.descriptor.valueTransform)
        else {
            Issue.record("expected a linear transform")
            return
        }
        #expect(linear.scale == 1.0)
        #expect(linear.offset == -8192.0)
    }

    // MARK: - Reconstruction in all three planes

    private func extract(
        _ plane: MPRPlane,
        sliceIndex: Int,
        volumeID: DataObjectID,
        publisher: PublicationCoordinator
    ) async throws -> ImageData {
        try await MPRSliceCoordinator.extractSlice(
            volumeID: volumeID,
            plane: plane,
            sliceIndex: sliceIndex,
            naming: { stage in
                // Two published stages: the extracted slab, then the squeezed
                // two-dimensional slice.
                let suffix = stage == .extracted ? "slab" : "slice"
                let prefix = "\(plane)-\(sliceIndex)"
                return (
                    outputObjectID: DataObjectID(rawValue: "\(prefix)-\(suffix)")!,
                    provenanceID: ProvenanceID(rawValue: "record-\(prefix)-\(suffix)")!,
                    createdAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z")
                )
            },
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 4_096
            ),
            software: try software()
        )
    }

    @Test("[Integration] A slab extraction preserves and translates the affine geometry")
    func slabExtractionPreservesGeometry() async throws {
        // Establishes precisely which stage blocks: region extraction handles
        // affine geometry, translating the origin by the region's lower bounds.
        let coordinator = try publisher()
        let volume = try ingestedVolume(objectName: "ct.volume.slab")
        _ = try await coordinator.publish(volume, mode: .complete)

        let slab = try await RegionExtractionOperation.execute(
            input: volume,
            region: try ImageRegion(
                lowerBounds: ContiguousArray([0, 0, 1]),
                upperBounds: ContiguousArray([2, 3, 2])
            ),
            outputObjectID: try #require(DataObjectID(rawValue: "slab.1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "slab.1.prov")),
            createdAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 4_096
            )
        )

        #expect(slab.descriptor.shape.extents == [2, 3, 1])
        guard case .affine(let affine) = try #require(slab.descriptor.spatialGeometry)
        else {
            Issue.record("expected the slab to keep an affine geometry")
            return
        }
        // Slice index 1 at 2.5 mm spacing shifts the origin's z by 2.5.
        let elements = Array(affine.indexToWorld.elements)
        #expect(elements[11] == 2.5)
        #expect(elements[10] == 2.5)
    }

    // MARK: - ADR-0244: the blocker is resolved

    @Test("[Integration] Squeeze now drops a singleton axis and keeps the geometry")
    func squeezeKeepsGeometry() async throws {
        // This test previously pinned the refusal ADR-0243 recorded. ADR-0244
        // decided the axis-drop rule, so it now asserts the new behaviour rather
        // than being deleted -- the coverage it was written to hold is kept.
        let coordinator = try publisher()
        let volume = try ingestedVolume(objectName: "ct.volume.squeeze")
        _ = try await coordinator.publish(volume, mode: .complete)

        let slab = try await RegionExtractionOperation.execute(
            input: volume,
            region: try ImageRegion(
                lowerBounds: ContiguousArray([0, 0, 1]),
                upperBounds: ContiguousArray([2, 3, 2])
            ),
            outputObjectID: try #require(DataObjectID(rawValue: "slab.2")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "slab.2.prov")),
            createdAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 4_096)
        )
        #expect(slab.descriptor.spatialGeometry != nil)

        let slice = try await SqueezeAxesOperation.execute(
            input: slab,
            axes: [2],
            outputObjectID: try #require(DataObjectID(rawValue: "slice.2")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "slice.2.prov")),
            createdAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 4_096)
        )

        #expect(slice.descriptor.shape.extents == [2, 3])
        guard case .affine(let affine) = try #require(slice.descriptor.spatialGeometry)
        else {
            Issue.record("expected the slice to keep an affine geometry")
            return
        }
        // Two surviving image axes, renumbered.
        #expect(affine.spatialAxes.imageAxes == [0, 1])
        let elements = Array(affine.indexToWorld.elements)
        // Columns 0 and 1 are the in-plane steps, unchanged.
        #expect(elements[0] == 0.8)
        #expect(elements[5] == 0.7)
        // The out-of-plane step is preserved rather than zeroed, which is what
        // keeps the matrix non-singular.
        #expect(elements[10] == 2.5)
        // The origin still names the slab's world position.
        #expect(elements[11] == 2.5)
    }

    @Test("[Integration] All three planes reconstruct from a geometry-bearing ingested volume")
    func allThreePlanesReconstruct() async throws {
        // VOX-VS1-009 on a volume that carries patient-space geometry, which is
        // what ADR-0243 could not do and ADR-0244 unblocked.
        let coordinator = try publisher()
        let volumeID = try #require(DataObjectID(rawValue: "ct.volume.3"))
        _ = try await coordinator.publish(
            try ingestedVolume(objectName: "ct.volume.3"),
            mode: .complete
        )

        let axial = try await extract(
            .axial,
            sliceIndex: 0,
            volumeID: volumeID,
            publisher: coordinator
        )
        let coronal = try await extract(
            .coronal,
            sliceIndex: 0,
            volumeID: volumeID,
            publisher: coordinator
        )
        let sagittal = try await extract(
            .sagittal,
            sliceIndex: 0,
            volumeID: volumeID,
            publisher: coordinator
        )

        // The volume is 2 columns x 3 rows x 2 slices, so each plane drops its own
        // fixed axis.
        #expect(axial.descriptor.shape.extents == [2, 3])
        #expect(coronal.descriptor.shape.extents == [2, 2])
        #expect(sagittal.descriptor.shape.extents == [3, 2])

        // Every plane keeps a geometry, including the two whose dropped slot is
        // not last and therefore needed a column permutation.
        for slice in [axial, coronal, sagittal] {
            #expect(slice.descriptor.spatialGeometry != nil)
            #expect(slice.descriptor.valueTransform != nil)
        }
    }

    @Test("[Integration] An extracted slice carries operation provenance over the volume")
    func extractedSliceHasOperationProvenance() async throws {
        let coordinator = try publisher()
        let volumeID = try #require(DataObjectID(rawValue: "ct.volume.4"))
        _ = try await coordinator.publish(
            try ingestedVolume(objectName: "ct.volume.4"),
            mode: .complete
        )
        let axial = try await extract(
            .axial,
            sliceIndex: 1,
            volumeID: volumeID,
            publisher: coordinator
        )

        // The ingest was an origin; a slice is an operation with the volume as its
        // input, which is the derivation chain VOX-VS1-019 asks provenance to show.
        guard case .operation = axial.provenance.activity else {
            Issue.record("expected an operation activity")
            return
        }
        #expect(axial.provenance.kind != .source)
        #expect(!axial.provenance.inputs.isEmpty)
    }

    @Test("[Integration] A geometry-free volume still reconstructs and acquires no geometry")
    func geometryFreeVolumeReconstructs() async throws {
        let coordinator = try publisher()
        let volumeID = try #require(DataObjectID(rawValue: "ct.volume.flat"))
        let geometryBearing = try ingestedVolume(objectName: "ct.volume.flat")
        let flatDescriptor = try ImageDescriptor(
            shape: geometryBearing.descriptor.shape,
            scalarFormat: geometryBearing.descriptor.scalarFormat,
            components: geometryBearing.descriptor.components,
            semantic: geometryBearing.descriptor.semantic,
            axes: geometryBearing.descriptor.axes,
            spatialGeometry: nil,
            valueTransform: geometryBearing.descriptor.valueTransform,
            units: geometryBearing.descriptor.units
        )
        let flat = try ImageData(
            descriptor: flatDescriptor,
            storage: geometryBearing.storage,
            metadata: geometryBearing.metadata,
            provenance: geometryBearing.provenance,
            identity: geometryBearing.identity
        )
        _ = try await coordinator.publish(flat, mode: .complete)

        for plane in [MPRPlane.axial, .coronal, .sagittal] {
            let slice = try await extract(
                plane,
                sliceIndex: 0,
                volumeID: volumeID,
                publisher: coordinator
            )
            #expect(slice.descriptor.shape.rank == 2)
            // ADR-0244 decision 6: nothing is invented for a volume that never
            // had a geometry.
            #expect(slice.descriptor.spatialGeometry == nil)
        }
    }
}
