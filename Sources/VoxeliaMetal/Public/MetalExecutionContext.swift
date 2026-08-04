// SPDX-License-Identifier: MIT

import Metal
import VoxeliaCore

/// An error raised while acquiring the Metal execution context.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// device names, models or driver detail.
public enum MetalContextError: Error, Sendable, Equatable {
    case deviceUnavailable
    case commandQueueUnavailable
    case unsupportedCapability
}

/// The Metal execution context boundary selected by `ADR-0079`,
/// opening milestone M3.
///
/// The context acquires the system default device and a command queue
/// through capability detection only: no API accepts or exposes a
/// device name, commercial model or named Metal generation, and
/// device-specific behaviour keys off the closed capability class. The
/// class is marked unchecked-`Sendable` on the recorded justification
/// that `MTLDevice` and `MTLCommandQueue` are documented thread-safe —
/// a documented platform-contract reliance, not an unchecked invariant
/// of Voxelia code. Device and queue handles stay module-internal for
/// the kernel and residency increments.
public final class MetalExecutionContext: @unchecked Sendable {
    /// The closed capability-class token spelling detected by version
    /// one; it parses as the `ADR-0051` execution-claim capability
    /// class, so GPU-executed claims plug into the existing provenance
    /// discipline unchanged.
    public static let metal3CapabilityIdentifier = "org.voxelia.capability.metal3"

    /// The detected closed capability class.
    public let capabilityClass: ExecutionClaimToken
    /// Whether the device shares one memory space with the CPU; the
    /// shared-resource strategy requires this evidence.
    public let supportsUnifiedMemory: Bool
    /// The opaque platform registry identifier, exposed as runtime
    /// evidence only; it is not a name and selects nothing.
    public let deviceRegistryIdentifier: UInt64

    let device: any MTLDevice
    let commandQueue: any MTLCommandQueue

    /// Acquires the system default device and command queue with
    /// closed capability detection.
    ///
    /// - Throws: ``MetalContextError``.
    public init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw MetalContextError.deviceUnavailable
        }
        guard device.supportsFamily(.metal3) else {
            throw MetalContextError.unsupportedCapability
        }
        guard let commandQueue = device.makeCommandQueue() else {
            throw MetalContextError.commandQueueUnavailable
        }
        self.device = device
        self.commandQueue = commandQueue
        self.capabilityClass = try ExecutionClaimToken(
            rawValue: Self.metal3CapabilityIdentifier
        )
        self.supportsUnifiedMemory = device.hasUnifiedMemory
        self.deviceRegistryIdentifier = device.registryID
    }
}
