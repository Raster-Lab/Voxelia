// SPDX-License-Identifier: MIT

import Metal

/// An error raised by residency fulfilment.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// device detail or allocation sizes.
public enum MetalResidencyError: Error, Sendable, Equatable {
    case unsupportedResidencyPolicy
    case policyRequiresNoDeviceResidency
    case sharedStorageUnavailable
    case invalidByteCount
    case bufferAllocationFailed
}

/// The closed storage class selected for one fulfilled policy.
public enum MetalResidencySelection: Sendable, Hashable {
    /// One memory space visible to CPU and GPU.
    case shared
    /// Device-private storage optimised for repeated GPU access.
    case privateDevice
}

/// The residency fulfilment boundary selected by `ADR-0081`.
///
/// The manager maps the declared `ResidencyPolicy` vocabulary onto
/// storage classes through capability detection and never mutates a
/// declared policy: every unfulfillable request is a typed rejection,
/// so caller intent is never silently rewritten. Buffer handles stay
/// module-internal like the device itself. The manager is immutable and
/// stores only the checked execution context; allocated buffers remain
/// local to each request rather than becoming shared manager state.
public final class MetalResidencyManager: Sendable {
    private let context: MetalExecutionContext

    /// Creates a manager over one acquired context.
    public init(context: MetalExecutionContext) {
        self.context = context
    }

    /// Selects the storage class for one declared policy.
    ///
    /// - Throws: ``MetalResidencyError``.
    public func selection(
        for policy: ResidencyPolicy
    ) throws -> MetalResidencySelection {
        switch policy {
        case .automatic:
            guard context.supportsUnifiedMemory else {
                throw MetalResidencyError.sharedStorageUnavailable
            }
            return .shared
        case .shared:
            guard context.supportsUnifiedMemory else {
                throw MetalResidencyError.sharedStorageUnavailable
            }
            return .shared
        case .gpuOptimised:
            return .privateDevice
        case .cpuOnly:
            throw MetalResidencyError.policyRequiresNoDeviceResidency
        case .streamed, .sparse:
            throw MetalResidencyError.unsupportedResidencyPolicy
        }
    }

    /// Allocates one device buffer under a fulfilled policy.
    ///
    /// - Throws: ``MetalResidencyError``.
    func makeBuffer(
        byteCount: Int,
        policy: ResidencyPolicy
    ) throws -> any MTLBuffer {
        guard byteCount > 0 else {
            throw MetalResidencyError.invalidByteCount
        }
        let options: MTLResourceOptions
        switch try selection(for: policy) {
        case .shared:
            options = [.storageModeShared]
        case .privateDevice:
            options = [.storageModePrivate]
        }
        guard
            let buffer = context.withMetalHandles({ device, _ in
                device.makeBuffer(
                    length: byteCount,
                    options: options
                )
            })
        else {
            throw MetalResidencyError.bufferAllocationFailed
        }
        return buffer
    }
}
