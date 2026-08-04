// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("StorageContract")
struct StorageContractTests {
    @Test("[Unit][VOX-STO-001][VOX-API-004] bindings validate with checked accounting")
    func bindingsValidateWithCheckedAccounting() throws {
        let shape = try ImageShape(extents: [4, 3, 2])
        let binding = try LogicalSampleBinding(
            shape: shape,
            scalarType: .float32,
            componentCount: 3
        )
        #expect(binding.logicalValueCount == 72)
        #expect(binding.logicalByteCount == 288)

        // Non-positive component counts are incompatible bindings.
        do {
            _ = try LogicalSampleBinding(shape: shape, scalarType: .uint8, componentCount: 0)
            #expect(Bool(false), "Expected a zero component count to be rejected.")
        } catch StorageContractError.incompatibleBinding {}

        // Checked value/byte accounting rejects overflow as a limit.
        let wide = try ImageShape(extents: [Int.max / 2, 2])
        do {
            _ = try LogicalSampleBinding(shape: wide, scalarType: .uint8, componentCount: 3)
            #expect(Bool(false), "Expected checked value accounting to reject overflow.")
        } catch StorageContractError.resourceLimitExceeded {}
        do {
            _ = try LogicalSampleBinding(shape: wide, scalarType: .float64, componentCount: 1)
            #expect(Bool(false), "Expected checked byte accounting to reject overflow.")
        } catch StorageContractError.resourceLimitExceeded {}

        requireSendable(LogicalSampleBinding.self)
        requireSendable(StorageContractError.self)
    }

    @Test("[Unit][VOX-STO-001][VOX-API-001] the step-5 projection is lossless")
    func stepFiveProjectionIsLossless() throws {
        // Projecting the existing controlled leaves consumes exactly the
        // representation-independent fields and matches direct construction.
        let shape = try ImageShape(extents: [8, 8])
        let format = try ScalarFormat(
            type: .int16,
            validBitCount: nil,
            byteOrder: .littleEndian
        )
        let components = try ComponentDescriptor(
            count: 2,
            interpretation: .vector,
            layout: .interleaved,
            componentNames: nil
        )
        let projected = try LogicalSampleBinding(
            shape: shape,
            scalarFormat: format,
            components: components
        )
        let direct = try LogicalSampleBinding(
            shape: shape,
            scalarType: .int16,
            componentCount: 2
        )
        #expect(projected == direct)
        #expect(projected.logicalValueCount == 128)
        #expect(projected.logicalByteCount == 256)

        // The projection is byte-order independent: representation-layer
        // facts never change logical identity.
        let bigEndian = try ScalarFormat(
            type: .int16,
            validBitCount: nil,
            byteOrder: .bigEndian
        )
        let reprojected = try LogicalSampleBinding(
            shape: shape,
            scalarFormat: bigEndian,
            components: components
        )
        #expect(reprojected == projected)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
