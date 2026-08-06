---
document_id: "ADR-0221"
title: "Multiplanar render path"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-ARC-006"
  - "VOX-VS1-009"
  - "VOX-VS1-010"
---

# ADR-0221 - Multiplanar render path

## Context

`ADR-0217` found `VOX-VS1-010` — "the first vertical slice shall provide Metal
axial, coronal and sagittal rendering" — genuinely unbuilt, with an unusually
precise diagnosis: **both halves exist and do not meet.** `MPRPlane` defines the
three planes and `MPRSliceCoordinator` extracts them under `ADR-0117`;
`ExactSliceRenderer` and `MetalSliceRenderer` render published scene layers on
the GPU. No source file connects them.

`ADR-0220` named this the only one of the sweep's six surfaced gaps that is both
unblocked and has a clear consumer, since the vertical slice names it directly.

## Decision

1. **The Metal path does not reconstruct planes. It renders a reconstruction
   the accepted CPU path already produced.** `MPRSliceCoordinator` extracts a
   plane by composing the registered region model and the singleton-axis
   squeeze, publishing both stages. The renderer consumes that published image
   as a scene layer.
2. **A GPU sampler for plane reconstruction is rejected, and the reason is the
   one this project keeps reaching.** It would be a second sampling predicate
   that could disagree with the accepted one — the same refusal `ADR-0205` made
   for a second intersection and `ADR-0212` for a second colour transform. An
   axis-aligned plane of a rank-three volume is an exact byte selection, so a
   GPU path could only match or differ; matching adds nothing and differing is a
   defect.
3. **This record therefore freezes no numeric boundary, and carries no
   algorithm specification and no oracle.** Every numeric rule in the path is
   already accepted: `VOXELIA-ALG-0006` for the region origin shift, the
   registered singleton drop for the squeeze, `VOXELIA-ALG-0002` for the window,
   and the accepted presentation path for the render. Introducing a new one
   here would mean introducing the second predicate decision 2 rejects.
4. **The plane vocabulary is `MPRPlane`, unchanged.** `ADR-0117` froze axial,
   coronal and sagittal, and the requirement names exactly those three. An
   oblique variant is `ADR-0142`'s accepted operation and a different row.
5. **The coordinator lives in `VoxeliaRendering`.** `VoxeliaRendering` already
   depends on `VoxeliaImaging`; the reverse edge would be a cycle. No dependency
   edge changes.
6. **`VOX-ARC-006` holds by construction, not by care.** The coordinator calls a
   caller-supplied `SliceRenderer`, the accepted backend-neutral protocol, so
   the Metal command lifecycle stays entirely inside whatever conforms to it.
   `VoxeliaImaging` and `VoxeliaRendering` both remain unable to import Metal,
   and the prohibited-import check enforces that.
7. **The plane is not restated in presentation provenance.** The rendered
   layer's own published object carries the extraction chain — region, then
   squeeze — so the plane is recoverable from its ancestry. Copying it into the
   presentation claim would create a second place for one fact to drift, which
   is the mistake `ADR-0214` decision 6 avoided for colour.
8. **The colour claim passes through unchanged.** `ADR-0214` made the request's
   colour output, transform and declared space explicit and required; the
   coordinator forwards the caller's values rather than choosing them, because
   choosing would be the permissive default the house rule forbids.
9. **The evidence is that the three planes actually differ.** A test that
   rendered three planes of a cube would pass while transposing them. The suite
   uses an **anisotropic** volume whose three planes have different extents and
   different contents, so a swapped or duplicated plane fails.
10. **`VOX-VS1-010` declares `T,D`; only the Test half is claimed.** The
    demonstration is an interactive act on the owner-gated draw loop, exactly as
    the other `T,D` rows in this project are treated. **`VOX-VS1-009`** — CPU
    reference axial, coronal and sagittal reconstruction, **T** — is discharged
    outright by the same suite, because the coordinator's reconstruction half
    *is* the CPU reference path.

## Alternatives considered

### Reconstruct planes with a Metal compute kernel

Rejected; see decision 2.

### Put the coordinator in `VoxeliaImaging`

Rejected; see decision 5. It would require `VoxeliaImaging` to depend on
`VoxeliaRendering`, inverting an existing edge and creating a cycle.

### Give the coordinator its own renderer rather than taking one

Rejected; see decision 6. Owning a renderer would pull the Metal lifecycle
towards the imaging semantics, which is precisely what `VOX-ARC-006` forbids.

### Record the plane in `PresentationProvenance`

Rejected; see decision 7.

### Test with a symmetric phantom

Rejected; see decision 9. A cube cannot distinguish a correct plane from a
transposed one, and a test that cannot fail is not evidence.

## Consequences

`VOX-VS1-010`'s Test half and `VOX-VS1-009` are discharged. The two halves that
existed separately now compose, and the composition adds no numeric rule, no
dependency edge and no Metal reach into the imaging layer.

The deliberate limitations are the three axis-aligned planes only, one volume
per render, and no interactive plane scrubbing.

## Affected modules

`VoxeliaRendering` gains the coordinator. No dependency edge changes and no
Metal import anywhere new.

## Compatibility impact

None; the coordinator is additive and nothing existing changes shape.

## Security impact

No new allocation beyond the accepted extraction and render paths; errors are
the composed contracts' own audited typed errors.

## Performance and memory impact

One published extraction plus one render per plane, both already accepted paths.

## Validation impact

No oracle, because no numeric boundary is frozen. The migration must prove that
all three planes render through the backend-neutral protocol, that an
**anisotropic** volume yields three genuinely different results so a transposed
or duplicated plane fails, and that the caller's colour claim reaches the
request unchanged.

## Migration

1. Add the multiplanar render coordinator to `VoxeliaRendering` with its suite.
2. The remaining surfaced gaps — lazy evaluation, progress reporting, benchmark
   classification, staging-buffer reuse and golden-result metadata — stay
   recorded and unclaimed.

## Supersession

This record supersedes nothing. It composes `ADR-0117`'s extraction with
`ADR-0085`'s render contract.

## References

- [ADR-0085 - Render request, result and protocol](ADR-0085-render-request-result-and-protocol.md)
- [ADR-0117 - MPR slice coordinator](ADR-0117-mpr-slice-coordinator.md)
- [ADR-0142 - Oblique slice operation](ADR-0142-oblique-slice-operation.md)
- [ADR-0205 - Surface picking design](ADR-0205-surface-picking-design.md)
- [ADR-0214 - Colour claim completion](ADR-0214-colour-claim-completion.md)
- [ADR-0217 - Vertical slice traceability](ADR-0217-vertical-slice-traceability.md)
- [ADR-0220 - Remaining traceability paydown](ADR-0220-remaining-traceability-paydown.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
