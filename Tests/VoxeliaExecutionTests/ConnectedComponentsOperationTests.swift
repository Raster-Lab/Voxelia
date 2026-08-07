// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("ConnectedComponentsOperation")
struct ConnectedComponentsOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func mask(extents: [Int], bytes: [UInt8]) throws -> ImageData {
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
                semantic: .mask,
                axes: axes,
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: shape,
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
                subject: .object(try #require(DataObjectID(rawValue: "ccl-in"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "ccl-in")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.15",
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
        connectivity: ComponentConnectivity
    ) async throws -> ImageData {
        try await ConnectedComponentsOperation.execute(
            input: input,
            connectivity: connectivity,
            outputObjectID: try #require(DataObjectID(rawValue: "ccl-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 512_000)
        )
    }

    private func labels(_ image: ImageData) throws -> [UInt16] {
        let extents = image.descriptor.shape.extents
        let bytes = try image.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
        var out = [UInt16]()
        var offset = 0
        while offset + 1 < bytes.count {
            out.append(UInt16(bytes[offset + 1]) << 8 | UInt16(bytes[offset]))
            offset += 2
        }
        return out
    }

    @Test("[Operation][VOX-IMG-013] fixture 1: the diagonal connectivity witness")
    func diagonalConnectivityWitness() async throws {
        let diagonal = try mask(extents: [2, 2], bytes: [1, 0, 0, 1])
        let faces = try await execute(diagonal, connectivity: .faces)
        #expect(try labels(faces) == [1, 0, 0, 2])
        #expect(faces.descriptor.semantic == .label)
        #expect(faces.descriptor.scalarFormat.type == .uint16)

        let vertices = try await execute(
            diagonal,
            connectivity: .facesEdgesAndVertices
        )
        #expect(try labels(vertices) == [1, 0, 0, 1])
    }

    @Test("[Operation][VOX-IMG-013] fixture 2: labels follow first-encounter order")
    func labelsFollowFirstEncounterOrder() async throws {
        let bars = try mask(
            extents: [5, 2],
            bytes: [1, 1, 0, 0, 0, 0, 0, 0, 1, 1]
        )
        let output = try await execute(bars, connectivity: .faces)
        #expect(try labels(output) == [1, 1, 0, 0, 0, 0, 0, 0, 2, 2])
    }

    @Test("[Operation][VOX-IMG-013] fixtures 3 and 4: the 3-D witness and the L shape")
    func threeDimensionalWitnessAndTheL() async throws {
        var cube = [UInt8](repeating: 0, count: 8)
        cube[0] = 1
        cube[6] = 1
        let volume = try mask(extents: [2, 2, 2], bytes: cube)
        let faces = try await execute(volume, connectivity: .faces)
        #expect(try labels(faces) == [1, 0, 0, 0, 0, 0, 2, 0])
        let edges = try await execute(volume, connectivity: .facesAndEdges)
        #expect(try labels(edges) == [1, 0, 0, 0, 0, 0, 1, 0])

        let ell = try mask(
            extents: [3, 3],
            bytes: [1, 0, 0, 1, 0, 0, 1, 1, 1]
        )
        let output = try await execute(ell, connectivity: .faces)
        #expect(try labels(output) == [1, 0, 0, 1, 0, 0, 1, 1, 1])
    }

    @Test("[Unit][VOX-IMG-013] the ceiling and admissions reject typed")
    func ceilingAndAdmissionsRejectTyped() async throws {
        // A 512 x 257 checkerboard yields 65,792 isolated components
        // under faces — past the sixteen-bit ceiling.
        let width = 512
        let height = 257
        var board = [UInt8](repeating: 0, count: width * height)
        for row in 0..<height {
            for column in 0..<width where (row + column) % 2 == 0 {
                board[column + width * row] = 1
            }
        }
        let checker = try mask(extents: [width, height], bytes: board)
        await #expect(throws: ConnectedComponentsError.componentCountExceeded) {
            _ = try await execute(checker, connectivity: .faces)
        }

        let flat = try mask(extents: [2, 2], bytes: [1, 0, 0, 1])
        await #expect(throws: ConnectedComponentsError.invalidConnectivity) {
            _ = try await execute(flat, connectivity: .facesAndEdges)
        }
        let corrupt = try mask(extents: [2, 2], bytes: [1, 2, 0, 1])
        await #expect(throws: ConnectedComponentsError.invalidMaskValue) {
            _ = try await execute(corrupt, connectivity: .faces)
        }
    }
}
