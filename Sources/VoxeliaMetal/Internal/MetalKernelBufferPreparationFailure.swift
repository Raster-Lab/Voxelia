// SPDX-License-Identifier: MIT

/// The public-facing class of one internal kernel buffer-preparation failure.
enum MetalKernelBufferPreparationFailure: Sendable, Equatable {
    case allocation
    case execution

    /// Keeps capacity/allocation failures distinct from storage and coherency
    /// faults without exposing internal transfer details.
    static func classify(_ error: any Error) -> Self {
        guard let transferError = error as? MetalBufferTransferError else {
            return .execution
        }
        switch transferError {
        case .invalidByteCount, .bufferAllocationFailed:
            return .allocation
        case .invalidRange, .unsupportedStorageMode, .invalidInlineBinding,
            .commandNotCompleted, .commandFailed:
            return .execution
        }
    }
}
