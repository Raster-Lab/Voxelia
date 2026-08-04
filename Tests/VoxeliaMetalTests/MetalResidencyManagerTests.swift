// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaMetal

@Suite("MetalResidencyManager")
struct MetalResidencyManagerTests {
    @Test("[Unit][VOX-PLT-014][VOX-EXE-002] policies fulfil by capability with real buffers")
    func policiesFulfilByCapabilityWithRealBuffers() throws {
        let manager = MetalResidencyManager(context: try MetalExecutionContext())

        // Automatic and shared select shared storage on the detected
        // unified-memory capability, and a real shared buffer
        // round-trips CPU writes.
        #expect(try manager.selection(for: .automatic) == .shared)
        #expect(try manager.selection(for: .shared) == .shared)
        let sharedBuffer = try manager.makeBuffer(byteCount: 12, policy: .shared)
        #expect(sharedBuffer.length == 12)
        let payload: [UInt8] = Array(0..<12)
        sharedBuffer.contents().copyMemory(from: payload, byteCount: 12)
        let readBack = Array(
            UnsafeBufferPointer(
                start: sharedBuffer.contents().bindMemory(
                    to: UInt8.self,
                    capacity: 12
                ),
                count: 12
            )
        )
        #expect(readBack == payload)

        // GPU-optimised selects private device storage and allocates
        // with the requested length.
        #expect(try manager.selection(for: .gpuOptimised) == .privateDevice)
        let privateBuffer = try manager.makeBuffer(
            byteCount: 64,
            policy: .gpuOptimised
        )
        #expect(privateBuffer.length == 64)

        // Declared intent is never rewritten: a device-buffer request
        // under cpuOnly is a contradiction, streaming and sparse need
        // their own contracts, and byte counts validate.
        do {
            _ = try manager.selection(for: .cpuOnly)
            #expect(Bool(false), "Expected cpuOnly to be rejected.")
        } catch MetalResidencyError.policyRequiresNoDeviceResidency {}
        for policy in [ResidencyPolicy.streamed, .sparse] {
            do {
                _ = try manager.selection(for: policy)
                #expect(Bool(false), "Expected an unsupported policy to be rejected.")
            } catch MetalResidencyError.unsupportedResidencyPolicy {}
        }
        do {
            _ = try manager.makeBuffer(byteCount: 0, policy: .shared)
            #expect(Bool(false), "Expected a zero byte count to be rejected.")
        } catch MetalResidencyError.invalidByteCount {}

        requireSendable(MetalResidencyManager.self)
        requireSendable(MetalResidencySelection.self)
        requireSendable(MetalResidencyError.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
