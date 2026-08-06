---
document_id: "ADR-0196"
title: "Geometry acceleration architecture assessment"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-007"
  - "VOX-ARC-010"
  - "VOX-GEO-004"
  - "VOX-GEO-006"
  - "VOX-GEO-011"
---

# ADR-0196 - Geometry acceleration architecture assessment

## Context

`ADR-0183` decision 2 lists the geometry arc's increments in dependency order
and ends with "backend-specific acceleration adapters derived from the
canonical mesh, never embedded in its identity or treated as authoritative
geometry". Every earlier increment is accepted, implemented and evidenced
through `ADR-0195`. This record assesses that final stage, whose governing
requirement is `VOX-GEO-011`.

**A correction is recorded first.** The `AUTONOMY_STATUS.md` next-action line
written during the `ADR-0195` increment named a "surface-rendering assessment
over a publishable canonical mesh" as this arc's penultimate stage. That is
wrong. `ADR-0183` decision 6 states the opposite in its own words: "Surface
rendering follows the canonical mesh and extraction contracts. `VOX-SUR-*`
work becomes assessable only after a valid mesh can be published; it is not
folded into this arc." Surface rendering is a nine-row requirement block
(`VOX-SUR-001` through `VOX-SUR-009`) that now becomes assessable, but it needs
its own arc-opening record in the M6 queue and is not a stage of this arc. The
mis-statement is corrected here rather than silently dropped, because the
standing process lesson is that an arc's own opening ADR is the authority on
its decomposition, not a later summary of it.

`VOX-GEO-011` reads, verbatim from the v0.1.1 baseline table:

> The geometry architecture shall permit acceleration structures without
> making a particular Metal or RealityKit structure canonical.

Its declared priority is P1 and its declared verification methods are **I,R —
Inspection and Review**. It is deliberately not a Test row and not a
Demonstration row. The requirement constrains what the architecture must *not*
foreclose and must *not* canonise; it does not require that any particular
acceleration structure exist.

## Assessment

### The requirement is satisfied, and the evidence is structural

1. **The declared dependency closure excludes every backend framework.**
   `Package.swift` declares `VoxeliaGeometry`'s dependencies as exactly
   `VoxeliaCore` and `VoxeliaSpatial`. Neither transitively reaches Metal,
   MetalKit, RealityKit or Model I/O.
2. **Every Geometry source file imports only those two modules.** The complete
   set of `import` statements across `Sources/VoxeliaGeometry` is
   `import VoxeliaCore` and `import VoxeliaSpatial`.
3. **No canonical geometry value carries backend state.** `TriangleMesh`
   stores a position domain, topology and vertex attributes and nothing else.
   It exposes no residency handle, buffer, device reference or acceleration
   field, and it deliberately has no `Hashable` or `Codable` identity that a
   backend representation could be folded into.
4. **No acceleration structure exists anywhere to be canonised.**
   `Sources/VoxeliaMetal` contains no mesh, geometry or acceleration type; its
   public surface is slice and volume rendering, kernels, pipeline caching,
   residency and scheduling. Across all of `Sources`, the only occurrence of
   the strings `ModelIO` or `RealityKit` is the sentence in `TriangleMesh`'s
   own documentation asserting independence from them.
5. **The one governed backend transfer boundary is one-way and byte-level.**
   `ADR-0186` governs Metal shared-buffer transfer as an explicit checked byte
   copy; no accepted record permits a backend buffer to become an input to
   authoritative geometry, and `ADR-0183` decision 1 already discharges the
   arc-wide rule that rasterised presentation output is never a measurement
   input.
6. **Every published geometry operation returns a pure value.** Scalar and
   labelled extraction, deterministic normals, total facet area and certified
   enclosed volume all live in `VoxeliaCPU`, publish immutable values, and are
   selected through `ImplementationRegistry` rather than through a backend
   type. The registry is the accepted place a future accelerated
   implementation registers itself, and `ADR-0194`/`ADR-0195` both require an
   accelerated backend to reproduce the CPU reference bit-for-bit or register
   a separately accepted approximation.

