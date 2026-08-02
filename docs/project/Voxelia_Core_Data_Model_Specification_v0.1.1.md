---
document_id: VOXELIA-CDMS
title: "Voxelia Core Data Model Specification"
version: "0.1.1"
status: "Corrective Release"
document_type: "Core Data Model Specification"
project: "Voxelia"
platform_policy: "Apple Silicon ARM64 and Apple operating systems only"
licence: "MIT"
language: "en-GB"
date: "2026-08-02"
owner: "Voxelia Project"
governing_documents:
  - "Voxelia Project Foundation v0.1.1"
  - "Voxelia Master Technical Architecture v0.1.1"
  - "Voxelia Requirements Baseline v0.1.1"
  - "Voxelia Validation and Benchmark Strategy v0.1.1"
  - "Voxelia Repository and Package Scaffold Specification v0.1.1"
repository: "To be established"
supersedes: "Voxelia Core Data Model Specification v0.1"
superseded_by: null
classification: "Public"
---

# Voxelia Core Data Model Specification v0.1.1

> **Platform applicability:** Voxelia exclusively targets Apple Silicon ARM64 hardware and Apple operating systems. References to operation across more than one platform mean only macOS, iOS/iPadOS, visionOS and tvOS within the Apple ecosystem. No alternate processor architecture, operating system, hosted Swift toolchain, renderer or compatibility target is within scope.

## Document control

| Field | Value |
|---|---|
| Document | Voxelia Core Data Model Specification |
| Document identifier | `VOXELIA-CDMS` |
| Version | 0.1.1 |
| Status | Corrective Release |
| Date | 2 August 2026 |
| Project | Voxelia |
| Governing documents | Voxelia Project Foundation v0.1.1; Voxelia Master Technical Architecture v0.1.1; Voxelia Requirements Baseline v0.1.1; Voxelia Validation and Benchmark Strategy v0.1.1; Voxelia Repository and Package Scaffold Specification v0.1.1 |
| Licence | MIT |
| Language | British English |
| Principal modules | `VoxeliaSpatial`, `VoxeliaCore`, `VoxeliaStorage`, `VoxeliaGeometry` |
| Related future modules | `VoxeliaSegmentation`, `VoxeliaRegistration`, `VoxeliaDICOMKit`, `VoxeliaCompression` |
| Intended audience | Project maintainers, systems engineers, architects, Swift implementers, algorithm developers, validation engineers, rendering developers, DICOM integrators and downstream product teams |

### Revision history

| Version | Date | Summary |
|---|---:|---|
| 0.1 | 2026-08-02 | Initial specification of the canonical Voxelia image, volume, axis, spatial, region, view, identity, metadata, provenance, storage, geometry, segmentation and transform data models. |

### Approval record

This version is a draft for architecture, API, implementation and validation review. Formal approval roles, signatories, repository commit and release association shall be added when project governance is established.

---

## 1. Purpose

This document defines the canonical data model on which Voxelia processing, rendering, storage, validation and interoperability shall be built.

It specifies:

- dynamic-rank image shape and indexing;
- scalar and component representation;
- axis semantics;
- image and volume descriptors;
- value transformations;
- coordinate spaces;
- affine, rectilinear and frame-set geometry;
- spatial transforms;
- regions and views;
- immutable data handles;
- content, source and derivation identity;
- typed and namespaced metadata;
- provenance records and derivation graphs;
- backend-neutral storage contracts;
- contiguous, mapped, tiled, bricked and compressed storage descriptors;
- geometry and mesh data;
- segmentation data;
- registration and transform results;
- canonical serialisation rules;
- concurrency and ownership semantics;
- error handling;
- DICOMKit adapter boundaries;
- validation obligations; and
- Milestone M1 acceptance criteria.

The core data model is the most stable part of Voxelia. It shall remain independent of:

- DICOM object representation;
- Metal textures and buffers;
- RealityKit entities;
- Model I/O assets;
- Core Image objects;
- VTK and ITK classes;
- one host application; and
- one physical storage layout.

---

## 2. Authority and precedence

The **Voxelia Project Foundation v0.1.1** is the highest-level project-specific authority.

The **Voxelia Master Technical Architecture v0.1.1** establishes the canonical-model architecture.

The **Voxelia Requirements Baseline v0.1.1** establishes the normative data, spatial, region, metadata, geometry and storage requirements.

The **Voxelia Validation and Benchmark Strategy v0.1.1** establishes how model invariants and conversions shall be verified.

The **Voxelia Repository and Package Scaffold Specification v0.1.1** establishes module ownership and permitted dependencies.

If this specification conflicts with the Project Foundation, the Foundation takes precedence. If it conflicts with another governing document without conflicting with the Foundation, the discrepancy shall be resolved before implementation by:

- correcting this specification;
- revising the governing architecture or requirement; or
- approving an Architecture Decision Record.

---

## 3. Scope

### 3.1 Included

This specification applies to the canonical public and package-level models owned by:

- `VoxeliaSpatial`;
- `VoxeliaCore`;
- `VoxeliaStorage`;
- `VoxeliaGeometry`;
- shared model portions later used by `VoxeliaSegmentation`; and
- shared transform and result portions later used by `VoxeliaRegistration`.

### 3.2 Excluded

This specification does not define:

- operation scheduling;
- processing kernels;
- Metal resource allocation;
- rendering scene models;
- DICOM parsing;
- codec implementation;
- registration optimisation algorithms;
- segmentation algorithms;
- network transport;
- persistent database schemas;
- browser serialisation protocols; or
- application workflow.

It defines the data contracts those systems shall consume and produce.

---

## 4. Requirements allocation

This specification principally addresses:

- `VOX-ARC-002` through `VOX-ARC-008`;
- `VOX-API-001` through `VOX-API-010`;
- `VOX-DAT-001` through `VOX-DAT-015`;
- `VOX-SPA-001` through `VOX-SPA-014`;
- `VOX-RGN-001` through `VOX-RGN-009`;
- `VOX-META-001` through `VOX-META-011`;
- `VOX-GEO-001` through `VOX-GEO-011`;
- `VOX-SEG-001` through `VOX-SEG-010`;
- `VOX-REG-001` through `VOX-REG-010`;
- `VOX-STO-001` through `VOX-STO-012`;
- `VOX-BRK-001` through `VOX-BRK-011`;
- `VOX-CON-003`;
- `VOX-CON-010`;
- `VOX-SEC-001`;
- `VOX-SEC-002`;
- `VOX-VAL-002` through `VOX-VAL-005`; and
- the data-model portions of `VOX-VS1-*`.

Derived implementation requirements in this document shall retain traceability to those identifiers.

---

## 5. Design principles

### 5.1 Semantics before representation

A volume is not a texture and an image is not a byte array.

The canonical model shall describe:

- what the samples mean;
- how they are indexed;
- how indices map into physical space;
- how stored values map into authoritative values;
- how components are interpreted;
- where the data originated;
- how it was derived; and
- how it may be accessed.

Physical storage and GPU residency are separate concerns.

### 5.2 Immutable authoritative data

Published canonical data handles shall be immutable.

A change shall produce a new object through:

- a builder before publication;
- a transaction that commits a new immutable result; or
- a versioned Voxelia operation.

Untracked in-place mutation is prohibited because it invalidates:

- content identity;
- cache keys;
- provenance;
- validation evidence; and
- concurrent readers.

### 5.3 Dynamic rank with optimised common cases

The canonical image model shall support dynamic rank.

Convenience wrappers shall provide validated two-dimensional, three-dimensional and four-dimensional behaviour without duplicating storage.

### 5.4 Explicit spaces and transforms

Index space and physical space shall never be conflated.

Every geometry, measurement and transform shall identify its coordinate spaces.

### 5.5 Backend neutrality

Canonical public types shall not expose backend-specific resources.

Metal, CPU, RealityKit and other representations shall be derived and cached by their owning modules.

### 5.6 Format neutrality

Source-format details may be retained as namespaced metadata and provenance, but shall not replace canonical fields.

### 5.7 Validation by construction

Initialisers shall reject structurally invalid states where practical.

Where full validation requires asynchronous storage access, the model shall distinguish:

- structurally valid;
- integrity checked;
- content verified; and
- diagnostically validated.

### 5.8 Stable identity

Immutable data shall have a stable identity suitable for:

- cache lookup;
- provenance;
- distributed work;
- validation; and
- change detection.

Source identity and full-content identity are distinct.

### 5.9 Efficient views

Crops, slices, component selections, time-point selections and axis permutations should avoid copying when the storage supports the required access pattern.

### 5.10 No hidden coercion

The model shall not silently:

- convert irregular frames into a regular volume;
- reinterpret labels as intensity;
- change coordinate conventions;
- normalise values;
- apply modality transformations;
- change component layout;
- alter byte order;
- collapse overlapping segments; or
- discard provenance.

Every lossy or semantic conversion shall be explicit.

---

## 6. Module ownership

| Model area | Owning module |
|---|---|
| Coordinate spaces, units, matrices, planes, rays, bounds and transforms | `VoxeliaSpatial` |
| Shapes, axes, scalar formats, components, image descriptors, identities, metadata and provenance | `VoxeliaCore` |
| Storage descriptors, capabilities, type erasure, region reading, bricking and compression descriptors | `VoxeliaStorage` |
| Point, line, curve, mesh and geometry data | `VoxeliaGeometry` |
| Segmentation descriptors and representations | Initially specified here; activated in `VoxeliaSegmentation` |
| Registration result and metric models | Initially specified here; activated in `VoxeliaRegistration` |
| DICOM source translation | `VoxeliaDICOMKit` |
| Codec-specific compressed representations | `VoxeliaCompression` |
| GPU residency and resources | `VoxeliaMetal` |

No lower-level module shall depend on a higher-level optional module to define canonical semantics.

---

## 7. Swift API conventions

### 7.1 Value types

Descriptors, identifiers, regions and immutable records shall normally be `struct` or `enum`.

They should conform to:

- `Sendable`;
- `Hashable` where identity-by-value is meaningful; and
- `Codable` where stable serialisation is intended.

### 7.2 Reference types

Reference types may be used for:

- type-erased storage boxes;
- lazily calculated content digests;
- mapped-resource ownership;
- cache-managed objects; and
- objects whose lifetime controls an external resource.

Reference semantics shall not imply mutable authoritative content.

### 7.3 Initialisation

Public initialisers shall:

- validate invariants;
- throw typed errors where validation can fail;
- avoid force unwraps;
- avoid silent normalisation unless documented; and
- preserve all supplied semantic information.

### 7.4 Collections

Canonical variable-length collections shall prefer:

```swift
ContiguousArray<Element>
```

where dense predictable storage is beneficial.

Public APIs may accept generic `Collection` inputs and materialise validated canonical collections.

### 7.5 Integer types

Logical indices, extents and counts shall use `Int` within the process.

Serialised formats shall define explicit integer ranges and reject values that cannot be represented safely on the executing platform.

### 7.6 Floating-point types

Authoritative physical geometry, transforms and measurements shall use `Double`.

`Float` may be used for:

- GPU-derived representations;
- explicitly float-valued sample storage;
- non-authoritative render intermediates; and
- validated operation outputs whose format is explicitly `float32`.

### 7.7 Dates

Provenance times shall use an absolute instant representation.

Serialised JSON shall use a canonical UTC representation.

### 7.8 Access control

Only types required by adopters shall be `public`.

Implementation helpers shall remain `internal`, `package` or `private`.

---

## 8. Fundamental identifiers

### 8.1 Typed string identifier

