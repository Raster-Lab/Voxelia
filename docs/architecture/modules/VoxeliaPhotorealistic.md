# VoxeliaPhotorealistic

**Purpose:** Optional photorealistic rendering module (`ADR-0385`). Not
re-exported by the umbrella `Voxelia` product: a host that does not link
this product has no photorealistic code at all, and conventional
diagnostic rendering in `VoxeliaRendering` neither depends on nor knows
about this module.

**Direct dependencies:** VoxeliaCore

**M8 status:** Foundation only — the activation seam and the closed
interactive/progressive/reference quality-mode vocabulary. The physics,
determinism, presentation and validation arcs of the `ADR-0384` queue
build into this module.
