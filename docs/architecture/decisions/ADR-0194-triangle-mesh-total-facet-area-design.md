---
document_id: "ADR-0194"
title: "Triangle-mesh total facet area design"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-001"
  - "VOX-API-002"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-API-005"
  - "VOX-API-006"
  - "VOX-API-010"
  - "VOX-ARC-007"
  - "VOX-ARC-010"
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-CPU-001"
  - "VOX-CPU-006"
  - "VOX-ERR-001"
  - "VOX-SEC-001"
  - "VOX-SEC-002"
  - "VOX-SEC-011"
  - "VOX-META-003"
  - "VOX-META-004"
  - "VOX-META-005"
  - "VOX-META-006"
  - "VOX-GEO-002"
  - "VOX-GEO-003"
  - "VOX-GEO-006"
  - "VOX-GEO-010"
  - "VOX-GEO-011"
---

# ADR-0194 - Triangle-mesh total facet area design

## Context

Accepted `ADR-0183` places authoritative mesh measurement after the canonical
mesh, scalar and labelled extraction, and deterministic normal boundaries. All
of those are complete through accepted `ADR-0193`.

The read-only measurement contract audit recorded in `AUTONOMY_STATUS.md` on
2026-08-06 established that no accepted record fixes an implementable
mesh-measurement contract. `ADR-0143`/`VOXELIA-ALG-0018` governs one ordered
planar polygon's anchored vector-area magnitude and cannot select total-facet
versus union area, per-facet norm and reduction order, representability
handling, duplicate and degenerate policy, limits or cancellation for a mesh.
`ADR-0143`/`VOXELIA-ALG-0019` is explicitly a supplied voxel count multiplied
by an affine cell volume and expressly rejects mesh and contour volume; it
grants no authority for a polyhedral volume operation.

The audit further established that the canonical `TriangleMesh` proves neither
closure, orientation consistency, connected or nested shell meaning, nor
self-intersection status, and that the accepted extraction operations can emit
boundary-touching surfaces. A tetrahedral signed sum over an arbitrary admitted
mesh is therefore only an algebraic quantity and cannot honestly be published
under the Validation and Benchmark Strategy's enclosed-volume name.

The audit ended by offering the project owner two options: **Option A**, a
separately governed total-facet-area stage now with certified enclosed volume
as a distinct later stage; or **Option B**, one larger record governing both at
once. On 2026-08-06 the project owner responded to the recorded decision gate
with an explicit instruction to continue the autonomous work and to take the
project's own decisions: "I am approving you all permision please start work
and complete autonomously and you can take your own decisions." That is the
fresh authorization the gate required. **Option A is selected**, on the audit's
own recommendation: it is the smaller acceptance increment, it publishes only a
quantity the admitted mesh contract actually determines, and it leaves every
topology and orientation obligation to the record that will need them.

This record therefore freezes the total-facet-area contract only. It does not
open, pre-commit or constrain the enclosed-volume record beyond refusing to
publish an unverified algebraic volume under that name.

## Decision

1. **Version one measures total facet area only.** The operation reduces the
   admitted mesh to one unsigned binary64 scalar: the serial sum, in exact
   topology order, of each triangle's own area. It does not compute a union
   area, a closed-surface area, an enclosed volume, a per-shell or per-component
   decomposition, a projected area or a sampled approximation. The published
   quantity is a property of the supplied facet list, not of any surface that
   facet list may or may not bound.
2. **The measurement asserts no topology, orientation or manifold claim.**
   Winding is irrelevant because the per-facet magnitude is unsigned. Duplicate
   facets retain full multiplicity. Coincident, overlapping, self-intersecting,
   non-manifold, disconnected and boundary-touching facets are all admitted and
   all counted. The published API and documentation must say so explicitly, so
   that no consumer mistakes total facet area for a certified surface area.
3. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0031` defines `triangle-mesh-total-facet-area/binary64-v1`:
   triangle order, the ordered edge subtraction and cross product shared with
   `VOXELIA-ALG-0030`, exact-zero degeneracy, maximum-component-scaled
   Euclidean magnitude, the halving, serial topology-order accumulation and
   every representability failure. The CPU reference cannot use FMA, fast math,
   reassociation, `hypot`, compensated or pairwise summation, a sorted
   reduction, a parallel reduction or an epsilon. A different magnitude
   formulation or reduction requires another algorithm version.
4. **The unit is an explicit powered length unit.** Migration adds
   `PoweredLengthUnit` to `VoxeliaGeometry`: the source coordinate space's exact
   `MeasurementUnit` base plus a positive integer exponent, published as two
   separate immutable fields. Area publishes exponent two. The base unit's
   `scaleToCanonical` and `offsetToCanonical` are **not** raised, combined or
   reinterpreted, and the value grants no conversion authority; a consumer
   needing a canonical area derives its own conversion under its own accepted
   rule. Admission requires `UnitDimension.length` and a non-zero exponent.
   This closes the audit's finding that `MeasurementUnit` classifies a length
   without defining any squared or cubed unit algebra, without inventing a
   speculative general unit calculus and without the older Interaction
   measurements' bare-`Double` silence about their source units.
5. **Geometry owns five immutable declaration/publication values and one
   closed error family.** Migration adds `PoweredLengthUnit`,
   `TriangleMeshTotalFacetAreaLimits`,
   `TriangleMeshTotalFacetAreaRequest`,
   `TriangleMeshTotalFacetAreaPublicationContext`,
   `TriangleMeshTotalFacetAreaMeasurement` and
   `TriangleMeshTotalFacetAreaResult` to `VoxeliaGeometry`. Every stored field
   is immutable and `Sendable`; none is `Codable` or `Hashable`.
   `TriangleMeshTotalFacetAreaError` is payload-free, `Sendable` and `Equatable`
   with exactly `invalidLimits`, `invalidSource`, `resourceLimitExceeded`,
   `areaNotRepresentable`, `cancelled` and `publicationFailed`.
6. **The failure family claims only what the operation implements.** There is
   no `undefinedArea` case: zero is a legitimate total, and every undefined
   unsigned magnitude is already a representability failure. There is no
   attribute-related case: attributes are never read. This follows the
   `ADR-0071`/`ADR-0173` discharge precedent — a case whose condition another
   admission already covers is removed before acceptance, not carried as dead
   API surface.
7. **The request is an unadmitted source-claim declaration.** It stores one
   source `TriangleMesh`, one source `DataIdentity`, one source
   `ProvenanceRecord` and one limits value. The nonthrowing initializer retains
   even mismatched source claims or zero ceilings so asynchronous execution can
   preserve cancellation-first precedence. Admission requires the source
   provenance subject to equal `.object(sourceIdentity.objectID)`. As in
   `ADR-0193`, this proves only internal claim correspondence: without a
   canonical mesh projection, neither identity nor provenance cryptographically
   binds the supplied mesh bytes, and the API must say so.
8. **Limits bound exactly the two linear domains the operation controls.** The
   required positive `UInt64` ceilings are maximum vertex count and maximum
   triangle count, checked before traversal. There is deliberately **no**
   additional-logical-byte ceiling and **no** existing-attribute ceiling: the
   reference allocates no per-vertex or per-facet buffer, reducing already-owned
   immutable positions into one binary64 accumulator, and it never scans
   attributes. Declaring ceilings for a constant-space reduction and a scan that
   does not happen would misrepresent the resource contract. An admitted
   topology already owns `triangleCount * 3` host indices, so the traversal
   offset cannot overflow the 64-bit Apple `Int` domain; `ALG-0031` registers
   that boundary explicitly rather than adding a checked product that can never
   fail.
9. **The measurement value is atomic and self-describing.**
   `TriangleMeshTotalFacetAreaMeasurement` stores the finite non-negative
   binary64 `value`, its `PoweredLengthUnit` and the exact `facetCount` reduced.
   Publishing the facet count makes the multiplicity rule inspectable rather
   than a documentation-only promise. Construction rejects a non-finite or
   negative value, a negative-zero value, and an exponent other than two for
   this operation's own publication path.
10. **The source mesh is not republished.** The result publishes a measurement,
    not a mesh. Positions, topology and attributes are unchanged and unowned by
    this operation, so there is no source-preservation obligation to prove and
    no output mesh to bind. This is the deliberate difference from `ADR-0193`,
    whose result had to prove a source-preserving append.
11. **Admission and cancellation precedence are fixed.** CPU execution checks:
    task cancellation; two positive limits; source claim correspondence; then
    count ceilings. Triangle traversal polls before ordinal zero and every 64
    triangles, matching `ADR-0193`'s cadence. Cancellation at a poll precedes
    the facet at that ordinal. Within one facet, the exact numerical and failure
    order is `ALG-0031`. A final check after the complete total exists precedes
    every measurement, identity and provenance construction. Any failure returns
    no aggregate and no partial total.
12. **Publication authority is caller-owned and output claims are atomic.**
    `TriangleMeshTotalFacetAreaPublicationContext` contains the output
    `DataObjectID`, `ProvenanceID`, `CanonicalInstant` and `SoftwareIdentity`.
    The operation mints no identifier or time and accepts no caller-selected
    backend, precision, approximation or validation claim. The result exposes
    one measurement, identity and provenance record and validates them against
    the request and context without retaining those witnesses.
13. **Result validation proves claim correspondence and unit derivation, not
    algorithm execution.** Construction checks output authority, nil content ID,
    empty top-level source identities, the exact operation, implementation,
    version and digest correspondence, one source-mesh derivation input,
    transformed provenance with one one-based source-mesh input and exact source
    parent, no warnings, that the measurement's base unit is exactly the source
    coordinate space's unit, that the exponent is two, and that the facet count
    equals the source triangle count. It does not recompute the total, admit the
    source provenance graph, authenticate execution claims or invent a mesh
    content digest.
14. **Tokens, fixed parameters and claims are exact.** Operation token is
    `org.voxelia.op.triangle-mesh-total-facet-area`; CPU implementation token is
    `org.voxelia.impl.triangle-mesh-total-facet-area.cpu`; both use version
    `1.0.0`. Input role is `source-mesh`, occurrence one. Under the operation
    namespace, the unique technical parameter collection contains these entries
    in order:
    - `algorithm-identifier` = `triangle-mesh-total-facet-area/binary64-v1`;
    - `quantity-rule` = `total-facet-area-with-multiplicity`;
    - `facet-area-rule` = `half-scaled-euclidean-cross-magnitude`;
    - `degenerate-face-rule` = `zero-area-contributes-zero`;
    - `accumulation-rule` = `triangle-order-serial-sum`;
    - `orientation-rule` = `unsigned-winding-independent`;
    - `topology-claim` = `none`; and
    - `unit-rule` = `source-length-unit-power-two`.

    VCMJ-1 emission uses the standard 65,536-byte ceiling and feeds the
    operation-parameters digest. Limits, cancellation cadence, source claims,
    output authority and software do not affect the successful total and are
    excluded. The source coordinate unit is likewise excluded: it is carried by
    the published measurement and by the source mesh's own identity, and
    admitting it here would make the digest vary with a value the arithmetic
    never reads.
15. **CPU owns the stateless reference and staged registration.** Migration
    adds `CPUTriangleMeshTotalFacetAreaOperation` in `VoxeliaCPU` with
    `execute(request:publication:) async throws`. It needs no storage read or
    coordinator and introduces no package edge. Successful claims use default
    profile, CPU backend, binary64-strict precision, full quality, exact
    approximation, nil capability and kernel, no warning and validation
    `.unknown`. Registration is added only after exact numerical, cancellation,
    binding and public-operation conformance passes.
16. **Independent analytical evidence is registered now.** The standard-library
    Python oracle forces every displayed binary64 operation and proves winding
    independence, multiplicity, degenerate contribution, empty and all-degenerate
    positive-zero totals, the scaled magnitude, reduction-order sensitivity,
    contraction sensitivity, subnormal halving to zero, and edge, magnitude and
    accumulation overflow. Its two SHA-256 fixtures are frozen in `ALG-0031`.
    Swift must reproduce all successful output bits and failure classes exactly;
    no tolerance applies.

## Alternatives considered

### Govern facet area and certified enclosed volume together (Option B)

Rejected as the recorded audit recommended. Enclosed volume additionally
requires watertightness and edge/vertex manifoldness predicates, orientation
consistency, disconnected and nested shell meaning, cavity semantics,
degeneracy, duplicate and self-intersection policy, signed-versus-magnitude
semantics, a reference origin, a reduction order and predicate resource limits.
None of those is determined by any accepted record, and every one changes
scientific output. Bundling them would produce a record that cannot be reviewed
as a single decision and would delay a quantity the mesh contract already
determines. Enclosed volume remains a distinct governed stage.

### Publish an algebraic tetrahedral volume now and caveat it

Rejected. A tetrahedral signed sum over a mesh that proves no closure or
orientation consistency is not the Validation and Benchmark Strategy's enclosed
volume, and a caveat in documentation does not stop a consumer reading the
field name. `VOX-GEO-010` requires authoritative measurement, and an
authoritative name attached to an unverified quantity is the failure mode the
whole governance discipline exists to prevent.

### Publish a deduplicated or union area

Rejected. Union area requires exact coplanar overlap detection and
self-intersection resolution — a constructive-geometry contract with its own
predicate, tolerance and robustness obligations that no accepted record
supplies. Facet-area-with-multiplicity is exactly determined by the admitted
mesh and is a truthful, well-defined quantity. A union area remains available
as a separate operation with its own record.

### Reuse `VOXELIA-ALG-0018` planar polygon area per triangle

Rejected as the governing authority, though the two agree in spirit.
`ALG-0018` is anchored-vector-area over an ordered polygon of arbitrary length
with its own admission and expression order, and reusing it would either
restate its rule under a mislabelled domain or force the mesh operation to
adopt a polygon-shaped input it does not have. Reusing `ALG-0030`'s already
frozen triangle cross-product expression instead keeps the two geometry
operations bit-consistent about the same doubled-area vector, which is the
relationship that actually matters. `ALG-0031` records the shared expression
explicitly rather than silently duplicating it.

### Compensated or sorted accumulation

Rejected. Both alter output bits relative to serial topology order and would
make the CPU reference something other than the exact validation oracle. The
registered order-sensitive fixture demonstrates the difference is real, not
theoretical. An accelerated backend must match bit-for-bit or register a
separately accepted approximation.

### Treat an exactly zero facet as a failure

Rejected. A zero-area facet is an admitted facet of an admitted mesh; the
extraction operations can legitimately emit one, and removing or rejecting it
would either alter topology or refuse a valid mesh. `ADR-0193` rejects a zero
*vertex normal* because a direction genuinely does not exist there; a zero
*area* is a defined value. The two records differ deliberately, and the
difference is recorded here so it does not read as an inconsistency.

### Declare an additional-logical-byte ceiling for symmetry with `ADR-0193`

Rejected. `ADR-0193` allocates two 24-byte-per-vertex buffers and needs that
ceiling. This operation allocates none. A ceiling that can never bind would
imply a payload the operation does not have, and the house discipline is to
claim what is implemented. The zero-payload property is registered in the
oracle output instead.

### Put `PoweredLengthUnit` in `VoxeliaSpatial`

Rejected for version one. `VoxeliaSpatial` owns `MeasurementUnit` and
`CoordinateSpaceDescriptor`, and a unit algebra there would eventually be the
right home. But there is exactly one consumer today, and expanding an accepted
lower-module contract speculatively is the pattern this project avoids. A later
record can promote the type — with the older Interaction measurements as a
second consumer — once a real cross-module need exists.

## Consequences

The next migration can implement one bounded, stateless, bit-exact CPU
reference with no remaining choice about quantity, magnitude formulation,
degeneracy, reduction, unit, failure, cancellation or provenance.

The deliberate limitations are that the published quantity counts multiplicity
and overlap, makes no surface or topology claim, offers no unit conversion, and
covers area only. Certified enclosed volume, watertightness predicates, union
area and backend acceleration remain separate governed records; the enclosed-
volume stage inherits the full obligation list recorded in the 2026-08-06 audit.

Surface rendering and backend-specific derived acceleration remain the
subsequent `ADR-0183` stages.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds immutable values to `VoxeliaGeometry`, the numerical and public
reference to `VoxeliaCPU`, and one CPU registry entry after conformance. Core,
Spatial, Execution, Rendering and Metal ownership or dependency edges do not
change.

## Compatibility impact

None in this design-only increment. Later APIs are additive before 1.0. A
different quantity, magnitude formulation, reduction, degeneracy rule or unit
representation requires a new operation or algorithm version.

## Security impact

Both counts are checked before traversal, traversal is cancellable, errors are
payload-free and publication is atomic. Diagnostics reveal no coordinates, area
values, facet counts, topology, attributes, identifiers or provenance. No
unsafe memory, raw-pointer serialisation or backend buffer enters the design.

## Performance and memory impact

The numerical reference is `O(triangleCount)` and uses constant additional
space: one binary64 accumulator and one facet-local working vector. Public
result binding is `O(1)`; unlike `ADR-0193` it performs no attribute or position
scan, because it publishes no mesh. Already-owned source arrays and ordinary
allocator overhead are excluded explicitly rather than hidden under a false
exact-memory claim. No benchmark or throughput claim is made.

## Validation impact

The oracle registers:

```text
fixtureSHA256=38bad8cfd458b0dca99df2522e34124d51fe607f7fa428fa9f7a586c661d6feb
totalBytesSHA256=8a8af5729b9008d759b9886eb757b31a85cf6dab22d07696b06062f3df668605
fixtures=13 successful=10 failures=3
additionalLogicalByteCount=0 ceilings=vertexCount,triangleCount
maximumHostTriangleCount=3074457345618258602
```

Migration must add focused declaration and result-binding tests, independent
parameter reconstruction and a digest golden, powered-unit admission and
derivation checks, every admission and error precedence, count boundaries,
triangle and final cancellation, all oracle fixtures, repeated determinism and
detached `Sendable` transfer. CPU registration follows only after the complete
operation-level evidence is green. This design increment requires oracle
reproduction, documentation, register, index, link, manifest and
release-integrity checks; product builds and tests and unavailable Apple
destinations are intentionally not evidence for a documentation-only change.

## Migration

1. Add `PoweredLengthUnit`, the four declaration/publication values, the
   measurement value and the closed error family to `VoxeliaGeometry` with exact
   parameter, result-binding, unit-admission, privacy and `Sendable` evidence.
2. Add the internal CPU serial reference kernel with every arithmetic,
   resource, failure and cancellation fixture from `ALG-0031`.
3. Add public identity and provenance assembly and atomic result return,
   reproduce the independent parameter digest, and register the CPU
   implementation only after complete conformance is green.
4. Resume the certified enclosed-volume record, then surface rendering and
   backend-specific derived acceleration, as separate governed records.

## Supersession

This record executes the authoritative-measurement design step of `ADR-0183`
for area only, and composes `ADR-0143`, `ADR-0189` and `ADR-0193`. It supersedes
no accepted record. It closes the mesh-measurement decision gate recorded in
`AUTONOMY_STATUS.md` on 2026-08-06 by selecting Option A.

## References

- [ADR-0038 - Provenance record boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0143 - Area and volume measurement design](ADR-0143-area-volume-measurement-design.md)
- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](ADR-0189-coordinate-bearing-triangle-mesh.md)
- [ADR-0190 - Scalar surface extraction design](ADR-0190-scalar-surface-extraction-design.md)
- [ADR-0192 - Labelled surface extraction design](ADR-0192-labelled-surface-extraction-design.md)
- [ADR-0193 - Deterministic triangle-mesh vertex normals design](ADR-0193-deterministic-triangle-mesh-vertex-normals-design.md)
- [VOXELIA-ALG-0031 - Triangle-mesh total facet area binary64-v1](../../algorithms/VOXELIA-ALG-0031-triangle-mesh-total-facet-area.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
