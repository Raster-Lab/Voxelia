# ``VoxeliaGeometry``

Point, curve, mesh and geometry data models.

## Canonical mesh status

Accepted geometry records provide the immutable canonical triangle-mesh
payload and scalar-surface request/publication values used by the M6 extraction
arc. The CPU reader and numerical kernel, stable geometry bytes and backend
acceleration remain separate governed contracts.

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

### Scalar-surface operation

- ``ScalarSurfaceExtractionLimits``
- ``ScalarSurfaceExtractionRequest``
- ``ScalarSurfaceExtractionPublicationContext``
- ``ScalarSurfaceExtractionResult``
- ``ScalarSurfaceExtractionError``

### Project documents

- <doc:Architecture>
- <doc:Requirements>