The common pattern shall be:

```swift
public protocol VoxeliaStringIdentifier:
    RawRepresentable,
    Sendable,
    Hashable,
    Codable
where RawValue == String {}
```

Concrete identifiers shall remain distinct types rather than aliases.

Examples include:

```swift
public struct CoordinateSpaceID: VoxeliaStringIdentifier {
    public let rawValue: String
}

public struct DataObjectID: VoxeliaStringIdentifier {
    public let rawValue: String
}

public struct SegmentID: VoxeliaStringIdentifier {
    public let rawValue: String
}

public struct ProvenanceID: VoxeliaStringIdentifier {
    public let rawValue: String
}
```

### 8.2 Identifier syntax

Voxelia-owned identifiers should use reverse-domain or scoped forms:

```text
org.voxelia.coordinate.world
org.voxelia.semantic.intensity
org.voxelia.operation.resample
```

External identifiers shall preserve their source namespace.

### 8.3 Empty identifiers

Empty and whitespace-only identifiers shall be rejected.

### 8.4 Identifier case

Identifier comparison shall be case-sensitive unless the external namespace explicitly defines another rule.

---

## 9. Version model

Voxelia shall use a small value type for semantic versions embedded in provenance and serialised schemas.

```swift
public struct SemanticVersion: Sendable, Hashable, Codable, Comparable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: String?
    public let buildMetadata: String?
}
```

Requirements:

- major, minor and patch shall be non-negative;
- invalid prerelease and build syntax shall be rejected;
- comparison shall follow Semantic Versioning precedence;
- build metadata shall not affect precedence; and
- schema versions may use a separate `SchemaVersion` type when compatibility semantics differ.

---

## 10. Units and quantities

### 10.1 Neutral unit model

Voxelia shall use a neutral unit descriptor rather than binding the canonical model directly to one external unit library.

```swift
public struct MeasurementUnit: Sendable, Hashable, Codable {
    public let namespace: String
    public let code: String
    public let displayName: String?
    public let dimension: UnitDimension?
    public let scaleToCanonical: Double?
    public let offsetToCanonical: Double?
}
```

### 10.2 Unit dimensions

Initial dimensions include:

- length;
- time;
- angle;
- frequency;
- mass;
- temperature;
- electric potential;
- concentration;
- activity;
- dimensionless; and
- custom.

### 10.3 Spatial units

A coordinate space shall use one length unit consistently.

Medical patient coordinates will normally use millimetres through the DICOMKit adapter.

### 10.4 Unit conversion

Unit conversion shall be explicit.

An absent conversion definition shall not be guessed from display text.

### 10.5 Sample units

Image sample units may differ from spatial units.

Examples include:

- Hounsfield unit;
- becquerel per millilitre;
- seconds;
- millimetres per second;
- probability;
- arbitrary unit; and
- no declared unit.

---

## 11. Shape model

### 11.1 Canonical type

```swift
public struct ImageShape: Sendable, Hashable, Codable {
    public let extents: ContiguousArray<Int>

    public var rank: Int { extents.count }

    public func elementCount() throws -> Int
}
```

### 11.2 Invariants

- rank shall be at least one;
- every extent shall be greater than zero;
- the collection shall not be mutated after initialisation;
- element-count multiplication shall detect overflow; and
- no small fixed maximum rank shall be imposed by the type.

### 11.3 Empty data

An empty image shall not be represented using a zero extent.

Where an operation has no output, it shall return an explicit empty-result or optional result according to the operation specification.

### 11.4 Convenience access

Convenience properties may include:

```swift
public var width: Int? { get }
public var height: Int? { get }
public var depth: Int? { get }
```

They shall derive meaning from axis semantics or documented canonical rank convention, not merely assume all rank-three data is spatial X/Y/Z.

### 11.5 Shape errors

```swift
public enum ShapeError: Error, Sendable, Equatable {
    case emptyRank
    case nonPositiveExtent(axis: Int, value: Int)
    case elementCountOverflow
    case rankMismatch(expected: Int, actual: Int)
}
```

---

## 12. Index model

### 12.1 Canonical index

```swift
public struct ImageIndex: Sendable, Hashable, Codable {
    public let components: ContiguousArray<Int>

    public var rank: Int { components.count }
}
```

### 12.2 Convention

Voxelia shall use:

- zero-based indices;
- integer coordinates at pixel or voxel centres;
- axis zero changing fastest in canonical contiguous storage; and
- explicit axis descriptors for semantic meaning.

### 12.3 Bounds

An index is valid for a shape when:

```text
0 <= index[axis] < extent[axis]
```

### 12.4 Linear offset

A linear offset shall not be calculated without:

- a shape or stride descriptor;
- overflow checking; and
- bounds validation unless an internal precondition is already proven.

---

## 13. Region model

### 13.1 Canonical region

```swift
public struct ImageRegion: Sendable, Hashable, Codable {
    public let lowerBounds: ContiguousArray<Int>
    public let upperBounds: ContiguousArray<Int>

    public var rank: Int { lowerBounds.count }
    public func extents() throws -> ImageShape
}
```

### 13.2 Convention

Regions shall be half-open:

```text
[lower, upper)
```

### 13.3 Invariants

- lower and upper rank shall match;
- every lower bound shall be less than or equal to its upper bound;
- a region may be empty only in transient query and intersection results;
- a storage read shall reject an empty region unless the operation explicitly permits no-op reads;
- bounds arithmetic shall detect overflow; and
- containment within an image shape shall be validated before access.

### 13.4 Region operations

The model shall support:

- intersection;
- union where representable as one rectangular region;
- translation;
- expansion;
- contraction;
- clipping to shape;
- containment;
- adjacency;
- volume or element count; and
- conversion between lower-plus-extent and lower-plus-upper forms.

### 13.5 Region errors

```swift
public enum RegionError: Error, Sendable, Equatable {
    case rankMismatch
    case invertedBounds(axis: Int, lower: Int, upper: Int)
    case outsideShape
    case arithmeticOverflow
    case emptyRead
}
```

---

## 14. Axis model

### 14.1 Axis descriptor

```swift
public struct AxisDescriptor: Sendable, Hashable, Codable {
    public let id: AxisID
    public let name: String
    public let semantic: AxisSemantic
    public let unit: MeasurementUnit?
    public let sampling: AxisSampling
}
```

### 14.2 Axis semantics

```swift
public enum AxisSemantic: Sendable, Hashable, Codable {
    case spatialX
    case spatialY
    case spatialZ
    case time
    case cardiacPhase
    case respiratoryPhase
    case energy
    case echo
    case diffusionDirection
    case channel
    case component
    case ensemble
    case generic(namespace: String, name: String)
}
```

### 14.3 Axis sampling

```swift
public enum AxisSampling: Sendable, Hashable, Codable {
    case indexOnly
    case regular(origin: Double, spacing: Double)
    case irregular(coordinates: ContiguousArray<Double>)
    case categorical(labels: ContiguousArray<String>)
    case externallyDefined(identifier: String)
}
```

### 14.4 Invariants

- axis count shall equal image rank;
- axis IDs shall be unique within one descriptor;
- irregular-coordinate count shall equal the corresponding extent;
- categorical-label count shall equal the corresponding extent;
- regular spacing shall be finite and non-zero;
- semantic duplication shall be permitted only when the operation and descriptor explicitly support it; and
- spatial axes participating in `SpatialGeometry` shall be identified consistently.

### 14.5 Axis ordering

Logical axis order is part of the descriptor and identity.

Axis permutation creates a new descriptor or view and shall not be treated as metadata-only.

---

## 15. Scalar representation

### 15.1 Scalar type

```swift
public enum ScalarType: String, Sendable, Codable, Hashable, CaseIterable {
    case int8
    case uint8
    case int16
    case uint16
    case int32
    case uint32
    case int64
    case uint64
    case float16
    case float32
    case float64
}
```

### 15.2 Byte order

```swift
public enum ByteOrder: String, Sendable, Codable, Hashable {
    case native
    case littleEndian
    case bigEndian
}
```

Canonical decoded in-memory storage should normally use `.native`.

Source byte order may be retained in storage descriptors, metadata and provenance.

### 15.3 Scalar format

```swift
public struct ScalarFormat: Sendable, Hashable, Codable {
    public let type: ScalarType
    public let validBitCount: Int?
    public let byteOrder: ByteOrder
}
```

### 15.4 Derived properties

The type shall expose:

- byte count;
- bit count;
- signedness;
- integer classification;
- floating-point classification;
- finite-value support; and
- valid value range where representable.

### 15.5 Valid bits

If `validBitCount` is present:

- it shall be greater than zero;
- it shall not exceed the container bit width;
- the interpretation of unused bits shall be supplied by source decoding or metadata;
- canonical decoded values should be normalised into the declared scalar type when appropriate; and
- original packed layout shall not be inferred solely from `validBitCount`.

### 15.6 Packed formats

Packed bit formats shall not be represented as ordinary scalar arrays unless the storage descriptor explicitly describes packing.

The initial canonical decoded model shall favour unpacked native scalar values.

---

## 16. Component model

### 16.1 Component interpretation

```swift
public enum ComponentInterpretation: Sendable, Hashable, Codable {
    case scalar
    case rgb
    case rgba
    case vector
    case tensor
    case complex
    case labelProbability
    case generic(namespace: String, name: String)
}
```

### 16.2 Component layout

```swift
public enum ComponentLayout: Sendable, Hashable, Codable {
    case interleaved
    case planar
    case storageDefined
}
```

### 16.3 Component descriptor

```swift
public struct ComponentDescriptor: Sendable, Hashable, Codable {
    public let count: Int
    public let interpretation: ComponentInterpretation
    public let layout: ComponentLayout
    public let componentNames: ContiguousArray<String>?
}
```

### 16.4 Invariants

- count shall be greater than zero;
- `.scalar` shall normally have count one;
- `.rgb` shall have count three;
- `.rgba` shall have count four;
- component-name count shall equal component count;
- tensor and vector dimensionality shall be explicit in count and metadata; and
- layout shall not alter logical component ordering.

### 16.5 Components versus axes

Components are values associated with each logical sample.

An explicit channel axis is a dimension of the image.

The two shall not be conflated.

A conversion between a component layout and a channel axis shall be explicit.

---

## 17. Image semantics

### 17.1 Canonical semantic

```swift
public enum ImageSemantic: Sendable, Hashable, Codable {
    case intensity
    case label
    case probability
    case colour
    case vectorField
    case deformationField
    case tensor
    case parametric
    case mask
    case generic(namespace: String, name: String)
}
```

### 17.2 Behavioural influence

Semantics shall influence permitted or default behaviour.

Examples:

- label and mask data default to nearest-neighbour resampling;
- probability data shall define its numerical domain;
- deformation fields require vector components and spatial transform semantics;
- colour data requires colour-space metadata;
- tensor data requires tensor-layout metadata; and
- intensity data may carry a value transform and physical units.

### 17.3 Semantic consistency

Initialisers shall validate obvious contradictions, including:

- label semantic with an incompatible component interpretation;
- deformation-field semantic without vector components;
- colour semantic without compatible component interpretation; and
- mask semantic with an unsupported scalar domain unless a mapping is declared.

Full domain validation may remain operation-specific.

---

## 18. Value transformations

### 18.1 Purpose

A value transform describes the mapping from decoded stored values to authoritative physical, modality or calibrated values.

It is not a display window or transfer function.

### 18.2 Canonical type

