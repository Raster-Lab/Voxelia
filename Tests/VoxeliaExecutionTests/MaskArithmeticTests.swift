// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

/// Shared fixture builders for the ALG-0058 suites.
private enum Fixture {
    static func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    static func image(
        name: String,
        scalarType: ScalarType,
        extents: [Int],
        bytes: [UInt8],
        semantic: ImageSemantic = .intensity
    ) throws -> ImageData {
        let shape = try ImageShape(extents: ContiguousArray(extents))
        var axes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        for (index, axisName) in ["x", "y", "z"].prefix(extents.count).enumerated() {
            guard let axisID = AxisID(rawValue: axisName) else {
                throw MaskApplyError.invalidOutputAxis
            }
            axes.append(
                try AxisDescriptor(
                    id: axisID,
                    name: axisName,
                    semantic: semantics[index],
                    unit: nil,
                    sampling: .indexOnly
                )
            )
        }
        guard
            let objectID = DataObjectID(rawValue: name),
            let recordID = ProvenanceID(rawValue: "record-\(name)")
        else {
            throw MaskApplyError.invalidOutputAxis
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
                id: recordID,
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
                subject: .object(objectID),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: objectID,
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.11",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    static func read(_ image: ImageData) throws -> [UInt8] {
        let extents = image.descriptor.shape.extents
        return try image.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
    }
}

@Suite("MaskApplyOperation")
struct MaskApplyOperationTests {
    private func execute(
        _ input: ImageData,
        mask: ImageData,
        fill: Double
    ) async throws -> ImageData {
        try await MaskApplyOperation.execute(
            input: input,
            mask: mask,
            fillValue: fill,
            outputObjectID: try #require(DataObjectID(rawValue: "masked-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try Fixture.software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    @Test("[Operation][VOX-IMG-010] fixture 1: mask keeps and fills exactly")
    func maskKeepsAndFillsExactly() async throws {
        let input = try Fixture.image(
            name: "mask-in",
            scalarType: .int16,
            extents: [6, 1],
            bytes: [12, 254, 0, 0, 40, 0, 144, 1, 255, 11, 100, 0]
        )
        let mask = try Fixture.image(
            name: "mask-mask",
            scalarType: .uint8,
            extents: [6, 1],
            bytes: [1, 0, 1, 0, 1, 0],
            semantic: .mask
        )
        let output = try await execute(input, mask: mask, fill: -1024)
        // The oracle's expected int16 samples -500, -1024, 40, -1024,
        // 3071, -1024 in little-endian bytes.
        #expect(
            try Fixture.read(output) == [
                12, 254, 0, 252, 40, 0, 0, 252, 255, 11, 0, 252,
            ]
        )
        #expect(output.descriptor.semantic == .intensity)
    }

    @Test("[Unit][VOX-IMG-010] a corrupt mask byte and a lossy fill reject typed")
    func corruptMaskAndLossyFillRejectTyped() async throws {
        let input = try Fixture.image(
            name: "mask-in",
            scalarType: .int16,
            extents: [2, 1],
            bytes: [1, 0, 2, 0]
        )
        let corrupt = try Fixture.image(
            name: "mask-corrupt",
            scalarType: .uint8,
            extents: [2, 1],
            bytes: [1, 2],
            semantic: .mask
        )
        await #expect(throws: MaskApplyError.invalidMaskValue) {
            _ = try await execute(input, mask: corrupt, fill: 0)
        }
        let mask = try Fixture.image(
            name: "mask-ok",
            scalarType: .uint8,
            extents: [2, 1],
            bytes: [1, 0],
            semantic: .mask
        )
        await #expect(throws: MaskApplyError.fillValueNotRepresentable) {
            _ = try await execute(input, mask: mask, fill: 0.5)
        }
        let wrongShape = try Fixture.image(
            name: "mask-shape",
            scalarType: .uint8,
            extents: [3, 1],
            bytes: [1, 0, 1],
            semantic: .mask
        )
        await #expect(throws: MaskApplyError.shapeMismatch) {
            _ = try await execute(input, mask: wrongShape, fill: 0)
        }
    }
}

