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

### Project documents

- <doc:Architecture>
- <doc:Requirements>