```swift
public enum ValueTransform: Sendable, Hashable, Codable {
    case identity
    case linear(scale: Double, offset: Double)
    case lookupTable(LookupTableDescriptor)
    case piecewiseLinear(PiecewiseLinearDescriptor)
    case composed(ContiguousArray<ValueTransform>)
}
```

### 18.3 Lookup table

```swift
public struct LookupTableDescriptor: Sendable, Hashable, Codable {
    public let firstMappedValue: Int64
    public let values: ContiguousArray<Double>
    public let outputUnit: MeasurementUnit?
}
```

### 18.4 Composition

Composition order shall be explicit and documented as first-to-last application.

Empty composition shall be rejected or canonicalised to `.identity`.

### 18.5 Finite parameters

Scale, offset and table values shall be finite unless an operation specification explicitly permits non-finite output.

### 18.6 Raw, authoritative and presentation stages

The data model shall distinguish:

1. decoded stored value;
2. authoritative transformed value; and
3. presentation value.

A display window, VOI LUT, transfer function or colour map shall not be placed in `ValueTransform`.

---

## 19. Image descriptor

### 19.1 Canonical type

```swift
public struct ImageDescriptor: Sendable, Hashable, Codable {
    public let shape: ImageShape
    public let scalarFormat: ScalarFormat
    public let components: ComponentDescriptor
    public let semantic: ImageSemantic
    public let axes: ContiguousArray<AxisDescriptor>
    public let spatialGeometry: SpatialGeometry?
    public let valueTransform: ValueTransform?
    public let units: MeasurementUnit?
}
```

### 19.2 Invariants

- axis count shall equal shape rank;
- axis IDs shall be unique;
- component and semantic constraints shall pass;
- spatial geometry shall reference valid image axes;
- spatial geometry dimensionality shall be supported;
- units shall describe authoritative sample values, not spatial coordinates;
- a value transform shall be compatible with sample semantics;
- all serialised values required for identity shall be canonical; and
- descriptor construction shall not access storage.

### 19.3 Storage independence

The descriptor shall not contain:

- byte length;
- memory address;
- file URL;
- Metal resource;
- brick cache;
- DICOM dataset;
- codec object; or
- mutable state.

### 19.4 Descriptor identity

Descriptor identity shall include every field that affects interpretation.

Changing any such field creates a distinct descriptor even if sample bytes are unchanged.

### 19.5 Descriptor validation

Validation shall be split into:

- structural validation at initialisation;
- spatial validation;
- semantic validation;
- storage compatibility validation when bound to storage; and
- content validation where sample inspection is required.

---

## 20. Rank-specific convenience wrappers

### 20.1 Types

```swift
public struct Image2D: Sendable {
    public let data: ImageData
}

public struct Volume3D: Sendable {
    public let data: ImageData
}

public struct TimeVolume4D: Sendable {
    public let data: ImageData
}
```

### 20.2 Initialisation

Wrappers shall validate:

- expected spatial rank;
- required axis semantics;
- compatible spatial geometry;
- no accidental loss of non-spatial axes; and
- operation-specific constraints.

### 20.3 Storage

Wrappers shall not duplicate or copy storage.

### 20.4 Naming

A rank-four image is not automatically a time volume.

`TimeVolume4D` shall require an explicit time axis and three spatial axes.

---

## 21. Coordinate spaces

### 21.1 Coordinate-space identifier

```swift
public struct CoordinateSpaceID: Sendable, Hashable, Codable {
    public let rawValue: String
}
```

### 21.2 Handedness

```swift
public enum CoordinateHandedness: String, Sendable, Hashable, Codable {
    case rightHanded
    case leftHanded
    case unspecified
}
```

### 21.3 Convention

```swift
public enum CoordinateConvention: Sendable, Hashable, Codable {
    case cartesianRightHanded
    case cartesianLeftHanded
    case dicomPatientLPS
    case neuroimagingRAS
    case imageDisplay
    case custom(namespace: String, name: String)
}
```

### 21.4 External reference

```swift
public struct ExternalFrameReference: Sendable, Hashable, Codable {
    public let namespace: String
    public let identifier: String
}
```

### 21.5 Descriptor

```swift
public struct CoordinateSpaceDescriptor: Sendable, Hashable, Codable {
    public let id: CoordinateSpaceID
    public let convention: CoordinateConvention
    public let handedness: CoordinateHandedness
    public let unit: MeasurementUnit
    public let externalReferences: ContiguousArray<ExternalFrameReference>
}
```

### 21.6 Invariants

- coordinate unit shall have length dimension for ordinary physical spaces;
- identifier shall be non-empty;
- external references shall be unique by namespace and identifier;
- declared handedness shall not contradict a built-in convention;
- conversion between different conventions shall be explicit; and
- equality of identifiers shall not imply transform equivalence unless defined by the host or adapter.

---

## 22. Matrix representation

### 22.1 Canonical matrix

To ensure stable `Codable` and hashing semantics independent of `simd` implementation details, the canonical serialisable matrix shall be:

```swift
public struct Matrix4x4Double: Sendable, Hashable, Codable {
    public let elements: ContiguousArray<Double>
}
```

The collection shall contain exactly sixteen row-major values.

Internal accelerated conversions may use `simd_double4x4`.

### 22.2 Homogeneous convention

The matrix shall transform column vectors using homogeneous coordinates:

```text
world = M × [indexX, indexY, indexZ, 1]ᵀ
```

The serialised layout and mathematical convention shall be documented together to avoid row/column ambiguity.

### 22.3 Validation

- all elements shall be finite;
- affine geometry shall have an affine final row within the declared tolerance;
- inversion shall detect singularity;
- transform composition order shall be explicit; and
- equality is exact value equality, while geometric equivalence uses a tolerance.

---

## 23. Spatial-axis mapping

### 23.1 Type

```swift
public struct SpatialAxisMapping: Sendable, Hashable, Codable {
    public let imageAxes: ContiguousArray<Int>
}
```

### 23.2 Invariants

- count shall be one, two or three;
- indices shall be unique;
- every index shall be within image rank;
- ordering shall correspond to the coordinates consumed by the spatial transform; and
- axes not listed are non-spatial for that geometry.

### 23.3 Three-dimensional transforms

A 4×4 transform may represent one-, two- or three-dimensional spatial data by holding unused coordinates at zero.

The mapping shall define which image axes supply the X, Y and Z index coordinates.

---

## 24. Affine-grid geometry

### 24.1 Type

```swift
public struct AffineGridGeometry: Sendable, Hashable, Codable {
    public let spatialAxes: SpatialAxisMapping
    public let indexToWorld: Matrix4x4Double
    public let coordinateSpace: CoordinateSpaceDescriptor
}
```

### 24.2 Voxel-centre convention

Integer index coordinates map to pixel or voxel centres.

The continuous support of one sample extends half a sample around its centre unless an operation specifies another reconstruction kernel.

### 24.3 Requirements

The geometry shall support:

- index-to-world mapping;
- world-to-index inverse where invertible;
- spatial basis vectors;
- spacing magnitude;
- direction matrix;
- origin;
- physical bounds;
- oriented bounds; and
- transformation of points and vectors.

### 24.4 Spacing

Spacing is derived from basis-vector magnitude.

Negative orientation shall be represented in direction, not negative spacing.

### 24.5 Regularity

An affine grid represents a regular lattice.

Irregular slice positions shall not be approximated as affine without a validated regularity assessment or explicit resampling.

---

## 25. Rectilinear-grid geometry

### 25.1 Purpose

A rectilinear grid represents separable non-uniform coordinates along one, two or three spatial axes.

### 25.2 Type

```swift
public struct RectilinearGridGeometry: Sendable, Hashable, Codable {
    public let spatialAxes: SpatialAxisMapping
    public let coordinates: ContiguousArray<ContiguousArray<Double>>
    public let orientation: Matrix4x4Double
    public let coordinateSpace: CoordinateSpaceDescriptor
}
```

### 25.3 Invariants

- coordinate-array count shall equal spatial-axis count;
- each coordinate-array length shall equal the corresponding image extent;
- coordinates shall be finite;
- coordinates shall be strictly monotonic for operations requiring invertibility;
- orientation shall define the shared basis and origin convention;
- duplicate positions shall be rejected unless the model explicitly permits coincident samples; and
- conversion to an affine grid shall be explicit.

### 25.4 Initial implementation status

The type may be introduced at M1 while optimised operations remain limited.

Unsupported operations shall return typed capability errors rather than reinterpret the geometry.

---

## 26. Frame-set geometry

### 26.1 Purpose

A frame set represents individually positioned frames that do not necessarily form one regular volume.

### 26.2 Frame descriptor

```swift
public struct FrameGeometry: Sendable, Hashable, Codable {
    public let frameIndex: ImageIndex
    public let frameAxes: SpatialAxisMapping
    public let indexToWorld: Matrix4x4Double
    public let coordinateSpace: CoordinateSpaceDescriptor
    public let frameIdentity: String?
}
```

### 26.3 Frame set

```swift
public struct FrameSetGeometry: Sendable, Hashable, Codable {
    public let frameAxis: Int
    public let frames: ContiguousArray<FrameGeometry>
}
```

### 26.4 Invariants

- frame axis shall be within image rank;
- frame count shall equal the extent of the frame axis unless sparse framing is explicitly supported;
- each frame index shall be valid;
- frame identities shall be unique when present;
- frame coordinate spaces shall be compatible or explicitly transformed;
- per-frame matrices shall be finite; and
- no regular-volume guarantee is implied.

### 26.5 Regularity assessment

A separate operation shall assess whether a frame set is regular within a declared tolerance.

The result shall include:

- orientation variation;
- spacing variation;
- duplicate frames;
- missing positions;
- ordering;
- maximum residual; and
- suitability for affine representation.

The geometry type itself shall not silently perform this conversion.

---

## 27. Spatial geometry enumeration

```swift
public enum SpatialGeometry: Sendable, Hashable, Codable {
    case affineGrid(AffineGridGeometry)
    case rectilinearGrid(RectilinearGridGeometry)
    case frameSet(FrameSetGeometry)
}
```

### 27.1 Image compatibility

A geometry shall be validated against the image descriptor before binding.

### 27.2 Unsupported geometry

An operation that supports only affine grids shall reject rectilinear and frame-set data with a typed error.

### 27.3 Identity impact

Geometry is part of descriptor and data identity.

Changing geometry without changing bytes creates a distinct interpreted data object.

---

## 28. Spatial primitives

`VoxeliaSpatial` shall provide canonical primitives including:

```swift
public struct Point3D: Sendable, Hashable, Codable {
    public let x: Double
    public let y: Double
    public let z: Double
    public let coordinateSpace: CoordinateSpaceID
}

public struct Vector3D: Sendable, Hashable, Codable {
    public let x: Double
    public let y: Double
    public let z: Double
    public let coordinateSpace: CoordinateSpaceID
}

public struct Plane3D: Sendable, Hashable, Codable {
    public let origin: Point3D
    public let normal: Vector3D
}

public struct Ray3D: Sendable, Hashable, Codable {
    public let origin: Point3D
    public let direction: Vector3D
}
```

### 28.1 Invariants

- coordinates shall be finite;
- vectors used as directions or normals shall be non-zero;
- normalisation shall be explicit;
- operands shall have compatible coordinate spaces;
- operations shall reject mismatched spaces unless a transform is supplied; and
- geometry calculations shall use double precision.

---

## 29. Bounds

### 29.1 Axis-aligned bounds

```swift
public struct AxisAlignedBounds3D: Sendable, Hashable, Codable {
    public let minimum: Point3D
    public let maximum: Point3D
}
```

### 29.2 Oriented bounds

