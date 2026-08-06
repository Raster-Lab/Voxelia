---
document_id: "ADR-0215"
title: "Multi-volume fusion assessment"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-ERR-001"
  - "VOX-MPR-011"
---

# ADR-0215 - Multi-volume fusion assessment

## Context

`ADR-0208` recorded, while opening the colour and overlay arc, that
`VOX-MPR-011` — "Voxelia shall support multi-volume fusion for spatially
registered inputs", P1, `T,D`, M6 — appears in the requirements baseline and the
release traceability index and **nowhere else**: in no accepted record and not
once in the autonomy ledger, including the M6 opening assessment that enumerated
the milestone's rows. It was deliberately not folded into that arc, because
fusion is not colour or overlay work.

This record assesses it. `ADR-0208` bound the assessment two ways: it must
settle the row's relationship to `VOX-DVR-010`'s deferred multi-volume
compositing half rather than assume they are the same question, and it must not
pre-judge whether the finding is documentation, a deferral or a built path.

## Findings

1. **The two questions are different.** `ADR-0180` deferred multi-volume
   compositing as the open half of `VOX-DVR-010`, and that half lives **inside
   the ray-cast traversal**: combining two volumes at every sample along a ray,
   interacting with transfer functions, gradient lighting and early ray
   termination. `VOX-MPR-011` lives at the **reconstruction** stage: two volumes
   reconstructed onto one plane and combined for display. Different stage,
   different data, different blend point. Discharging one would not discharge
   the other, and the deferral of the DVR half does not bind this row.
2. **Registration is already structural, and nothing needed inventing.**
   `ObliqueSliceOperation` takes an `AffineGridGeometry` output grid and rejects
   a coordinate-space mismatch **typed**. Reconstructing the *same* grid from
   two volumes therefore yields two co-registered images **by construction**:
   every output sample of both images is the same physical position. There is no
   resampling machinery to write, and no relabelling can occur.
3. **The blend rule that blocked the DVR half now exists for this one.**
   `ADR-0180` deferred its half for want of a consumer-driven blend rule. Two
   increments ago `VOXELIA-ALG-0045` froze exactly the rule fusion needs: a
   colour-mapped overlay composited over a base with per-pixel straight alpha.
   A colour-mapped functional volume over a greyscale anatomical one *is* that
   model. The colour and overlay arc supplied the missing piece for this row
   without being aimed at it.
4. **What is genuinely missing is the registration admission between two
   reconstructions.** Each operation checks its own grid against its own volume;
   nothing checks that two *reconstructions* share a grid, a space and an
   extent. That check is the requirement's actual core — "spatially registered
   inputs" is the whole claim — and it exists nowhere.

The finding is therefore a **built path**, and a small one: the composition plus
the admission nothing currently performs.

## Decision

1. **`VOX-MPR-011` is discharged for its Test method by a fused reconstruction
   reference in `VoxeliaExecution`**, composing the accepted reconstruction,
   colour-map and overlay-compositing models rather than adding a fourth.
2. **This record freezes no numeric boundary, so it carries no algorithm
   specification and no oracle.** The arithmetic is `ALG-0045`'s, reused
   unchanged; the new content is an admission. This is the `ADR-0198`,
   `ADR-0209` and `ADR-0211` precedent.
3. **The registration admission is exact value equality, not a tolerance.** Two
   reconstructions are registered when their coordinate spaces, their
   index-to-world transforms, their axis mappings and their extents are equal.
   `AffineGridGeometry` is `Hashable`, so this is exact. **A tolerance would be
   a fabricated claim**: two grids that differ by any amount are not the same
   plane, and deciding how much difference is acceptable is a clinical judgement
   no accepted record supplies.
4. **"Spatially registered" means the inputs already share a coordinate space —
   this record does not compute a registration.** Rigid or deformable
   registration is a different problem with its own literature, its own
   validation burden and its own arc; reading the requirement as asking for it
   would be inventing scope. The requirement says *registered inputs*, and this
   record admits them.
