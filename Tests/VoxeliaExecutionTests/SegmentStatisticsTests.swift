// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("SegmentStatistics")
struct SegmentStatisticsTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func image(
        name: String,
        scalarType: ScalarType,
        semantic: ImageSemantic,
        bytes: [UInt8],
        withGeometry: Bool = false
    ) throws -> ImageData {
        let shape = try ImageShape(extents: [6, 1])
        var spatial: SpatialGeometry? = nil
        if withGeometry {
            spatial = .affine(
                try AffineGridGeometry(
                    spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
                    indexToWorld: try Matrix4x4Double(elements: [
                        0.5, 0, 0, 0,
                        0, 0.25, 0, 0,
                        0, 0, 2, 0,
                        0, 0, 0, 1,
                    ]),
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
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
                scalarFormat: try ScalarFormat(
                    type: scalarType,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 1,
                    interpretation: .scalar,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: semantic,
                axes: [
                    try AxisDescriptor(
                        id: try #require(AxisID(rawValue: "x")),
                        name: "x",
                        semantic: .spatialX,
                        unit: nil,
                        sampling: .indexOnly
                    ),
                    try AxisDescriptor(
                        id: try #require(AxisID(rawValue: "y")),
                        name: "y",
                        semantic: .spatialY,
                        unit: nil,
                        sampling: .indexOnly
                    ),
                ],
                spatialGeometry: spatial,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: shape,
                        scalarType: scalarType,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-\(name)")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
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
                        identifier: "1.2.840.113619.22",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func floatBytes(_ values: [Float32]) -> [UInt8] {
        var out = [UInt8]()
        for value in values {
            let bits = value.bitPattern
            out.append(UInt8(bits & 0xFF))
            out.append(UInt8((bits >> 8) & 0xFF))
            out.append(UInt8((bits >> 16) & 0xFF))
            out.append(UInt8(bits >> 24))
        }
        return out
    }

    @Test("[Operation][VOX-SEG-009] the oracle fixture matches with visible exclusions")
    func oracleFixtureMatchesWithVisibleExclusions() async throws {
        let stored = try image(
            name: "stats-in",
            scalarType: .float32,
            semantic: .intensity,
            bytes: floatBytes([100, 0, 300, .nan, 500, 250]),
            withGeometry: true
        )
        let mask = try image(
            name: "stats-mask",
            scalarType: .uint8,
            semantic: .mask,
            bytes: [1, 1, 1, 1, 1, 0]
        )
        let statistics = try await SegmentStatisticsComputer.compute(
            image: stored,
            mask: mask,
            paddingValue: 0,
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
        #expect(statistics.maskSampleCount == 5)
        #expect(statistics.includedSampleCount == 3)
        #expect(statistics.excludedPaddedCount == 1)
        #expect(statistics.excludedNonFiniteCount == 1)
        #expect(statistics.sum == 900)
        #expect(statistics.mean == 300)
        #expect(statistics.minimum == 100)
        #expect(statistics.maximum == 500)
        #expect(statistics.cellVolume == 0.25)
        #expect(statistics.physicalVolume == 1.25)
    }

    @Test("[Operation][VOX-SEG-009] empty inclusion publishes absent statistics honestly")
    func emptyInclusionPublishesAbsentStatisticsHonestly() async throws {
        let stored = try image(
            name: "stats-in",
            scalarType: .float32,
            semantic: .intensity,
            bytes: floatBytes([0, 0, 0, 0, 0, 0])
        )
        let mask = try image(
            name: "stats-mask",
            scalarType: .uint8,
            semantic: .mask,
            bytes: [1, 1, 0, 0, 0, 0]
        )
        let statistics = try await SegmentStatisticsComputer.compute(
            image: stored,
            mask: mask,
            paddingValue: 0,
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
        // Everything the mask claims was padding: the counts stay
        // honest and every statistic is absent, never zero.
        #expect(statistics.maskSampleCount == 2)
        #expect(statistics.includedSampleCount == 0)
        #expect(statistics.excludedPaddedCount == 2)
        #expect(statistics.mean == nil)
        #expect(statistics.minimum == nil)
        #expect(statistics.sum == nil)
        // No geometry was declared: the volumes are absent too.
        #expect(statistics.cellVolume == nil)
        #expect(statistics.physicalVolume == nil)
    }

    @Test("[Unit][VOX-SEG-009] admissions reject typed")
    func admissionsRejectTyped() async throws {
        let stored = try image(
            name: "stats-in",
            scalarType: .float32,
            semantic: .intensity,
            bytes: floatBytes([1, 2, 3, 4, 5, 6])
        )
        let corrupt = try image(
            name: "stats-mask",
            scalarType: .uint8,
            semantic: .mask,
            bytes: [1, 3, 0, 0, 0, 0]
        )
        await #expect(throws: SegmentStatisticsError.invalidMaskValue) {
            _ = try await SegmentStatisticsComputer.compute(
                image: stored,
                mask: corrupt,
                paddingValue: nil,
                coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
            )
        }
        let mask = try image(
            name: "stats-mask-ok",
            scalarType: .uint8,
            semantic: .mask,
            bytes: [1, 1, 0, 0, 0, 0]
        )
        await #expect(throws: SegmentStatisticsError.invalidPaddingValue) {
            _ = try await SegmentStatisticsComputer.compute(
                image: stored,
                mask: mask,
                paddingValue: .infinity,
                coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
            )
        }
    }
}
