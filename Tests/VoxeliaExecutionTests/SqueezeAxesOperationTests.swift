// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("SqueezeAxesOperation")
struct SqueezeAxesOperationTests {
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

    private func slab(extents: [Int], axisNames: [String]) throws -> ImageData {
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        let count = extents.reduce(1, *)
        let bytes = (0..<count).map { UInt8($0) }
        var axes = ContiguousArray<AxisDescriptor>()
        for (index, name) in axisNames.enumerated() {
            axes.append(try axis(name, semantic: semantics[index]))
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
                id: try #require(ProvenanceID(rawValue: "record-slab")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T07:20:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "slab-1"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "slab-1")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.slab",
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
        axes: [Int],
        suffix: String
    ) async throws -> ImageData {
        try await SqueezeAxesOperation.execute(
            input: input,
            axes: axes,
            outputObjectID: try #require(DataObjectID(rawValue: "slab-\(suffix)")),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "record-slab-\(suffix)")
            ),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T07:25:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    @Test("[Unit][VOX-EXE-002][VOX-MPR-001] the squeeze drops singletons byte-identically")
    func squeezeDropsSingletonsByteIdentically() async throws {
        // Both VOXELIA-ALG-0013 fixtures: the payload is byte-identical
        // and the remaining axes keep their descriptors in order.
        let thick = try slab(extents: [2, 3, 1], axisNames: ["x", "y", "z"])
        let slice = try await execute(thick, axes: [2], suffix: "a")
        #expect(slice.descriptor.shape.extents == [2, 3])
        #expect(
            try slice.storage.read(
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [2, 3])
            ).bytes == Array(0..<6)
        )
        #expect(slice.descriptor.axes.map(\.id.rawValue) == ["x", "y"])

        let column = try slab(extents: [1, 4], axisNames: ["x", "y"])
        let line = try await execute(column, axes: [0], suffix: "b")
        #expect(line.descriptor.shape.extents == [4])
        #expect(
            try line.storage.read(
                region: try ImageRegion(lowerBounds: [0], upperBounds: [4])
            ).bytes == Array(0..<4)
        )
        #expect(line.descriptor.axes.map(\.id.rawValue) == ["y"])

        // The parameter digest reproduces independently.
        let expectedDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try SqueezeAxesOperation.parameterCollection(axes: [2]),
                maximumOutputByteCount: 65_536
            )
        )
        #expect(slice.identity.derivation?.parameterDigest == expectedDigest)

        requireSendable(SqueezeError.self)
    }

    @Test("[Unit][VOX-EXE-006][VOX-ERR-001] squeeze admission rejects typed")
    func squeezeAdmissionRejectsTyped() async throws {
        let thick = try slab(extents: [2, 3, 1], axisNames: ["x", "y", "z"])

        // Empty, non-singleton, duplicate, out-of-range and total
        // selections reject typed.
        for axes in [[], [0], [2, 2], [3], [-1]] {
            do {
                _ = try await execute(thick, axes: axes, suffix: "r")
                #expect(Bool(false), "Expected an invalid selection to be rejected.")
            } catch SqueezeError.invalidAxisSelection {}
        }
        do {
            let point = try slab(extents: [1], axisNames: ["x"])
            _ = try await execute(point, axes: [0], suffix: "t")
            #expect(Bool(false), "Expected a total drop to be rejected.")
        } catch SqueezeError.invalidAxisSelection {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