5. **Version one fuses exactly two reconstructions**, a base and one overlay.
   N-volume fusion needs an ordering rule and a per-volume opacity policy with
   no consumer to settle them, and `ALG-0045` already composites a list when one
   arrives.
6. **The base is greyscale and the overlay is colour-mapped**, which is the
   fusion shape every consumer of this requirement means. The reverse — a
   greyscale overlay over a colour base — needs no new rule if a consumer
   appears, because the compositing model does not care.
7. **The failure family is exactly three payload-free cases**:
   `coordinateSpaceMismatch`, `gridMismatch` and `extentMismatch`. Each is
   reachable and each is distinct: a caller that mismatched spaces has a
   different problem from one that mismatched extents.
8. **`VOX-MPR-011` declares `T,D`, and only the Test half is claimed.** The
   demonstration half depends on the owner-gated interactive draw loop, exactly
   as the `VOX-SUR` rows' demonstration halves do, and is recorded here as an
   outstanding dependency rather than claimed by an off-screen render.
9. **`VOX-DVR-010`'s deferred half stays deferred.** Finding 1 establishes it is
   a different question, and nothing here supplies its per-sample blend rule.

## Alternatives considered

### Treat `VOX-MPR-011` as already covered by `VOX-DVR-010`'s deferral

Rejected; see finding 1. They are different stages with different blend points,
and inheriting a deferral would have left a baseline row silently unassessed for
a second time.

### Discharge the row by documentation, as `ADR-0196` did for `VOX-GEO-011`

Rejected. `VOX-GEO-011` declares `I,R`; `VOX-MPR-011` declares `T,D`. There is a
real test obligation, and the same verification-method reading that decided
`ADR-0207` decides this.

### Admit registration within a tolerance

Rejected; see decision 3.

### Compute the registration between two unregistered volumes

Rejected; see decision 4.

### Build an N-volume fusion now

Rejected; see decision 5.

## Consequences

`VOX-MPR-011`'s Test method is discharged; its Demonstration half joins the
owner-gated draw-loop dependency list. M6's actionable work is then complete:
every remaining M6 row is either discharged or explicitly gated.

The deliberate limitations are two reconstructions only, exact registration
equality, no registration computation, and a greyscale base with a
colour-mapped overlay.

## Affected modules

`VoxeliaExecution`. No dependency edge changes.

## Compatibility impact

None; the reference is new and composes existing models without changing them.

## Security impact

Errors are payload-free and disclose no geometry, extents or samples.

## Performance and memory impact

`O(n)` in the reconstructed sample count, with one output pixel per sample.

## Validation impact

No oracle, because no numeric boundary is frozen — `ALG-0045`'s registered
digests already cover the arithmetic. The migration must prove all three
admission failures, prove that two reconstructions on the same grid fuse, prove
that an opacity of zero yields the base exactly and one yields the overlay
colour exactly, and prove the composition agrees with the accepted overlay
model rather than reimplementing it.

## Migration

1. Add the fused reconstruction reference to `VoxeliaExecution`.
2. M6's actionable queue is then empty; the remaining rows are gated.

## Supersession

This record assesses a requirement no accepted record had reached. It supersedes
nothing, and it does not reopen `ADR-0180`'s deferral of `VOX-DVR-010`'s other
half.

## References

- [ADR-0142 - Oblique slice operation](ADR-0142-oblique-slice-operation.md)
- [ADR-0180 - Segmentation masks design](ADR-0180-segmentation-masks-design.md)
- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0207 - GPU-produced geometry representability assessment](ADR-0207-gpu-geometry-representation-assessment.md)
- [ADR-0208 - Colour and overlay arc](ADR-0208-colour-and-overlay-arc.md)
- [ADR-0213 - Overlay compositing design](ADR-0213-overlay-compositing-design.md)
- [VOXELIA-ALG-0017 - Oblique slice sampling](../../algorithms/VOXELIA-ALG-0017-oblique-slice-sampling.md)
- [VOXELIA-ALG-0045 - Overlay alpha compositing](../../algorithms/VOXELIA-ALG-0045-overlay-alpha-compositing.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
