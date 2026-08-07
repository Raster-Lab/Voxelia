---
document_id: "ADR-0191"
title: "Scalar surface operation and publication boundary"
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
  - "VOX-GEO-006"
  - "VOX-GEO-007"
  - "VOX-GEO-008"
---

# ADR-0191 - Scalar surface operation and publication boundary

## Context

Accepted `ADR-0190` and `VOXELIA-ALG-0028` freeze the numerical scalar-
surface model but deliberately defer its public request, source adapter and
mesh/identity/provenance publication boundary. Implementing those pieces from
the algorithm prose alone would leave observable choices unresolved: whether
limits are validated before cancellation, which stored scalar and image
semantics are admitted, which module owns the coordinated read and transform,
how callers supply output identity fields, and what makes the returned
publication internally coherent.

The audit also found three literal incompatibilities between the algorithm's
informal provenance spellings and accepted Core values. `sourceVolume` is not
a valid lowercase `DerivationInputRole` or `ProvenanceInputRole`; provenance
occurrences start at one, so occurrence zero is invalid; and
`scalar-surface-extraction` is not a valid reverse-domain
`DerivationOperationToken`. A product implementation cannot silently repair
those spellings. The project owner authorised continued autonomous governance,
implementation and verified pushes, so this record selects the exact Core-
compatible boundary and records the corrections before product source.

## Decision

1. **Geometry owns four immutable public declaration values.** The later
   source increment adds `ScalarSurfaceExtractionLimits`,
   `ScalarSurfaceExtractionRequest`,
   `ScalarSurfaceExtractionPublicationContext` and
   `ScalarSurfaceExtractionResult` to `VoxeliaGeometry`. Every stored field is
   immutable and `Sendable`; none is `Codable` or `Hashable`. The values expose
   no Metal, Storage implementation, scheduler, cache or mutable publisher.
2. **A request is an unadmitted declaration.**
   `ScalarSurfaceExtractionLimits` contains required `UInt64`
   `maximumVertexCount` and `maximumTriangleCount` fields, with no defaults.
   `ScalarSurfaceExtractionRequest` contains one `ImageData` source, one
   binary64 `isovalue` and one limits value. Both initializers are nonthrowing:
   zero limits and a non-finite isovalue must remain representable so the async
   operation can enforce the frozen cancellation-first admission precedence.
   Construction grants no assurance that a request is executable. The request
   type exposes the exact public `operationIdentifier` and
   `algorithmIdentifier` string constants; the CPU operation exposes its own
   `implementationIdentifier`, so registration sites cannot duplicate token
   spelling.
3. **Publication authority is explicit and separate from scientific
   parameters.** `ScalarSurfaceExtractionPublicationContext` contains the
   caller-supplied `DataObjectID`, `ProvenanceID`, `CanonicalInstant` and
   `SoftwareIdentity` for the output. The operation mints no identifier and
   reads no clock. Context fields do not enter the parameter digest or mesh
   computation. The value contains no caller-selectable implementation,
   backend, precision, approximation or validation claim.
4. **The result atomically binds only the accepted output claims.**
   `ScalarSurfaceExtractionResult` exposes one `TriangleMesh`, one
   `DataIdentity` and one `ProvenanceRecord`. Its public validating initializer
   additionally receives the exact request and publication context; those
   witnesses are checked but not retained. The initializer recomputes the
   request's parameter digest and rejects as
   `ScalarSurfaceExtractionError.publicationFailed` unless all of the following
   hold:
   - the identity object and provenance record ID, subject, instant and
     software match the publication context exactly;
   - the identity has no top-level content ID or source-identity claims,
     because no canonical mesh projection is accepted yet;
   - the derivation and provenance operation claims use the same operation,
     version, implementation, implementation version and parameter digest;
   - both operation claims carry the exact digest recomputed from the request;
   - each claim has exactly one source input with the corrected role and exact
     request-source object identity, and provenance also has the exact source
     graph-node parent;
   - provenance is transformed, has no warning, and its activity is an
     operation; and
   - the result mesh coordinate descriptor equals the request source's affine
     geometry coordinate descriptor exactly.
   Validation does not claim the source record is graph-admitted, that the
   software/execution claims are authentic, or that an unavailable mesh digest
   exists.
