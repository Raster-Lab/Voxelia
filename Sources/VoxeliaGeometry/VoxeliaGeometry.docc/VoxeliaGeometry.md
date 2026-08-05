# ``VoxeliaGeometry``

Point, curve, mesh and geometry data models.

## Canonical mesh status

Accepted geometry records provide the immutable canonical triangle-mesh
payload used by the M6 extraction arc. Extraction algorithms, provenance-
bearing publication, stable geometry bytes and backend acceleration remain
separate governed contracts.

## Direct dependencies

`VoxeliaCore`, `VoxeliaSpatial`

## Topics

### Geometry vocabularies

- ``GeometryKind``
- ``GeometryAttributeSemantic``
- ``GeometryAttributeDescriptor``
- ``MeshPrimitive``
- ``IndexType``
- ``TriangleMeshTopology``
- ``TriangleMeshTopologyError``
- ``TriangleMeshPositionDomain``
- ``TriangleMeshPositionDomainError``
- ``TriangleMeshVertexAttribute``
- ``TriangleMeshVertexAttributeError``
- ``TriangleMesh``
- ``TriangleMeshError``

### Project documents

- <doc:Architecture>
- <doc:Requirements>
