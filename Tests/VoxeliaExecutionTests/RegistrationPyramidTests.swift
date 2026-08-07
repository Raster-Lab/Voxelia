// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("RegistrationPyramid")
struct RegistrationPyramidTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
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

    /// A constant rank-three calibrated volume: the Gaussian of a
    /// constant is the constant (the weights are normalised) and every
    /// selected sample is the constant, so the pyramid witness can
    /// assert values exactly without re-deriving either algorithm.
    private func constantVolume() throws -> ImageData {
        let extents = [4, 4, 4]
        let bytes = [UInt8](repeating: 7, count: 64)
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
                axes: [
                    try axis("x", semantic: .spatialX),
                    try axis("y", semantic: .spatialY),
                    try axis("z", semantic: .spatialZ),
                ],
                spatialGeometry: .affine(
                    try AffineGridGeometry(
                        spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
                        indexToWorld: try Matrix4x4Double(elements: [
                            0.5, 0, 0, 0,
                            0, 0.5, 0, 0,
                            0, 0, 2.0, 0,
                            0, 0, 0, 1,
                        ]),
                        coordinateSpace: try space()
                    )
                ),
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
                id: try #require(ProvenanceID(rawValue: "record-pyr-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "pyr-in"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "pyr-in")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.29",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func identity(_ index: Int) throws -> RegistrationPyramidLevelIdentity {
        RegistrationPyramidLevelIdentity(
            smoothedObjectID: try #require(DataObjectID(rawValue: "pyr-smooth-\(index)")),
            smoothedProvenanceID: try #require(
                ProvenanceID(rawValue: "record-pyr-smooth-\(index)")
            ),
            downsampledObjectID: try #require(DataObjectID(rawValue: "pyr-down-\(index)")),
            downsampledProvenanceID: try #require(
                ProvenanceID(rawValue: "record-pyr-down-\(index)")
            )
        )
    }

    @Test("[Integration][VOX-REG-006] the schedule drives both frozen operations")
    func theScheduleDrivesBothFrozenOperations() async throws {
        let input = try constantVolume()
        let levels = try await RegistrationPyramid.build(
            image: input,
            schedule: [
                try RegistrationScheduleLevel(shrinkFactor: 2, smoothingSigma: 1),
                try RegistrationScheduleLevel(shrinkFactor: 1, smoothingSigma: 0),
            ],
            identities: [try identity(0), try identity(1)],
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 4_096)
        )
        #expect(levels.count == 2)

        // The coarse level smoothed then halved: ceil(4/2) extents, the
        // ALG-0056 index-step geometry scaling, and the constant value
        // preserved by both frozen operations.
        let coarse = levels[0]
        #expect(coarse.descriptor.shape.extents == [2, 2, 2])
        guard case .affine(let scaled)? = coarse.descriptor.spatialGeometry else {
            Issue.record("the coarse level lost its calibration")
            return
        }
        #expect(scaled.indexToWorld.elements[0] == 1.0)
        #expect(scaled.indexToWorld.elements[5] == 1.0)
        #expect(scaled.indexToWorld.elements[10] == 4.0)
        #expect(coarse.identity.objectID.rawValue == "pyr-down-0")
        let coarseBytes = try coarse.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0, 0], upperBounds: [2, 2, 2])
        ).bytes
        #expect(coarseBytes == [UInt8](repeating: 7, count: 8))

        // The unit level skipped both passes: the input itself, its
        // identity intact — no fabricated derivation.
        let fine = levels[1]
        #expect(fine.identity.objectID.rawValue == "pyr-in")
        #expect(fine.descriptor.shape.extents == [4, 4, 4])
    }

    @Test("[Unit][VOX-REG-006] an identity count mismatch refuses typed")
    func anIdentityCountMismatchRefusesTyped() async throws {
        await #expect(throws: RegistrationPyramidError.identityCountMismatch) {
            _ = try await RegistrationPyramid.build(
                image: try constantVolume(),
                schedule: [
                    try RegistrationScheduleLevel(shrinkFactor: 2, smoothingSigma: 0)
                ],
                identities: [],
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
                software: try software(),
                coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
            )
        }
    }
}
