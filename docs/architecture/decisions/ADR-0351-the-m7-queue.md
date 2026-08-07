---
document_id: "ADR-0351"
title: "The M7 queue"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
---

# ADR-0351 - The M7 queue

## Context

`ADR-0350` entered M7-M10; the ledger's next action is the M7 derivation. M7 is
44 rows — advanced processing, segmentation and registration — and this record
groups them into arcs, fixes the arc order by dependency, and batches the owner
questions so they arrive once. Naming the rows here traces them; **traced is
not satisfied**, and every row stays open until its arc's records discharge it.

## The six arcs, in order

1. **Image-processing foundations** — `VOX-IMG-010` (threshold, mask,
   arithmetic), `VOX-IMG-011` (convolution and Gaussian with explicit boundary
   conditions), `VOX-IMG-012` (morphology), `VOX-IMG-013` (connected
   components), `VOX-IMG-014` (distance transforms), `VOX-IMG-007` (label-map
   nearest-neighbour default), `VOX-R2D-004` (floating-point pipeline input).
   First because segmentation composes every one of them, and because they are
   pure CPU numerics — design-first with oracles, no owner input.

2. **Segmentation** — `VOX-SEG-001` through `VOX-SEG-010`: the mask and
   multi-segment model (overlap without a forced exclusive label), segment
   descriptors with provenance, geometry binding, nearest-neighbour resampling
   default (`VOX-SEG-005` with `VOX-IMG-007`), the operation set over arc 1
   (`VOX-SEG-006`), region growing with recorded seeds (`VOX-SEG-007`),
   explicit provenance-producing editing (`VOX-SEG-008`), statistics from
   authoritative data (`VOX-SEG-009`), and the AI-adapter boundary
   (`VOX-SEG-010`, whose `R` is the owner's).

3. **Registration** — `VOX-REG-001` through `VOX-REG-010` plus `VOX-VAL-014`:
   the transform-category model, result records naming metric, optimiser,
   schedule and convergence, coordinate-space validation composing the
   accepted affine machinery, landmark/rigid/affine portfolio,
   multi-resolution pyramids (composing `LevelSelectOperation`), mean-square
   and mutual-information metrics, explicit non-convergence reporting, and
   the registration validation report. `VOX-DAT-008` (additional axes) and
   `VOX-SPA-012` (rectilinear and frame-set geometry without false
   regularisation) open here because registration is their first consumer.

4. **Reconstruction and format tails** — `VOX-MPR-012`/`VOX-MPR-013` (curved
   planar reconstruction with an explicit physical centreline and back-mapping)
   and `VOX-DCM-011`/`VOX-DCM-012` (enhanced multi-frame geometry models and
   DICOM segmentation/parametric/surface/registration adapters).

5. **Extension mechanism** — `VOX-EXT-001` through `VOX-EXT-006`. Much of the
   substance exists (`ImplementationRegistry`, registration identities,
   provenance requirements); the arc's work is measuring what the rows demand
   against what is built, closing gaps, and leaving the `D` halves for the
   owner's next session.

6. **Interoperability** — `VOX-ADP-007` through `VOX-ADP-010`: VTK/ITK
   exchange as optional, never-core dependencies. **Blocked on the owner
   batch below before any dependency enters the tree.**

## The owner batch (asked once, here — nothing proceeds on these until answered)

1. **VTK/ITK interop scope** (`VOX-ADP-008`/`VOX-ADP-009`, both "should"):
   which packages, if any, are approved for the optional adapters — supply
   chain stays owner-reserved. A "defer to post-1.0" answer retires the two
   "should" rows for this series and leaves `VOX-ADP-007`/`010` dischargeable
   as boundary rules.
2. **AI inference reference adapter** (`VOX-SEG-010`): the boundary will be
   built and inspected; does the owner want a reference adapter against a
   specific model/runtime now, or the boundary alone with `R` at the next
   session?
3. **DICOM SEG capability** (`VOX-DCM-012`): the adapters compose DICOMKit;
   if gaps surface in the library the standing instruction is fix-what-
   surfaces — confirmation that this applies to SEG/parametric-map reading.

## Decision

1. The queue and order above are fixed; arc 1 opens next increment with the
   threshold/mask/arithmetic design (`VOX-IMG-010`), design-first with an
   independent oracle.
2. The owner batch is surfaced with this record and not re-asked piecemeal;
   arcs 1-5 proceed without it, arc 6 waits.
3. Rows named here leave the untraced baseline per the ratchet's own rule;
   the baseline keeps only rows no record yet names.

## Alternatives considered

### Open segmentation first

Rejected. Its operation set (`VOX-SEG-006`) is arc 1 by another name; opening
it first would rebuild the foundations inside a consumer arc.

## Consequences

M7 is a derived, ordered queue with its owner questions batched; the untraced
baseline drops to the M8-M10 rows plus nothing of M7.

## Affected modules

None. This record derives; the arcs build.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_requirement_traceability.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1289 tests in 225 suites pass, unchanged — this record adds no code.

## Migration

1. This record; the baseline shrinks by the ratchet's rule.
2. **Next**: arc 1, increment one — the `VOX-IMG-010` design.
3. **Owner**: the batch above, at leisure; only arc 6 waits on it.

## Supersession

This record supersedes nothing. It derives the queue `ADR-0350`'s entry
created, the same act `ADR-0290` and `ADR-0319` performed for earlier sweeps.

## References

- [ADR-0350 - v0.2.0 released and M7-M10 entered](ADR-0350-v020-released-and-m7-m10-entered.md)
- [ADR-0343 - Open the progressive refinement arc](ADR-0343-open-the-progressive-refinement-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