```swift
public struct OrientedBounds3D: Sendable, Hashable, Codable {
    public let centre: Point3D
    public let axes: ContiguousArray<Vector3D>
    public let halfExtents: SIMD3<Double>
}
```

### 29.3 Sample support

Image physical bounds shall distinguish:

- centre bounds; and
- sample-support bounds extending by half a sample in regular grids.

The caller shall select the required interpretation.

---

## 30. Spatial transforms

### 30.1 Transform protocol

```swift
public protocol SpatialTransform: Sendable {
    var sourceSpace: CoordinateSpaceDescriptor { get }
    var destinationSpace: CoordinateSpaceDescriptor { get }
    var kind: SpatialTransformKind { get }
    var inverseAvailability: InverseAvailability { get }

    func transform(point: Point3D) throws -> Point3D
    func transform(vector: Vector3D) throws -> Vector3D
}
```

Normals require inverse-transpose handling and shall use a dedicated method or validated implementation.

### 30.2 Transform kinds

```swift
public enum SpatialTransformKind: String, Sendable, Hashable, Codable {
    case identity
    case rigid
    case similarity
    case affine
    case composite
    case deformationField
}
```

### 30.3 Type erasure

```swift
public struct AnySpatialTransform: Sendable {
    // Internal type-erased immutable transform box.
}
```

Type erasure shall preserve:

- source and destination space;
- kind;
- serialisable descriptor where available;
- identity;
- provenance; and
- runtime type safety.

### 30.4 Affine transform

```swift
public struct AffineSpatialTransform: SpatialTransform, Hashable, Codable {
    public let sourceSpace: CoordinateSpaceDescriptor
    public let destinationSpace: CoordinateSpaceDescriptor
    public let matrix: Matrix4x4Double
}
```

### 30.5 Composite transform

A composite transform shall apply an ordered list.

Adjacent coordinate spaces shall match.

An empty composite shall canonicalise to identity or be rejected according to the initialiser.

### 30.6 Deformation-field transform

A deformation field shall reference canonical `ImageData` with:

- `vectorField` or `deformationField` semantic;
- compatible vector components;
- explicit source geometry;
- explicit vector unit;
- interpolation policy;
- outside-domain policy; and
- provenance.

### 30.7 Inversion

Inverse availability shall distinguish:

- exact;
- analytically available;
- numerically available;
- unavailable; and
- not yet evaluated.

A failed numerical inverse shall not be advertised as available.

---

## 31. View model

### 31.1 Purpose

A view provides a logical image derived from existing storage without necessarily materialising new sample data.

### 31.2 Index transform

```swift
public struct IndexViewTransform: Sendable, Hashable, Codable {
    public let sourceRank: Int
    public let destinationRank: Int
    public let sourceOrigin: ContiguousArray<Int>
    public let destinationToSourceAxis: ContiguousArray<Int?>
    public let sourceStep: ContiguousArray<Int>
    public let fixedSourceIndices: ContiguousArray<Int?>
}
```

This representation supports:

- crop;
- slice;
- axis permutation;
- axis reversal;
- component-independent index selection; and
- stride-compatible subsampling.

The exact implementation may be revised by ADR if a simpler equally expressive representation is validated.

### 31.3 View descriptor

```swift
public struct ImageViewDescriptor: Sendable, Hashable, Codable {
    public let sourceIdentity: DataIdentity
    public let indexTransform: IndexViewTransform
    public let componentSelection: ComponentSelection?
    public let logicalDescriptor: ImageDescriptor
}
```

### 31.4 View data

```swift
public struct ImageView: Sendable {
    public let descriptor: ImageViewDescriptor
    public let source: ImageData
}
```

### 31.5 Invariants

- transform ranks shall be valid;
- mapped axes shall be unique;
- fixed indices shall be within source bounds;
- step shall not be zero;
- negative steps shall derive reversed geometry correctly;
- logical shape shall match the transform;
- component selection shall be valid;
- source lifetime shall be retained; and
- view provenance shall reference the source.

### 31.6 Materialisation

A materialisation operation shall produce new storage and a new `ImageData`.

Materialisation shall not occur implicitly merely because a backend prefers contiguous data.

---

## 32. Content identity

### 32.1 Digest algorithm

```swift
public enum DigestAlgorithm: String, Sendable, Hashable, Codable {
    case sha256
    case sha512
    case blake3
    case custom
}
```

Use of a custom algorithm shall include a namespaced identifier and shall require approval for persistent or distributed identity.

### 32.2 Content identifier

```swift
public struct ContentID: Sendable, Hashable, Codable {
    public let algorithm: String
    public let digest: ContiguousArray<UInt8>
}
```

### 32.3 Content scope

A content ID shall declare what it covers.

```swift
public enum ContentScope: String, Sendable, Hashable, Codable {
    case sampleBytes
    case descriptorAndSamples
    case storageObject
    case compressedRepresentation
    case serialisedObject
}
```

The scope shall be included in the identity record.

### 32.4 Canonical content identity

For authoritative immutable image identity used across systems, the preferred scope is:

```text
descriptorAndSamples
```

The digest input shall use:

- canonical descriptor serialisation;
- canonical logical sample order;
- canonical component order; and
- documented treatment of byte order.

A physical storage padding byte shall not affect logical content identity.

### 32.5 Lazy content identity

Large data may calculate the content ID lazily.

Until complete, the data shall retain source or derivation identity and shall not falsely claim a full-content digest.

---

## 33. Source and derivation identity

### 33.1 Source identity

```swift
public struct SourceIdentity: Sendable, Hashable, Codable {
    public let namespace: String
    public let identifier: String
    public let version: String?
    public let contentID: ContentID?
}
```

Examples include:

- a DICOM SOP Instance and frame;
- an object-store key and version;
- a file and verified digest;
- a dataset manifest entry; and
- a generated phantom identifier.

### 33.2 Derivation identity

```swift
public struct DerivationIdentity: Sendable, Hashable, Codable {
    public let operationID: String
    public let operationVersion: SemanticVersion
    public let implementationID: String?
    public let inputIdentities: ContiguousArray<DataIdentityReference>
    public let parameterDigest: ContentID
}
```

### 33.3 Data identity

```swift
public struct DataIdentity: Sendable, Hashable, Codable {
    public let objectID: DataObjectID
    public let contentID: ContentID?
    public let sourceIdentities: ContiguousArray<SourceIdentity>
    public let derivation: DerivationIdentity?
}
```

### 33.4 Object identity

`objectID` identifies one immutable Voxelia object instance or published object record.

It shall not be used as a substitute for content equality.

### 33.5 Cache use

A cache shall prefer:

1. verified content identity;
2. deterministic derivation identity with verified inputs; or
3. trusted source identity under an explicit cache policy.

---

## 34. Metadata model

### 34.1 Metadata key

```swift
public struct MetadataKey<Value: Sendable>: Sendable, Hashable {
    public let namespace: String
    public let name: String
}
```

### 34.2 Stored metadata key

For heterogeneous serialisation:

```swift
public struct AnyMetadataKey: Sendable, Hashable, Codable {
    public let namespace: String
    public let name: String
}
```

### 34.3 Metadata value

```swift
public enum MetadataValue: Sendable, Hashable, Codable {
    case boolean(Bool)
    case signedInteger(Int64)
    case unsignedInteger(UInt64)
    case floatingPoint(Double)
    case string(String)
    case binary(Data)
    case instant(String)
    case unit(MeasurementUnit)
    case code(CodedConcept)
    case array(ContiguousArray<MetadataValue>)
    case object(ContiguousArray<MetadataEntry>)
}
```

A canonical instant string shall use UTC ISO 8601 syntax.

### 34.4 Metadata entry

```swift
public struct MetadataEntry: Sendable, Hashable, Codable {
    public let key: AnyMetadataKey
    public let value: MetadataValue
}
```

### 34.5 Collection

```swift
public struct MetadataCollection: Sendable, Hashable, Codable {
    public let entries: ContiguousArray<MetadataEntry>
}
```

### 34.6 Invariants

- key namespace and name shall be non-empty;
- duplicate keys shall be rejected unless the namespace schema explicitly permits multiplicity;
- object keys shall be unique;
- floating-point metadata shall define whether non-finite values are permitted;
- metadata shall not duplicate required descriptor fields as an alternative source of truth; and
- adapters shall namespace source-format metadata.

### 34.7 Typed access

Typed accessors shall validate that stored values match the expected type.

A failed typed read shall return a typed metadata error, not silently coerce unrelated values.

### 34.8 Privacy classification

Metadata may carry a classification:

```swift
public enum MetadataPrivacyClass: String, Sendable, Hashable, Codable {
    case publicData
    case technical
    case potentiallyIdentifying
    case sensitive
    case hostDefined
}
```

The classification supports logging and export policy but does not replace host privacy controls.

---

## 35. Neutral coded concept

### 35.1 Type

```swift
public struct CodedConcept: Sendable, Hashable, Codable {
    public let scheme: String
    public let value: String
    public let meaning: String?
    public let version: String?
}
```

### 35.2 Neutrality

The type shall not require DICOM.

The DICOMKit adapter may populate it from DICOM coded terminology.

Other adapters may use SNOMED CT, UCUM, internal ontologies or scientific code systems.

### 35.3 Equality

Semantic equality shall be based primarily on scheme, value and version rules.

Meaning text shall not be treated as the identifier.

---

## 36. Provenance model

### 36.1 Provenance record

```swift
public struct ProvenanceRecord: Sendable, Hashable, Codable {
    public let id: ProvenanceID
    public let kind: ProvenanceKind
    public let createdAt: String
    public let software: SoftwareIdentity
    public let sources: ContiguousArray<ProvenanceReference>
    public let operation: OperationProvenance?
    public let execution: ExecutionProvenance?
    public let warnings: ContiguousArray<ProvenanceWarning>
    public let validation: ValidationStatus
}
```

### 36.2 Provenance kinds

```swift
public enum ProvenanceKind: String, Sendable, Hashable, Codable {
    case source
    case imported
    case decoded
    case viewed
    case transformed
    case processed
    case segmented
    case registered
    case rendered
    case materialised
    case cached
}
```

### 36.3 Software identity

```swift
public struct SoftwareIdentity: Sendable, Hashable, Codable {
    public let name: String
    public let version: SemanticVersion
    public let commit: String?
    public let buildIdentifier: String?
}
```

### 36.4 Operation provenance

```swift
public struct OperationProvenance: Sendable, Hashable, Codable {
    public let operationID: String
    public let operationVersion: SemanticVersion
    public let implementationID: String
    public let implementationVersion: SemanticVersion
    public let parameterDigest: ContentID
}
```

### 36.5 Execution provenance

```swift
public struct ExecutionProvenance: Sendable, Hashable, Codable {
    public let profile: ExecutionProfileDescriptor
    public let backend: BackendDescriptor
    public let deviceCapabilityClass: String?
    public let kernelOrShaderIdentity: String?
    public let approximationStatus: ApproximationStatus
}
```

### 36.6 Validation status

```swift
public enum ValidationStatus: Sendable, Hashable, Codable {
    case unknown
    case experimental
    case preview
    case validated(evidenceID: String)
    case diagnosticReady(evidenceID: String)
    case deprecated(reason: String)
}
```

### 36.7 Warnings

Warnings shall be structured:

```swift
public struct ProvenanceWarning: Sendable, Hashable, Codable {
    public let code: String
    public let severity: WarningSeverity
    public let message: String
}
```

### 36.8 Provenance graph

Provenance records shall form a directed acyclic graph.

