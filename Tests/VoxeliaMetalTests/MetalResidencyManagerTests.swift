// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaMetal

@Suite("MetalResidencyManager")
struct MetalResidencyManagerTests {
    @Test("[Unit][VOX-PLT-014][VOX-EXE-002] policies fulfil by capability with real buffers")
    func policiesFulfilByCapabilityWithRealBuffers() throws {
        let context = try MetalExecutionContext()
        let manager = MetalResidencyManager(context: context)

        // Automatic and shared select shared storage on the detected
        // unified-memory capability, and a real shared buffer
        // round-trips CPU writes.
        #expect(try manager.selection(for: .automatic) == .shared)
        #expect(try manager.selection(for: .shared) == .shared)
        let sharedBuffer = try manager.makeBuffer(byteCount: 12, policy: .shared)
        #expect(sharedBuffer.length == 12)
        let payload: [UInt8] = Array(0..<12)
        try MetalBufferTransfer.write(payload, to: sharedBuffer, offset: 0)
        let (readbackBuffer, writer) = try context.withMetalHandles {
            device, commandQueue in
            let readbackBuffer = try #require(
                device.makeBuffer(length: 12, options: [.storageModeShared])
            )
            let writer = try #require(commandQueue.makeCommandBuffer())
            let blit = try #require(writer.makeBlitCommandEncoder())
            blit.copy(
                from: sharedBuffer,
                sourceOffset: 0,
                to: readbackBuffer,
                destinationOffset: 0,
                size: 12
            )
            blit.endEncoding()
            return (readbackBuffer, writer)
        }
        writer.commit()
        writer.waitUntilCompleted()
        withExtendedLifetime(sharedBuffer) {}
        let readBack = try MetalBufferTransfer.readBytes(
            from: readbackBuffer,
            offset: 0,
            count: 12,
            after: writer
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

    @Test(
        "[Concurrency][VOX-CON-003][VOX-MTL-007][VOX-MTL-008] concurrent requests preserve policy"
    )
    func concurrentRequestsPreservePolicy() async throws {
        let manager = MetalResidencyManager(context: try MetalExecutionContext())

        try await withThrowingTaskGroup(of: Int.self) { group in
            for index in 0..<24 {
                group.addTask {
                    let byteCount = (index + 1) * 16
                    let policy: ResidencyPolicy
                    let expectedSelection: MetalResidencySelection
                    switch index % 3 {
                    case 0:
                        policy = .automatic
                        expectedSelection = .shared
                    case 1:
                        policy = .shared
                        expectedSelection = .shared
                    default:
                        policy = .gpuOptimised
                        expectedSelection = .privateDevice
                    }

                    #expect(try manager.selection(for: policy) == expectedSelection)
                    let buffer = try manager.makeBuffer(
                        byteCount: byteCount,
                        policy: policy
                    )
                    #expect(buffer.length == byteCount)
                    switch expectedSelection {
                    case .shared:
                        #expect(buffer.storageMode == .shared)
                    case .privateDevice:
                        #expect(buffer.storageMode == .private)
                    }
                    return buffer.length
                }
            }

            var observedLengths = Set<Int>()
            for try await length in group {
                #expect(observedLengths.insert(length).inserted)
            }
            #expect(observedLengths.count == 24)
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
