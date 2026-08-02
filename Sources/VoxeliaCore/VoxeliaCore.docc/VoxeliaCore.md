# ``VoxeliaCore``

Canonical scientific descriptors, identities, metadata and provenance.

## M1 status

The core data model begins with validated dynamic-rank image shapes and
immutable dynamic-rank indices. Shapes detect invalid extents and element-count
overflow; indices preserve the zero-based integer-coordinate convention while
leaving shape-aware bounds validation to access operations. Validated scalar
formats describe integer and floating containers without inferring packed
storage semantics.

## Direct dependencies

`VoxeliaSpatial`

## Topics

### Identifiers

- ``DataObjectID``

### Versioning

- ``SemanticVersion``
- ``SemanticVersionError``

### Image coordinates and regions

- ``ImageShape``
- ``ShapeError``
- ``ImageIndex``
- ``ImageRegion``
- ``RegionError``

### Scalar representation

- ``ScalarType``
- ``ScalarValueRange``
- ``ByteOrder``
- ``ScalarFormat``

### Component model

- ``ComponentInterpretation``
- ``ComponentLayout``
- ``ComponentDescriptor``

### Image semantics

- ``ImageSemantic``

### Value transformations

- ``LookupTableDescriptor``

### Content identity

- ``DigestAlgorithm``
- ``ContentScope``

### Metadata

- ``MetadataPrivacyClass``

### Common errors

- ``DataModelError``

### Project documents

- <doc:Architecture>
- <doc:Requirements>
