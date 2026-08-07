---
document_id: "ADR-0193"
title: "Deterministic triangle-mesh vertex normals design"
status: "Accepted"
date: "2026-08-05"
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
  - "VOX-GEO-004"
  - "VOX-GEO-005"
  - "VOX-GEO-006"
  - "VOX-GEO-009"
  - "VOX-GEO-011"
---

# ADR-0193 - Deterministic triangle-mesh vertex normals design

## Context

Accepted `ADR-0183` places deterministic reference normal generation after
the canonical mesh and scalar/labelled extraction boundaries. Those
dependencies are complete through accepted `ADR-0192`: `TriangleMesh` owns
finite binary64 positions, exact independent-triangle topology and exact
vertex attributes; both extraction operations publish winding-correct meshes
with identity and source-linked provenance. `VOX-GEO-009` now requires the
next operation to have deterministic reference behaviour.

The v0.1.1 baseline does not choose face versus vertex domain, weighting,
crease policy, degenerate handling, reduction order, normalisation expression,
zero-vector behaviour, output scalar layout or a publication source shape.
Those choices change scientific output bits and cannot be inferred from a
renderer. The project owner's broadened autonomous approval authorises this
separate design/algorithm increment and subsequent verified migration while
measurement, rendering and acceleration remain out of scope.

## Decision

1. **Version one generates smooth vertex-domain normals only.** The operation
   derives exactly one normal for every source vertex by summing oriented
   doubled-area face vectors. It does not emit face-domain data, duplicate
   vertices for flat shading, detect creases, infer smoothing groups or create
   tangent frames. This directly fits the accepted vertex-attribute-only mesh
   boundary and supports `VOX-GEO-004`/`VOX-GEO-009` without guessing a future
   multi-domain attribute model.
2. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0030` defines
   `triangle-area-weighted-vertex-normals/binary64-v1`: triangle/corner/
   component order, ordered edge subtraction and cross product, serial
   area-weighted accumulation, exact-zero degeneracy, maximum-component-scaled
   Euclidean normalisation, positive-zero output and every representability
   failure. The CPU reference cannot use FMA, fast math, reassociation,
   compensation, a parallel reduction or an epsilon. An implementation with a
   different weighting or reduction requires another algorithm/version.
3. **Geometry owns four immutable declaration/publication values and one
   closed error family.** Migration adds
   `TriangleMeshVertexNormalGenerationLimits`,
   `TriangleMeshVertexNormalGenerationRequest`,
   `TriangleMeshVertexNormalGenerationPublicationContext` and
   `TriangleMeshVertexNormalGenerationResult` to `VoxeliaGeometry`. Every
   stored field is immutable and `Sendable`; none is `Codable` or `Hashable`.
   `TriangleMeshVertexNormalGenerationError` is payload-free, `Sendable` and
   `Equatable` with exactly `invalidLimits`, `invalidSource`,
   `normalAlreadyPresent`, `resourceLimitExceeded`,
   `normalNotRepresentable`, `undefinedNormal`, `cancelled` and
   `publicationFailed`.
4. **The request is an unadmitted source-claim declaration.** It stores one
   source `TriangleMesh`, one source `DataIdentity`, one source
   `ProvenanceRecord` and one limits value. The nonthrowing initializer retains
   even mismatched source claims or zero ceilings so asynchronous execution can
   preserve cancellation-first precedence. Admission requires the source
   provenance subject to equal `.object(sourceIdentity.objectID)`. This proves
   only internal claim correspondence: without a canonical mesh projection,
   neither identity nor provenance cryptographically binds the supplied mesh
   bytes, and the API/documentation must say so.
5. **Limits explicitly bound every operation-controlled linear domain.** The
   required positive `UInt64` ceilings are maximum vertex count, triangle
   count, existing vertex-attribute count and additional logical byte count.
   Source counts are checked before scans or allocation. Additional bytes are
   exactly two `vertexCount * 3 * 8` logical buffers—one binary64 accumulator
   and one final normal attribute—and all products/sums are checked before
   allocation. The ceiling does not misrepresent allocator bookkeeping or
   already-owned source bytes as operation-controlled payload.
6. **Existing normals fail closed.** A source with built-in semantic `.normal`
   returns `normalAlreadyPresent`; the operation never overwrites, preserves as
   authoritative, blends with or validates existing normals. Other existing
   attributes are retained byte-for-byte and in order. A custom semantic is
   not treated as a normal by text matching. This avoids a caller-dependent
   replacement policy and makes one successful request unambiguous.
7. **The output mesh is a source-preserving append.** Positions retain every
   source bit and the exact coordinate descriptor, topology is unchanged, and
   every existing attribute retains descriptor, bytes and order. One `.normal`
   attribute is appended last with float64, absent valid-bit count,
   little-endian byte order, three `.vector` components, interleaved layout,
   absent component names and source vertex count. Components are
   dimensionless coordinates in the source position basis. Serialisation is
   explicit checked little-endian encoding, never raw-memory rebinding.
8. **Orientation comes only from authoritative topology.** For `(i0, i1, i2)`,
   the face contribution is `(p1 - p0) cross (p2 - p0)` in the exact expression
   order. This follows right-hand winding: scalar inside-to-outside and labelled
   selected-to-unselected directions remain intact. Duplicate triangles retain
   multiplicity. Non-manifold and disconnected incident fans contribute in
   topology order rather than being silently repaired or rejected.
9. **Degeneracy is explicit and atomic.** An exactly zero face vector
   contributes nothing but does not alter topology. After complete
   accumulation, an exactly zero vector at any vertex—whether isolated,
   incident only to degenerate faces or cancelled by opposite winding—causes
   `undefinedNormal` and no result. No fallback axis, neighbouring normal,
   epsilon, area filter or topology repair is allowed. Any non-finite ordered
   intermediate causes `normalNotRepresentable`, even if an alternate
   mathematical formulation could return a finite direction.
10. **Admission and cancellation precedence are fixed.** CPU execution checks:
    task cancellation; four positive limits; source claim correspondence;
    count ceilings; the existing-attribute scan; checked additional bytes;
    then allocation. The attribute scan polls before ordinal zero and every
    4,096 attributes, triangle traversal before ordinal zero and every 64
    triangles, and vertex normalisation before ordinal zero and every 4,096
    vertices. Cancellation at a poll precedes the item at that ordinal. Within
    one item, the exact numerical/failure order is `ALG-0030`. A final check
    after complete mesh construction precedes every identity/provenance
    construction. Any failure returns no aggregate or partial attribute.
11. **Publication authority is caller-owned and output claims are atomic.**
    `TriangleMeshVertexNormalGenerationPublicationContext` contains the output
    `DataObjectID`, `ProvenanceID`, `CanonicalInstant` and `SoftwareIdentity`.
    The operation mints no identifier or time and accepts no caller-selected
    backend, precision, approximation or validation claim. The result exposes
    one mesh, identity and provenance record and validates them against the
    request/context without retaining those witnesses.
12. **Result validation proves structural preservation and claim
    correspondence, not algorithm execution.** Construction checks output
    authority, nil mesh content ID, empty top-level source identities, the
    exact operation/implementation/digest correspondence, one source-mesh
    derivation input, transformed provenance with one one-based source-mesh
    input and exact source parent, no warnings, exact coordinate descriptor,
    bit-exact source positions, exact topology, byte-exact source attributes in
    order—including exact UTF-8 comparison for generic and component-name
    strings—and exactly one final normal attribute with the frozen descriptor
    and byte count. It does not recompute the numerical normals, admit the source
    provenance graph, authenticate execution claims or invent a mesh content
    digest.
13. **Tokens, fixed parameters and claims are exact.** Operation token is
    `org.voxelia.op.triangle-mesh-vertex-normal-generation`; CPU implementation
    token is
    `org.voxelia.impl.triangle-mesh-vertex-normal-generation.cpu`; both use
    version `1.0.0`. Input role is `source-mesh`, occurrence one. Under the
    operation namespace, the unique technical parameter collection contains
    these entries in order:
    - `algorithm-identifier` =
      `triangle-area-weighted-vertex-normals/binary64-v1`;
    - `weighting-rule` = `oriented-doubled-area-vector`;
    - `degenerate-face-rule` = `zero-vector-contributes-nothing`;
    - `accumulation-rule` =
      `triangle-order-corner-order-component-order`;
    - `normalization-rule` = `maximum-component-scaled-euclidean`;
    - `zero-component-rule` = `positive-zero`;
    - `output-attribute` =
      `vertex-interleaved-float64-little-endian`; and
    - `existing-normal-rule` = `reject`.

    VCMJ-1 emission uses the standard 65,536-byte ceiling and feeds the
    operation-parameters digest. Limits, cancellation cadence, source claims,
    output authority and software do not affect successful normal values and
    are excluded.
14. **CPU owns the stateless reference and staged registration.** Migration
    adds `CPUTriangleMeshVertexNormalGenerationOperation` in `VoxeliaCPU` with
    `execute(request:publication:) async throws`. It needs no storage read or
    coordinator and introduces no package edge. Successful claims use default
    profile, CPU backend, binary64-strict precision, full quality, exact
    approximation, nil capability/kernel, no warning and validation `.unknown`.
    Registration is added only after exact numerical, cancellation, binding
    and public-operation conformance passes.
15. **Independent analytical evidence is registered now.** The standard-
    library Python oracle forces every displayed binary64 operation, proves
    orientation, area weighting, reversed winding, degenerate contribution,
    gradual-subnormal normalisation, positive-zero serialisation, undefined
    cancellation/isolated vertices, numerical overflow and one-past checked
    logical bytes. Its two SHA-256 fixtures are frozen in `ALG-0030`. Swift must
    reproduce all successful output bits and failure classes exactly; no
    tolerance applies.

## Alternatives considered

### Emit face normals

The accepted mesh owns vertex-domain attributes only, and surface rendering
requires vertex normals. A face-domain stream would need a new interpolation-
domain model. Duplicating vertices for flat shading would change authoritative
topology and identity. Both remain separate operations.

### Uniform or angle weighting

Uniform weighting overemphasises small triangles; angle weighting requires a
separate trigonometric and degeneracy contract. Oriented doubled-area vectors
use the authoritative positions directly, retain winding and avoid an
intermediate normalisation. Other weighting remains a new algorithm.

### Parallel or compensated accumulation

Both alter output bits relative to serial topology order. The CPU reference is
the exact validation oracle, not a throughput sketch. An accelerated backend
must match it bit-for-bit or register a separately accepted approximation.

### Repair zero normals

Choosing an axis, copying a neighbour, dropping faces or using an epsilon would
publish geometry not determined by the admitted source contract. Atomic
`undefinedNormal` is explicit and diagnostic-safe.

### Replace an existing normal

Replacement would need authority and provenance rules for whether the prior
attribute is wrong, presentation-only or scientific. Rejecting prevents silent
loss and leaves a future explicit replacement operation possible.

### Require a generic provenance-bearing MeshData aggregate first

No canonical mesh byte/content projection exists, and the accepted extraction
results already demonstrate derivation-only structural publication. An
operation-specific request can carry mesh, identity and provenance claims while
clearly disclaiming cryptographic mesh binding; inventing a general persistent
mesh aggregate would expand this criterion.

## Consequences

The next migration can implement one bounded, stateless, bit-exact CPU
reference with no remaining choice about output domain, weighting,
degeneracy, reduction, normalisation, failure, cancellation or provenance.
The deliberate limitations are smooth all-incident-face averaging, rejection
of any undefined vertex, no normal replacement and no canonical mesh digest.

Authoritative mesh measurement remains next in the accepted geometry order.
Surface rendering may consume the eventual normal-bearing canonical mesh only
after product migration completes; this design does not claim rendering
acceptance.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds immutable values to `VoxeliaGeometry`, the numerical/public
reference to `VoxeliaCPU`, and one CPU registry entry after conformance. Core,
Spatial, Execution, Rendering and Metal ownership or dependency edges do not
change.

## Compatibility impact

None in this design-only increment. Later APIs are additive before 1.0. A
different weighting, degeneracy, reduction, normalisation, output descriptor
or replacement policy requires a new operation or algorithm version.

## Security impact

All counts and byte products are checked before allocation, scans and
numerical work are cancellable, errors are payload-free and publication is
atomic. Diagnostics reveal no coordinates, normal values, topology, counts,
attributes, identifiers or provenance. No unsafe memory, raw-pointer
serialisation or backend buffer enters the design.

## Performance and memory impact

The numerical reference is `O(attributeCount + triangleCount + vertexCount)`;
public result binding may additionally scan the already-owned existing
attribute bytes to prove exact preservation.
Operation-controlled logical payload is exactly 48 bytes per vertex at peak:
24 accumulator bytes plus 24 final attribute bytes, bounded by the caller's
explicit ceiling. Already-owned source arrays and ordinary allocator overhead
are excluded explicitly rather than hidden under a false exact-memory claim.
No benchmark or throughput claim is made.

## Validation impact

The oracle registers:

```text
fixtureSHA256=1306df51656d104cfacc9cafc5f2fd7910bbe0104e10a435326310d94d6c94fc
normalAttributeBytesSHA256=076b11f527589e716986a14a99ff86590b592b95f948ca6b6309627baff96d17
fixtures=12 successful=8 failures=4
maximumAdditionalByteVertexCount=384307168202282325
```

Migration must add focused declaration/result-binding tests, independent
parameter reconstruction and digest golden, exact descriptor/byte and source-
preservation checks, every admission/error precedence, count/byte boundaries,
attribute/triangle/vertex/final cancellation, all oracle fixtures, repeated
determinism and detached `Sendable` transfer. CPU registration follows only
after the complete operation-level evidence is green. This design increment
requires oracle reproduction, documentation/register/index/link, manifest and
release-integrity checks; product builds/tests and unavailable Apple
destinations are intentionally not evidence for a documentation-only change.

## Migration

1. Add the four immutable Geometry values and closed error family with exact
   parameter/result binding, source-preservation, privacy and `Sendable`
   evidence.
2. Add the internal CPU serial reference kernel with every arithmetic,
   resource, failure and cancellation fixture from `ALG-0030`.
3. Add public identity/provenance assembly and atomic result return, reproduce
   the independent parameter digest, and register the CPU implementation only
   after complete conformance is green.
4. Resume authoritative mesh measurement and backend-specific derived
   acceleration as separate governed records.

## Supersession

This record executes the deterministic-normal design step of `ADR-0183` and
composes `ADR-0189` through `ADR-0192`; it supersedes no accepted record.

## References

- [ADR-0038 - Provenance record boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](ADR-0189-coordinate-bearing-triangle-mesh.md)
- [ADR-0190 - Scalar surface extraction design](ADR-0190-scalar-surface-extraction-design.md)
- [ADR-0191 - Scalar surface operation and publication boundary](ADR-0191-scalar-surface-operation-boundary.md)
- [ADR-0192 - Labelled surface extraction design](ADR-0192-labelled-surface-extraction-design.md)
- [VOXELIA-ALG-0030 - Triangle area-weighted vertex normals binary64-v1](../../algorithms/VOXELIA-ALG-0030-triangle-area-weighted-vertex-normals.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
