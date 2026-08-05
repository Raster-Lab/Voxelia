// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaImaging

@Suite("MPRSliceCoordinator")
struct MPRSliceCoordinatorTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func axis(_ id: String, semantic: AxisSemantic) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: semantic,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func volume(
        extents: [Int],
        name: String,
        depthSampling: AxisSampling = .indexOnly,
        geometry: SpatialGeometry? = nil
    ) throws -> ImageData {
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        let names = ["x", "y", "z"]
        let count = extents.reduce(1, *)
        let bytes = (0..<count).map { UInt8($0) }
        var axes = ContiguousArray<AxisDescriptor>()
        for index in 0..<extents.count {
            let sampling = index == 2 ? depthSampling : AxisSampling.indexOnly
            axes.append(
                try AxisDescriptor(
                    id: try #require(AxisID(rawValue: names[index])),
                    name: names[index],
                    semantic: semantics[index],
                    unit: nil,
                    sampling: sampling
                )
            )
        }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: ContiguousArray(extents)),
                scalarFormat: try ScalarFormat(
                    type: .uint8,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 1,
                    interpretation: .scalar,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: .intensity,
                axes: axes,
                spatialGeometry: geometry,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: try ImageShape(extents: ContiguousArray(extents)),
                        scalarType: .uint8,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-\(name)")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T07:40:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: name))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: name)),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.\(name)",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
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
                maximumRetainedResultByteCount: 64
            ),
            resultCache: nil
        )
    }

    private func extract(
        _ plane: MPRPlane,
        sliceIndex: Int,
        volumeID: String,
        prefix: String,
        publisher: PublicationCoordinator
    ) async throws -> ImageData {
        try await MPRSliceCoordinator.extractSlice(
            volumeID: try #require(DataObjectID(rawValue: volumeID)),
            plane: plane,
            sliceIndex: sliceIndex,
            naming: { stage in
                let suffix = stage == .extracted ? "slab" : "slice"
                return (
                    outputObjectID: DataObjectID(rawValue: "\(prefix)-\(suffix)")!,
                    provenanceID: ProvenanceID(rawValue: "record-\(prefix)-\(suffix)")!,
                    createdAt: try CanonicalInstant(
                        utcString: "2026-08-05T07:45:00Z"
                    )
                )
            },
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 64
            ),
            software: try software()
        )
    }

    @Test("[Unit][VOX-MPR-001][VOX-MPR-004] all three planes reconstruct exactly")
    func allThreePlanesReconstructExactly() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(
            try volume(extents: [2, 3, 2], name: "volume-1"),
            mode: .complete
        )

        // Independently computed plane fixtures over samples 0...11
        // with axis zero fastest, each slice published with its slab.
        let axial = try await extract(
            .axial,
            sliceIndex: 1,
            volumeID: "volume-1",
            prefix: "ax",
            publisher: publisher
        )
        #expect(axial.descriptor.shape.extents == [2, 3])
        #expect(
            try axial.storage.read(
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [2, 3])
            ).bytes == [6, 7, 8, 9, 10, 11]
        )
        #expect(axial.descriptor.axes.map(\.id.rawValue) == ["x", "y"])

        let coronal = try await extract(
            .coronal,
            sliceIndex: 1,
            volumeID: "volume-1",
            prefix: "co",
            publisher: publisher
        )
        #expect(coronal.descriptor.shape.extents == [2, 2])
        #expect(
            try coronal.storage.read(
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [2, 2])
            ).bytes == [2, 3, 8, 9]
        )
        #expect(coronal.descriptor.axes.map(\.id.rawValue) == ["x", "z"])

        let sagittal = try await extract(
            .sagittal,
            sliceIndex: 1,
            volumeID: "volume-1",
            prefix: "sa",
            publisher: publisher
        )
        #expect(sagittal.descriptor.shape.extents == [3, 2])
        #expect(
            try sagittal.storage.read(
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [3, 2])
            ).bytes == [1, 3, 5, 7, 9, 11]
        )
        #expect(sagittal.descriptor.axes.map(\.id.rawValue) == ["y", "z"])

        // Both stages published per slice, and the slice's parent edge
        // binds to its slab record.
        #expect(await publisher.publishedObjectCount == 7)
        let sliceRecordID = try #require(ProvenanceID(rawValue: "record-ax-slice"))
        let sliceRecord = try #require(
            await publisher.publishedProvenanceRecord(for: sliceRecordID)
        )
        let slabRecordID = try #require(ProvenanceID(rawValue: "record-ax-slab"))
        #expect(sliceRecord.inputs[0].parent == .graphNode(slabRecordID))

        requireSendable(MPRPlane.self)
        requireSendable(MPRPublicationStage.self)
        requireSendable(MPRError.self)
    }

    @Test("[Unit][VOX-MPR-005][VOX-ERR-001] crosshair components map to slice indices")
    func crosshairComponentsMapToSliceIndices() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(
            try volume(
                extents: [2, 3, 2],
                name: "volume-1",
                depthSampling: .regular(origin: 10, spacing: 2.5)
            ),
            mode: .complete
        )
        let volumeID = try #require(DataObjectID(rawValue: "volume-1"))

        // The ADR-0130 frozen rule: exact indices including the
        // ties-to-even case at the half-slice boundary.
        let exact = try await MPRSliceCoordinator.sliceIndex(
            forAxisValue: 12.5,
            plane: .axial,
            volumeID: volumeID,
            publisher: publisher
        )
        #expect(exact == 1)
        let tied = try await MPRSliceCoordinator.sliceIndex(
            forAxisValue: 11.25,
            plane: .axial,
            volumeID: volumeID,
            publisher: publisher
        )
        #expect(tied == 0)

        // Out-of-volume components and non-regular fixed axes reject
        // typed — never a clamp.
        do {
            _ = try await MPRSliceCoordinator.sliceIndex(
                forAxisValue: 16,
                plane: .axial,
                volumeID: volumeID,
                publisher: publisher
            )
            #expect(Bool(false), "Expected an out-of-volume component to be rejected.")
        } catch MPRError.crosshairOutsideVolume {}
        do {
            _ = try await MPRSliceCoordinator.sliceIndex(
                forAxisValue: 12.5,
                plane: .sagittal,
                volumeID: volumeID,
                publisher: publisher
            )
            #expect(Bool(false), "Expected a non-regular fixed axis to be rejected.")
        } catch MPRError.unsupportedAxisSampling {}
    }

    private func obliqueGeometry() throws -> SpatialGeometry {
        // The exact ALG-0016 rotation-scale fixture with translation
        // (10, 20, 30): world x = 10 - 2·i1, y = 20 + 2·i0,
        // z = 30 + i2.
        var elements = [Double](repeating: 0, count: 16)
        elements[1] = -2
        elements[3] = 10
        elements[4] = 2
        elements[7] = 20
        elements[10] = 1
        elements[11] = 30
        elements[15] = 1
        return .affine(
            try AffineGridGeometry(
                spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
                indexToWorld: try Matrix4x4Double(elements: elements),
                coordinateSpace: try CoordinateSpaceDescriptor(
                    id: try #require(CoordinateSpaceID(rawValue: "patient")),
                    convention: .dicomPatientLPS,
                    handedness: .unspecified,
                    unit: try MeasurementUnit(
                        namespace: "UCUM",
                        code: "mm",
                        dimension: .length
                    ),
                    externalReferences: []
                )
            )
        )
    }

    @Test("[Unit][VOX-MPR-005][VOX-SPA-004] world crosshair points map through oblique geometry")
    func worldCrosshairPointsMapThroughObliqueGeometry() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(
            try volume(
                extents: [2, 3, 2],
                name: "volume-1",
                geometry: try obliqueGeometry()
            ),
            mode: .complete
        )
        _ = try await publisher.publish(
            try volume(extents: [2, 3, 2], name: "volume-2"),
            mode: .complete
        )
        let volumeID = try #require(DataObjectID(rawValue: "volume-1"))
        let patient = try #require(CoordinateSpaceID(rawValue: "patient"))

        // The world image of index (1, 2, 1) selects every plane's
        // slice through the frozen ADR-0138 composition.
        let point = try Point3D(x: 6, y: 22, z: 31, coordinateSpace: patient)
        let axial = try await MPRSliceCoordinator.sliceIndex(
            forWorldPoint: point,
            plane: .axial,
            volumeID: volumeID,
            publisher: publisher
        )
        #expect(axial == 1)
        let coronal = try await MPRSliceCoordinator.sliceIndex(
            forWorldPoint: point,
            plane: .coronal,
            volumeID: volumeID,
            publisher: publisher
        )
        #expect(coronal == 2)
        let sagittal = try await MPRSliceCoordinator.sliceIndex(
            forWorldPoint: point,
            plane: .sagittal,
            volumeID: volumeID,
            publisher: publisher
        )
        #expect(sagittal == 1)

        // A fixed-axis component that left the volume and a volume
        // claiming no world mapping both reject typed.
        do {
            _ = try await MPRSliceCoordinator.sliceIndex(
                forWorldPoint: try Point3D(
                    x: 6,
                    y: 22,
                    z: 32.6,
                    coordinateSpace: patient
                ),
                plane: .axial,
                volumeID: volumeID,
                publisher: publisher
            )
            #expect(Bool(false), "Expected an out-of-volume point to be rejected.")
        } catch MPRError.crosshairOutsideVolume {}
        do {
            _ = try await MPRSliceCoordinator.sliceIndex(
                forWorldPoint: point,
                plane: .axial,
                volumeID: try #require(DataObjectID(rawValue: "volume-2")),
                publisher: publisher
            )
            #expect(Bool(false), "Expected an uncalibrated volume to be rejected.")
        } catch MPRError.volumeNotSpatiallyCalibrated {}
    }

    @Test("[Unit][VOX-ERR-001] slice admission rejects typed")
    func sliceAdmissionRejectsTyped() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(
            try volume(extents: [2, 3, 2], name: "volume-1"),
            mode: .complete
        )
        _ = try await publisher.publish(
            try volume(extents: [2, 3], name: "plane-1"),
            mode: .complete
        )

        // An unpublished volume, a rank-two volume and an out-of-range
        // index reject typed.
        do {
            _ = try await extract(
                .axial,
                sliceIndex: 0,
                volumeID: "volume-9",
                prefix: "r1",
                publisher: publisher
            )
            #expect(Bool(false), "Expected an unpublished volume to be rejected.")
        } catch MPRError.volumeNotPublished {}
        do {
            _ = try await extract(
                .axial,
                sliceIndex: 0,
                volumeID: "plane-1",
                prefix: "r2",
                publisher: publisher
            )
            #expect(Bool(false), "Expected a rank-two volume to be rejected.")
        } catch MPRError.unsupportedVolumeShape {}
        for index in [-1, 2] {
            do {
                _ = try await extract(
                    .axial,
                    sliceIndex: index,
                    volumeID: "volume-1",
                    prefix: "r3",
                    publisher: publisher
                )
                #expect(Bool(false), "Expected an out-of-range index to be rejected.")
            } catch MPRError.invalidSliceIndex {}
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