Cycle detection shall be applied when importing or composing complete records.

Compact records may reference externally stored parents by ID and digest.

### 36.9 Patient information

Provenance shall not include patient-identifying data by default.

Source-format adapters shall include only technical identities necessary for traceability unless the host explicitly permits more.

---

## 37. Image data handle

### 37.1 Canonical type

```swift
public struct ImageData: Sendable {
    public let descriptor: ImageDescriptor
    public let storage: AnyImageStorage
    public let metadata: MetadataCollection
    public let provenance: ProvenanceRecord
    public let identity: DataIdentity
}
```

### 37.2 Binding validation

Construction shall validate:

- storage logical descriptor compatibility;
- shape compatibility;
- scalar and component compatibility;
- storage byte-order compatibility;
- geometry and axis compatibility;
- identity completeness rules;
- provenance-source consistency; and
- metadata uniqueness.

### 37.3 Immutability

The properties shall be immutable.

The storage object may lazily load immutable content, but shall not change the logical data associated with the identity.

### 37.4 Equality

`ImageData` shall not automatically conform to `Equatable` by comparing storage references.

Equality use cases shall distinguish:

- same object ID;
- same content ID;
- same source identity;
- same descriptor;
- same logical samples; and
- same provenance.

Dedicated comparison APIs shall be used.

### 37.5 Hashing

`ImageData` shall not be `Hashable` unless hashing semantics are explicitly defined by a future ADR.

`DataIdentity` is the preferred key.

---

## 38. Storage descriptor

### 38.1 Canonical descriptor

```swift
public struct StorageDescriptor: Sendable, Hashable, Codable {
    public let kind: StorageKind
    public let shape: ImageShape
    public let scalarFormat: ScalarFormat
    public let components: ComponentDescriptor
    public let byteLength: Int?
    public let strides: ContiguousArray<Int>?
    public let alignment: Int?
    public let persistence: StoragePersistence
    public let integrity: StorageIntegrityDescriptor?
}
```

### 38.2 Storage kind

```swift
public enum StorageKind: String, Sendable, Hashable, Codable {
    case contiguous
    case memoryMapped
    case tiled
    case bricked
    case compressed
    case remote
    case callback
    case view
}
```

### 38.3 Persistence

```swift
public enum StoragePersistence: String, Sendable, Hashable, Codable {
    case transient
    case processLifetime
    case mappedFile
    case persistentCache
    case external
}
```

### 38.4 Strides

Strides shall be expressed in bytes.

For canonical contiguous interleaved storage:

- component stride is scalar byte width;
- axis zero changes fastest;
- row and higher strides shall be overflow-checked; and
- no implicit padding is assumed.

A storage provider may declare other strides and layouts.

### 38.5 Byte length

When known, byte length shall be non-negative and sufficient for the declared layout.

When unknown for remote or compressed storage, it may be absent.

---

## 39. Storage capabilities

```swift
public struct StorageCapabilities: OptionSet, Sendable, Hashable, Codable {
    public let rawValue: UInt64

    public static let randomRead: Self
    public static let sequentialRead: Self
    public static let directByteAccess: Self
    public static let memoryMapped: Self
    public static let writableBuilder: Self
    public static let tiled: Self
    public static let bricked: Self
    public static let compressed: Self
    public static let multiresolution: Self
    public static let remote: Self
    public static let prefetch: Self
    public static let contentDigest: Self
}
```

Capabilities describe what the storage can do.

They shall not claim a capability that returns a different logical dataset from the associated identity.

---

## 40. Storage protocol

### 40.1 Base protocol

```swift
public protocol ImageStorage: Sendable {
    var descriptor: StorageDescriptor { get }
    var capabilities: StorageCapabilities { get }

    func read(
        region: ImageRegion,
        into destination: ImageWriteDestination
    ) async throws
}
```

### 40.2 Read destination

```swift
public protocol ImageWriteDestination: Sendable {
    var descriptor: DestinationDescriptor { get }

    func withWritableBytes<R: Sendable>(
        _ body: @Sendable (UnsafeMutableRawBufferPointer) throws -> R
    ) async throws -> R
}
```

The final implementation may use a safer internal closure or typed destination design. Any unsafe pointer lifetime shall remain scoped and documented.

### 40.3 Optional protocols

Separate capability protocols may include:

- `ContiguousReadableStorage`;
- `MemoryMappedStorage`;
- `BrickReadableStorage`;
- `CompressedRepresentationStorage`;
- `PrefetchableStorage`;
- `DigestibleStorage`; and
- `StorageBuilder`.

### 40.4 Type erasure

```swift
public struct AnyImageStorage: Sendable {
    // Immutable, type-erased storage box.
}
```

Any use of `@unchecked Sendable` inside type erasure shall have:

- documented invariant;
- independent review;
- stress tests;
- no mutable logical data; and
- controlled lifetime.

### 40.5 Read semantics

A successful read shall fill the complete requested destination region.

Partial completion shall not be published as successful.

Cancellation or failure shall leave destination state defined by the destination contract.

---

## 41. Storage compatibility

An `ImageStorage` may be bound to an `ImageDescriptor` only when:

- shape matches;
- scalar container type matches;
- component count and logical order match;
- storage layout can expose the declared logical samples;
- byte order is supported;
- valid bits are interpreted consistently;
- spatial geometry does not require storage-specific hidden changes; and
- storage does not change values during the immutable object lifetime.

A codec object is not canonical storage until it can expose the required logical read contract or a compressed-storage adapter wraps it.

---

## 42. Contiguous storage

### 42.1 Requirements

Contiguous storage shall support:

- native logical sample order;
- explicit strides;
- direct byte access where safe;
- complete-content digest;
- immutable ownership;
- bounded lifetime; and
- region copy.

### 42.2 Ownership

Storage may own:

- Swift-managed memory;
- aligned allocation;
- immutable `Data`;
- mapped immutable memory; or
- host-supplied immutable bytes with retained lifetime.

### 42.3 No-copy construction

A no-copy constructor shall clearly state:

- ownership;
- lifetime;
- deallocator;
- alignment;
- mutability; and
- `Sendable` safety.

---

## 43. Memory-mapped storage

Mapped storage shall define:

- file identity;
- offset;
- mapped length;
- page alignment;
- read-only or builder status;
- file-change policy;
- integrity digest;
- error recovery; and
- lifetime.

A mapped file that can be modified externally shall not be treated as immutable authoritative content without:

- snapshot semantics;
- verified digest; or
- explicit invalidation policy.

---

## 44. Tiled storage

### 44.1 Tile grid

```swift
public struct TileGridDescriptor: Sendable, Hashable, Codable {
    public let tileShape: ImageShape
    public let levels: ContiguousArray<ResolutionLevelDescriptor>
}
```

### 44.2 Requirements

Tiled storage shall define:

- logical tile regions;
- boundary tiles;
- level geometry;
- tile identity;
- compression;
- integrity; and
- read order.

Two-dimensional tiles and three-dimensional bricks share concepts but remain distinct descriptors for clarity.

---

## 45. Bricked volume storage

### 45.1 Brick key

```swift
public struct BrickKey: Sendable, Hashable, Codable {
    public let level: Int
    public let coordinates: SIMD3<Int>
}
```

### 45.2 Brick descriptor

```swift
public struct BrickDescriptor: Sendable, Hashable, Codable {
    public let key: BrickKey
    public let logicalRegion: ImageRegion
    public let storedRegion: ImageRegion
    public let halo: SIMD3<Int>
    public let scalarFormat: ScalarFormat
    public let contentID: ContentID?
    public let statistics: BrickStatistics?
}
```

### 45.3 Brick grid

```swift
public struct BrickGridDescriptor: Sendable, Hashable, Codable {
    public let volumeShape: ImageShape
    public let nominalBrickShape: SIMD3<Int>
    public let levels: ContiguousArray<ResolutionLevelDescriptor>
}
```

### 45.4 Resolution level

```swift
public struct ResolutionLevelDescriptor: Sendable, Hashable, Codable {
    public let level: Int
    public let shape: ImageShape
    public let scaleFromBase: SIMD3<Double>
    public let spatialGeometry: SpatialGeometry
}
```

### 45.5 Invariants

- base level shall be level zero;
- level identifiers shall be unique;
- level geometry shall preserve physical correspondence;
- boundary bricks may have smaller logical regions;
- stored regions may include halo;
- halo shall not change logical indexing;
- brick coordinates shall map deterministically to regions;
- content IDs shall cover the representation declared by their scope; and
- empty or invalid bricks shall not masquerade as valid zero-filled content.

### 45.6 Brick statistics

```swift
public struct BrickStatistics: Sendable, Hashable, Codable {
    public let minimum: Double?
    public let maximum: Double?
    public let mean: Double?
    public let variance: Double?
    public let nonZeroCount: UInt64?
    public let occupancy: Double?
}
```

Statistics shall identify whether they refer to raw or authoritative transformed values.

---

## 46. Compressed storage descriptor

### 46.1 Codec identifier

```swift
public struct CodecIdentifier: Sendable, Hashable, Codable {
    public let namespace: String
    public let name: String
    public let version: String?
    public let profile: String?
}
```

### 46.2 Compressed representation

```swift
public struct CompressedRepresentationDescriptor:
    Sendable,
    Hashable,
    Codable
{
    public let codec: CodecIdentifier
    public let logicalDescriptorDigest: ContentID
    public let compressedByteLength: Int?
    public let resolutionLevels: Int
    public let regionAccess: CompressedRegionAccess
    public let lossless: Bool
    public let contentID: ContentID?
}
```

### 46.3 Region access

```swift
public enum CompressedRegionAccess: Sendable, Hashable, Codable {
    case completeObject
    case frame
    case slab
    case brick
    case regionOfInterest
    case progressiveResolution
    case custom(namespace: String, name: String)
}
```

### 46.4 Requirements

- codec-specific parameters shall remain in namespaced metadata or adapter descriptors;
- the descriptor shall state whether the representation is lossless;
- decoded destination format shall be explicit;
- compressed identity and decoded logical identity shall remain distinct;
- a compressed representation shall not be treated as a Metal texture;
- JP3D cache representation shall remain distinct from DICOM transfer-syntax identity; and
- partial decode capabilities shall be declared rather than inferred.

---

## 47. Remote and callback-backed storage

The storage contract may be implemented by a host application or service.

It shall define:

- immutable logical identity;
- region or brick request;
- cancellation;
- retry ownership;
- integrity;
- unavailable-region behaviour;
- latency hints;
- prefetch hints; and
- error mapping.

Voxelia shall not define authentication or transport.

A remote provider shall not return different logical content under one immutable identity.

---

## 48. Storage builders and editing

### 48.1 Builder state

A builder is mutable and not yet authoritative.

```swift
public protocol ImageStorageBuilder: Sendable {
    var targetDescriptor: ImageDescriptor { get }

    func write(
        region: ImageRegion,
        from source: ImageReadSource
    ) async throws

    func commit(
        provenance: ProvenanceRecord,
        metadata: MetadataCollection
    ) async throws -> ImageData
}
```

### 48.2 Commit

Commit shall:

- complete all required regions;
- validate storage compatibility;
- calculate or schedule identity;
- freeze logical content;
- create provenance;
- reject outstanding failed writes; and
- return a new immutable `ImageData`.

### 48.3 Transactions

Editing transactions may support copy-on-write or sparse changes.

They shall publish a new object and preserve parent provenance.

---

## 49. Geometry data model

### 49.1 Geometry kinds