5. **The public error family is the closed ten-case family.**
   `ScalarSurfaceExtractionError` is `Error`, `Sendable` and `Equatable` with
   exactly `invalidLimits`, `unsupportedSource`, `nonFiniteIsovalue`,
   `nonFiniteSample`, `resourceLimitExceeded`,
   `interpolationNotRepresentable`, `positionNotRepresentable`,
   `sourceReadFailed`, `cancelled` and `publicationFailed`. Cases carry no
   payload. No underlying storage, transform, identity or provenance error
   crosses the operation boundary.
6. **Admission is exact and ordered.** The CPU operation checks, in order:
   task cancellation; both positive limits; source admission; finite
   isovalue; one coordinated full source read and transform admission; then the
   first non-finite authoritative sample in axis-zero-fastest order. Source
   admission requires rank three, exactly one component whose interpretation
   is exactly `.scalar`, semantic `.intensity`, `.probability` or
   `.parametric`, an affine geometry whose spatial-axis mapping is a
   permutation of image axes zero through two, exact maximum-index binary64
   representability, and the finite non-zero determinant rule from `ALG-0028`.
   The `.rgb`, `.rgba`, `.vector`, `.tensor`, `.complex`, `.labelProbability`
   and generic component interpretations reject even when a malformed or
   otherwise valid descriptor carries count one. Label, mask, colour, vector,
   deformation, tensor and generic image semantics reject; labelled extraction
   remains a distinct operation.
7. **The initial stored-value adapter is closed rather than heuristic.** The
   CPU reference admits `int8`, `uint8`, `int16`, `uint16`, `int32`, `uint32`,
   `float16`, `float32` and `float64` in the descriptor's accepted byte order.
   `int64` and `uint64` reject at source admission because their complete value
   domains do not convert exactly to binary64; the implementation does not
   inspect values and conditionally widen that public domain. All bytes come
   from the packed `RegionReadResult`; source valid-bit metadata is preserved
   but does not invent an unapproved bit-placement rule.
8. **Value transformation is CPU-owned composition of accepted models.** An
   absent transform and `.identity` are exact no-ops. `.linear`,
   `.lookupTable` and `.composed` follow `VOXELIA-ALG-0003` through `0005`,
   including the eight-stage ceiling, nonempty lookup table, integer lookup
   input and no nested composition. Unsupported transform shape or scalar
   decoding maps to `sourceReadFailed`; a successfully decoded or transformed
   NaN/infinity maps to `nonFiniteSample` at its first logical occurrence.
   Pixel-padding or missing-value semantics are not guessed from arbitrary
   metadata and no sentinel parameter exists: a caller must first publish a
   complete authoritative source lattice under a separately accepted
   operation when such values are present.
   The reference performs one axis-zero-fastest validation pass over the owned
   packed bytes and then decodes/transforms the eight required corners on
   demand during cell traversal. It does not allocate an unbudgeted full
   binary64 copy of the lattice; repeating the pure transform is preferable to
   multiplying retained source memory. Both passes use one shared decoder and
   transform evaluator so their classifications cannot drift. The validation
   pass checks cancellation before sample zero and before every sample whose
   axis-zero-fastest ordinal is a multiple of 4,096. This source-adapter cadence
   is execution policy and does not enter successful-result identity.
9. **CPU owns execution while composing the existing bounded read path.** A
   stateless `CPUScalarSurfaceExtractionOperation` in `VoxeliaCPU` provides
   the async `execute(request:publication:coordinator:)` entry point and uses
   `StorageReadCoordinator` for exactly one full-rank read. The retention token
   is released immediately after staging owned bytes, including all throwing
   paths. Geometry contains no read or transform implementation, and Execution
   contains no geometry kernel. Because the public CPU entry point names the
   Execution-owned coordinator, `VoxeliaCPU` gains an explicit direct
   dependency on `VoxeliaExecution` in addition to its existing Imaging and
   Geometry dependencies. `CCR-0028` corrects the MTA/RPSS dependency rows;
   both fail-closed graph checkers enforce the edge. Execution does not depend
   on CPU, so the graph remains acyclic and no reverse edge is introduced.
10. **Returning the immutable aggregate is the publication boundary.** The CPU
    operation builds mesh, identity and provenance in private local values and
    returns `ScalarSurfaceExtractionResult` only after its final cancellation
    check and complete result validation. No public callback, inout destination
    or partially filled result exists. A caller that needs generation or stale-
    result policy applies it after the operation returns and before publishing
    the returned value into host state; this operation cannot mutate that
    state. Cancellation or any mapped failure returns no mesh, identity or
    provenance aggregate.
