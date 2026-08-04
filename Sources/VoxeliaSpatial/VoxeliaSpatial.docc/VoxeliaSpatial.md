# ``VoxeliaSpatial``

Spatial coordinate systems, units, transforms and geometry primitives.

## M0 status

This target is part of the repository and dependency scaffold. Its substantive
public API is introduced only by reviewed milestone specifications.

## Direct dependencies

None.

## Topics

### Units

- ``MeasurementUnit``
- ``MeasurementUnitError``
- ``UnitDimension``

### Identifiers

- ``VoxeliaStringIdentifier``
- ``VoxeliaStringIdentifierError``
- ``AxisID``

### Axis model

- ``AxisSemantic``
- ``AxisSampling``
- ``AxisSamplingError``
- ``AxisDescriptor``
- ``AxisDescriptorError``

### Coordinate spaces

- ``CoordinateSpaceID``
- ``CoordinateHandedness``
- ``ExternalFrameReference``
- ``ExternalFrameReferenceError``

### Matrices

- ``Matrix4x4Double``
- ``Matrix4x4DoubleError``

### Spatial-axis mappings

- ``SpatialAxisMapping``
- ``SpatialAxisMappingError``

### Spatial primitives

- ``Point3D``
- ``Vector3D``
- ``Plane3D``
- ``Ray3D``
- ``SpatialPrimitiveError``
- ``AxisAlignedBounds3D``
- ``SpatialBoundsError``
- ``SpatialTransformKind``

### Project documents

- <doc:Architecture>
- <doc:Requirements>