```swift
public enum GeometryKind: String, Sendable, Hashable, Codable {
    case pointSet
    case lineSet
    case polylineSet
    case centreLine
    case triangleMesh
    case polygonMesh
    case boundingVolume
}
```

### 49.2 Geometry descriptor

```swift
public struct GeometryDescriptor: Sendable, Hashable, Codable {
    public let kind: GeometryKind
    public let coordinateSpace: CoordinateSpaceDescriptor
    public let primitiveCount: Int
    public let attributes: ContiguousArray<GeometryAttributeDescriptor>
}
```

### 49.3 Attribute semantic

```swift
public enum GeometryAttributeSemantic: Sendable, Hashable, Codable {
    case position
    case normal
    case tangent
    case colour
    case textureCoordinate
    case scalarValue
    case label
    case confidence
    case custom(namespace: String, name: String)
}
```

### 49.4 Attribute descriptor

```swift
public struct GeometryAttributeDescriptor:
    Sendable,
    Hashable,
    Codable
{
    public let semantic: GeometryAttributeSemantic
    public let scalarFormat: ScalarFormat
    public let components: ComponentDescriptor
    public let elementCount: Int
}
```

### 49.5 Geometry storage

Geometry storage shall remain backend-neutral and shall support:

- separate or interleaved attributes;
- index buffers;
- memory mapping;
- immutable content identity;
- optional GPU residency derived by `VoxeliaMetal`; and
- provenance.

---

## 50. Mesh model

### 50.1 Mesh primitive

```swift
public enum MeshPrimitive: String, Sendable, Hashable, Codable {
    case points
    case lines
    case lineStrip
    case triangles
    case triangleStrip
    case polygons
}
```

### 50.2 Index type

```swift
public enum IndexType: String, Sendable, Hashable, Codable {
    case uint16
    case uint32
    case uint64
}
```

### 50.3 Mesh descriptor

```swift
public struct MeshDescriptor: Sendable, Hashable, Codable {
    public let primitive: MeshPrimitive
    public let vertexCount: Int
    public let indexCount: Int
    public let indexType: IndexType?
    public let attributes: ContiguousArray<GeometryAttributeDescriptor>
    public let coordinateSpace: CoordinateSpaceDescriptor
}
```

### 50.4 Invariants

- counts shall be non-negative;
- index type shall be present when indexed topology is used;
- every referenced index shall be within vertex count;
- position attribute shall exist;
- position shall contain two or three components according to the geometry specification;
- normal attributes shall be compatible with position count;
- attribute element counts shall match their interpolation domain; and
- topology validation shall be separate from mere descriptor construction where storage access is required.

### 50.5 Mesh data

```swift
public struct MeshData: Sendable {
    public let descriptor: MeshDescriptor
    public let storage: AnyGeometryStorage
    public let metadata: MetadataCollection
    public let provenance: ProvenanceRecord
    public let identity: DataIdentity
}
```

---

## 51. Point, line and curve models

The initial model shall support:

- point sets;
- independent line segments;
- polylines;
- centre lines; and
- optional per-point scalar and label attributes.

A centre line shall additionally support:

- ordered points;
- arc-length calculation;
- optional radius;
- optional tangent;
- source-space relationship; and
- provenance.

Curve interpolation is an operation and shall not be implied solely by a point list.

---

## 52. Segmentation model

### 52.1 Purpose

Segmentation is scientific data, not merely an overlay.

### 52.2 Segment identifier

```swift
public struct SegmentID: Sendable, Hashable, Codable {
    public let rawValue: String
}
```

### 52.3 Algorithm descriptor

```swift
public struct SegmentAlgorithmDescriptor:
    Sendable,
    Hashable,
    Codable
{
    public let type: SegmentAlgorithmType
    public let name: String?
    public let version: String?
    public let modelIdentity: String?
}
```

### 52.4 Algorithm type

```swift
public enum SegmentAlgorithmType: String, Sendable, Hashable, Codable {
    case manual
    case semiautomatic
    case automatic
    case imported
    case unknown
}
```

### 52.5 Display recommendation

```swift
public struct SegmentDisplayRecommendation:
    Sendable,
    Hashable,
    Codable
{
    public let rgba: SIMD4<Float>?
    public let opacity: Float?
    public let visibleByDefault: Bool?
}
```

Display recommendations are not authoritative segment semantics.

### 52.6 Segment descriptor

```swift
public struct SegmentDescriptor: Sendable, Hashable, Codable {
    public let id: SegmentID
    public let label: String
    public let category: CodedConcept?
    public let type: CodedConcept?
    public let algorithm: SegmentAlgorithmDescriptor
    public let recommendedDisplay: SegmentDisplayRecommendation?
    public let trackingIdentity: String?
    public let metadata: MetadataCollection
}
```

### 52.7 Representation

```swift
public enum SegmentationRepresentation: Sendable {
    case labelImage(LabelImageSegmentation)
    case segmentCollection(SegmentCollectionSegmentation)
}
```

### 52.8 Label image

A label image assigns at most one segment label to each sample.

It shall define:

- integer label image;
- mapping from stored label value to `SegmentID`;
- background value;
- geometry;
- source relationship; and
- provenance.

### 52.9 Segment collection

A segment collection shall contain one mask or fractional field per segment and shall permit overlap.

Each segment field shall have:

- segment ID;
- `ImageData`;
- binary, occupancy or probability interpretation;
- numerical domain;
- threshold for optional binary conversion; and
- geometry.

### 52.10 Segmentation object

```swift
public struct Segmentation: Sendable {
    public let sourceSpace: CoordinateSpaceDescriptor
    public let geometry: SpatialGeometry
    public let representation: SegmentationRepresentation
    public let segments: ContiguousArray<SegmentDescriptor>
    public let provenance: ProvenanceRecord
    public let identity: DataIdentity
}
```

### 52.11 Invariants

- segment IDs shall be unique;
- representation references shall resolve to declared segments;
- label values shall be unique;
- overlapping segments shall not be collapsed silently;
- fractional domains shall be explicit;
- geometry shall be compatible with segment fields;
- conversion between representations shall be explicit; and
- segmentation editing shall create new provenance.

---

## 53. Registration result model

### 53.1 Metric sample

```swift
public struct MetricSample: Sendable, Hashable, Codable {
    public let level: Int
    public let iteration: Int
    public let metricValue: Double
    public let parameterDigest: ContentID?
}
```

### 53.2 Convergence status

```swift
public enum ConvergenceStatus: String, Sendable, Hashable, Codable {
    case converged
    case iterationLimit
    case toleranceReached
    case cancelled
    case numericallyInvalid
    case insufficientOverlap
    case unsupportedGeometry
    case failed
}
```

### 53.3 Convergence report

```swift
public struct ConvergenceReport: Sendable, Hashable, Codable {
    public let status: ConvergenceStatus
    public let iterations: Int
    public let levelsCompleted: Int
    public let finalMetricValue: Double?
    public let message: String?
    public let warnings: ContiguousArray<ProvenanceWarning>
}
```

### 53.4 Registration quality

```swift
public struct RegistrationQuality: Sendable, Hashable, Codable {
    public let landmarkError: Double?
    public let inverseConsistencyError: Double?
    public let overlapMeasure: Double?
    public let jacobianMinimum: Double?
    public let jacobianMaximum: Double?
    public let extrapolatedFraction: Double?
}
```

### 53.5 Registration result

```swift
public struct RegistrationResult: Sendable {
    public let fixedSpace: CoordinateSpaceDescriptor
    public let movingSpace: CoordinateSpaceDescriptor
    public let transform: AnySpatialTransform
    public let metricHistory: ContiguousArray<MetricSample>
    public let convergence: ConvergenceReport
    public let quality: RegistrationQuality?
    public let provenance: ProvenanceRecord
    public let identity: DataIdentity
}
```

### 53.6 Direction

Unless the operation specification explicitly states otherwise, the transform maps:

```text
moving space → fixed space
```

### 53.7 Failure status

A non-converged result may retain diagnostic information but shall not be treated as an accepted transform without an explicit host decision.

---

## 54. Deformation-field model

A deformation field shall be canonical `ImageData` with:

- semantic `.deformationField`;
- three vector components for three-dimensional physical displacement;
- explicit vector unit;
- affine or supported spatial geometry;
- source and destination coordinate spaces;
- interpolation policy;
- outside-domain policy; and
- provenance.

The model shall distinguish:

- displacement field;
- absolute-position field; and
- velocity field.

No interpretation shall be inferred solely from vector count.

---

## 55. Canonical serialisation

### 55.1 Purpose

Serialisation supports:

- validation;
- cache manifests;
- distributed contracts;
- provenance;
- debugging; and
- document examples.

It does not imply a complete persistent scientific file format.

### 55.2 Initial format

The initial reference serialisation shall be canonical JSON for descriptors and records.

YAML may be used for human-authored manifests under validated schemas.

### 55.3 Canonical JSON requirements

Canonical JSON shall define:

- UTF-8;
- stable key order;
- no insignificant whitespace in digest form;
- stable numeric representation;
- explicit enum tags;
- base64 or hexadecimal binary encoding;
- UTC instant syntax;
- schema version;
- rejection of duplicate keys; and
- treatment of non-finite floating-point values.

### 55.4 Sample data

Large sample bytes shall not be embedded in descriptor JSON by default.

They shall be referenced by:

- content ID;
- relative artefact path;
- object-store URI;
- brick manifest; or
- storage adapter identity.

### 55.5 Schema evolution

Every serialised top-level structure shall include or be wrapped by a schema version.

Readers shall:

- reject unsupported major versions;
- permit compatible minor additions according to schema rules;
- preserve unknown namespaced metadata where safe; and
- avoid silent reinterpretation.

---

## 56. Identity canonicalisation

A canonical descriptor digest shall use:

- canonical JSON;
- normalised identifier strings;
- stable enum encoding;
- ordered axes;
- ordered metadata where metadata is included;
- stable matrix element order;
- explicit absent versus null handling; and
- no process memory addresses.

Where floating-point values participate in identity:

- NaN shall not be permitted unless a canonical bit pattern and semantic rule are defined;
- negative zero shall be canonicalised where semantic equality requires it;
- infinity shall be rejected unless explicitly permitted; and
- approximate geometric equivalence shall not imply equal content identity.

---

## 57. Concurrency and ownership

### 57.1 `Sendable`

All canonical descriptors and records shall be `Sendable`.

Storage and type-erasure implementations shall be `Sendable` only when their ownership and immutability guarantees are valid.

### 57.2 Shared mutable state

The core data model shall contain no shared mutable global state.

Lazy digest caches or mapped-resource state shall use:

- actor isolation;
- lock-protected internal state with documented invariants; or
- immutable one-time initialisation.

### 57.3 `@unchecked Sendable`

Every use shall be:

- isolated;
- justified;
- documented;
- independently reviewed; and
- stress tested.

### 57.4 Unsafe bytes

Unsafe byte access shall be scoped to a closure whose pointer cannot escape.

The storage owner shall remain alive for the closure duration.

### 57.5 Lifetime

Views, mapped regions and no-copy storage shall retain their backing owner for the complete read lifetime.

---

## 58. Error model

### 58.1 Common data-model error

