# Architecture

The `VoxeliaGeometry` target follows the dependency and ownership rules in the
Voxelia Master Technical Architecture and Repository and Package Scaffold
Specification.

Canonical triangle meshes own finite binary64 position triples, checked
independent-triangle topology and exact non-position vertex-attribute bytes.
The position domain binds the Spatial-owned coordinate descriptor directly;
Geometry neither duplicates nor re-exports Spatial values. Mesh payloads are
immutable and backend-neutral. Stable geometry bytes, content identity,
provenance-bearing publication and acceleration adapters remain separately
governed boundaries.
