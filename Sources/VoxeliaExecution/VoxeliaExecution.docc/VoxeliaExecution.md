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

### Progress reporting

- ``ProgressObservation``
- ``ProgressObserver``
- ``ProgressSequence``
- ``ProgressReportingError``
- ``discardingProgressObserver``

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
- ``GridResampleOperation``
- ``GridResampleError``
- ``LevelSelectOperation``
- ``LevelSelectError``
- ``ThresholdOperation``
- ``ThresholdError``
- ``MaskApplyOperation``
- ``MaskApplyError``
- ``ArithmeticOperation``
- ``ArithmeticOperator``
- ``ArithmeticOperand``
- ``ArithmeticError``
- ``ConvolveOperation``
- ``ConvolutionBoundary``
- ``ConvolveError``
- ``GaussianFilterOperation``
- ``GaussianFilterError``
- ``MorphologyOperation``
- ``MorphologyOperator``
- ``MorphologyError``
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
- ``StudyCacheGenerator``
- ``StudyCacheBrick``
- ``StudyCacheProgress``
- ``FirstUsefulImagePlan``
- ``FirstUsefulImagePlane``
- ``FirstUsefulImageAssembly``
- ``FirstUsefulImageError``

### Publication

- ``PublicationCoordinator``
- ``PublicationReceipt``
- ``PublicationError``

### Project documents

- <doc:Architecture>
- <doc:Requirements>
