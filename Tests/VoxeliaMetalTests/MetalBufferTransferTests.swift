// SPDX-License-Identifier: MIT

import Metal
import Testing

@testable import VoxeliaMetal

@Suite("MetalBufferTransfer")
struct MetalBufferTransferTests {
    @Test("[Unit][VOX-SEC-001][VOX-SEC-002] exact shared writes return owned bytes")
    func exactSharedWritesReturnOwnedBytes() throws {
        let context = try MetalExecutionContext()
        let payloads: [[UInt8]] = [
            [0xA5],
            Array(0..<13),
            (0..<28).map { UInt8(truncatingIfNeeded: $0 &* 17) },
        ]

        for original in payloads {
            var source = original
            let (upload, buffer, writer) = try context.withMetalHandles {
                device, queue in
                let upload = try MetalBufferTransfer.makeSharedBuffer(
                    copying: source,
                    using: device
                )
                source[0] ^= 0xFF
                let buffer = try #require(
                    device.makeBuffer(
                        length: original.count,
                        options: [.storageModeShared]
                    )
                )
                let writer = try #require(queue.makeCommandBuffer())
                let blit = try #require(writer.makeBlitCommandEncoder())
                blit.copy(
                    from: upload,
                    sourceOffset: 0,
                    to: buffer,
                    destinationOffset: 0,
                    size: original.count
                )
                blit.endEncoding()
                writer.commit()
                return (upload, buffer, writer)
            }
            writer.waitUntilCompleted()
            withExtendedLifetime(upload) {}

            let snapshot = try MetalBufferTransfer.readBytes(
                from: buffer,
                offset: 0,
                count: original.count,
                after: writer
            )
            #expect(snapshot == original)

            try MetalBufferTransfer.write(
                Array(repeating: 0xEE, count: original.count),
                to: buffer,
                offset: 0
            )
            #expect(snapshot == original)
        }
    }

    @Test("[Unit][VOX-SEC-001] lower and upper transfer ranges are exact")
    func lowerAndUpperTransferRangesAreExact() throws {
        let context = try MetalExecutionContext()
        try context.withMetalHandles { device, queue in
            let upload = try MetalBufferTransfer.makeSharedBuffer(
                copying: Array(0..<8),
                using: device
            )
            try MetalBufferTransfer.write([0xA6, 0xA7], to: upload, offset: 6)
            let buffer = try #require(
                device.makeBuffer(length: 8, options: [.storageModeShared])
            )
            let writer = try #require(queue.makeCommandBuffer())
            let blit = try #require(writer.makeBlitCommandEncoder())
            blit.copy(
                from: upload,
                sourceOffset: 0,
                to: buffer,
                destinationOffset: 0,
                size: 8
            )
            blit.endEncoding()
            writer.commit()
            writer.waitUntilCompleted()

            #expect(
                try MetalBufferTransfer.readBytes(
                    from: buffer,
                    offset: 0,
                    count: 1,
                    after: writer
                ) == [0]
            )
            #expect(
                try MetalBufferTransfer.readBytes(
                    from: buffer,
                    offset: 6,
                    count: 2,
                    after: writer
                ) == [0xA6, 0xA7]
            )
        }
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-001] invalid sizes and ranges reject typed")
    func invalidSizesAndRangesRejectTyped() {
        expectTransferError(.invalidByteCount) {
            try MetalBufferTransfer.validateAllocationByteCount(0, maximum: 8)
        }
        expectTransferError(.invalidByteCount) {
            try MetalBufferTransfer.validateAllocationByteCount(-1, maximum: 8)
        }
        expectTransferError(.invalidByteCount) {
            try MetalBufferTransfer.validateAllocationByteCount(9, maximum: 8)
        }
        expectTransferError(.invalidByteCount) {
            _ = try MetalBufferTransfer.validatedRange(offset: 0, count: 0, limit: 8)
        }
        expectTransferError(.invalidByteCount) {
            _ = try MetalBufferTransfer.validatedRange(offset: 0, count: -1, limit: 8)
        }
        expectTransferError(.invalidRange) {
            _ = try MetalBufferTransfer.validatedRange(offset: -1, count: 1, limit: 8)
        }
        expectTransferError(.invalidRange) {
            _ = try MetalBufferTransfer.validatedRange(offset: 7, count: 2, limit: 8)
        }
        expectTransferError(.invalidRange) {
            _ = try MetalBufferTransfer.validatedRange(
                offset: Int.max,
                count: 1,
                limit: Int.max
            )
        }
    }

    @Test("[Unit][VOX-ERR-001][VOX-MTL-007] nonshared storage rejects before access")
    func nonsharedStorageRejectsBeforeAccess() throws {
        let context = try MetalExecutionContext()
        try context.withMetalHandles { device, queue in
            let privateBuffer = try #require(
                device.makeBuffer(length: 8, options: [.storageModePrivate])
            )
            expectTransferError(.unsupportedStorageMode) {
                try MetalBufferTransfer.write([1], to: privateBuffer, offset: 0)
            }

            let writer = try #require(queue.makeCommandBuffer())
            writer.commit()
            writer.waitUntilCompleted()
            expectTransferError(.unsupportedStorageMode) {
                _ = try MetalBufferTransfer.readBytes(
                    from: privateBuffer,
                    offset: 0,
                    count: 1,
                    after: writer
                )
            }

            #if os(macOS)
                if let managedBuffer = device.makeBuffer(
                    length: 8,
                    options: [.storageModeManaged]
                ) {
                    expectTransferError(.unsupportedStorageMode) {
                        try MetalBufferTransfer.write(
                            [1],
                            to: managedBuffer,
                            offset: 0
                        )
                    }
                }
            #endif
        }
    }

    @Test("[Unit][VOX-CON-004][VOX-MTL-014] readback requires completed writer")
    func readbackRequiresCompletedWriter() throws {
        expectTransferError(.commandNotCompleted) {
            try MetalBufferTransfer.validateCompletedStatus(.notEnqueued)
        }
        expectTransferError(.commandNotCompleted) {
            try MetalBufferTransfer.validateCompletedStatus(.enqueued)
        }
        expectTransferError(.commandNotCompleted) {
            try MetalBufferTransfer.validateCompletedStatus(.committed)
        }
        expectTransferError(.commandNotCompleted) {
            try MetalBufferTransfer.validateCompletedStatus(.scheduled)
        }
        expectTransferError(.commandFailed) {
            try MetalBufferTransfer.validateCompletedStatus(.error)
        }
        do {
            try MetalBufferTransfer.validateCompletedStatus(.completed)
        } catch {
            #expect(Bool(false), "Expected completed status to pass.")
        }

        let context = try MetalExecutionContext()
        try context.withMetalHandles { device, queue in
            let buffer = try MetalBufferTransfer.makeSharedBuffer(
                copying: [0x42],
                using: device
            )
            let writer = try #require(queue.makeCommandBuffer())
            expectTransferError(.commandNotCompleted) {
                _ = try MetalBufferTransfer.readBytes(
                    from: buffer,
                    offset: 0,
                    count: 1,
                    after: writer
                )
            }
        }
    }

    @Test("[Unit][VOX-CON-004] inline binding is small copied data only")
    func inlineBindingIsSmallCopiedDataOnly() throws {
        let context = try MetalExecutionContext()
        try context.withMetalHandles { _, queue in
            let commandBuffer = try #require(queue.makeCommandBuffer())
            let encoder = try #require(commandBuffer.makeComputeCommandEncoder())
            expectTransferError(.invalidInlineBinding) {
                try MetalBufferTransfer.setInlineBytes([], on: encoder, index: 0)
            }
            expectTransferError(.invalidInlineBinding) {
                try MetalBufferTransfer.setInlineBytes(
                    Array(
                        repeating: 0,
                        count: MetalBufferTransfer.maximumInlineByteCount + 1
                    ),
                    on: encoder,
                    index: 0
                )
            }
            expectTransferError(.invalidInlineBinding) {
                try MetalBufferTransfer.setInlineBytes([1], on: encoder, index: -1)
            }
            try MetalBufferTransfer.setInlineBytes(
                Array(0..<28),
                on: encoder,
                index: 0
            )
            encoder.endEncoding()
        }
    }

    @Test("[Unit][VOX-REP-008][VOX-SEC-001] scalar words serialize explicitly")
    func scalarWordsSerializeExplicitly() throws {
        let words: [UInt32] = [
            0x0000_0000,
            0x0000_0001,
            0x1234_5678,
            Float(1).bitPattern,
            UInt32(bitPattern: -2),
            0x89AB_CDEF,
            0xFFFF_FFFF,
        ]
        let bytes = try MetalKernelParameterBytes.littleEndianWords(words)

        #expect(bytes.count == 28)
        #expect(Array(bytes[0..<4]) == [0x00, 0x00, 0x00, 0x00])
        #expect(Array(bytes[4..<8]) == [0x01, 0x00, 0x00, 0x00])
        #expect(Array(bytes[8..<12]) == [0x78, 0x56, 0x34, 0x12])
        #expect(Array(bytes[12..<16]) == [0x00, 0x00, 0x80, 0x3F])
        #expect(Array(bytes[16..<20]) == [0xFE, 0xFF, 0xFF, 0xFF])
        #expect(Array(bytes[20..<24]) == [0xEF, 0xCD, 0xAB, 0x89])
        #expect(Array(bytes[24..<28]) == [0xFF, 0xFF, 0xFF, 0xFF])
        #expect(try MetalKernelParameterBytes.littleEndianWords([1, 2]).count == 8)
        #expect(try MetalKernelParameterBytes.littleEndianWords([1]).count == 4)

        do {
            _ = try MetalKernelParameterBytes.byteCount(forWordCount: -1)
            #expect(Bool(false), "Expected negative word count to reject.")
        } catch MetalKernelParameterBytesError.invalidWordCount {}
        do {
            _ = try MetalKernelParameterBytes.byteCount(forWordCount: Int.max)
            #expect(Bool(false), "Expected word-count overflow to reject.")
        } catch MetalKernelParameterBytesError.byteCountOverflow {}
    }

    @Test("[Unit][VOX-ERR-001][VOX-MTL-014] kernel buffer faults classify typed")
    func kernelBufferFaultsClassifyTyped() {
        #expect(
            MetalKernelBufferPreparationFailure.classify(
                MetalBufferTransferError.invalidByteCount
            ) == .allocation
        )
        #expect(
            MetalKernelBufferPreparationFailure.classify(
                MetalBufferTransferError.bufferAllocationFailed
            ) == .allocation
        )
        for error in [
            MetalBufferTransferError.invalidRange,
            .unsupportedStorageMode,
            .invalidInlineBinding,
            .commandNotCompleted,
            .commandFailed,
        ] {
            #expect(
                MetalKernelBufferPreparationFailure.classify(error)
                    == .execution
            )
        }
        #expect(
            MetalKernelBufferPreparationFailure.classify(
                MetalKernelParameterBytesError.byteCountOverflow
            ) == .execution
        )
    }

    @Test("[Concurrency][VOX-CON-003][VOX-MTL-004] independent transfers do not alias")
    func independentTransfersDoNotAlias() async throws {
        let context = try MetalExecutionContext()
        try await withThrowingTaskGroup(of: Int.self) { group in
            for taskIndex in 0..<24 {
                group.addTask {
                    let payload = (0..<13).map {
                        UInt8(truncatingIfNeeded: taskIndex &* 19 &+ $0)
                    }
                    let (upload, buffer, writer) = try context.withMetalHandles {
                        device, queue in
                        let upload = try MetalBufferTransfer.makeSharedBuffer(
                            copying: payload,
                            using: device
                        )
                        let buffer = try #require(
                            device.makeBuffer(
                                length: payload.count,
                                options: [.storageModeShared]
                            )
                        )
                        let writer = try #require(queue.makeCommandBuffer())
                        let blit = try #require(
                            writer.makeBlitCommandEncoder()
                        )
                        blit.copy(
                            from: upload,
                            sourceOffset: 0,
                            to: buffer,
                            destinationOffset: 0,
                            size: payload.count
                        )
                        blit.endEncoding()
                        return (upload, buffer, writer)
                    }
                    writer.commit()
                    await writer.completed()
                    withExtendedLifetime(upload) {}
                    #expect(
                        try MetalBufferTransfer.readBytes(
                            from: buffer,
                            offset: 0,
                            count: payload.count,
                            after: writer
                        ) == payload
                    )
                    return taskIndex
                }
            }

            var completed = Set<Int>()
            for try await taskIndex in group {
                #expect(completed.insert(taskIndex).inserted)
            }
            #expect(completed.count == 24)
        }
    }

    private func expectTransferError(
        _ expected: MetalBufferTransferError,
        _ operation: () throws -> Void
    ) {
        do {
            try operation()
            #expect(Bool(false), "Expected a typed transfer failure.")
        } catch let error as MetalBufferTransferError {
            #expect(error == expected)
        } catch {
            #expect(Bool(false), "Expected MetalBufferTransferError.")
        }
    }
}
