// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("TransposeAxesOperation")
struct TransposeAxesOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func axis(
        _ id: String,
        semantic: AxisSemantic,
        sampling: AxisSampling = .indexOnly
    ) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: semantic,
            unit: nil,
            sampling: sampling
        )
    }

    private func volume(
        extents: [Int],
        axes: [AxisDescriptor],
        geometry: SpatialGeometry? = nil
    ) throws -> ImageData {
        let count = extents.reduce(1, *)
        let bytes = (0..<count).map { UInt8($0) }
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
                axes: ContiguousArray(axes),
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
                id: try #require(ProvenanceID(rawValue: "record-volume")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T07:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "volume-1"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "volume-1")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.volume",
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
        axisOrder: [Int],
        suffix: String
    ) async throws -> ImageData {
        try await TransposeAxesOperation.execute(
            input: input,
            axisOrder: axisOrder,
            outputObjectID: try #require(DataObjectID(rawValue: "volume-\(suffix)")),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "record-volume-\(suffix)")
            ),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T07:05:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func bytes(_ image: ImageData, extents: [Int]) throws -> [UInt8] {
        try image.storage.read(
            region: try ImageRegion(
                lowerBounds: ContiguousArray(repeating: 0, count: extents.count),
                upperBounds: ContiguousArray(extents)
            )
        ).bytes
    }

    @Test("[Unit][VOX-EXE-002][VOX-MPR-001] the exact remap reproduces the fixtures")
    func exactRemapReproducesTheFixtures() async throws {
        // The rank-two VOXELIA-ALG-0012 fixture, with axis descriptors
        // and sampling payloads travelling with their axes.
        let plane = try volume(
            extents: [2, 3],
            axes: [
                try axis("x", semantic: .spatialX),
                try axis(
                    "y",
                    semantic: .spatialY,
                    sampling: .irregular(coordinates: [1.5, 2.5, 4.0])
                ),
            ]
        )
        let swapped = try await execute(plane, axisOrder: [1, 0], suffix: "a")
        #expect(try bytes(swapped, extents: [3, 2]) == [0, 2, 4, 1, 3, 5])
        #expect(swapped.descriptor.axes[0].id.rawValue == "y")
        #expect(swapped.descriptor.axes[1].id.rawValue == "x")
        guard
            case .irregular(let coordinates) = swapped.descriptor.axes[0].sampling
        else {
            #expect(Bool(false), "Expected the irregular payload to travel.")
            return
        }
        #expect(coordinates == [1.5, 2.5, 4.0])

        // The rank-three fixture, the identity permutation, and the
        // inverse composition.
        let stack = try volume(
            extents: [2, 3, 2],
            axes: [
                try axis("x", semantic: .spatialX),
                try axis("y", semantic: .spatialY),
                try axis("z", semantic: .spatialZ),
            ]
        )
        let rotated = try await execute(stack, axisOrder: [2, 0, 1], suffix: "b")
        #expect(
            try bytes(rotated, extents: [2, 2, 3])
                == [0, 6, 1, 7, 2, 8, 3, 9, 4, 10, 5, 11]
        )
        let identity = try await execute(stack, axisOrder: [0, 1, 2], suffix: "c")
        #expect(try bytes(identity, extents: [2, 3, 2]) == Array(0..<12))
        let restored = try await execute(rotated, axisOrder: [1, 2, 0], suffix: "d")
        #expect(try bytes(restored, extents: [2, 3, 2]) == Array(0..<12))

        // The parameter digest reproduces independently.
        let expectedDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try TransposeAxesOperation.parameterCollection(
                    axisOrder: [2, 0, 1]
                ),
                maximumOutputByteCount: 65_536
            )
        )
        #expect(rotated.identity.derivation?.parameterDigest == expectedDigest)

        requireSendable(TransposeError.self)
    }

    @Test("[Unit][VOX-EXE-006][VOX-ERR-001] transposition admission rejects typed")
    func transpositionAdmissionRejectsTyped() async throws {
        let plane = try volume(
            extents: [2, 3],
            axes: [
                try axis("x", semantic: .spatialX),
                try axis("y", semantic: .spatialY),
            ]
        )

        // Non-permutations and geometry-bearing input reject typed.
        for order in [[0, 0], [0], [0, 2], [0, 1, 2]] {
            do {
                _ = try await execute(plane, axisOrder: order, suffix: "e")
                #expect(Bool(false), "Expected a non-permutation to be rejected.")
            } catch TransposeError.invalidAxisOrder {}
        }
        do {
            let space = try CoordinateSpaceDescriptor(
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
            let calibrated = try volume(
                extents: [2, 3],
                axes: [
                    try axis("x", semantic: .spatialX),
                    try axis("y", semantic: .spatialY),
                ],
                geometry: .affine(
                    try AffineGridGeometry(
                        spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
                        indexToWorld: .identity,
                        coordinateSpace: space
                    )
                )
            )
            _ = try await execute(calibrated, axisOrder: [1, 0], suffix: "f")
            #expect(Bool(false), "Expected geometry-bearing input to be rejected.")
        } catch TransposeError.unsupportedGeometry {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