```swift
public enum DataModelError: Error, Sendable, Equatable {
    case invalidIdentifier
    case invalidShape(ShapeError)
    case invalidRegion(RegionError)
    case axisCountMismatch
    case duplicateAxisIdentifier
    case invalidScalarFormat
    case invalidComponentDescriptor
    case semanticMismatch
    case invalidValueTransform
    case invalidCoordinateSpace
    case invalidGeometry
    case incompatibleGeometry
    case singularTransform
    case coordinateSpaceMismatch
    case storageDescriptorMismatch
    case unsupportedStorageCapability
    case invalidContentIdentity
    case duplicateMetadataKey
    case invalidProvenance
    case provenanceCycle
    case invalidGeometryAttribute
    case meshIndexOutOfBounds
    case invalidSegmentation
    case invalidRegistrationResult
    case arithmeticOverflow
    case cancelled
}
```

The final implementation may use more specialised error types while preserving actionable context.

### 58.2 Context

Errors should carry:

- field;
- axis;
- expected value;
- actual value;
- source object identity; and
- remediation guidance

where safe and useful.

### 58.3 Privacy

Error descriptions shall avoid source metadata that may identify a patient unless the host explicitly enables such detail.

---

## 59. Validation state

The data model may attach integrity state separately from diagnostic validation.

```swift
public enum DataIntegrityState: Sendable, Hashable, Codable {
    case unknown
    case structurallyValid
    case checksumVerified(ContentID)
    case contentVerified(ContentID)
    case failed(reason: String)
}
```

Integrity state describes data consistency.

It does not declare that an algorithm or clinical interpretation is validated.

---

## 60. DICOMKit adapter mapping

### 60.1 Boundary

`VoxeliaDICOMKit` shall translate DICOMKit output into canonical Voxelia objects.

DICOMKit types shall not enter `VoxeliaCore` or `VoxeliaSpatial`.

### 60.2 Mapping table

| DICOM concept | Voxelia destination |
|---|---|
| Rows and Columns | `ImageShape` extents |
| Number of frames or series frame count | frame or additional axis extent |
| Bits allocated and pixel representation | `ScalarFormat` |
| Bits stored | `validBitCount` and decoder provenance |
| Samples per pixel | `ComponentDescriptor.count` |
| Photometric interpretation | semantic and namespaced metadata |
| Planar configuration | `ComponentLayout` or decoded-layout provenance |
| Pixel spacing | affine basis or frame geometry |
| Image orientation | affine basis or frame geometry |
| Image position | affine origin or frame geometry |
| Frame of reference UID | `ExternalFrameReference` |
| Rescale slope and intercept | `ValueTransform.linear` |
| Modality LUT | `ValueTransform.lookupTable` |
| Pixel padding | typed metadata used by processing and presentation |
| SOP Instance UID and frame number | `SourceIdentity` |
| Segment metadata | `SegmentDescriptor` |
| Spatial registration | `RegistrationResult` or transform descriptor |
| Deformable registration | deformation-field transform |
| Encapsulated transfer syntax | compressed-storage and codec provenance |

### 60.3 Regular-series assembly

The adapter shall:

- order frames using physical geometry;
- assess regularity;
- create `AffineGridGeometry` only when justified;
- create `FrameSetGeometry` for irregular data;
- preserve source identities; and
- report missing, duplicated or contradictory geometry.

### 60.4 Stored values

The adapter shall distinguish:

- compressed source;
- decoded stored value;
- authoritative modality-transformed value; and
- presentation value.

### 60.5 Source metadata

Unmapped DICOM attributes may be retained using a DICOM namespace.

They shall not replace canonical fields already extracted.

### 60.6 Privacy

The adapter shall not place patient-identifying attributes into generic provenance or logs by default.

---

## 61. Codec adapter mapping

`VoxeliaCompression` shall translate codec capabilities into:

- `CodecIdentifier`;
- `CompressedRepresentationDescriptor`;
- storage capabilities;
- decoded destination descriptors;
- region and resolution access;
- content identity;
- integrity;
- cancellation; and
- provenance.

Codec-specific types shall remain inside the adapter.

The same logical data may have multiple compressed representations.

Each representation shall have its own identity while referencing the same decoded logical identity when lossless equality has been verified.

---

## 62. Metal residency boundary

`VoxeliaMetal` may derive:

- `MTLBuffer`;
- `MTLTexture`;
- heaps;
- sparse textures;
- acceleration structures; and
- private resource caches

from canonical data.

These resources shall not be stored in `ImageDescriptor`, `ImageData`, `MeshDescriptor` or `MeshData`.

Residency shall be keyed by:

- data identity;
- region or brick;
- representation;
- scalar and component layout;
- quality level;
- device identity; and
- resource-generation state.

GPU resource eviction shall not change canonical data identity.

---

## 63. RealityKit and Model I/O boundaries

RealityKit and Model I/O adapters may translate canonical geometry into framework-specific assets.

They shall not:

- become the authoritative mesh store;
- define patient or scientific coordinate semantics;
- change topology silently;
- change units silently;
- change winding order without provenance; or
- replace canonical measurements.

Round trips shall document any unsupported attributes or precision loss.

---

## 64. Validation requirements

### 64.1 Shape and index

Validation shall cover:

- rank one through representative high rank;
- invalid extents;
- overflow;
- index bounds;
- stride calculation; and
- serialisation.

### 64.2 Axis and descriptor

Validation shall cover:

- rank mismatch;
- duplicate axis IDs;
- irregular coordinate count;
- semantic contradictions;
- value-transform composition;
- unit handling; and
- stable descriptor digest.

### 64.3 Spatial

Validation shall cover:

- identity;
- translation;
- rotation;
- scale;
- reflection;
- anisotropy;
- composition;
- inversion;
- singularity;
- coordinate convention;
- affine bounds;
- rectilinear coordinates;
- frame-set irregularity; and
- physical measurement.

### 64.4 Regions and views

Validation shall cover:

- crop;
- slice;
- permutation;
- reversal;
- subsampling;
- geometry derivation;
- source lifetime;
- zero-copy behaviour; and
- explicit materialisation.

### 64.5 Identity

Validation shall cover:

- canonical descriptor digest;
- same logical data in different physical layouts;
- source versus content identity;
- lazy digest;
- corrupted content;
- derivation parameter changes; and
- serialisation stability.

### 64.6 Metadata and provenance

Validation shall cover:

- typed access;
- duplicate keys;
- namespacing;
- privacy classification;
- DAG cycle detection;
- source references;
- operation and backend records; and
- canonical serialisation.

### 64.7 Storage

Validation shall cover:

- descriptor compatibility;
- contiguous reads;
- mapped lifetime;
- region reads;
- cancellation;
- partial failure;
- boundary bricks;
- halos;
- multi-resolution geometry;
- integrity; and
- thread safety.

### 64.8 Geometry

Validation shall cover:

- attribute counts;
- index bounds;
- topology descriptors;
- coordinate spaces;
- content identity;
- mapped storage; and
- framework-adapter round trips.

### 64.9 Segmentation

Validation shall cover:

- label maps;
- overlapping segments;
- fractional domains;
- explicit lossy conversion;
- segment identity;
- geometry; and
- provenance.

### 64.10 Registration

Validation shall cover:

- moving-to-fixed direction;
- space compatibility;
- convergence status;
- non-converged results;
- transform identity;
- deformation-field semantics; and
- provenance.

---

## 65. Property-based testing

Property-based tests should assert:

- region intersection is commutative;
- crop followed by materialisation preserves logical values;
- axis permutation followed by inverse permutation restores descriptor and values;
- affine composition matches sequential point mapping;
- invertible transform followed by inverse returns within tolerance;
- content digest is independent of physical padding;
- descriptor digest changes when interpretation changes;
- view construction never creates out-of-bounds source access;
- conversion from label image to segment collection and back is lossless when segments do not overlap;
- provenance graph remains acyclic; and
- brick partition covers the full volume without gap or unintended overlap in logical regions.

---

## 66. Performance constraints of the model

The model shall be designed so that:

- descriptor construction does not read full sample data;
- shape and region operations are O(rank);
- affine point transformation is constant time;
- metadata lookup may be indexed internally;
- content digest may be lazy;
- views avoid copying when possible;
- `AnyImageStorage` introduces bounded dispatch overhead;
- geometry descriptors do not require GPU allocation;
- large manifests can be streamed or incrementally decoded; and
- serialisation of descriptors does not embed large sample buffers.

Performance optimisation shall not weaken invariants.

---

## 67. Memory constraints

The implementation shall:

- detect multiplication overflow before allocation;
- avoid retaining duplicate canonical metadata unnecessarily;
- permit metadata interning internally without exposing shared mutation;
- avoid copying descriptor collections on every read;
- permit mapped and borrowed immutable storage;
- avoid storing complete brick manifests redundantly per brick;
- permit compact provenance references; and
- retain source owners only as long as required.

---

## 68. API evolution

### 68.1 Pre-1.0

During `0.x`:

- public types may change;
- breaking changes shall be documented;
- serialised schema versions shall remain explicit;
- migrations should be supplied for persisted project artefacts; and
- speculative public fields shall be avoided.

### 68.2 Post-1.0

After 1.0:

- field removal or semantic reinterpretation requires a major version;
- new optional serialised fields may be added under schema compatibility rules;
- enum expansion implications shall be documented;
- deprecations shall include migration guidance; and
- diagnostic interpretation changes require validation and release notes.

### 68.3 Frozen representation

Swift memory layout shall not be treated as a stable serialisation or binary ABI.

No type shall be marked `@frozen` solely for performance before compatibility implications are approved.

---

## 69. Initial public API sequence

Implementation should proceed in this order:

1. identifiers and versions;
2. units;
3. shape and index;
4. region;
5. axis model;
6. scalar and component descriptors;
7. image semantic and value transform;
8. coordinate spaces and matrix;
9. affine geometry;
10. image descriptor;
11. metadata;
12. provenance;
13. data identity;
14. storage descriptors and protocol;
15. contiguous storage;
16. image data handle;
17. views;
18. rectilinear and frame-set geometry;
19. bricked descriptors;
20. geometry descriptors and storage;
21. segmentation model; and
22. registration result model.

No Metal or DICOMKit implementation shall be needed to complete items 1 through 17.

---

## 70. Milestone M1 acceptance criteria

M1 core data-model work shall not be accepted until:

### 70.1 Shape, index and region

- [ ] Dynamic-rank shape exists.
- [ ] Non-positive extents are rejected.
- [ ] Element-count overflow is detected.
- [ ] Zero-based index convention is documented and tested.
- [ ] Half-open regions are implemented.
- [ ] Region bounds and arithmetic are validated.

### 70.2 Axes and samples

- [ ] Axis descriptors exist.
- [ ] Axis count is validated against rank.
- [ ] Scalar formats cover required integer and floating types.
- [ ] Scalar format properties are tested.
- [ ] Components are distinct from axes.
- [ ] Image semantics are represented.
- [ ] Value transforms are explicit and tested.

### 70.3 Spatial model

- [ ] Coordinate-space descriptors exist.
- [ ] Double-precision 4×4 matrix exists.
- [ ] Affine-grid geometry exists.
- [ ] Index-to-world and world-to-index are tested.
- [ ] Singular transform produces typed failure.
- [ ] Physical bounds are tested.
- [ ] Convention conversion is explicit.
- [ ] Rectilinear and frame-set model stubs or reviewed designs exist without false regularisation.

### 70.4 Descriptor and identity

- [ ] `ImageDescriptor` exists and is storage-independent.
- [ ] Structural validation passes.
- [ ] Descriptor canonical serialisation exists.
- [ ] `DataIdentity`, `SourceIdentity` and `ContentID` exist.
- [ ] Content-scope semantics are documented.
- [ ] Descriptor-and-sample digest design is validated on small data.

### 70.5 Metadata and provenance

