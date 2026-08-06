# ``VoxeliaGeometry``

Point, curve, mesh and geometry data models.

## Canonical mesh status

Accepted geometry records provide the immutable canonical triangle-mesh
payload and scalar/labelled-surface request/publication values used by the M6
extraction arc. Geometry also owns the immutable deterministic vertex-normal
request/publication values consumed by the completed deterministic CPU
reference operation. Stable geometry bytes and backend acceleration remain
separate contracts.

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

### Labelled-surface operation

- ``LabelledSurfaceLabelSet``
- ``LabelledSurfaceExtractionLimits``
- ``LabelledSurfaceExtractionRequest``
- ``LabelledSurfaceExtractionPublicationContext``
- ``LabelledSurfaceExtractionResult``
- ``LabelledSurfaceExtractionError``

### Vertex-normal operation

- ``TriangleMeshVertexNormalGenerationLimits``
- ``TriangleMeshVertexNormalGenerationRequest``
- ``TriangleMeshVertexNormalGenerationPublicationContext``
- ``TriangleMeshVertexNormalGenerationResult``
- ``TriangleMeshVertexNormalGenerationError``

### Total-facet-area measurement

- ``PoweredLengthUnit``
- ``PoweredLengthUnitError``
- ``TriangleMeshTotalFacetAreaLimits``
- ``TriangleMeshTotalFacetAreaRequest``
- ``TriangleMeshTotalFacetAreaPublicationContext``
- ``TriangleMeshTotalFacetAreaMeasurement``
- ``TriangleMeshTotalFacetAreaResult``
- ``TriangleMeshTotalFacetAreaError``

### Project documents

- <doc:Architecture>
- <doc:Requirements>
