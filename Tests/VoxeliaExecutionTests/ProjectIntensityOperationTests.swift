// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("ProjectIntensityOperation")
struct ProjectIntensityOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func volume(
        extents: [Int],
        bytes: [UInt8],
        geometry: SpatialGeometry? = nil
    ) throws -> ImageData {
        var axes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        let names = ["x", "y", "z"]
        for index in 0..<extents.count {
            axes.append(
                try AxisDescriptor(
                    id: try #require(AxisID(rawValue: names[index])),
                    name: names[index],
                    semantic: semantics[index],
                    unit: nil,
                    sampling: .indexOnly
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
                id: try #require(ProvenanceID(rawValue: "record-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T10:50:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "volume-7"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "volume-7")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.10",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func project(
        _ input: ImageData,
        mode: ProjectionMode,
        axis: Int,
        paddingValue: Int64? = nil
    ) async throws -> [UInt8] {
        let output = try await ProjectIntensityOperation.execute(
            input: input,
            mode: mode,
            axis: axis,
            paddingValue: paddingValue,
            outputObjectID: try #require(DataObjectID(rawValue: "plane-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T10:51:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
        let extents = output.descriptor.shape.extents
        #expect(extents.count == 2)
        return try output.storage.read(
            region: try ImageRegion(
                lowerBounds: [0, 0],
                upperBounds: extents
            )
        ).bytes
    }

    /// The specification volume: rays along axis two are
    /// (10, 30, 20), (1, 2, 2), (0, 1, 0), (3, 4, 0).
    private let primaryBytes: [UInt8] = [10, 1, 0, 3, 30, 2, 1, 4, 20, 2, 0, 0]

    @Test("[Unit][VOX-MPR-007][VOX-MPR-008][VOX-MPR-009] all modes project all axes exactly")
    func allModesProjectAllAxesExactly() async throws {
        // The ALG-0020 primary fixture along axis two, plus the
        // independently computed axis-zero and axis-one projections —
        // every value exact, repetition bit-identical.
        let input = try volume(extents: [2, 2, 3], bytes: primaryBytes)
        #expect(try await project(input, mode: .maximum, axis: 2) == [30, 2, 1, 4])
        #expect(try await project(input, mode: .minimum, axis: 2) == [10, 1, 0, 0])
        #expect(try await project(input, mode: .average, axis: 2) == [20, 2, 0, 2])
        #expect(
            try await project(input, mode: .maximum, axis: 0)
                == [10, 3, 30, 4, 20, 0]
        )
        #expect(
            try await project(input, mode: .minimum, axis: 0)
                == [1, 0, 2, 1, 2, 0]
        )
        #expect(
            try await project(input, mode: .average, axis: 0)
                == [6, 2, 16, 2, 11, 0]
        )
        #expect(
            try await project(input, mode: .maximum, axis: 1)
                == [10, 3, 30, 4, 20, 2]
        )
        #expect(
            try await project(input, mode: .minimum, axis: 1)
                == [0, 1, 1, 2, 0, 0]
        )
        #expect(
            try await project(input, mode: .average, axis: 1)
                == [5, 2, 16, 3, 10, 1]
        )
        let repeated = try await project(input, mode: .average, axis: 2)
        #expect(repeated == [20, 2, 0, 2])
    }

    @Test("[Unit][VOX-MPR-009] the half-even boundary rounds in every direction")
    func halfEvenBoundaryRoundsInEveryDirection() async throws {
        // Depth-two rays (1,2), (2,3), (0,1), (255,254): the average
        // half-even boundary rounding up to even, down to even, to
        // zero and at the top of the domain.
        let input = try volume(
            extents: [2, 2, 2],
            bytes: [1, 2, 0, 255, 2, 3, 1, 254]
        )
        #expect(try await project(input, mode: .average, axis: 2) == [2, 2, 0, 254])
    }

    @Test("[Unit][VOX-MPR-010] the sentinel excludes and all-excluded rays are zero")
    func sentinelExcludesAndAllExcludedRaysAreZero() async throws {
        // Sentinel 7 over rays (7,5,7), (7,7,7), (6,7,9): partial
        // exclusion reduces to the ray's remaining samples, the
        // all-excluded ray outputs exactly zero for every mode, and
        // the mixed ray averages fifteen halves to eight.
        let input = try volume(
            extents: [3, 1, 3],
            bytes: [7, 7, 6, 5, 7, 7, 7, 7, 9]
        )
        #expect(
            try await project(input, mode: .maximum, axis: 2, paddingValue: 7)
                == [5, 0, 9]
        )
        #expect(
            try await project(input, mode: .minimum, axis: 2, paddingValue: 7)
                == [5, 0, 6]
        )
        #expect(
            try await project(input, mode: .average, axis: 2, paddingValue: 7)
                == [5, 0, 8]
        )
    }

    @Test("[Unit][VOX-MPR-006] a depth-one projection is the identity")
    func depthOneProjectionIsTheIdentity() async throws {
        let input = try volume(extents: [2, 2, 1], bytes: [10, 1, 0, 3])
        for mode in ProjectionMode.allCases {
            #expect(try await project(input, mode: mode, axis: 2) == [10, 1, 0, 3])
        }
    }

    @Test("[Unit][VOX-ERR-001] projection admissions reject typed")
    func projectionAdmissionsRejectTyped() async throws {
        let input = try volume(extents: [2, 2, 3], bytes: primaryBytes)
        await #expect(throws: ProjectIntensityError.invalidProjectionAxis) {
            _ = try await self.project(input, mode: .maximum, axis: 3)
        }
        await #expect(throws: ProjectIntensityError.invalidPaddingValue) {
            _ = try await self.project(
                input,
                mode: .maximum,
                axis: 2,
                paddingValue: 300
            )
        }
        let plane = try volume(extents: [2, 2], bytes: [1, 2, 3, 4])
        await #expect(throws: ProjectIntensityError.unsupportedLayerFormat) {
            _ = try await self.project(plane, mode: .maximum, axis: 0)
        }
        let space = try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
        let calibrated = try volume(
            extents: [2, 2, 3],
            bytes: primaryBytes,
            geometry: .affine(
                try AffineGridGeometry(
                    spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
                    indexToWorld: Matrix4x4Double.identity,
                    coordinateSpace: space
                )
            )
        )
        await #expect(throws: ProjectIntensityError.unsupportedGeometry) {
            _ = try await self.project(calibrated, mode: .maximum, axis: 2)
        }
    }
}
