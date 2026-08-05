---
document_id: "ADR-0192"
title: "Labelled surface extraction design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-010"
  - "VOX-ARC-005"
  - "VOX-ARC-007"
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-CPU-001"
  - "VOX-CPU-006"
  - "VOX-DAT-009"
  - "VOX-DAT-012"
  - "VOX-ERR-001"
  - "VOX-SEC-001"
  - "VOX-SEC-002"
  - "VOX-SEC-011"
  - "VOX-META-003"
  - "VOX-META-004"
  - "VOX-META-005"
  - "VOX-META-006"
  - "VOX-GEO-006"
  - "VOX-GEO-007"
  - "VOX-GEO-008"
  - "VOX-GEO-011"
---

# ADR-0192 - Labelled surface extraction design

## Context

Accepted `ADR-0183` requires labelled extraction to be frozen separately from
scalar interpolation. The scalar reference and publication boundary are now
implemented, but applying an isovalue to a label image would invent an order
and distance between categorical identifiers. A labelled operation still has
observable choices of its own: integer container domain, requested-set
canonicalisation, selected-selected interfaces, source-boundary treatment,
edge position, ordering, coordinate winding, resource ceilings, cancellation
and result identity.

The M7 segmentation model will later represent binary, fractional, sparse and
overlapping segments. This M6 operation cannot pre-empt that model. It operates
only on one mutually exclusive integer label image and returns the boundary of
one exact requested label union. It neither claims that a label value is a
segment identity nor converts overlapping segment collections into a label
image. The project owner authorised continued autonomous governance,
implementation and verified pushes; this record freezes the design and its
independent evidence before product source.

## Decision

1. **The v1 result is one requested-set union.** A sample is selected exactly
   when its decoded stored integer is a member of the requested set. The output
   is the boundary between selected and unselected membership in the fixed
   Freudenthal tetrahedralisation. An interface between two selected labels is
   absent, as is an interface between two unselected labels. Requesting every
   value present in the source or only absent values therefore returns a valid
   empty mesh. There is no implicit background value, per-label mesh fan-out,
   label priority, tolerance or range comparison.
2. **The requested set preserves the complete integer domain.** The later
   Geometry increment adds an immutable `LabelledSurfaceLabelSet` with exactly
   `signed(ContiguousArray<Int64>)` and
   `unsigned(ContiguousArray<UInt64>)` cases. Values must be nonempty, strictly
   increasing and unique. The declaration remains constructible before
   admission so the cancellable operation, rather than an initializer, applies
   failure precedence. Signed and unsigned values are never coerced across
   domains, even when their mathematical values appear equal. Values outside a
   narrower matching source container remain valid but simply cannot match.
3. **Resource authority is explicit.** `LabelledSurfaceExtractionLimits`
   contains required positive `maximumSelectedLabelCount`,
   `maximumVertexCount` and `maximumTriangleCount` values, with no defaults.
   The operation's hard v1 requested-label ceiling is 65,536; a host ceiling
   above it is `invalidLimits`, while a valid request whose set exceeds its
   host ceiling is `resourceLimitExceeded`. The requested set is searched in
   place by binary search; execution does not allocate an unbounded hash set.
   Cell counts, source byte counts, prospective new vertices, triangles,
   indices and parameter-document sizes use checked arithmetic.
4. **Source admission is closed.** The source must have rank three, exactly one
   component whose interpretation is exactly `.scalar`, semantic exactly
   `.label`, an affine spatial-axis permutation of image axes zero through two,
   exact maximum-index binary64 representability and the finite non-zero
   determinant rule from `VOXELIA-ALG-0028`. Units must be absent. A value
   transform must be absent or exactly `.identity`; linear, lookup and composed
   transforms reject because label identifiers are decoded categorical values,
   not calibrated scalar measurements. A narrower `validBitCount` rejects
   until bit placement or an upstream normalisation operation is accepted.