- [ ] Namespaced metadata exists.
- [ ] Typed access is tested.
- [ ] Duplicate-key behaviour is defined.
- [ ] Provenance record exists.
- [ ] Provenance graph cycle detection exists.
- [ ] Technical provenance excludes patient-identifying data by default.

### 70.6 Storage

- [ ] Storage descriptor and capabilities exist.
- [ ] Storage protocol exists.
- [ ] Type erasure exists.
- [ ] `@unchecked Sendable`, if used, is reviewed.
- [ ] Contiguous immutable storage exists.
- [ ] Region read tests pass.
- [ ] Storage compatibility validation passes.
- [ ] Builder commit returns immutable `ImageData`.

### 70.7 Views

- [ ] Crop view exists.
- [ ] Slice view exists.
- [ ] Axis permutation and reversal are designed and tested.
- [ ] View geometry is derived correctly.
- [ ] Source lifetime is retained.
- [ ] Explicit materialisation exists.
- [ ] Zero-copy claims are demonstrated.

### 70.8 Geometry

- [ ] Point-set and triangle-mesh descriptors exist.
- [ ] Position attributes are required.
- [ ] Index bounds are validated.
- [ ] Geometry coordinate spaces are explicit.
- [ ] Mesh identity and provenance exist.

### 70.9 Quality

- [ ] All public types compile under Swift 6 strict concurrency.
- [ ] No prohibited framework import appears in core modules.
- [ ] Unit and property-based tests pass.
- [ ] Validation report is reviewed.
- [ ] Requirement traceability is complete for M1 P0 requirements.
- [ ] Known limitations are documented.

---

## 71. M1 evidence package

Recommended evidence:

```text
docs/releases/m1/
├── M1_Evidence_Index.md
├── M1_Core_Data_Model_Validation_Report.md
├── Shape_and_Region_Test_Report.md
├── Spatial_Transform_Validation_Report.md
├── Descriptor_and_Identity_Report.md
├── Metadata_and_Provenance_Report.md
├── Storage_and_View_Report.md
├── Geometry_Model_Report.md
├── Strict_Concurrency_Report.md
├── Requirement_Traceability.yaml
└── checksums.sha256
```

---

## 72. Open implementation decisions

The following decisions may require focused ADRs during implementation:

1. exact canonical JSON library or implementation;
2. digest algorithm required for cross-system identity;
3. whether `Data` is permitted directly in core serialisable metadata;
4. internal metadata indexing strategy;
5. exact `AnyImageStorage` type-erasure implementation;
6. safe destination-buffer API design;
7. SIMD versus custom vector types at public boundaries;
8. matrix storage and multiplication implementation;
9. representation of two-dimensional geometry in a 4×4 transform;
10. exact index-view transform representation;
11. handling of negative view steps in storage providers;
12. canonical colour-space metadata;
13. exact probability-domain descriptor;
14. deformation-field outside-domain policy;
15. compact provenance graph representation;
16. persistent brick-manifest schema;
17. geometry attribute-buffer storage abstraction;
18. binary serialisation after canonical JSON;
19. public module re-export policy; and
20. which future segmentation and registration types become public before M7.

An open decision shall not be resolved implicitly by the first convenient implementation.

---

## 73. Acceptance criteria for this specification

This specification is ready to govern implementation when reviewers agree that it:

- conforms to the Project Foundation;
- conforms to the Master Technical Architecture;
- covers the applicable Requirements Baseline domains;
- respects repository module ownership;
- defines dynamic-rank shape and indexing;
- defines scalar, component and semantic models;
- defines axis and value-transform models;
- defines explicit spatial coordinate systems;
- defines affine, rectilinear and frame-set geometry;
- defines regions and views;
- defines immutable data and identity;
- defines typed metadata and provenance;
- defines backend-neutral storage;
- defines bricked and compressed descriptors;
- defines geometry, segmentation and registration result models;
- defines DICOMKit, codec and Metal boundaries;
- defines concurrency and serialisation rules;
- defines validation and M1 acceptance; and
- does not silently resolve its listed open implementation decisions.

---

# Appendix A — Core type inventory

| Type | Module | Initial milestone |
|---|---|---:|
| `SemanticVersion` | `VoxeliaCore` | M1 |
| `MeasurementUnit` | `VoxeliaSpatial` or shared foundational target as approved | M1 |
| `ImageShape` | `VoxeliaCore` | M1 |
| `ImageIndex` | `VoxeliaCore` | M1 |
| `ImageRegion` | `VoxeliaCore` | M1 |
| `AxisDescriptor` | `VoxeliaCore` | M1 |
| `ScalarType` | `VoxeliaCore` | M1 |
| `ScalarFormat` | `VoxeliaCore` | M1 |
| `ComponentDescriptor` | `VoxeliaCore` | M1 |
| `ImageSemantic` | `VoxeliaCore` | M1 |
| `ValueTransform` | `VoxeliaCore` | M1 |
| `CoordinateSpaceDescriptor` | `VoxeliaSpatial` | M1 |
| `Matrix4x4Double` | `VoxeliaSpatial` | M1 |
| `SpatialAxisMapping` | `VoxeliaSpatial` | M1 |
| `AffineGridGeometry` | `VoxeliaSpatial` | M1 |
| `RectilinearGridGeometry` | `VoxeliaSpatial` | M1/M7 |
| `FrameSetGeometry` | `VoxeliaSpatial` | M1/M4 |
| `SpatialGeometry` | `VoxeliaSpatial` | M1 |
| `ImageDescriptor` | `VoxeliaCore` | M1 |
| `MetadataCollection` | `VoxeliaCore` | M1 |
| `ProvenanceRecord` | `VoxeliaCore` | M1/M2 |
| `ContentID` | `VoxeliaCore` | M1 |
| `DataIdentity` | `VoxeliaCore` | M1/M2 |
| `StorageDescriptor` | `VoxeliaStorage` | M1 |
| `StorageCapabilities` | `VoxeliaStorage` | M1 |
| `ImageStorage` | `VoxeliaStorage` | M1 |
| `AnyImageStorage` | `VoxeliaStorage` | M1 |
| `ImageData` | `VoxeliaCore` with storage dependency as approved by architecture | M1 |
| `ImageView` | `VoxeliaCore`/`VoxeliaStorage` boundary as approved | M1 |
| `BrickDescriptor` | `VoxeliaStorage` | M5 |
| `CompressedRepresentationDescriptor` | `VoxeliaStorage` | M5 |
| `GeometryDescriptor` | `VoxeliaGeometry` | M1 |
| `MeshDescriptor` | `VoxeliaGeometry` | M1 |
| `MeshData` | `VoxeliaGeometry` | M1 |
| `Segmentation` | `VoxeliaSegmentation` | M7 |
| `RegistrationResult` | `VoxeliaRegistration` | M7 |

---

# Appendix B — Canonical logical ordering

For canonical contiguous interleaved storage:

```text
component changes fastest
then axis 0
then axis 1
...
then axis rank - 1
```

For a scalar image, component count is one.

For shape:

```text
[e0, e1, e2]
```

and index:

```text
[i0, i1, i2]
```

the scalar logical offset is:

```text
i0 + e0 × (i1 + e1 × i2)
```

For interleaved components:

```text
component + componentCount × scalarLogicalOffset
```

Physical storage may differ, but the storage adapter shall expose equivalent logical values.

---

# Appendix C — Affine convention example

For a three-dimensional affine grid:

```text
index = [i, j, k, 1]ᵀ
world = indexToWorld × index
```

A matrix may be constructed as:

```text
| bx.x  by.x  bz.x  origin.x |
| bx.y  by.y  bz.y  origin.y |
| bx.z  by.z  bz.z  origin.z |
| 0     0     0     1        |
```

where `bx`, `by` and `bz` are physical basis vectors per index step.

Their magnitudes provide spacing.

Integer indices map to sample centres.

---

# Appendix D — Example image descriptor

```json
{
  "shape": {
    "extents": [512, 512, 320]
  },
  "scalarFormat": {
    "type": "int16",
    "validBitCount": 12,
    "byteOrder": "native"
  },
  "components": {
    "count": 1,
    "interpretation": "scalar",
    "layout": "interleaved",
    "componentNames": null
  },
  "semantic": "intensity",
  "axes": [
    {
      "id": "column",
      "name": "Column",
      "semantic": "spatialX",
      "unit": null,
      "sampling": {
        "regular": {
          "origin": 0.0,
          "spacing": 1.0
        }
      }
    },
    {
      "id": "row",
      "name": "Row",
      "semantic": "spatialY",
      "unit": null,
      "sampling": {
        "regular": {
          "origin": 0.0,
          "spacing": 1.0
        }
      }
    },
    {
      "id": "slice",
      "name": "Slice",
      "semantic": "spatialZ",
      "unit": null,
      "sampling": {
        "regular": {
          "origin": 0.0,
          "spacing": 1.0
        }
      }
    }
  ],
  "spatialGeometry": {
    "affineGrid": {
      "spatialAxes": {
        "imageAxes": [0, 1, 2]
      },
      "indexToWorld": {
        "elements": [
          0.7, 0.0, 0.0, -180.0,
          0.0, 0.7, 0.0, -180.0,
          0.0, 0.0, 1.0, -160.0,
          0.0, 0.0, 0.0, 1.0
        ]
      },
      "coordinateSpace": {
        "id": {
          "rawValue": "dicom.frame-of-reference.1"
        },
        "convention": "dicomPatientLPS",
        "handedness": "rightHanded",
        "unit": {
          "namespace": "UCUM",
          "code": "mm",
          "displayName": "millimetre",
          "dimension": "length",
          "scaleToCanonical": 0.001,
          "offsetToCanonical": 0.0
        },
        "externalReferences": []
      }
    }
  },
  "valueTransform": {
    "linear": {
      "scale": 1.0,
      "offset": -1024.0
    }
  },
  "units": {
    "namespace": "DICOM",
    "code": "HU",
    "displayName": "Hounsfield unit",
    "dimension": "dimensionless",
    "scaleToCanonical": null,
    "offsetToCanonical": null
  }
}
```

The exact generated `Codable` representation may differ. Canonical schema shall be documented before digest use.

---

# Appendix E — Example provenance chain

```text
DICOM source frames
    │
    ├── imported by VoxeliaDICOMKit
    │
    ├── decoded by J2KSwift / other approved codec
    │
    ├── assembled as FrameSetGeometry
    │
    ├── validated as regular
    │
    ├── represented as AffineGridGeometry
    │
    └── published as immutable ImageData
            │
            ├── source identities
            ├── descriptor digest
            ├── content digest when available
            └── provenance references
```

Each derivation shall preserve the preceding technical identities without requiring patient-identifying metadata.

---

# Appendix F — Example storage compatibility checks

Binding a descriptor to storage shall reject:

- shape mismatch;
- scalar container mismatch;
- component-count mismatch;
- incompatible component layout without an adapter;
- insufficient byte length;
- invalid stride;
- unsupported byte order;
- packed data presented as unpacked;
- mutable externally changing content under an immutable identity;
- brick manifest whose regions do not cover the declared volume; and
- compressed storage whose decoded descriptor does not match the image descriptor.

---

# Appendix G — Foundation statement

The Voxelia core data model shall provide:

> **A stable, immutable, dynamic-rank and backend-neutral representation of scientific images, volumes, geometry and their spatial meaning, with explicit sample semantics, coordinate systems, storage contracts, identity, metadata and provenance. It shall preserve authoritative data independently from source formats, GPU resources and presentation, while enabling efficient zero-copy views, bricked storage, DICOM integration, validation and distributed execution.**
