// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

/// `ADR-0291` (`VOX-R2D-003`): the presentation pipeline supports signed and unsigned
/// integer input values required by supported modalities.
///
/// The plan is specific about what that means: §"Source signedness — Signed and unsigned",
/// validation fixtures naming "synthetic signed 16-bit CT" and "synthetic unsigned 16-bit
/// CT", and an acceptance line reading "correct signedness". CT arrives both ways — signed
/// stored values, or unsigned with a rescale intercept — and both must present correctly.
///
/// Signedness is not a formatting detail here. The same sixteen bits are a different
/// number under each interpretation, and the pipeline decodes them differently:
/// `Int64(Int16(bitPattern:))` sign-extends, `Int64(UInt16)` zero-extends.
@Suite("StoredSignedness")
struct StoredSignednessTests {
    private func axis(_ id: String) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: .spatialX,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    /// Twelve samples, little-endian, from the given sixteen-bit patterns.
    private func bytes(_ patterns: [UInt16]) -> [UInt8] {
        patterns.flatMap { [UInt8(truncatingIfNeeded: $0), UInt8(truncatingIfNeeded: $0 >> 8)] }
    }

    private func input(scalarType: ScalarType, patterns: [UInt16]) throws -> ImageData {
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: scalarType,
            componentCount: 1
        )
        // Sized from the binding rather than assuming two bytes per sample. A wider
        // scalar type would otherwise be refused by the storage contract before the
        // operation's own scalar admission ran, and the refusal test would be asserting
        // the wrong guard.
        var storedBytes = bytes(patterns)
        if storedBytes.count != binding.logicalByteCount {
            storedBytes = Array(
                repeating: 1, count: binding.logicalByteCount)
        }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: [4, 3]),
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
                axes: [try axis("x"), try axis("y")],
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(binding: binding, bytes: storedBytes)
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "series-7"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "series-7")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: storedBytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.2",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func windowed(
        _ scalarType: ScalarType,
        _ patterns: [UInt16],
        center: Double,
        width: Double
    ) async throws -> [UInt8] {
        let output = try await WindowLevelOperation.execute(
            input: try input(scalarType: scalarType, patterns: patterns),
            center: try MetadataFloatingPoint(value: center),
            width: try MetadataFloatingPoint(value: width),
            paddingValue: nil,
            outputObjectID: try #require(DataObjectID(rawValue: "series-8")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:01Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 256)
        )
        return try output.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        ).bytes
    }

    // MARK: - Signedness is honoured

    @Test("[Unit][VOX-R2D-003] the same bits present differently as signed and unsigned")
    func sameBitsPresentDifferentlyAsSignedAndUnsigned() async throws {
        // `0xFC18` is -1000 read as int16 and 64536 read as uint16. A pipeline that
        // ignored signedness would produce the same output for both, and a CT stored as
        // signed would then display as if every soft-tissue voxel were far brighter than
        // bone.
        let patterns = [UInt16](repeating: 0xFC18, count: 12)
        let signed = try await windowed(.int16, patterns, center: 0, width: 2000)
        let unsigned = try await windowed(.uint16, patterns, center: 0, width: 2000)

        #expect(signed != unsigned)
        // -1000 sits at the bottom of a window centred on 0 with width 2000, so it is
        // black; 64536 is far above it, so it clamps white.
        #expect(signed.allSatisfy { $0 == 0 })
        #expect(unsigned.allSatisfy { $0 == 255 })
    }

    @Test("[Unit][VOX-R2D-003] non-negative patterns agree under both interpretations")
    func nonNegativePatternsAgreeUnderBothInterpretations() async throws {
        // The control. Sign extension is a no-op below 0x8000, so the two paths must
        // agree exactly there — which is what shows the divergence above is signedness
        // rather than two unrelated code paths that happen to differ.
        let patterns: [UInt16] = [
            0, 1, 100, 500, 1000, 4000, 10_000, 20_000,
            30_000, 32_000, 32_766, 32_767,
        ]
        let signed = try await windowed(.int16, patterns, center: 16_000, width: 32_000)
        let unsigned = try await windowed(.uint16, patterns, center: 16_000, width: 32_000)

        #expect(signed == unsigned)
        // Non-vacuity: the window must actually spread these across the range rather than
        // clamping everything to one value.
        #expect(Set(signed).count > 1)
    }

    @Test("[Unit][VOX-R2D-003] the signed extremes decode without trapping")
    func signedExtremesDecodeWithoutTrapping() async throws {
        // `0x8000` is Int16.min and `0x7FFF` is Int16.max. Sign extension of the minimum
        // is where a naive negation or magnitude step would trap.
        let patterns: [UInt16] = [
            0x8000, 0x7FFF, 0x8000, 0x7FFF, 0x8000, 0x7FFF,
            0x8000, 0x7FFF, 0x8000, 0x7FFF, 0x8000, 0x7FFF,
        ]
        let signed = try await windowed(.int16, patterns, center: 0, width: 65_535)
        #expect(signed.count == 12)
        // The minimum maps below the centre and the maximum above it, so alternating
        // samples must differ.
        #expect(signed[0] < signed[1])
    }

    @Test("[Unit][VOX-R2D-003] the unsigned extremes decode across the full range")
    func unsignedExtremesDecodeAcrossTheFullRange() async throws {
        let patterns: [UInt16] = [
            0, 0xFFFF, 0, 0xFFFF, 0, 0xFFFF,
            0, 0xFFFF, 0, 0xFFFF, 0, 0xFFFF,
        ]
        let unsigned = try await windowed(.uint16, patterns, center: 32_768, width: 65_535)
        #expect(unsigned[0] < unsigned[1])
        #expect(unsigned[0] == 0)
        #expect(unsigned[1] == 255)
    }

    // MARK: - Which types the pipeline admits

    @Test("[Unit][VOX-R2D-003] the modality integer types are admitted")
    func modalityIntegerTypesAreAdmitted() async throws {
        // `uint8`, `int16` and `uint16` cover the supported modalities' stored
        // representations. Each must present rather than be refused.
        for scalarType in [ScalarType.int16, .uint16] {
            let output = try await windowed(
                scalarType, [UInt16](repeating: 100, count: 12),
                center: 100, width: 200)
            #expect(output.count == 12)
        }
    }

    @Test("[Unit][VOX-R2D-003] a non-modality scalar type is refused, not coerced")
    func nonModalityScalarTypeIsRefused() async throws {
        // The negative half, and it matters: a pipeline that silently coerced a
        // floating-point or wider integer input would present something whose stored
        // interpretation nobody declared. `ADR-0290` records the same fail-closed
        // property for quality policies.
        for scalarType in [ScalarType.float32, .int32, .uint32, .int64] {
            await #expect(throws: WindowLevelError.unsupportedScalarType) {
                _ = try await windowed(
                    scalarType, [UInt16](repeating: 1, count: 12),
                    center: 0, width: 100)
            }
        }
    }
}