5. **All native integer containers are exact.** `int8`, `uint8`, `int16`,
   `uint16`, `int32`, `uint32`, `int64` and `uint64` are admitted in native,
   little-endian and big-endian storage order. The requested-set case must match
   source signedness. Float containers reject, including integral-looking
   values. The decoder compares in the source integer domain and never converts
   a label through `Double`, so `Int64.min`, `Int64.max` and `UInt64.max`
   remain distinguishable.
6. **Adjacency is simplicial, not morphological.** The surface is the
   piecewise-linear membership boundary induced by the global six-tetrahedron
   Freudenthal subdivision frozen in `VOXELIA-ALG-0029`. It makes no separate
   6-, 18- or 26-connected component claim. Every tetrahedral edge whose
   endpoints have opposite membership is intersected at its exact image-space
   midpoint. Label magnitudes cannot move that point. Only complete source
   cells are visited; there is no ghost exterior, cap or padding rule.
7. **Topology and coordinates reuse only frozen structural rules.** Cell,
   tetrahedron, case-table, triangle and edge order are the same global order
   as the accepted scalar reference, but the algorithm has a distinct identity
   and no scalar interpolation branch. A vertex key is the ascending pair of
   global sample ordinals for one opposite-membership edge. Positions are
   authoritative `Double`, transformed by the exact source affine evaluation
   order. An image midpoint must represent its specified dyadic value exactly;
   ordinary correctly rounded affine arithmetic is accepted, while any
   non-finite affine intermediate or result fails. Negative effective image-to-
   world orientation swaps every triangle's second and third index so physical
   winding remains selected-to-unselected.
8. **Geometry owns immutable public declarations only.** The later source
   increment adds `LabelledSurfaceExtractionLimits`,
   `LabelledSurfaceLabelSet`, `LabelledSurfaceExtractionRequest`,
   `LabelledSurfaceExtractionPublicationContext` and
   `LabelledSurfaceExtractionResult` to `VoxeliaGeometry`. Request fields are
   the immutable `ImageData` source, label set and limits. Publication context
   contains caller-supplied `DataObjectID`, `ProvenanceID`,
   `CanonicalInstant` and `SoftwareIdentity`. The result atomically binds one
   complete `TriangleMesh`, `DataIdentity` and `ProvenanceRecord`. No type is
   mutable, backend-bearing, `Codable` or speculatively `Hashable`.
9. **The result carries no invented segment attribute.** One union can contain
   multiple requested label values, so no single label can authoritatively be
   attached to every output vertex or primitive. The exact requested set is
   bound by the parameter digest. Per-label batches, face-side label pairs,
   segment descriptors, connected components and overlapping-segment output
   require separate contracts. The result otherwise applies the complete
   scalar result-binding checks with its own operation identity, including the
   exact source input/parent and source coordinate descriptor.
10. **CPU owns reading and reference execution.** A stateless
    `CPULabelledSurfaceExtractionOperation` later composes exactly one bounded
    full-rank `StorageReadCoordinator` read, releases the retention token after
    staging owned bytes, validates/decodes with one shared integer decoder and
    executes the reference kernel. Geometry does not read storage; Execution
    does not own the geometry kernel; no dependency edge beyond the accepted
    `VoxeliaCPU -> {VoxeliaGeometry, VoxeliaExecution}` graph is needed.
11. **The public error family is closed and payload-free.** It contains exactly
    `invalidLimits`, `invalidLabelSet`, `unsupportedSource`,
    `resourceLimitExceeded`, `positionNotRepresentable`, `sourceReadFailed`,
    `cancelled` and `publicationFailed`. Diagnostics expose no label values,
    coordinates, limits, source identity, storage failure or provenance.
