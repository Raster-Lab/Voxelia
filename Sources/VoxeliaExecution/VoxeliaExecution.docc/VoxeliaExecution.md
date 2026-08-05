# ``VoxeliaExecution``

Operations, scheduling, cancellation, progress and result caching.

## M0 status

This target is part of the repository and dependency scaffold. Its substantive
public API is introduced only by reviewed milestone specifications.

## Direct dependencies

`VoxeliaStorage`

## Topics

### Coordinated reads

- ``StorageReadCoordinator``
- ``CoordinatedReadResult``
- ``ReadRetentionToken``

### Coordinated identity

- ``MetadataIdentityCoordinator``
- ``CoordinatedMetadataIdentity``

### Result caching

- ``ContentResultCache``
- ``ContentResultCacheError``

### Operations

- ``RegionExtractionOperation``
- ``RegionExtractionError``
- ``WindowLevelOperation``
- ``WindowLevelError``
- ``ResampleNearestOperation``
- ``ResampleError``
- ``CompositeLayersOperation``
- ``CompositeError``
- ``InvertDisplayOperation``
- ``InvertDisplayError``
- ``TransposeAxesOperation``
- ``TransposeError``
- ``SqueezeAxesOperation``
- ``SqueezeError``
- ``ResampleLinearOperation``
- ``ResampleLinearError``
- ``ResampleCubicOperation``
- ``ResampleCubicError``
- ``ObliqueSliceOperation``
- ``ObliqueSliceError``
- ``ProjectIntensityOperation``
- ``ProjectionMode``
- ``ProjectIntensityError``
- ``ImplementationRegistry``
- ``RegisteredImplementation``
- ``RegistrationError``

### Brick requests

- ``BrickRequestBroker``
- ``BrickRequestError``
- ``BrickResultCache``
- ``BrickCacheError``

### Publication

- ``PublicationCoordinator``
- ``PublicationReceipt``
- ``PublicationError``

### Project documents

- <doc:Architecture>
- <doc:Requirements>
