---
document_id: "ADR-0027"
title: "Frame geometry anchor-index boundary"
status: "Proposed"
date: "2026-08-02"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-ARC-001"
  - "VOX-ARC-002"
  - "VOX-ARC-003"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-DAT-001"
  - "VOX-DAT-005"
  - "VOX-DAT-008"
  - "VOX-DAT-013"
  - "VOX-SPA-012"
  - "VOX-DCM-011"
  - "VOX-ERR-001"
---

# ADR-0027 - Frame geometry anchor-index boundary

## Context

The approved package direction makes `VoxeliaSpatial` dependency-free and
makes `VoxeliaCore` depend on `VoxeliaSpatial`. Cycles are prohibited. The
Master Technical Architecture and `VOX-ARC-002` assign affine, rectilinear and
frame-set spatial geometry to Spatial, while the Core Data Model Specification
assigns the general dynamic-rank `ImageIndex` to Core.

Core Data Model Specification section 26 nevertheless declares a Spatial-owned
`FrameGeometry` with this field:

```swift
public let frameIndex: ImageIndex
```

Implementing that declaration in Spatial would require the prohibited reverse
dependency on Core. Moving the existing public `ImageIndex` would instead
relocate a general data-domain value already used by Core shape and region
APIs, while moving frame geometry upward would leave the Spatial-owned
`SpatialGeometry` aggregate with the same reverse dependency.

The field's semantics are also incomplete. `ImageIndex` is a full logical
image coordinate, but the specification does not state which components locate
the frame, what components on axes that vary within the frame mean, or how the
value relates to `FrameSetGeometry.frameAxis` and frame-array order. A scalar
frame ordinal would lose the future time, phase, energy, echo, diffusion and
other dimensions that the architecture requires enhanced multi-frame adapters
to preserve. A source DICOM frame number is provenance identity and must not be
repurposed as a logical image coordinate.

This proposal selects one full-rank, role-specific boundary value and the
minimum canonical anchor meaning needed for stable value identity. It does not
select frame-set ordering, sparse coverage, enhanced dimension tuples,
coordinate-space compatibility, regularity assessment or full geometry
construction. Its Proposed status does not authorise implementation or
controlled-document changes.

## Decision

If this ADR is accepted, `VoxeliaSpatial` will own these public values:

```swift
public enum FrameAnchorIndexError: Error, Sendable, Equatable {
    case emptyRank
    case componentOutsidePossibleImageRange(axis: Int, value: Int)
}

public struct FrameAnchorIndex: Sendable, Hashable, Codable {
    public let components: ContiguousArray<Int>
    public var rank: Int { components.count }

    public init<Components: Collection>(
        components: Components
    ) throws where Components.Element == Int
}
```

The controlled `FrameGeometry` declaration will replace and rename only the
conflicting field:

```swift
public let frameAnchorIndex: FrameAnchorIndex
```

A `FrameAnchorIndex` is one full logical parent-image coordinate at the origin
of a positioned full frame's local index coordinates. This initial contract is
limited to frames that span every mapped parent axis starting at parent index
zero. Cropped, tiled or subframe geometry whose local zero maps to a non-zero
parent coordinate requires a later explicit view or geometry contract. The
anchor is not:

- the ordinal of the value in `FrameSetGeometry.frames`;
- a DICOM or source frame number;
- `frameIdentity` or `SourceIdentity`;
- a physical point;
- a linear storage offset; or
- a substitute for Core's general `ImageIndex`.

Component order is logical image-axis order. Count, order and every component
participate in exact equality, hashing and serialised value identity. No lane
may later be ignored, normalised or reordered while retaining the same public
value.

The throwing initializer will materialise the supplied collection once and
apply these shape-independent rules in axis order:

1. an empty component collection throws `.emptyRank`;
2. every component must be in `0..<Int.max`; and
3. the first component outside that range throws
   `.componentOutsidePossibleImageRange(axis:value:)`.

`Int.max` is rejected because no valid `ImageShape` can contain it: an extent
is itself an `Int`, and index validity requires `component < extent`.
`Int.max - 1` remains structurally possible, although only a later shape-bound
check can prove it valid. The type imposes no small rank maximum and performs
no rank inference, upper-bound lookup, stride calculation, offset arithmetic,
axis sorting or source-identity conversion.

When a future `FrameGeometry` binds the anchor to its
`SpatialAxisMapping`, Spatial-owned validation must require:

- every mapped image-axis ordinal to be within `frameAnchorIndex.rank`; and
- the anchor component for every mapped axis to be exactly zero, because those
  axes vary within the frame and zero identifies their local origin.

This canonical anchor rule prevents geometrically equivalent frames from
carrying different ignored coordinates that would compare or encode
differently. It does not authorise `FrameGeometry`; the blocked coordinate-
space descriptor, matrix and frame-identity contracts still apply.

