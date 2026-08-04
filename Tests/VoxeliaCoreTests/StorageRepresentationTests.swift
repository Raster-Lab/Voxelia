// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("StorageRepresentation")
struct StorageRepresentationTests {
    private func binding() throws -> LogicalSampleBinding {
        try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .int16,
            componentCount: 2
        )
    }

    @Test("[Unit][VOX-STO-002][VOX-API-004] canonical packed admission is exact")
    func canonicalPackedAdmissionIsExact() throws {
        let binding = try binding()
        let packed = try DecodedStridedRepresentation.canonicalPacked(
            binding: binding,
            byteOrder: .littleEndian,
            locality: .external
        )
        #expect(packed.axisStrides == [4, 16])
        #expect(packed.componentStride == 2)
        #expect(packed.initializedByteCount == 48)

        // A nonzero checked base offset is admitted when covered.
        _ = try DecodedStridedRepresentation(
            binding: binding,
            baseOffset: 8,
            axisStrides: [4, 16],
            componentStride: 2,
            byteOrder: .littleEndian,
            locality: .external,
            initializedByteCount: 56
        )

        // Short initialised length, negative offset, non-canonical stride
        // and rank mismatch reject with the exact typed causes.
        do {
            _ = try DecodedStridedRepresentation(
                binding: binding,
                baseOffset: 8,
                axisStrides: [4, 16],
                componentStride: 2,
                byteOrder: .littleEndian,
                locality: .external,
                initializedByteCount: 55
            )
            #expect(Bool(false), "Expected a short initialised length to reject.")
        } catch StorageContractError.resourceLimitExceeded {}
        do {
            _ = try DecodedStridedRepresentation(
                binding: binding,
                baseOffset: -1,
                axisStrides: [4, 16],
                componentStride: 2,
                byteOrder: .littleEndian,
                locality: .external,
                initializedByteCount: 48
            )
            #expect(Bool(false), "Expected a negative base offset to reject.")
        } catch StorageContractError.invalidRegion {}
        do {
            _ = try DecodedStridedRepresentation(
                binding: binding,
                baseOffset: 0,
                axisStrides: [16, 4],
                componentStride: 2,
                byteOrder: .littleEndian,
                locality: .external,
                initializedByteCount: 48
            )
            #expect(Bool(false), "Expected a non-canonical stride to reject.")
        } catch StorageContractError.incompatibleBinding {}
        do {
            _ = try DecodedStridedRepresentation(
                binding: binding,
                baseOffset: 0,
                axisStrides: [4],
                componentStride: 2,
                byteOrder: .littleEndian,
                locality: .external,
                initializedByteCount: 48
            )
            #expect(Bool(false), "Expected a rank mismatch to reject.")
        } catch StorageContractError.incompatibleBinding {}

        requireSendable(StorageRepresentationDescriptor.self)
        requireSendable(DecodedStridedRepresentation.self)
        requireSendable(OpaqueRepresentation.self)
    }

    @Test("[Unit][VOX-STO-002][VOX-SEC-006] byte-order and opaque rules hold")
    func byteOrderAndOpaqueRulesHold() throws {
        let binding = try binding()

        // Multi-byte .native order is process-local only.
        do {
            _ = try DecodedStridedRepresentation.canonicalPacked(
                binding: binding,
                byteOrder: .native,
                locality: .external
            )
            #expect(Bool(false), "Expected external native order to reject.")
        } catch StorageContractError.incompatibleBinding {}
        _ = try DecodedStridedRepresentation.canonicalPacked(
            binding: binding,
            byteOrder: .native,
            locality: .processLocalOwned
        )

        // Single-byte scalars may use .native anywhere.
        let bytes = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4]),
            scalarType: .uint8,
            componentCount: 1
        )
        _ = try DecodedStridedRepresentation.canonicalPacked(
            binding: bytes,
            byteOrder: .native,
            locality: .mapped
        )

        // Opaque tags are bounded and non-blank; negative lengths reject.
        _ = try OpaqueRepresentation(formatTag: "org.example.brick-v1", knownByteCount: 100)
        for invalid in [(" ", 1), ("x", -1)] {
            do {
                _ = try OpaqueRepresentation(
                    formatTag: invalid.0,
                    knownByteCount: invalid.1
                )
                #expect(Bool(false), "Expected an invalid opaque tag to reject.")
            } catch StorageContractError.incompatibleBinding {}
        }
        do {
            _ = try OpaqueRepresentation(
                formatTag: String(repeating: "a", count: 256),
                knownByteCount: nil
            )
            #expect(Bool(false), "Expected an oversized tag to reject.")
        } catch StorageContractError.incompatibleBinding {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