### One enforcement gap was found and is closed here

`Tools/Scripts/check_prohibited_imports.py` mechanically forbids `ModelIO` in
`VoxeliaCore`, `VoxeliaSpatial`, `VoxeliaStorage`, `VoxeliaExecution`,
`VoxeliaImaging` and `VoxeliaRendering` — but **not** in `VoxeliaGeometry`,
whose prohibited set listed only Metal, MetalKit, RealityKit, CoreImage and
DICOMKit.

That omission matters more in Geometry than in any of the six modules that do
carry it. Model I/O is Apple's mesh interchange framework, so Geometry is
precisely the module where an accidental Model I/O dependency is plausible.
`ADR-0183` decision 1 states that the published geometry value "is independent
of Metal, RealityKit, Model I/O and physical buffer residency", and
`TriangleMesh`'s own documentation repeats it. The claim was therefore asserted
in two accepted places and enforced in none.

No source file violates it today — the check passes unchanged after the fix —
so this is a latent gap, not a live defect. It is closed now, while the
requirement it protects is under assessment, rather than left for a future
increment to discover by regression.

### No acceleration adapter is built, and that is the correct outcome

Building a speculative adapter now would be wrong on three independent grounds.

There is no consumer. No accepted record defines a surface renderer, a picking
path or any other component that would consume an acceleration structure;
`VOX-SUR-*` is unopened. Building one would mean inventing its shape from
nothing.

It would risk the exact harm the requirement forbids. A single adapter written
without a consumer would, in practice, become the shape every later consumer
conformed to — which is how a particular structure becomes canonical by
default rather than by decision.

The requirement's own verification methods are Inspection and Review. A
documentation-only assessment is the verification the baseline asks for, and
this project's precedent (`ADR-0037`, `ADR-0114`, `ADR-0121`, `ADR-0145`,
`ADR-0181`) is that an assessment record is the correct product when nothing
needs building. Inventing work to look productive would be the failure mode,
not the discipline.

## Decision

1. **`VOX-GEO-011` is discharged by inspection**, on the six structural
   findings above. The geometry architecture permits acceleration structures —
   the canonical mesh is a pure value any backend can derive from — and makes
   no Metal, RealityKit or Model I/O structure canonical, because none exists
   and none can be reached from the module.
2. **The Model I/O enforcement gap is closed.** `ModelIO` is added to
   `VoxeliaGeometry`'s prohibited-import set, making the accepted independence
   claim mechanically enforced rather than merely asserted. The check passes
   unchanged, confirming no existing violation.
3. **No acceleration adapter, backend geometry type or GPU mesh residency
   model is created.** A real adapter arrives with its first genuine consumer,
   under its own record, and must be derived and non-authoritative: it may not
   enter canonical mesh identity, may not become a measurement input, and must
   reproduce the accepted CPU references bit-for-bit or register a separately
   accepted approximation.
4. **The `ADR-0183` geometry arc is closed.** Its requirement set is
   discharged: `VOX-GEO-004` by the attribute vocabulary plus a deterministic
   normal producer, `VOX-GEO-006` by the coordinate-space and provenance rules
   every accepted operation carries, `VOX-GEO-007` and `VOX-GEO-008` by scalar
   and labelled Freudenthal extraction, `VOX-GEO-009` by deterministic vertex
   normals, `VOX-GEO-010` by total facet area and certified enclosed volume,
   and `VOX-GEO-011` by this record.
5. **`VOX-SUR-*` is now assessable and needs its own arc-opening record.** It
   is not reopened, folded in or pre-designed here.

On `VOX-GEO-004` the claim is stated precisely rather than generously: the
attribute representation supports normals, colours, scalar fields, labels and
texture coordinates as declared semantics, and only normals currently have an
accepted generating operation. That is consistent with the requirement's own
"where applicable" wording, because no accepted record yet defines a colour or
texture-coordinate producer. This record does not claim producers that do not
exist.

