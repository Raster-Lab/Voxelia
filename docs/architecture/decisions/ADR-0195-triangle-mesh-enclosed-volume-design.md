---
document_id: "ADR-0195"
title: "Triangle-mesh certified enclosed volume design"
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

# ADR-0195 - Triangle-mesh certified enclosed volume design

## Context

Accepted `ADR-0194` selected Option A of the 2026-08-06 mesh-measurement
decision gate: a separately governed total-facet-area stage first, with
certified enclosed volume left as a distinct later record. That area stage is
now accepted, implemented and registered. This record is the deferred second
half, and it inherits the complete obligation list the preceding audit
enumerated: watertightness and edge/vertex manifoldness predicates,
orientation consistency, disconnected and nested shell meaning, cavity
semantics, degeneracy/duplicate/self-intersection policy,
signed-versus-magnitude semantics, a reference origin, a reduction order and
predicate resource limits.

The audit's central finding stands and is the reason this record exists at all:
the canonical `TriangleMesh` proves neither closure, orientation consistency,
connected or nested shell meaning, nor self-intersection status, so a
tetrahedral sum over an arbitrary admitted mesh is only an algebraic quantity
and cannot honestly be published as an enclosed volume. `ADR-0143`/
`VOXELIA-ALG-0019` does not help: it is a supplied voxel count multiplied by an
affine cell volume and expressly rejects mesh and contour volume.

The unit question is already settled — `ADR-0194`'s `PoweredLengthUnit` admits
any positive exponent, so volume publishes exponent three with no new unit
vocabulary. Everything else in the list is open, and every item on it changes
scientific output.

This record is authored and accepted under the project owner's standing
autonomous mandate of 2026-08-06, the same authorization that closed the
`ADR-0194` gate.

## Decision

1. **Certification is a hard admission gate, not a warning.** The operation
   first proves the admitted mesh is a closed, edge-manifold, consistently
   oriented surface, and publishes a volume only if it is. Unlike total facet
   area, this quantity is meaningless for an arbitrary mesh, so a caveat
   attached to a number computed anyway would be exactly the failure mode the
   audit rejected. An uncertified mesh returns a typed failure and no value.
2. **The certified predicate is exactly four properties.** Over the exact
   admitted topology: no triangle repeats a vertex index; every directed edge
   occurs exactly once; every directed edge's reverse is present; and,
   following from those, every undirected edge carries exactly two incident
   triangles traversing it in opposite directions. These are precisely the
   hypotheses the divergence identity needs. Nothing weaker is accepted and
   nothing stronger is claimed.
3. **Vertex manifoldness is deliberately not required.** A pinch-point vertex,
   whose link is two or more disjoint cycles, is admitted. The divergence
   identity does not need a single-cycle link: each shell still contributes
   exactly its own volume. Requiring it would reject a mesh whose published
   volume is exactly correct, which is a false negative the project has no
   reason to accept. `ALG-0032` registers a pinch-point fixture that certifies
   and returns the exact sum of its two shells.
4. **Non-self-intersection is deliberately not certified, and the limitation
   is inside the digest.** Deciding self-intersection needs exact or adaptive
   geometric predicates that no accepted record supplies and that this record
   does not invent. For a self-intersecting closed oriented surface the facet
   sum is the winding-number-weighted signed volume, not the enclosed volume.
   Rather than bury that in prose, `self-intersection-rule = not-certified` is
   an entry in the operation's parameter document, so it is inside the
   cryptographic digest identifying every published result. A consumer
   comparing digests cannot lose the caveat.
5. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0032` defines `triangle-mesh-enclosed-volume/binary64-v1`:
   the two-pass structure, the origin-anchored scalar triple product in exact
   expression order, serial topology-order accumulation of the six-fold total,
   the single final division by six, the orientation-sign rule and every
   representability failure. The CPU reference cannot use FMA, fast math,
   reassociation, a determinant-expansion reordering, compensated or pairwise
   summation, a sorted reduction, a parallel reduction or an epsilon.
6. **The reference origin is the source coordinate space's own origin.**
   Positions are used exactly as published; there is no recentering, centroid
   shift or first-vertex rebasing. The sum is origin-independent in real
   arithmetic but not in binary64, so the anchor is part of the algorithm
   identity. `ALG-0032` registers the consequence explicitly: a unit cube at
   the origin encloses exactly `1.0`, the same cube translated by
   `(0.1, 0.2, 0.3)` encloses `1.0000000000000004`. Recentering inside the
   operation would need a centroid rule, a second pass and its own rounding
   contract, and would change published bits without appearing in the digest.
7. **The facet term is origin-anchored and must not be confused with the area
   operations' cross product.** For `(i0, i1, i2)` the term is
   `p0 · (p1 × p2)` — a cross product over positions, not over edge vectors.
   `VOXELIA-ALG-0030` and `VOXELIA-ALG-0031` share an edge-vector cross
   product computing an origin-independent doubled area; this computes an
   origin-dependent signed determinant. The two expressions are deliberately
   different and `ALG-0032` says so, because reusing the wrong one would look
   like consistency and produce silent nonsense.
8. **The six-fold total is the accumulated quantity; the division happens
   once.** Facet terms accumulate in exact topology order, then the total is
   divided by six exactly once. Dividing per facet would introduce one
   rounding per triangle instead of one for the whole mesh and would change
   the published bits.
9. **Orientation sign is named, not absolutised.** A consistently outward
   surface totals non-negative; a consistently inward one totals negative.
   Both certify, since inward orientation is consistent. A strictly negative
   total fails `invertedOrientation` rather than publishing its magnitude:
   silently absolutising would hide a real upstream error behind a plausible
   number, and the accepted scalar and labelled extraction operations both
   emit outward winding. A total of zero or negative zero is admitted and
   published as positive zero.
10. **Shells and cavities are defined by orientation, never by geometry.**
    Connectivity is never examined; any number of disjoint closed shells is
    admitted and each contributes its own signed volume. A cavity is an
    inward-oriented shell, which subtracts — the divergence identity's own
    answer for a solid with a void. No containment test is performed and it is
    not verified that an inner shell lies geometrically inside an outer one.
    `ALG-0032` registers a side-four outward cube containing a side-two inward
    cube enclosing exactly `56.0`.
11. **Certification and volume are two complete passes, never interleaved.**
    No arithmetic runs for an uncertified surface. This makes it impossible for
    `volumeNotRepresentable` to mask an `openSurface`, and guarantees a
    partially-summed uncertified mesh never exists. The cost is one extra
    traversal, which is accepted deliberately.
12. **Geometry owns four immutable declaration/publication values and one
    closed error family.** Migration adds
    `TriangleMeshEnclosedVolumeLimits`,
    `TriangleMeshEnclosedVolumeRequest`,
    `TriangleMeshEnclosedVolumePublicationContext`,
    `TriangleMeshEnclosedVolumeMeasurement` and
    `TriangleMeshEnclosedVolumeResult` to `VoxeliaGeometry`, reusing
    `PoweredLengthUnit` unchanged at exponent three. Every stored field is
    immutable and `Sendable`; none is `Codable` or `Hashable`.
    `TriangleMeshEnclosedVolumeError` is payload-free, `Sendable` and
    `Equatable` with exactly `invalidLimits`, `invalidSource`,
    `resourceLimitExceeded`, `degenerateFacet`, `openSurface`,
    `nonManifoldOrientation`, `invertedOrientation`,
    `volumeNotRepresentable`, `cancelled` and `publicationFailed`.
13. **There is no duplicate-facet case.** A repeated facet traverses each of
    its directed edges a second time and is already `nonManifoldOrientation`.
    Carrying a separate case whose condition another admission already
    discharges is the `ADR-0071`/`ADR-0173` pattern this project removes before
    acceptance, and `ALG-0032` registers a duplicate-facet fixture proving the
    discharge.
14. **Limits bound all three domains this operation controls.** The required
    positive `UInt64` ceilings are maximum vertex count, maximum triangle count
    and maximum additional logical byte count. The third exists here and did
    not exist in `ADR-0194` for a real reason: certification holds one
    directed-edge record per facet corner, each an ordered pair of 64-bit
    indices, so the operation owns `triangleCount * 3 * 16` logical bytes.
    All products and the comparison are checked before allocation; the ceiling
    excludes already-owned source payload, immutable result shells, allocator
    bookkeeping and hash-table load factor. The registered one-past boundary is
    `384307168202282325` triangles.
15. **The measurement value is atomic and self-describing.**
    `TriangleMeshEnclosedVolumeMeasurement` stores the finite non-negative
    binary64 `value`, its `PoweredLengthUnit` and the exact `facetCount`
    certified and reduced. Construction rejects a non-finite, negative or
    negative-zero value and any exponent other than three. As in `ADR-0194`'s
    implementation, that exponent obligation is discharged at the measurement's
    own admission and is not restated unreachably in the result.
16. **The source mesh is not republished.** The result publishes a
    measurement, not a mesh, so there is no source-preservation obligation and
    no output mesh to bind.
17. **Admission and cancellation precedence are fixed.** CPU execution checks:
    task cancellation; three positive limits; source claim correspondence;
    count ceilings; checked additional bytes; then allocation. Certification
    polls before facet zero and every 64 facets; the reverse-partner scan runs
    only after every facet is recorded. Volume traversal polls before facet
    zero and every 64 facets. The orientation-sign check follows complete
    accumulation and precedes the division. A final check after the volume
    exists precedes every measurement, identity and provenance construction.
18. **Publication authority is caller-owned and output claims are atomic**,
    exactly as in `ADR-0193` and `ADR-0194`:
    `TriangleMeshEnclosedVolumePublicationContext` carries the output
    `DataObjectID`, `ProvenanceID`, `CanonicalInstant` and `SoftwareIdentity`;
    the operation mints no identifier or time and accepts no caller-selected
    backend, precision, approximation or validation claim.
19. **Result validation proves claim correspondence and unit derivation, not
    algorithm execution.** Construction checks output authority, nil content
    ID, empty top-level source identities, exact operation/implementation/
    version/digest correspondence, one source-mesh derivation input,
    transformed provenance with one one-based source-mesh input and exact
    source parent, no warnings, that the measurement's base unit is exactly the
    source coordinate space's unit, and that the facet count equals the source
    triangle count. It does not recompute the volume, re-run certification,
    admit the source provenance graph, authenticate execution claims or invent
    a mesh content digest.
20. **Tokens, fixed parameters and claims are exact.** Operation token is
    `org.voxelia.op.triangle-mesh-enclosed-volume`; CPU implementation token is
    `org.voxelia.impl.triangle-mesh-enclosed-volume.cpu`; both use version
    `1.0.0`. Input role is `source-mesh`, occurrence one. Under the operation
    namespace, the unique technical parameter collection contains these entries
    in order:
    - `algorithm-identifier` = `triangle-mesh-enclosed-volume/binary64-v1`;
    - `certification-rule` = `closed-edge-manifold-consistently-oriented`;
    - `vertex-manifold-rule` = `not-required`;
    - `self-intersection-rule` = `not-certified`;
    - `degenerate-facet-rule` = `reject-repeated-index`;
    - `facet-term-rule` = `origin-anchored-scalar-triple-product`;
    - `reference-origin` = `source-coordinate-space-origin`;
    - `accumulation-rule` = `triangle-order-serial-sum-then-divide-by-six`;
    - `orientation-rule` = `outward-positive-inward-rejected`; and
    - `unit-rule` = `source-length-unit-power-three`.

    VCMJ-1 emission uses the standard 65,536-byte ceiling and feeds the
    operation-parameters digest. Limits, cancellation cadence, source claims,
    output authority and software do not affect the successful volume and are
    excluded. The source coordinate unit is likewise excluded: it is carried by
    the published measurement and the arithmetic never reads it.
21. **CPU owns the stateless reference and staged registration.** Migration
    adds `CPUTriangleMeshEnclosedVolumeOperation` in `VoxeliaCPU` with
    `execute(request:publication:) async throws`. It needs no storage read or
    coordinator and introduces no package edge. Successful claims use default
    profile, CPU backend, binary64-strict precision, full quality, exact
    approximation, nil capability and kernel, no warning and validation
    `.unknown`. Registration is added only after exact numerical,
    certification, cancellation, binding and public-operation conformance
    passes.
22. **Independent analytical evidence is registered now.** The standard-library
    Python oracle forces every displayed binary64 operation and proves the unit
    tetrahedron and cube, exact scaling, origin dependence, the empty mesh,
    disjoint shells, cavity subtraction, the pinch point, the double-sided
    facet, reduction-order sensitivity, and all six failure classes. Its two
    SHA-256 fixtures are frozen in `ALG-0032`. Swift must reproduce all
    successful output bits and failure classes exactly; no tolerance applies.

## Alternatives considered

### Publish the algebraic sum with a documentation caveat

Rejected — this is precisely what the 2026-08-06 audit refused and what
`ADR-0183` and `ADR-0194` both reject. A field named "enclosed volume" is read
as an enclosed volume regardless of the prose beside it. Certification as a
hard gate is the only honest way to attach the name.

### Also require vertex manifoldness

Rejected. It is a strictly stronger condition than the divergence identity
needs, so requiring it would reject meshes whose published volume is exactly
correct — a false negative with no compensating safety benefit. The decision
is recorded with a fixture rather than left as an unexamined omission.

### Certify non-self-intersection

Rejected for version one, and this is the record's most significant
limitation. Robust triangle-triangle intersection over arbitrary binary64
positions requires exact or adaptive predicate arithmetic — an entire
subsystem, with its own error, resource and determinism contracts, that no
accepted record supplies. Inventing it speculatively inside a measurement
record is exactly the expansion this project avoids. Naming the limitation in
the parameter digest, rather than only in prose, is the strongest available
mitigation. A future record may add a certified non-self-intersecting variant
under a new algorithm identity.

### Publish the magnitude of a negative total

Rejected. Absolutising converts a real upstream orientation error into a
plausible number, and both accepted extraction operations emit outward
winding, so a negative total is diagnostic. Naming `invertedOrientation`
follows the same reasoning `ADR-0193` used to reject repairing a zero normal.

### Recentre positions on the mesh centroid before summing

Rejected for version one, though it is better conditioned. It requires
inventing a centroid definition and its own summation order, an extra pass, and
a rounding contract — all of which change the published bits. Version one
freezes the simplest defensible anchor and registers the precision consequence
as a fixture, so a future recentred variant is a visible new algorithm
identity rather than a silent improvement.

### Divide each facet term by six

Rejected. It introduces one rounding per triangle instead of one for the whole
mesh, for no benefit. The six-fold total is the natural accumulated quantity.

### Reuse `VOXELIA-ALG-0031`'s edge-vector cross product

Rejected, and called out explicitly in both documents. That expression computes
an origin-independent doubled area; the volume term needs an origin-dependent
signed determinant over positions. The superficial similarity is a trap, and
the algorithm names it rather than letting a future implementer "unify" them.

### Interleave certification with volume accumulation in one pass

Rejected. Two passes cost one extra traversal and buy a real guarantee: no
arithmetic runs for an uncertified surface, so a representability failure can
never mask a topology failure, and no partial total for an uncertified mesh
can ever exist.

### Carry a separate duplicate-facet error case

Rejected under the `ADR-0071`/`ADR-0173` discharge precedent — a repeated facet
is already a repeated directed edge. The fixture proves it rather than leaving
the reader to trust the reasoning.

## Consequences

The next migration can implement one bounded, stateless, bit-exact CPU
reference with no remaining choice about certification, facet term, reference
origin, reduction, division, orientation sign, cavity meaning, unit, failure,
cancellation or provenance. With this record accepted and migrated,
`VOX-GEO-010` is discharged in both halves — total facet area and enclosed
volume — and the Validation and Benchmark Strategy's section 31.2 comparison
of surface area against enclosed volume becomes expressible.

The deliberate limitations are that self-intersection is not certified, that
precision degrades for meshes far from the coordinate origin, that an
inward-oriented mesh is rejected rather than absolutised, and that no
containment relationship between shells is verified. Each is registered with a
fixture or an explicit parameter entry rather than left implicit.

Surface rendering and backend-specific derived acceleration remain the
subsequent `ADR-0183` stages.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds immutable values to `VoxeliaGeometry`, the numerical and public
reference to `VoxeliaCPU`, and one CPU registry entry after conformance. Core,
Spatial, Execution, Rendering and Metal ownership or dependency edges do not
change. `PoweredLengthUnit` is reused unchanged.

## Compatibility impact

None in this design-only increment. Later APIs are additive before 1.0. A
different certification set, facet term, reference origin, reduction,
division placement, orientation rule or unit representation requires a new
operation or algorithm version.

## Security impact

All counts and byte products are checked before allocation, both passes are
cancellable, errors are payload-free and publication is atomic. Diagnostics
reveal no coordinates, volume values, facet counts, topology, attributes,
identifiers or provenance — in particular, a certification failure discloses
neither the offending facet ordinal nor the offending edge. No unsafe memory,
raw-pointer serialisation or backend buffer enters the design.

## Performance and memory impact

Certification is `O(triangleCount)` expected time over a hashed directed-edge
collection and `O(triangleCount)` governed logical payload — exactly
`triangleCount * 3 * 16` bytes, bounded by the caller's explicit ceiling.
Volume reduction is `O(triangleCount)` time and constant additional space.
Public result binding is `O(1)`. Already-owned source arrays, allocator
overhead and hash-table load factor are excluded explicitly rather than hidden
under a false exact-memory claim. No benchmark or throughput claim is made.

## Validation impact

The oracle registers:

```text
fixtureSHA256=7f3c73ceb34815bc3bb4af7d5bc3e957c992d9670a7a9841c105a945992ab90e
volumeBytesSHA256=c313f1c0b8e59fa267541313abfc0d314df0bb7cb5711a4f29616f604296ae71
fixtures=16 successful=10 failures=6
maximumAdditionalByteTriangleCount=384307168202282325
```

Migration must add focused declaration and result-binding tests, independent
parameter reconstruction and a digest golden, powered-unit derivation at
exponent three, every admission and error precedence, count and byte
boundaries, certification and volume cancellation cadence, all oracle
fixtures, repeated determinism and detached `Sendable` transfer. CPU
registration follows only after the complete operation-level evidence is green.
This design increment requires oracle reproduction, documentation, register,
index, link, manifest and release-integrity checks; product builds and tests
and unavailable Apple destinations are intentionally not evidence for a
documentation-only change.

## Migration

1. Add the four declaration/publication values, the measurement value and the
   closed ten-case error family to `VoxeliaGeometry`, reusing
   `PoweredLengthUnit` at exponent three, with exact parameter,
   result-binding, unit-derivation, privacy and `Sendable` evidence.
2. Add the internal CPU certification predicate and serial volume reference
   with every topological, arithmetic, resource, failure and cancellation
   fixture from `ALG-0032`.
3. Add public identity and provenance assembly and atomic result return,
   reproduce the independent parameter digest, and register the CPU
   implementation only after complete conformance is green.
4. Resume `ADR-0183`'s remaining stages: the surface-rendering assessment over
   a publishable canonical mesh, then backend-specific derived acceleration.

## Supersession

This record completes the authoritative-measurement design step of `ADR-0183`
by delivering the enclosed-volume half `ADR-0194` deferred. It composes
`ADR-0143`, `ADR-0189` and `ADR-0194` and supersedes no accepted record.

## References

- [ADR-0038 - Provenance record boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0143 - Area and volume measurement design](ADR-0143-area-volume-measurement-design.md)
- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](ADR-0189-coordinate-bearing-triangle-mesh.md)
- [ADR-0193 - Deterministic triangle-mesh vertex normals design](ADR-0193-deterministic-triangle-mesh-vertex-normals-design.md)
- [ADR-0194 - Triangle-mesh total facet area design](ADR-0194-triangle-mesh-total-facet-area-design.md)
- [VOXELIA-ALG-0032 - Triangle-mesh certified enclosed volume binary64-v1](../../algorithms/VOXELIA-ALG-0032-triangle-mesh-enclosed-volume.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
