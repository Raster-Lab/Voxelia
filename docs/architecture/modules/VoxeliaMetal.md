# VoxeliaMetal

**Purpose:** Metal compute kernels, device residency, telemetry and the device render paths.

**Direct dependencies:** VoxeliaExecution, VoxeliaRendering

**Supported platforms:** Apple Silicon (`arm64`) on macOS 15+, iOS 18+, tvOS 18+ and visionOS 2+ — enforced by the manifest and the platform gate.

**Diagnostic status:** Non-diagnostic by default: device entries are approximate or exact per their registrations, and diagnostic selection remains owner-gated.