11. **Core-compatible registered spellings are authoritative.** The semantic
    operation token is `org.voxelia.op.scalar-surface-extraction`; the CPU
    implementation token is
    `org.voxelia.impl.scalar-surface-extraction.cpu`; both use version `1.0.0`.
    Derivation and provenance use input role `source-volume`. Provenance uses
    occurrence `1`, the first allowed occurrence, and the derivation contains
    the corresponding first positional input. These spellings supersede
    `ADR-0190`/`ALG-0028`'s unnamespaced token, camel-case role and occurrence-
    zero wording without changing the numerical algorithm identity.
12. **The parameter document is exact.** Its unique technical
    `MetadataCollection`, in this order and under namespace
    `org.voxelia.op.scalar-surface-extraction`, contains:
    `algorithm-identifier` =
    `freudenthal-surface-extraction/binary64-v1`, `isovalue` = the exact
    accepted `MetadataFloatingPoint`, `inside-rule` =
    `sample-greater-than-or-equal`, and `boundary-rule` =
    `interior-cells-only`. VCMJ-1 canonical bytes feed the registered
    operation-parameters digest. Limits, cancellation cadence, output IDs,
    timestamp and software identity are excluded because they cannot alter a
    successful mesh.
13. **CPU execution claims are fixed.** A successful CPU publication uses
    profile `org.voxelia.profile.default`, backend
    `org.voxelia.backend.cpu`, precision
    `org.voxelia.precision.binary64-strict`, quality
    `org.voxelia.quality.full`, exact approximation, and nil capability/kernel.
    Its provenance is transformed, carries no warnings and uses validation
    claim `.unknown` until the complete CPU conformance evidence is accepted.
    A later accelerated implementation may use the same public request/result
    values but must supply its own accepted implementation and execution
    claims while preserving result-binding invariants.
14. **Failure mapping and precedence are closed.** Coordinator cancellation or
    an observed cancelled task maps to `cancelled`; every other coordinated
    read failure maps to `sourceReadFailed`. Decode/transform admission maps to
    `sourceReadFailed`; finite-value failure maps to `nonFiniteSample`.
    Cancellation observed at a 4,096-sample validation boundary maps to
    `cancelled` before decoding that sample, so it precedes any failure at that
    or a later sample.
    Checked cell/output overflow or a caller ceiling maps to
    `resourceLimitExceeded`. The numerical traversal then follows `ALG-0028`
    cell order for cancellation, interpolation, position mapping and resource
    failure. Any identity, provenance, metadata-digest or result-binding
    construction failure after a complete mesh maps to `publicationFailed`.
    The final cancellation check precedes all publication construction.

## Alternatives considered

### Put the complete operation in Geometry

Geometry owns operation semantics, but reading storage and running the CPU
reference there would violate the CPU-kernel responsibility and make a
backend-neutral model own an Execution service. Geometry therefore owns the
request/result contract only.

### Put the request and result in Execution

Execution owns scheduling and typed operation infrastructure, but the values'
scientific meaning and mesh binding are Geometry responsibilities. Moving them
would also force Geometry consumers through an execution dependency and oppose
the accepted package direction.

### Keep Execution hidden behind CPU's transitive Imaging path

The live package already made Execution reachable through Imaging and existing
CPU registration source consumes that path, but the new public operation would
name `StorageReadCoordinator` directly. Retaining only the transitive edge
would reproduce the hidden-public-dependency defect rejected by `ADR-0187`.
The redundant direct edge records real API coupling and remains acyclic.

### Let callers provide authoritative `[Double]` samples

That would avoid storage adaptation but split source identity from the values,
bypass the coordinated read budget, and leave byte order/value-transform
evidence outside the operation. The immutable `ImageData` source plus one
bounded read preserves the accepted aggregate.

### Include a mesh content ID

No canonical mesh byte projection exists. Hashing Swift memory, only topology,
or a provisional serialisation would be a false persistent identity. The
derivation-only `DataIdentity` states exactly the claim that can currently be
made.

### Preserve the informal provenance spellings

Core constructors reject all three. Adding aliases, bypass initializers or a
second role grammar would weaken already accepted fail-closed contracts. The
corrected namespace, kebab-case role and one-based occurrence are explicit
instead.

## Consequences

The next increment can implement public values and the CPU reference without
choosing identity, provenance, read, transform or error behaviour inside the
code review. Scientific parameters remain distinct from output authority and
execution policy. The cost is an intentionally closed initial source domain,
no `Int64`/`UInt64` input, no generic semantic, no implicit padding treatment,
and no mesh content digest.