12. **Admission and cancellation precedence are exact.** The CPU operation
    checks: task cancellation; positive limits and the 65,536 hard ceiling;
    nonempty label set; requested count against the host ceiling; strict order
    and uniqueness; source admission; one source read; then integer decoding in
    axis-zero-fastest order. Label-set and source-sample scans poll before item
    zero and every item whose ordinal is a multiple of 4,096; cancellation at a
    poll precedes validation/decoding that item. Traversal polls before cell
    zero and each canonical cell ordinal divisible by 64. Within a cell,
    midpoint representation, affine mapping and resource failures follow
    table order. A final cancellation check precedes all identity/provenance
    construction, and every failure returns no partial aggregate.
13. **Identity spellings and parameters are fixed.** The operation token is
    `org.voxelia.op.labelled-surface-extraction`; CPU implementation token is
    `org.voxelia.impl.labelled-surface-extraction.cpu`; both use version
    `1.0.0`. The algorithm identifier is
    `freudenthal-label-set-surface/binary64-v1`. Input role is
    `source-volume`, with provenance occurrence one. The unique technical
    parameter collection, in this order and under the operation namespace,
    contains:
    - `algorithm-identifier` with the exact algorithm string;
    - `label-domain` with `signed-integer` or `unsigned-integer`;
    - `selected-labels` as an order-preserving `MetadataArray` of exact
      signed- or unsigned-integer values;
    - `membership-rule` = `exact-decoded-label-in-requested-set`;
    - `adjacency-rule` = `freudenthal-piecewise-linear`; and
    - `boundary-rule` = `interior-cells-only`.

    VCMJ-1 bytes use a hard 4,194,304-byte emission ceiling and feed the
    registered operation-parameters digest. The 65,536-label maximum must be
    proven to fit that bound before implementation. Limits, cancellation
    cadence, output authority and software do not enter successful mesh
    identity. Successful CPU claims otherwise match the accepted scalar CPU
    profile/backend/binary64-strict/full/exact vocabulary and remain validation
    `.unknown` until complete conformance is accepted.
14. **Failure mapping is closed.** A descriptor-domain, semantic, component,
    transform, unit, valid-bit, signedness, geometry, maximum-index or sample-
    count admission failure is `unsupportedSource`. Checked cell-count,
    canonical-ordinal or output arithmetic overflow and caller output ceilings
    are `resourceLimitExceeded`; a requested-label count over its valid host
    ceiling has the same classification. Full-region construction, expected
    packed-byte overflow or mismatch, integer decoder offset/bounds failure,
    retention release failure and every non-cancellation coordinator provider,
    contract or budget failure are `sourceReadFailed`. Coordinator cancellation
    or an observed cancelled task is `cancelled`. A non-exact image midpoint or
    non-finite affine intermediate/result is `positionNotRepresentable`.
    An impossible repeated table key, mesh construction failure, parameter-
    document/digest failure or any identity, provenance or result-binding
    failure after complete traversal is `publicationFailed`. The final
    cancellation check occurs before those publication constructions, so it
    wins when observed there.

## Alternatives considered

### Apply a scalar isovalue to label identifiers

This would assign ordering and metric distance to categories and place a
surface according to arbitrary numeric magnitudes. Exact membership with a
fixed midpoint is categorical and remains stable when identifiers are renamed.

### Emit one surface per requested label

That model duplicates selected-selected interfaces and requires an aggregate
result, per-surface identity and face ownership policy not present in the
accepted mesh boundary. A caller may invoke the union operation separately for
individual singleton sets; a future governed batch must define its own atomic
publication.

### Use a virtual exterior background

An implicit background would close surfaces at the image boundary and change
area/volume according to a value absent from the source. Version one processes
complete interior cells only, matching the scalar reference's explicit
boundary authority.

### Convert every label to `Int64` or `Double`

`UInt64.max` cannot be represented by either conversion without loss or
failure, and a shared signed domain changes unsigned identity. The two exact
integer domains avoid a value-dependent admission rule.

### Admit masks and overlapping segment collections now

Mask value mappings, fractional thresholds, stable segment identity and
overlap are M7 semantics. Folding them into an integer label-image reference
would prematurely constrain `VOX-SEG-001` through `VOX-SEG-004`.

