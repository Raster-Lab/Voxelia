// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("LevelSelectOperation")
struct LevelSelectOperationTests {
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

    private func geometry(elements: [Double]) throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: try Matrix4x4Double(elements: elements),
            coordinateSpace: try space()
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

    /// The oracle fixture volume: extents (5, 4, 3) with stored value
    /// `i0 + 5*i1 + 20*i2` over the anisotropic non-zero-origin
    /// geometry.
    private func volume() throws -> ImageData {
        let extents = [5, 4, 3]
        var bytes = [UInt8]()
        for i2 in 0..<3 {
            for i1 in 0..<4 {
                for i0 in 0..<5 {
                    bytes.append(UInt8(i0 + 5 * i1 + 20 * i2))
                }
            }
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
                axes: [
                    try axis("x", semantic: .spatialX),
                    try axis("y", semantic: .spatialY),
                    try axis("z", semantic: .spatialZ),
                ],
                spatialGeometry: .affine(
                    try geometry(
                        elements: [
                            0.5, 0, 0, 10.5,
                            0, 0.25, 0, -20.25,
                            0, 0, 2.0, 0.125,
                            0, 0, 0, 1,
                        ]
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
                id: try #require(ProvenanceID(rawValue: "record-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
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
                        identifier: "1.2.840.113619.7",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func execute(
        _ input: ImageData,
        level: BrickResolutionLevel
    ) async throws -> ImageData {
        try await LevelSelectOperation.execute(
            input: input,
            level: level,
            outputObjectID: try #require(DataObjectID(rawValue: "level-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func bytes(_ image: ImageData) throws -> [UInt8] {
        let extents = image.descriptor.shape.extents
        return try image.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
    }

    @Test("[Operation][VOX-BRK-009] fixture 1: uniform factor two selects the oracle bytes")
    func uniformFactorTwoSelectsTheOracleBytes() async throws {
        let output = try await execute(
            try volume(),
            level: try BrickResolutionLevel(index: 1, downsamplingFactors: [2, 2, 2])
        )
        #expect(output.descriptor.shape.extents == [3, 2, 2])
        #expect(try bytes(output) == [0, 2, 4, 10, 12, 14, 40, 42, 44, 50, 52, 54])
    }

    @Test("[Operation][VOX-BRK-009] fixture 2: mixed factors select every second row")
    func mixedFactorsSelectEverySecondRow() async throws {
        let output = try await execute(
            try volume(),
            level: try BrickResolutionLevel(index: 1, downsamplingFactors: [1, 2, 1])
        )
        #expect(output.descriptor.shape.extents == [5, 2, 3])
        #expect(
            try bytes(output) == [
                0, 1, 2, 3, 4, 10, 11, 12, 13, 14,
                20, 21, 22, 23, 24, 30, 31, 32, 33, 34,
                40, 41, 42, 43, 44, 50, 51, 52, 53, 54,
            ]
        )
    }

    @Test("[Operation][VOX-BRK-009] fixtures 3 and 4: large factors collapse axes ordinarily")
    func largeFactorsCollapseAxesOrdinarily() async throws {
        let input = try volume()
        let quartered = try await execute(
            input,
            level: try BrickResolutionLevel(index: 2, downsamplingFactors: [4, 4, 4])
        )
        #expect(quartered.descriptor.shape.extents == [2, 1, 1])
        #expect(try bytes(quartered) == [0, 4])

        let collapsed = try await execute(
            input,
            level: try BrickResolutionLevel(index: 3, downsamplingFactors: [8, 8, 8])
        )
        #expect(collapsed.descriptor.shape.extents == [1, 1, 1])
        #expect(try bytes(collapsed) == [0])
    }

    @Test("[Operation][VOX-BRK-009] fixture 5: the output claims the scaled geometry")
    func outputClaimsTheScaledGeometry() async throws {
        let output = try await execute(
            try volume(),
            level: try BrickResolutionLevel(index: 1, downsamplingFactors: [2, 2, 2])
        )
        guard case .affine(let levelGeometry)? = output.descriptor.spatialGeometry
        else {
            #expect(Bool(false), "Expected affine level geometry.")
            return
        }
        #expect(
            Array(levelGeometry.indexToWorld.elements) == [
                1.0, 0, 0, 10.5,
                0, 0.5, 0, -20.25,
                0, 0, 4.0, 0.125,
                0, 0, 0, 1,
            ]
        )
        #expect(
            levelGeometry.coordinateSpace.id.rawValue == "patient"
        )
    }

    @Test("[Unit][VOX-BRK-009] level zero and malformed levels reject typed")
    func levelZeroAndMalformedLevelsRejectTyped() async throws {
        let input = try volume()
        // Level zero is the volume itself: an identity copy would mint
        // a duplicate object while looking like work.
        await #expect(throws: LevelSelectError.invalidDownsamplingLevel) {
            _ = try await execute(
                input,
                level: try BrickResolutionLevel(index: 0, downsamplingFactors: [2, 2, 2])
            )
        }
        // A rank-two factor list cannot address a rank-three volume.
        await #expect(throws: LevelSelectError.invalidDownsamplingLevel) {
            _ = try await execute(
                input,
                level: try BrickResolutionLevel(index: 1, downsamplingFactors: [2, 2])
            )
        }
        // A factor above the sibling ceiling rejects.
        await #expect(throws: LevelSelectError.invalidDownsamplingLevel) {
            _ = try await execute(
                input,
                level: try BrickResolutionLevel(
                    index: 1,
                    downsamplingFactors: [16_385, 2, 2]
                )
            )
        }
    }

    @Test("[Unit][VOX-BRK-009] an uncalibrated volume rejects typed")
    func uncalibratedVolumeRejectsTyped() async throws {
        var bytes = [UInt8]()
        for value in 0..<60 {
            bytes.append(UInt8(value))
        }
        let extents = [5, 4, 3]
        let uncalibrated = try ImageData(
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
                spatialGeometry: nil,
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
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "volume-8"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "volume-8")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.8",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
        await #expect(throws: LevelSelectError.volumeNotSpatiallyCalibrated) {
            _ = try await execute(
                uncalibrated,
                level: try BrickResolutionLevel(index: 1, downsamplingFactors: [2, 2, 2])
            )
        }
    }

    @Test("[Operation][VOX-BRK-009] the derivation records the level parameters")
    func derivationRecordsTheLevelParameters() async throws {
        let output = try await execute(
            try volume(),
            level: try BrickResolutionLevel(index: 1, downsamplingFactors: [2, 2, 2])
        )
        guard case .operation(let operation, let claim) = output.provenance.activity
        else {
            #expect(Bool(false), "Expected an operation activity.")
            return
        }
        #expect(operation.operationID.rawValue == "org.voxelia.op.level-select")
        #expect(claim.approximationStatus == .exact)
        let digest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try LevelSelectOperation.parameterCollection(
                    level: try BrickResolutionLevel(
                        index: 1,
                        downsamplingFactors: [2, 2, 2]
                    )
                ),
                maximumOutputByteCount: 65_536
            )
        )
        #expect(operation.parameterDigest == digest)
    }
}
