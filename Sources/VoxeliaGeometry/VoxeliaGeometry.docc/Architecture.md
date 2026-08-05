# Architecture

The `VoxeliaGeometry` target follows the dependency and ownership rules in the
Voxelia Master Technical Architecture and Repository and Package Scaffold
Specification.

Canonical triangle meshes own finite binary64 position triples, checked
independent-triangle topology and exact non-position vertex-attribute bytes.
The position domain binds the Spatial-owned coordinate descriptor directly;
Geometry neither duplicates nor re-exports Spatial values. Mesh payloads are
immutable and backend-neutral. The scalar-surface contract binds one unadmitted
request and caller-supplied publication context to an immutable, structurally
coherent mesh/identity/provenance result. The request retains Core's erased
immutable source-storage contract, but Geometry owns no storage implementation,
reader or backend execution state.
Stable geometry bytes, a mesh content projection, CPU extraction and
acceleration adapters remain separately governed boundaries.
