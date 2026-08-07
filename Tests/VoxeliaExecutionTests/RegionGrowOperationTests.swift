// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("RegionGrowOperation")
struct RegionGrowOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func image(
        scalarType: ScalarType,
        extents: [Int],
        bytes: [UInt8]
    ) throws -> ImageData {
        let shape = try ImageShape(extents: ContiguousArray(extents))
        var axes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        for (index, name) in ["x", "y", "z"].prefix(extents.count).enumerated() {
            axes.append(
                try AxisDescriptor(
                    id: try #require(AxisID(rawValue: name)),
                    name: name,
                    semantic: semantics[index],
                    unit: nil,
                    sampling: .indexOnly
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
                semantic: .intensity,
                axes: axes,
                spatialGeometry: nil,
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
                id: try #require(ProvenanceID(rawValue: "record-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "grow-in"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "grow-in")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.20",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    /// The oracle bar: 100, 110, -1000, 120, 130, 140 as int16 bytes.
    private func bar() throws -> ImageData {
        try image(
            scalarType: .int16,
            extents: [6, 1],
            bytes: [100, 0, 110, 0, 24, 252, 120, 0, 130, 0, 140, 0]
        )
    }

    private func execute(
        _ input: ImageData,
        seeds: [[Int]],
        lower: Double = 50,
        upper: Double = 200,
        padding: Double? = nil,
        connectivity: ComponentConnectivity = .faces
    ) async throws -> ImageData {
        try await RegionGrowOperation.execute(
            input: input,
            seeds: seeds,
            lowerBound: lower,
            upperBound: upper,
            paddingValue: padding,
            connectivity: connectivity,
            outputObjectID: try #require(DataObjectID(rawValue: "grown-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func mask(_ image: ImageData) throws -> [UInt8] {
        let extents = image.descriptor.shape.extents
        return try image.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
    }

    @Test("[Operation][VOX-SEG-007] fixtures 1 and 2: plateaus and the inert seed")
    func plateausAndTheInertSeed() async throws {
        let input = try bar()
        let left = try await execute(input, seeds: [[1, 0]])
        #expect(try mask(left) == [1, 1, 0, 0, 0, 0])
        #expect(left.descriptor.semantic == .mask)

        let right = try await execute(input, seeds: [[4, 0]])
        #expect(try mask(right) == [0, 0, 0, 1, 1, 1])

        // An out-of-range seed founds nothing, deliberately not an
        // error.
        let inert = try await execute(input, seeds: [[2, 0]])
        #expect(try mask(inert) == [0, 0, 0, 0, 0, 0])
    }

    @Test("[Operation][VOX-SEG-007] fixture 3: the diagonal bridge needs vertex connectivity")
    func diagonalBridgeNeedsVertexConnectivity() async throws {
        var bytes = [UInt8]()
        for value in [100, -1000, -1000, -1000, 100, -1000, -1000, -1000, 100] {
            let bits = UInt16(bitPattern: Int16(value))
            bytes.append(UInt8(bits & 0xFF))
            bytes.append(UInt8(bits >> 8))
        }
        let plane = try image(scalarType: .int16, extents: [3, 3], bytes: bytes)
        let faces = try await execute(plane, seeds: [[0, 0]])
        #expect(try mask(faces) == [1, 0, 0, 0, 0, 0, 0, 0, 0])
        let vertices = try await execute(
            plane,
            seeds: [[0, 0]],
            connectivity: .facesEdgesAndVertices
        )
        #expect(try mask(vertices) == [1, 0, 0, 0, 1, 0, 0, 0, 1])
    }

    @Test("[Operation][VOX-SEG-007] fixture 4: the sentinel inside the range blocks growth")
    func sentinelInsideTheRangeBlocksGrowth() async throws {
        let padded = try image(
            scalarType: .int16,
            extents: [4, 1],
            bytes: [100, 0, 0, 0, 110, 0, 120, 0]
        )
        let blocked = try await execute(
            padded,
            seeds: [[0, 0]],
            lower: -10,
            upper: 200,
            padding: 0
        )
        #expect(try mask(blocked) == [1, 0, 0, 0])
        let flowing = try await execute(
            padded,
            seeds: [[0, 0]],
            lower: -10,
            upper: 200
        )
        #expect(try mask(flowing) == [1, 1, 1, 1])
    }

    @Test("[Unit][VOX-SEG-007] the recording is complete and admissions reject typed")
    func recordingIsCompleteAndAdmissionsRejectTyped() async throws {
        let input = try bar()
        let grown = try await execute(input, seeds: [[1, 0], [4, 0]], padding: -1000)
        guard case .operation(let operation, _) = grown.provenance.activity else {
            #expect(Bool(false), "Expected an operation activity.")
            return
        }
        // The recording the row demands, verified by digest identity.
        let expected = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try RegionGrowOperation.parameterCollection(
                    seeds: [[1, 0], [4, 0]],
                    lowerBound: 50,
                    upperBound: 200,
                    paddingValue: -1000,
                    connectivity: .faces
                ),
                maximumOutputByteCount: 262_144
            )
        )
        #expect(operation.parameterDigest == expected)
        #expect(operation.operationVersion.major == 1)
        #expect(operation.implementationVersion.major == 1)

        await #expect(throws: RegionGrowError.invalidSeed) {
            _ = try await execute(input, seeds: [])
        }
        await #expect(throws: RegionGrowError.invalidSeed) {
            _ = try await execute(input, seeds: [[9, 0]])
        }
        await #expect(throws: RegionGrowError.invalidConnectivity) {
            _ = try await execute(input, seeds: [[1, 0]], connectivity: .facesAndEdges)
        }
        await #expect(throws: RegionGrowError.invalidThresholdRange) {
            _ = try await execute(input, seeds: [[1, 0]], lower: 5, upper: 4)
        }
    }
}
