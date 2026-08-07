# Voxelia

**Purpose:** Umbrella product re-exporting the eight stable general-purpose modules (ADR-0406).

**Direct dependencies:** VoxeliaSpatial, VoxeliaCore, VoxeliaStorage, VoxeliaExecution, VoxeliaImaging, VoxeliaGeometry, VoxeliaRendering, VoxeliaInteraction

**Supported platforms:** Apple Silicon (`arm64`) on macOS 15+, iOS 18+, tvOS 18+ and visionOS 2+ — enforced by the manifest and the platform gate.

**Diagnostic status:** The stable diagnostic surface: optional integrations are not re-exported, structurally.