@Suite("ArithmeticOperation")
struct ArithmeticOperationTests {
    private func execute(
        _ input: ImageData,
        operand: ArithmeticOperand,
        op: ArithmeticOperator
    ) async throws -> ImageData {
        try await ArithmeticOperation.execute(
            input: input,
            operand: operand,
            operator: op,
            outputObjectID: try #require(DataObjectID(rawValue: "arith-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try Fixture.software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    @Test("[Operation][VOX-IMG-010] fixture 2: int16 add saturates both ways, counted")
    func int16AddSaturatesBothWaysCounted() async throws {
        let left = try Fixture.image(
            name: "arith-a",
            scalarType: .int16,
            extents: [4, 1],
            bytes: [48, 117, 208, 138, 100, 0, 0, 0]
        )
        let right = try Fixture.image(
            name: "arith-b",
            scalarType: .int16,
            extents: [4, 1],
            bytes: [16, 39, 240, 216, 28, 0, 0, 0]
        )
        let output = try await execute(left, operand: .image(right), op: .add)
        // 32767, -32768, 128, 0 little-endian.
        #expect(
            try Fixture.read(output) == [255, 127, 0, 128, 128, 0, 0, 0]
        )
        let warning = try #require(output.provenance.warnings.first)
        #expect(warning.code.rawValue == ArithmeticOperation.saturationWarningCode)
        #expect(warning.occurrenceCount == 2)
    }

    @Test("[Operation][VOX-IMG-010] fixture 3: uint8 multiply saturates once")
    func uint8MultiplySaturatesOnce() async throws {
        let left = try Fixture.image(
            name: "arith-a8",
            scalarType: .uint8,
            extents: [4, 1],
            bytes: [20, 3, 0, 15]
        )
        let right = try Fixture.image(
            name: "arith-b8",
            scalarType: .uint8,
            extents: [4, 1],
            bytes: [20, 4, 9, 17]
        )
        let output = try await execute(left, operand: .image(right), op: .multiply)
        // 15 x 17 is exactly 255, not a saturation.
        #expect(try Fixture.read(output) == [255, 12, 0, 255])
        let warning = try #require(output.provenance.warnings.first)
        #expect(warning.occurrenceCount == 1)
    }

    @Test("[Operation][VOX-IMG-010] fixture 4: a fractional scalar rounds ties to even")
    func fractionalScalarRoundsTiesToEven() async throws {
        let input = try Fixture.image(
            name: "arith-s",
            scalarType: .int16,
            extents: [4, 1],
            bytes: [10, 0, 11, 0, 255, 127, 251, 255]
        )
        let output = try await execute(input, operand: .scalar(100.5), op: .add)
        // 110, 112, 32767 (saturated), 96 little-endian.
        #expect(
            try Fixture.read(output) == [110, 0, 112, 0, 255, 127, 96, 0]
        )
        let warning = try #require(output.provenance.warnings.first)
        #expect(warning.occurrenceCount == 1)
    }

    @Test("[Operation][VOX-IMG-010][VOX-R2D-004] fixture 5: float32 stores infinity verbatim")
    func float32StoresInfinityVerbatim() async throws {
        let left = try Fixture.image(
            name: "arith-f",
            scalarType: .float32,
            extents: [4, 1],
            bytes: [230, 177, 97, 127, 0, 0, 192, 63, 0, 0, 32, 192, 0, 0, 0, 0]
        )
        let right = try Fixture.image(
            name: "arith-g",
            scalarType: .float32,
            extents: [4, 1],
            bytes: [230, 177, 97, 127, 0, 0, 32, 64, 0, 0, 0, 63, 0, 0, 0, 0]
        )
        let output = try await execute(left, operand: .image(right), op: .add)
        #expect(
            try Fixture.read(output) == [
                0, 0, 128, 127, 0, 0, 128, 64, 0, 0, 0, 192, 0, 0, 0, 0,
            ]
        )
        let warning = try #require(output.provenance.warnings.first)
        #expect(warning.code.rawValue == ArithmeticOperation.nonFiniteWarningCode)
        #expect(warning.occurrenceCount == 1)
    }

    @Test("[Unit][VOX-IMG-010] operand admission rejects typed")
    func operandAdmissionRejectsTyped() async throws {
        let input = try Fixture.image(
            name: "arith-in",
            scalarType: .int16,
            extents: [2, 1],
            bytes: [1, 0, 2, 0]
        )
        let mismatched = try Fixture.image(
            name: "arith-u8",
            scalarType: .uint8,
            extents: [2, 1],
            bytes: [1, 2]
        )
        await #expect(throws: ArithmeticError.operandTypeMismatch) {
            _ = try await execute(input, operand: .image(mismatched), op: .add)
        }
        await #expect(throws: ArithmeticError.invalidScalarOperand) {
            _ = try await execute(input, operand: .scalar(.nan), op: .add)
        }
    }
}
