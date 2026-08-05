# VoxeliaGeometry

**Purpose:** Point, curve, mesh and geometry data models.

**Direct dependencies:** VoxeliaCore, VoxeliaSpatial

`VoxeliaSpatial` owns the coordinate-space values consumed by canonical
Geometry APIs; Geometry does not redeclare or re-export them. The direct edge is
governed by accepted `ADR-0187` and controlled correction `CCR-0027`.