## Consequences

The operation has deterministic categorical semantics, exact 64-bit label
identity, bounded membership work and a topology directly comparable with the
accepted scalar binary-mask fixtures. Its deliberate limitation is one
mutually exclusive label image and one union mesh. The fixed Freudenthal
diagonal bias and possible twelve triangles per cell remain visible in the
algorithm identity.

## Affected modules

Documentation and the independent Python oracle only in this increment. The
planned implementation adds immutable declarations to `VoxeliaGeometry` and a
storage-composing reference to `VoxeliaCPU`; no Core, Spatial, Storage or
Execution ownership moves and no new package edge is required.

## Compatibility impact

None in this design-only increment. The later API is additive before 1.0. A
different membership, set canonicalisation, midpoint, diagonal, boundary,
winding or output-order rule requires a new algorithm/version and cannot
silently replace v1.

## Security impact

Requested labels are scientific input and may be sensitive-derived. They are
hashed into the technical parameter digest but never written into errors,
logs, warnings, identifiers or filenames. Exact read ownership, checked
arithmetic, explicit limits and no-partial publication remain mandatory.

## Performance and memory impact

The reference is `O(sampleCount log selectedLabelCount + emittedTriangles)`;
selected count is at most 65,536 and output state is bounded by caller limits.
The requested sorted array is searched without an execution hash-set copy.
No benchmark or throughput claim is made before Swift implementation.

## Validation impact

The independent oracle exhausts all 256 binary cube memberships and all 45,927
combinations of three raw labels, eight cube corners and seven nonempty label
subsets. It verifies all 4,096 two-cell binary shared-face patterns, exact
selected-to-unselected winding, selected-selected suppression, empty all/none
unions, reflected winding, every integer width/extreme and both explicit byte
orders. Registered digests are:

```text
cubeMembershipSHA256=4bed958ac7d25a4539de8a0cea28524271a89303c3e9e3fb0de0d311e5c6931d
cubeBinary64SHA256=154f1d57f1fe6491f9fe6267109fa46074ffba860d16f7284736388a434536aa
ternaryUnionSHA256=b4bfe7adc07d80b0231bff3be93e82adb42a3c7c8d0d72684899d7aa7ac6ef95
sharedFaceSHA256=d656b3f812750fd97813431fb9168d26e8f87ea1148f326cf6e2a83ef0a831e9
integerContainerSHA256=3bf3a336dfd94d366f4981ce0431e2ea42f126f48647e0ab39d3b6c3e6f54253
```

The CPU migration must reproduce the fixture positions bit-exactly, the full
index sequence and all failure/cancellation/publication classes. The oracle
does not validate Swift storage lifetime, parameter emission, concurrency or
provenance binding.

## Migration

1. Add the five immutable Geometry declaration/publication values and closed
   error family, including proof that the maximum parameter document fits its
   frozen byte ceiling.
2. Add the internal exact integer source adapter and labelled Freudenthal
   kernel with exhaustive differential, limit and cancellation evidence.
3. Add the public CPU operation and atomic identity/provenance result boundary,
   then register it only after complete conformance is green.
4. Continue the accepted geometry order with deterministic normals,
   authoritative measurement and backend-specific derived acceleration.

## Supersession

This record executes the labelled-design step of `ADR-0183` and composes the
mesh and publication patterns of `ADR-0189` through `ADR-0191`; it supersedes
no accepted record.

## References

- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](ADR-0189-coordinate-bearing-triangle-mesh.md)
- [ADR-0190 - Scalar surface extraction design](ADR-0190-scalar-surface-extraction-design.md)
- [ADR-0191 - Scalar surface operation and publication boundary](ADR-0191-scalar-surface-operation-boundary.md)
- [VOXELIA-ALG-0029 - Freudenthal label-set surface binary64-v1](../../algorithms/VOXELIA-ALG-0029-freudenthal-label-set-surface.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