## Alternatives considered

### Build a demonstration Metal acceleration adapter

Rejected. See "No acceleration adapter is built" above: no consumer, a real
risk of canonising a structure by default, and a verification method that asks
for inspection rather than demonstration.

### Discharge `VOX-GEO-011` without touching the import policy

Rejected. The assessment's whole value is that it inspects rather than assumes.
Having found that an accepted independence claim was unenforced in exactly the
module most exposed to it, recording the finding and leaving it open would make
the assessment weaker than the inspection that produced it.

### Add `ModelIO` to `VoxeliaCPU` and `VoxeliaMetal` as well

Rejected for this record. `VoxeliaMetal` is the module where a future Model I/O
or RealityKit adapter would legitimately live if one is ever accepted, so
tightening it pre-empts a decision that belongs to that adapter's own record.
`VoxeliaCPU`'s prohibited set is a separate, already-accepted boundary and
changing it is outside this assessment's scope.

### Fold the surface-rendering arc into this record

Rejected. `ADR-0183` decision 6 excluded `VOX-SUR-*` from this arc explicitly.
Nine requirement rows spanning transforms, depth, opacity, materials, colour
maps, clipping, picking, annotation registration and GPU-generated geometry
need their own decomposition, not a paragraph at the end of someone else's
closing record.

## Consequences

The geometry extraction arc opened by `ADR-0183` is complete. A canonical
triangle mesh, scalar and labelled surface extraction, deterministic vertex
normals, total facet area and certified enclosed volume are all accepted,
implemented, registered and evidenced, and the architecture is inspected and
confirmed to keep acceleration derived rather than canonical.

The deliberate limitation is that no accelerated geometry path exists. That is
a recorded absence with a stated trigger — a genuine consumer — not an
oversight.

The M6 queue's remaining items are the surface-rendering arc (`VOX-SUR-*`,
newly assessable) and the colour/overlay arc (`VOX-R2D-010/011/015` plus VOI
verification).

## Affected modules

Documentation and one repository policy script. No product source, public API,
registry entry, accepted algorithm or module dependency edge changes.

## Compatibility impact

None. No API changes. The prohibited-import addition constrains future source
only; it passes against the current tree unchanged.

## Security impact

Strictly positive and small: one more mechanically enforced module boundary,
closing a latent path by which a backend interchange framework could have
entered a module whose accepted contract forbids it.

## Performance and memory impact

None. No source executes differently.

## Validation impact

This assessment requires the prohibited-import check, the scaffold validation
that runs it, documentation, register, index, manifest and release-integrity
checks. Product builds and tests are not evidence for a policy-and-documentation
increment, and the standing rule applies: the claim that no product source
changed is verified against the staged diff rather than assumed.

## Migration

None for product source. The single repository change is one entry added to
`VoxeliaGeometry`'s prohibited-import set; it passes against the current tree,
so there is nothing to migrate. A future accelerated geometry path migrates
under its own record, with its first genuine consumer, subject to decision 3.

## Supersession

This record completes the final stage of `ADR-0183` and supersedes no accepted
record. It corrects a `AUTONOMY_STATUS.md` next-action line, not an accepted
decision.

## References

- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0186 - Governed Metal shared-buffer transfer boundary](ADR-0186-governed-metal-buffer-transfer.md)
- [ADR-0189 - Coordinate-bearing triangle mesh](ADR-0189-coordinate-bearing-triangle-mesh.md)
- [ADR-0193 - Deterministic triangle-mesh vertex normals design](ADR-0193-deterministic-triangle-mesh-vertex-normals-design.md)
- [ADR-0194 - Triangle-mesh total facet area design](ADR-0194-triangle-mesh-total-facet-area-design.md)
- [ADR-0195 - Triangle-mesh certified enclosed volume design](ADR-0195-triangle-mesh-enclosed-volume-design.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