The return-value publication is atomic within the library operation but does
not replace host generation coordination. A host must still suppress a
successfully returned stale generation before installing it in application
state.

## Affected modules

This acceptance increment affects `Package.swift`, both fail-closed graph
checkers, `VoxeliaCPU` module documentation and `CCR-0028` to make the existing
Execution API coupling explicit. Product migration then affects
`VoxeliaGeometry` for public declaration/result values and `VoxeliaCPU` for the
reference operation. Core, Spatial and Execution ownership remain unchanged.

## Compatibility impact

The direct CPU-to-Execution edge is additive before 1.0 and resolves no new
package product because Execution was already transitively required through
Imaging. The later API is additive. The corrected Core-compatible operation
and role spellings supersede only the unimplementable provenance wording of
`ADR-0190` and `VOXELIA-ALG-0028`; the algorithm identity and numerical output
are unchanged.

## Security impact

The boundary keeps source and output identifiers, values, coordinates and
metadata out of error payloads and logs. It requires one budgeted read, checked
counts, bounded key state, deterministic cancellation, no partial return and
no unverified content digest. Arbitrary metadata cannot silently enable a
padding or missing-value interpretation.

## Performance and memory impact

The operation stages one full packed source read, a vertex-key map bounded by
the vertex limit, and the final mesh. It deliberately does not retain a second
full binary64 lattice. The read coordinator's explicit retained-byte ceiling
and the two required output ceilings are the only host budgets; no permissive
default is introduced. A streaming/brick-seam algorithm would require a
separate identity and boundary.

## Validation impact

This acceptance increment must prove the exact three-dependency CPU edge in
both graph checkers, cycle freedom, prohibited-import policy and strict
debug/release compilation of CPU and its direct dependants. The source
increment must prove request declaration behaviour, the complete
admission/error precedence, every accepted/rejected scalar, component
interpretation and image semantic, endianness, all accepted transform forms
and transform failures, exact parameter bytes/digest, corrected tokens/role/
occurrence, identity/provenance
binding, token release on every path, cancellation at admission/64-cell/final
boundaries, no partial result, strict-concurrency transfer, empty-volume
publication and all `ALG-0028` fixtures. It must differential-test every output
position bit pattern and index against the independent oracle before CPU
registration is added. Cancellation fixtures include sample-validation
ordinals 0, 4,095, 4,096 and 4,097 as well as the algorithm's cell and final
publication boundaries.

## Migration

1. Record `CCR-0028`, add the explicit CPU-to-Execution edge to the manifest,
   both graph checkers and CPU module documentation, and verify the affected
   graph/build surface.
2. Add the four immutable Geometry values and closed error family with focused
   construction, binding, privacy and `Sendable` tests.
3. Add the CPU source adapter and reference kernel behind the one coordinated
   full read, then prove decoding, transforms, exact fixtures, limits and
   cancellation.
4. Add identity/provenance assembly and atomic result return, reproduce the
   corrected parameter schema and result-binding failures, then add the CPU
   registration only after all conformance evidence passes.
5. Resume labelled extraction, deterministic normals, authoritative mesh
   measurement and backend-specific derived acceleration as separate records.

## Supersession

This record composes `ADR-0183`, `ADR-0189` and `ADR-0190`. It supersedes only
`ADR-0190` decision 9 and `VOXELIA-ALG-0028`'s provenance-field wording for the
operation token, source role and occurrence. All numerical clauses and the
algorithm identifier remain unchanged.

## References

- [ADR-0038 - Provenance record boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0063 - ImageData aggregate](ADR-0063-image-data-aggregate.md)
- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](ADR-0189-coordinate-bearing-triangle-mesh.md)
- [ADR-0190 - Scalar surface extraction design](ADR-0190-scalar-surface-extraction-design.md)
- [CCR-0028 - CPU-Execution dependency correction](../corrections/CCR-0028-adr-0191-cpu-execution-dependency.md)
- [VOXELIA-ALG-0003 - Linear value transform](../../algorithms/VOXELIA-ALG-0003-linear-value-transform.md)
- [VOXELIA-ALG-0004 - Lookup-table value transform](../../algorithms/VOXELIA-ALG-0004-lookup-table-value-transform.md)
- [VOXELIA-ALG-0005 - Composed value-transform chain](../../algorithms/VOXELIA-ALG-0005-composed-value-transform-chain.md)
- [VOXELIA-ALG-0028 - Freudenthal scalar-surface extraction](../../algorithms/VOXELIA-ALG-0028-freudenthal-surface-extraction.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
