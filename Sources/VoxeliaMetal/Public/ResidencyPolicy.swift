// SPDX-License-Identifier: MIT

/// A requested policy for CPU/shared/GPU resource residency.
///
/// This value declares intent only. It does not imply that a device supports a
/// particular storage mode or that a residency manager has fulfilled it.
public enum ResidencyPolicy: Sendable, Codable {
    /// Let the residency manager select an appropriate policy.
    case automatic

    /// Keep the authoritative resource on the CPU.
    case cpuOnly

    /// Prefer storage directly accessible to both the CPU and GPU.
    case shared

    /// Prefer a representation optimized for repeated GPU access.
    case gpuOptimised

    /// Stream a bounded working set as the workload advances.
    case streamed

    /// Request sparse residency where the device and representation support it.
    case sparse
}
