# VoxeliaInteraction

**Purpose:** Render generations, frame presentation, progressive sessions, picking and viewport synchronisation.

**Direct dependencies:** VoxeliaRendering

**Supported platforms:** Apple Silicon (`arm64`) on macOS 15+, iOS 18+, tvOS 18+ and visionOS 2+ — enforced by the manifest and the platform gate.

**Diagnostic status:** Diagnostic presentation support: stale frames are dropped by generation comparison; window-free by gate.
