// SPDX-License-Identifier: MIT

import Metal

/// One payload-free failure from the internal Metal byte-transfer boundary.
enum MetalBufferTransferError: Error, Sendable, Equatable {
    case invalidByteCount
    case invalidRange
    case unsupportedStorageMode
    case bufferAllocationFailed
    case invalidInlineBinding
    case commandNotCompleted
    case commandFailed
}

/// The single reviewed host-memory boundary selected by `ADR-0186`.
///
/// All signatures own bytes or Metal objects and expose no pointer. Callers
/// retain invocation-local resources through command completion and provide
/// exclusive logical access to every transferred range.
enum MetalBufferTransfer {
    static let maximumInlineByteCount = 256

    /// Allocates one shared buffer and synchronously copies owned bytes into it.
    static func makeSharedBuffer(
        copying bytes: [UInt8],
        using device: any MTLDevice
    ) throws -> any MTLBuffer {
        try validateAllocationByteCount(
            bytes.count,
            maximum: device.maxBufferLength
        )
        guard
            let buffer = device.makeBuffer(
                length: bytes.count,
                options: [.storageModeShared]
            )
        else {
            throw MetalBufferTransferError.bufferAllocationFailed
        }
        guard buffer.length >= bytes.count else {
            throw MetalBufferTransferError.bufferAllocationFailed
        }
        try write(bytes, to: buffer, offset: 0)
        return buffer
    }

    /// Synchronously writes owned bytes into one validated shared-buffer range.
    static func write(
        _ bytes: [UInt8],
        to buffer: any MTLBuffer,
        offset: Int
    ) throws {
        _ = try validatedRange(
            offset: offset,
            count: bytes.count,
            limit: buffer.length
        )
        guard buffer.storageMode == .shared else {
            throw MetalBufferTransferError.unsupportedStorageMode
        }
        unsafe buffer.contents().advanced(by: offset).copyMemory(
            from: bytes,
            byteCount: bytes.count
        )
    }

    /// Binds one small owned parameter block by Metal's synchronous copy API.
    static func setInlineBytes(
        _ bytes: [UInt8],
        on encoder: any MTLComputeCommandEncoder,
        index: Int
    ) throws {
        guard
            !bytes.isEmpty,
            bytes.count <= maximumInlineByteCount,
            index >= 0
        else {
            throw MetalBufferTransferError.invalidInlineBinding
        }
        unsafe encoder.setBytes(bytes, length: bytes.count, index: index)
    }

    /// Copies one shared-buffer range after the same writer command completed.
    static func readBytes(
        from buffer: any MTLBuffer,
        offset: Int,
        count: Int,
        after writer: any MTLCommandBuffer
    ) throws -> [UInt8] {
        _ = try validatedRange(
            offset: offset,
            count: count,
            limit: buffer.length
        )
        guard buffer.storageMode == .shared else {
            throw MetalBufferTransferError.unsupportedStorageMode
        }
        try validateCompletedStatus(writer.status)
        return unsafe Array(
            UnsafeBufferPointer(
                start: buffer.contents().advanced(by: offset).bindMemory(
                    to: UInt8.self,
                    capacity: count
                ),
                count: count
            )
        )
    }

    static func validateAllocationByteCount(
        _ byteCount: Int,
        maximum: Int
    ) throws {
        guard byteCount > 0, maximum >= 0, byteCount <= maximum else {
            throw MetalBufferTransferError.invalidByteCount
        }
    }

    static func validatedRange(
        offset: Int,
        count: Int,
        limit: Int
    ) throws -> Range<Int> {
        guard count > 0 else {
            throw MetalBufferTransferError.invalidByteCount
        }
        guard offset >= 0, limit >= 0 else {
            throw MetalBufferTransferError.invalidRange
        }
        let (end, overflow) = offset.addingReportingOverflow(count)
        guard !overflow, end <= limit else {
            throw MetalBufferTransferError.invalidRange
        }
        return offset..<end
    }

    static func validateCompletedStatus(
        _ status: MTLCommandBufferStatus
    ) throws {
        switch status {
        case .completed:
            return
        case .error:
            throw MetalBufferTransferError.commandFailed
        default:
            throw MetalBufferTransferError.commandNotCompleted
        }
    }
}