This decision does not define how the future per-frame `indexToWorld` matrix
consumes frame-local coordinates or maps their origin to physical space. That
scientific transform contract, including unused inputs, affinity tolerance,
inversion and coordinate-space compatibility, must be approved before
`FrameGeometry` construction is authorised.

Core will remain the owner of later descriptor binding that requires
`ImageShape`, axis descriptors or complete `ImageDescriptor` context. That
binding must validate at least:

- anchor rank equals image rank;
- every component is less than the corresponding extent;
- `frameAxis` and every mapped image axis are within image rank; and
- frame-set geometry and image-axis semantics are compatible.

The future Spatial-owned `FrameSetGeometry` contract must separately decide
frame-anchor uniqueness, collection order, the relationship between the
anchor's frame-axis component and array position, dense versus sparse coverage,
and treatment of additional non-frame axes. Those policies are not silently
assigned to Core by this decision. Until they are approved, no implementation
may ignore an anchor component or claim enhanced multidimensional frame-set
coverage.

Type-level Codable for `FrameAnchorIndex` will use exactly this keyed shape:

```json
{"components":[0,0,7,2]}
```

The derived `rank` will not be encoded. Decoding will require the one
`components` key, reject missing, null and distinct extra fields, require an
array of integers representable as `Int`, and call the validating initializer.
It will therefore reject empty arrays, negative values and `Int.max`.
Invariant failures will be reported as `DecodingError.dataCorrupted` at the
`components` coding path with the corresponding `FrameAnchorIndexError`
preserved as the underlying error. Strict extra-field rejection must inspect
arbitrary coding keys or use an equivalent schema layer; an enum containing
only the expected key is insufficient because it hides unknown fields.

Raw duplicate-key rejection, lexical integer canonicalisation, key order,
schema-version envelopes and resource limits belong to the canonical-JSON
byte-ingress layer. A general Swift `Decoder` may already have collapsed
duplicate keys or accepted equivalent numeric spellings such as `1.0` and
`1e0`; this value decoder does not claim to recover that lost lexical
information. If the value is serialised as a top-level artefact, the later
canonical serializer must provide the required schema-version wrapper.

Acceptance will require controlled corrections to Core Data Model
Specification sections 26 and Appendix A. Core's existing `ImageIndex`, shape
and region APIs remain unchanged. No public type alias, implicit conversion or
new dependency edge is authorised.

## Alternatives considered

### Add a Spatial dependency on Core

This preserves the current field spelling, but it creates a package cycle with
the existing `Core -> Spatial` edge and violates `VOX-ARC-001`. It is not
viable.

### Move ImageIndex into Spatial

This keeps one full-rank index type and an acyclic graph. It is not recommended
because `ImageIndex` is already a public Core value used by shape and region
APIs, the controlled inventory assigns it to Core, and a move or compatibility
alias would broaden migration and re-export policy far beyond one geometry
field. It also would not define the frame-local anchor meaning.

### Move frame geometry into Core

This removes the immediate import, but conflicts with the architecture's
Spatial ownership and leaves the Spatial-owned `SpatialGeometry` aggregate
depending upward on a Core payload. Moving the aggregate as well would be a
much broader module redesign.

### Introduce another shared foundational target

A new target could own a common index value. It is not recommended because it
changes products, package edges, release evidence and public module ownership
for one field when a role-specific Spatial leaf is sufficient.

### Use a scalar ordinal or infer the coordinate from array position

This is small for a dense single-axis stack, but it discards the prescribed
full-rank coordinate and cannot identify future combinations of time, phase,
energy, echo, diffusion or other axes. Sparse and enhanced frame models must
remain explicit rather than being forced into one ordinal.

### Store raw integer components on FrameGeometry

`ContiguousArray<Int>` would preserve the bits without a dependency, but it
would remove nominal role separation, discoverable validation and a stable
wire contract from the public API.

### Use a sparse axis-coordinate map

A map of axis/value pairs could encode only fixed axes. It is deferred because
the governing documents do not define key ordering, required axes, duplicate
handling, sparse coverage or enhanced dimension tuples. Selecting those now
would exceed this boundary correction.

### Preserve every ImageIndex value without standalone validation

This would mirror the current general Core index, including empty, negative and
`Int.max` components. It is not recommended for the specialised anchor because
none of those values can bind to a valid positive-rank image. Rejecting only
shape-independently impossible states gives the public value a stronger
invariant without guessing parent extents.

### Remove the field without replacement

Dense frame-array order could act as the frame-axis coordinate. It is not
recommended because it loses the explicit full-rank locator, silently selects
dense ordering semantics and leaves future non-frame dimensions without a
stable representation.

## Consequences

- Spatial can eventually carry a frame anchor without importing Core or
  changing the package graph.
- Core retains its general `ImageIndex` and every existing shape and region API.
- The role-specific value duplicates one ordered integer collection, but makes
  its frame-local anchor meaning and stricter possible-image invariant explicit.
