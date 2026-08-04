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
- ``ProvenanceID``

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

### Image descriptor

- ``ImageDescriptor``
- ``ImageDescriptorError``

### Value transformations

- ``ValueTransform``
- ``LinearValueTransformDescriptor``
- ``ValueTransformComposition``
- ``LookupTableDescriptor``

### Canonical time

- ``CanonicalInstant``
- ``CanonicalInstantError``

### Storage contract

- ``LogicalSampleBinding``
- ``StorageRepresentationDescriptor``
- ``DecodedStridedRepresentation``
- ``OpaqueRepresentation``
- ``StorageRepresentationLocality``
- ``StorageSnapshotHandle``
- ``StorageReadAuthority``
- ``RegionReadTransaction``
- ``RegionReadResult``
- ``RegionFillCapability``
- ``ImageStorageContract``
- ``AnyImageStorage``
- ``StorageContractError``

### Content identity

- ``DigestAlgorithm``
- ``ContentScope``
- ``ContentID``
- ``ContentProjectionReference``
- ``ContentProjectionVersion``
- ``ContentProjectionReferenceError``
- ``ContentIdentityError``

### Metadata

- ``MetadataPrivacyClass``
- ``MetadataKey``
- ``AnyMetadataKey``
- ``MetadataKeyError``
- ``MetadataFloatingPoint``
- ``MetadataFloatingPointError``
- ``MetadataBinary``
- ``MetadataValue``
- ``MetadataValueError``
- ``MetadataArray``
- ``MetadataObject``
- ``MetadataEntry``
- ``MetadataCollection``
- ``MetadataCollectionError``
- ``MetadataMultiplicityPolicy``
- ``TypedMetadataEntry``
- ``MetadataReadError``

### Canonical metadata JSON

- ``CanonicalMetadataJSON``
- ``CanonicalMetadataDocument``
- ``CanonicalMetadataIngressLimits``
- ``CanonicalMultiplicityContext``
- ``MetadataSchemaVersion``
- ``MetadataSchemaReference``
- ``MetadataSchemaReferenceError``
- ``MetadataJSONIngressError``
- ``MetadataJSONEmissionError``
- ``CodedConcept``
- ``CodedConceptError``

### Provenance

- ``ProvenanceKind``
- ``ExecutionClaimToken``
- ``ExecutionComponentReference``
- ``ExecutionApproximationStatus``
- ``ExecutionProvenanceClaim``
- ``ExecutionClaimError``
- ``ProvenanceRecord``
- ``ProvenanceActivity``
- ``ProvenanceRecordError``
- ``ProvenanceGraph``
- ``ProvenanceGraphLimits``
- ``ProvenanceGraphError``
- ``CanonicalProvenanceJSON``
- ``ProvenanceJSONEmissionError``
- ``SoftwareIdentity``
- ``OperationProvenance``
- ``ProvenanceInputRole``
- ``ProvenanceInput``
- ``ProvenanceParentReference``
- ``ProvenanceValidationClaim``
- ``ValidationEvidenceID``
- ``ProvenanceClaimError``
- ``ProvenanceWarningCode``
- ``ProvenanceWarningSchemaVersion``
- ``ProvenanceWarningSeverity``
- ``ProvenanceWarning``
- ``ProvenanceWarningError``

### Data identity

- ``SourceIdentity``
- ``SourceIdentityError``
- ``DataIdentityReference``
- ``DataIdentityReferenceError``
- ``DerivationOperationToken``
- ``DerivationInputRole``
- ``DerivationInput``
- ``DerivationImplementationReference``
- ``DerivationIdentity``
- ``DerivationIdentityError``
- ``DataIdentity``
- ``DataIdentityError``

### Common errors

- ``DataModelError``

### Project documents

- <doc:Architecture>
- <doc:Requirements>
