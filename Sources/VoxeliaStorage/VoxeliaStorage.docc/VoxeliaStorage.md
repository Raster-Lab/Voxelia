# ``VoxeliaStorage``

Backend-neutral storage contracts and concrete storage implementations.

## M0 status

This target is part of the repository and dependency scaffold. Its substantive
public API is introduced only by reviewed milestone specifications.

## Direct dependencies

`VoxeliaCore`

## Topics

### Storage descriptors

- ``StorageKind``
- ``StoragePersistence``
- ``CodecIdentifier``
- ``CodecIdentifierError``
- ``CompressedRegionAccess``

### Bricked volumes

- ``BrickResolutionLevel``
- ``BrickGridDescriptor``
- ``BrickIdentity``
- ``BrickVocabularyError``
- ``BrickEvictionConsideration``
- ``CacheFormatID``
- ``CacheFormatVersion``
- ``BrickCacheEvent``
- ``BrickCacheEventSink``
- ``BrickCacheVocabularyError``
- ``BrickedImageStorage``
- ``BrickedStorageError``
- ``BrickStatistics``
- ``BrickStatisticsError``

### Canonical document persistence

- ``CanonicalDocumentStore``
- ``CanonicalDocumentName``
- ``CanonicalDocumentStoreError``
- ``CanonicalRecordArchival``
- ``ArchivedRecordReceipt``
- ``CanonicalArchivalError``

### Project documents

- <doc:Architecture>
- <doc:Requirements>