- Full-rank information is preserved without claiming that the current
  frame-set aggregate already supports sparse or enhanced multidimensional
  coverage.
- Empty, negative and `Int.max` components are intentionally rejected even
  though Core's general unbound `ImageIndex` remains permissive.
- Exact component order becomes a source and type-level wire compatibility
  contract after implementation. Strict rejection of distinct extra keys means
  adding a new leaf field will require an explicit schema evolution decision.
- Canonical JSON and digest bytes remain separate work; synthesized or custom
  Codable alone is not cross-system identity evidence.
- `FrameGeometry`, `FrameSetGeometry`, `SpatialGeometry` and every operation on
  them remain blocked by their other unresolved contracts.

## Affected modules

If accepted, this decision affects `VoxeliaSpatial` as the owner and eventual
implementation site of `FrameAnchorIndex` and as the owner of future
frame-geometry-local validation. `VoxeliaCore` remains the owner of
`ImageIndex`, `ImageShape`, `ImageDescriptor` and shape-aware binding. Future
DICOMKit and Validation modules are downstream consumers only. No package edge,
product or current module ownership changes.

## Compatibility impact

No public `FrameGeometry`, `FrameSetGeometry`, `SpatialGeometry`,
`FrameAnchorIndex` or serialised fixture exists, so the controlled field rename
and type correction would not move a compiled symbol or existing artefact.
Existing `VoxeliaCore.ImageIndex` source and wire behaviour remain untouched.

Once implemented, `FrameAnchorIndex`, its error cases, the `components` field,
validation range and exact type-level encoding become compatibility contracts.
Pre-1.0 changes still require changelog and migration documentation.

## Security impact

Decoded component arrays are untrusted. Type-level validation prevents empty
and shape-independently impossible coordinates from reaching later geometry
identity or access decisions. The canonical byte-ingress layer must cap raw
payload and container sizes, and reject duplicate keys before handing a parsed
value to the leaf decoder or materialising an unbounded component array. This
value contains no patient identity, file path, pointer, storage offset or
executable behavior.

## Performance and memory impact

Construction and decoding are linear in rank and materialise one immutable
contiguous array. Equality and hashing are linear in rank. No floating-point
work, multiplication, stride calculation, storage access, sorting, registry
lookup or hidden normalisation occurs.

## Validation impact

After acceptance and leaf implementation, focused Spatial evidence must cover:

- rank-one, all-zero, multi-rank and high-rank construction;
- acceptance of `Int.max - 1` and deterministic rejection of empty, negative
  and `Int.max` components at first, middle and last positions, including
  `Int.min` and mixed invalid values;
- generic collection materialisation and exact component-order identity;
- `Sendable`, equality and hashing behaviour;
- the exact one-key encoding with no derived rank;
- strict rejection of missing, null, wrong-shape and multiple differently named
  extra fields;
- rejection of string, Boolean, null, fractional and out-of-`Int` array
  elements;
- decode-time invariant revalidation with the `components` coding path and
  typed underlying error; and
- a static package-graph check proving Spatial still has no target dependency.

Canonical byte-ingress tests for duplicate keys, numeric spelling, schema
wrapping and resource limits remain separate. Frame-local zero-anchor tests,
shape-bound upper limits, duplicate/order policy, sparse coverage and full
frame-set tests must wait for their respective approved contracts. No Swift
test is warranted while this ADR remains Proposed.

## Migration

After acceptance:

1. correct Core Data Model Specification section 26 to use
   `frameAnchorIndex: FrameAnchorIndex` and add the Spatial-owned value and
   error to Appendix A;
2. implement only `FrameAnchorIndex` and its strict type-level encoding in
   `VoxeliaSpatial`;
3. add focused Spatial tests, DocC and static package-graph evidence;
4. decide the remaining frame-set collection, sparse/enhanced coverage and
   Core descriptor-binding contracts before implementing `FrameGeometry`; and
5. update traceability, changelog and release-integrity evidence.

No migration step may begin while this ADR remains Proposed.

## Supersession

This Proposed ADR neither supersedes nor is superseded by another file-backed
ADR. If accepted, it resolves only the cited frame-index dependency boundary
through the controlled data-model correction in the Migration section. It does
not replace the MTA's accepted decision to preserve irregular data as frame
sets. While Proposed, it has no supersession effect.

## References

- [Voxelia Master Technical Architecture v0.1.1, sections 8.1, 8.2, 10.3, 31.4 and Appendix A](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 2, 6, 12, 23, 26, 27, 55, 60 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1, sections 11 and 18](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1, section 13 and Appendix B](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, sections 6.5 through 6.8, 6.29 and 6.34](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Existing VoxeliaCore ImageIndex implementation](../../../Sources/VoxeliaCore/Public/ImageIndex.swift)
