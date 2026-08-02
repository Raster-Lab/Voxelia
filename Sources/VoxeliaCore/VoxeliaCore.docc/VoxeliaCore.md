# ``VoxeliaCore``

Canonical scientific descriptors, identities, metadata and provenance.

## M1 status

The core data model begins with validated dynamic-rank image shapes and
immutable dynamic-rank indices. Shapes detect invalid extents and element-count
overflow; indices preserve the zero-based integer-coordinate convention while
leaving shape-aware bounds validation to access operations.

## Direct dependencies

`VoxeliaSpatial`

## Topics

### Shape model

- ``ImageShape``
- ``ShapeError``
- ``ImageIndex``

### Project documents

- <doc:Architecture>
- <doc:Requirements>
