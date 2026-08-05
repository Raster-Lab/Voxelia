# VoxeliaGeometry

**Purpose:** Point, curve, mesh and geometry data models.

**Direct dependencies:** VoxeliaCore, VoxeliaSpatial

`VoxeliaSpatial` owns the coordinate-space values consumed by canonical
Geometry APIs; Geometry does not redeclare or re-export them. The direct edge is
governed by accepted `ADR-0187` and controlled correction `CCR-0027`.

The canonical `TriangleMesh` payload owns one finite binary64 position domain,
one independently checked triangle topology and ordered non-position vertex
attributes with exact descriptor-sized bytes. Its coordinate descriptor is the
position domain's Spatial-owned value. The payload is immutable and `Sendable`
but intentionally has no stable wire, hash/content identity, provenance
aggregate or backend residency contract.
