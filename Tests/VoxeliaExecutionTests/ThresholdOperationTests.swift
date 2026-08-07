// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("ThresholdOperation")
struct ThresholdOperationTests {
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

    /// A rank-two stored-domain image over the oracle's byte encodings.
    private func image(
        scalarType: ScalarType,
        extents: [Int],
        bytes: [UInt8],
        semantic: ImageSemantic = .intensity
    ) throws -> ImageData {
        let shape = try ImageShape(extents: ContiguousArray(extents))
        var axes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        for (index, name) in ["x", "y", "z"].prefix(extents.count).enumerated() {
            axes.append(try axis(name, semantic: semantics[index]))
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
                subject: .object(try #require(DataObjectID(rawValue: "threshold-in"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "threshold-in")),
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

    private func execute(
        _ input: ImageData,
        lower: Double,
        upper: Double,
        padding: Double?
    ) async throws -> ImageData {
        try await ThresholdOperation.execute(
            input: input,
            lowerBound: lower,
            upperBound: upper,
            paddingValue: padding,
            outputObjectID: try #require(DataObjectID(rawValue: "mask-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func maskBytes(_ image: ImageData) throws -> [UInt8] {
        let extents = image.descriptor.shape.extents
        return try image.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
    }

    @Test("[Operation][VOX-IMG-010] fixture 1: uint8 inclusive range")
    func uint8InclusiveRange() async throws {
        let output = try await execute(
            try image(scalarType: .uint8, extents: [6, 1], bytes: [0, 5, 10, 15, 20, 255]),
            lower: 5,
            upper: 20,
            padding: nil
        )
        #expect(try maskBytes(output) == [0, 1, 1, 1, 1, 0])
        #expect(output.descriptor.semantic == .mask)
        #expect(output.provenance.warnings.isEmpty)
    }

    @Test("[Operation][VOX-IMG-010] fixtures 2 and 3: the padding sentinel excludes first")
    func paddingSentinelExcludesFirst() async throws {
        let bytes: [UInt8] = [0, 252, 12, 254, 0, 0, 40, 0, 144, 1, 255, 11]
        let outOfRange = try await execute(
            try image(scalarType: .int16, extents: [6, 1], bytes: bytes),
            lower: -500,
            upper: 400,
            padding: -1024
        )
        #expect(try maskBytes(outOfRange) == [0, 1, 1, 1, 1, 0])

        // The sentinel inside the range still excludes: padding is not
        // data even when its value would pass the comparison.
        let insideRange = try await execute(
            try image(scalarType: .int16, extents: [6, 1], bytes: bytes),
            lower: -500,
            upper: 400,
            padding: 0
        )
        #expect(try maskBytes(insideRange) == [0, 1, 0, 1, 1, 0])
    }

    @Test("[Operation][VOX-IMG-010] fixture 4: uint16 range")
    func uint16Range() async throws {
        let output = try await execute(
            try image(
                scalarType: .uint16,
                extents: [4, 1],
                bytes: [0, 0, 100, 0, 255, 15, 255, 255]
            ),
            lower: 100,
            upper: 4095,
            padding: nil
        )
        #expect(try maskBytes(output) == [0, 1, 1, 0])
    }

    @Test("[Operation][VOX-IMG-010][VOX-R2D-004] fixture 5: float32 with non-finite samples")
    func float32WithNonFiniteSamples() async throws {
        let bytes: [UInt8] = [
            0, 0, 0, 63, 0, 0, 192, 63, 0, 0, 192, 127,
            0, 0, 128, 127, 0, 0, 128, 255, 0, 0, 32, 64,
        ]
        let output = try await execute(
            try image(scalarType: .float32, extents: [6, 1], bytes: bytes),
            lower: 1.0,
            upper: 2.5,
            padding: nil
        )
        // NaN excluded and counted; infinities compare as ordered
        // values; the inclusive upper edge is included.
        #expect(try maskBytes(output) == [0, 1, 0, 0, 0, 1])
        let warning = try #require(output.provenance.warnings.first)
        #expect(warning.code.rawValue == ThresholdOperation.nonFiniteWarningCode)
        #expect(warning.severity == .qualityAffecting)
        #expect(warning.occurrenceCount == 1)
    }

    @Test("[Unit][VOX-IMG-010] admission rejects range, padding and format typed")
    func admissionRejectsRangePaddingAndFormatTyped() async throws {
        let input = try image(scalarType: .uint8, extents: [2, 1], bytes: [1, 2])
        await #expect(throws: ThresholdError.invalidThresholdRange) {
            _ = try await execute(input, lower: 5, upper: 4, padding: nil)
        }
        await #expect(throws: ThresholdError.invalidThresholdRange) {
            _ = try await execute(
                input,
                lower: Double.nan,
                upper: 4,
                padding: nil
            )
        }
        await #expect(throws: ThresholdError.invalidPaddingValue) {
            _ = try await execute(
                input,
                lower: 0,
                upper: 4,
                padding: Double.infinity
            )
        }
        let label = try image(
            scalarType: .uint8,
            extents: [2, 1],
            bytes: [1, 2],
            semantic: .label
        )
        await #expect(throws: ThresholdError.unsupportedLayerFormat) {
            _ = try await execute(label, lower: 0, upper: 4, padding: nil)
        }
    }
}
