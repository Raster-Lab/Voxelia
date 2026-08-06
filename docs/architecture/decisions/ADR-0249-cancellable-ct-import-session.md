---
document_id: "ADR-0249"
title: "Cancellable CT import session"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ERR-001"
  - "VOX-VS1-017"
---

# ADR-0249 - Cancellable CT import session

## Context

`VOX-VS1-017` requires the first vertical slice to **demonstrate that
cancellation prevents stale result publication**, and declares `T` alone — so it
can be discharged completely, with no demonstration half left outstanding.

`ADR-0248` sized this row by noting that `RenderGeneration.isStale` exists with
zero production callers. That fact is correct and the inference drawn from it was
incomplete; the correction is decision 1 below.

## The finding: two different stages, and only one of them is this row

`ADR-0122` decision 3 already settled what the generation vocabulary is for:
"stamping frames and dropping stale ones is the interactive draw loop's
behaviour", with `VOX-INT-007` "discharged at the contract level" and the
draw-loop integration "recorded with its gate". **The absence of callers is
deliberate and recorded, not an oversight** — its consumer is owner-gated.

The First Vertical Slice Plan draws the same line twice, and reading it settles
this row:

- **§22.3** — "A CPU or Metal result may be **presented** only if its generation
  equals the current viewport generation." §58.2 repeats it: "only current
  generation **presented**", "obsolete completion ignored".
- **§22.1** — "A **CT import session shall be cancellable**", naming nine stages;
  §58.1 then requires that cancelling during metadata scan, decode, volume copy,
  identity calculation or publication yields "no partial `ImageData`", "typed
  cancellation" and "no corrupt cache entry".

`VOX-VS1-017`'s own wording is **publication**, not presentation. So this row is
§22.1 and §58.1 — the import path — and it is *not* gated on the draw loop.
§22.3's presentation rule stays with `ADR-0122`'s gate, alongside the other
Demonstration halves, and is not claimed here.

**The import path currently has no cancellation at all.** `RegionExtraction`,
`SqueezeAxes` and `WindowLevel` — the three operations the CT path actually uses —
contain no cancellation vocabulary, and neither does `PublicationCoordinator`.
The geometry and surface operations in `VoxeliaCPU` do carry cancellation probes,
so the pattern exists in the project; the imaging path never adopted it.

**There is also no owner of the frame loop.** `CTSeriesAssembler`,
`CTVolumeByteBuffer` and `CTVolumePublicationBuilder` are all Voxelia types, but
the loop over a series' frames lives in caller code — the `VOX-VS1-001`
demonstration harness had to write it by hand. A cancellable import session has
nowhere to live until something owns that loop, which is why this row needs a
built path rather than an assessment.

## The second finding: publication-time atomicity is already structural

§58.1 asks what happens when cancellation arrives *during* publication.
`PublicationCoordinator.publish` is explicitly three-phase, and its phase two is
a **non-suspending critical section** in which "identifier reuse, the ceiling,
the ancestry closure, graph admission and the registry mutation linearise
together".

A non-suspending region has no cancellation point. There is nothing to check and
nothing to interrupt: the registry either takes the whole graph or throws.
"No partial `ImageData`" and "no corrupt cache entry" are therefore **properties
of the existing design**, not properties a new probe would add. Phase three's
cache alias is already best-effort and already documented as never unwinding a
completed publication.

So the correct decision is to add **no** cancellation probe to `publish`, and to
record why — an unreachable check inside a critical section would be a branch
that can never fire, which this project removes on sight.

## Decision

1. **`ADR-0248`'s sizing of this row is corrected.** It reported
   `RenderGeneration.isStale` as having zero production callers and treated that
   as the gap. The fact is right; the framing was not. `ADR-0122` decision 3
   deliberately left presentation wiring to the gated draw loop, so the
   uncalled predicate is a recorded deferral rather than an omission — and it
   belongs to `VOX-INT-007`, not to this row. This record corrects that framing
   here rather than editing `ADR-0248`.
2. **A source-agnostic cancellable assembly session is added to
   `VoxeliaImaging`.** It owns the multi-frame loop that callers currently write
   by hand, and it is parameterised by a frame-supplying closure rather than
   coupled to DICOM. `VoxeliaDICOMKit` supplies the DICOM-backed closure.
3. **The session is in `VoxeliaImaging`, not `VoxeliaDICOMKit`, and the reason is
   testability.** A session behind the optional DICOM product could only be
   tested with the dependency present, and its cancellation test would need
   patient data no repository test may read. A source-agnostic session is
   testable from `VoxeliaImagingTests` with a synthetic frame source, which is
   what `VOX-VS1-017`'s `T` obligation actually requires.
4. **The cancellation model composes the accepted per-operation pattern rather
   than inventing a second one**: a checkpoint enum plus a
   `@Sendable (Checkpoint) -> Bool` probe, with the probe consulted at named
   sites and a `.final` checkpoint immediately before the publication aggregate
   is returned. This is the shape `ADR-0195` decision 17 and its siblings already
   use in `VoxeliaCPU`.
5. **The checkpoint set covers only the stages the session performs.** §22.1
   lists nine stages, and this session does not perform source discovery (the
   caller supplies the sources) or viewport readiness (there is no viewport).
   Claiming checkpoints for stages the session does not run would be a false
   claim about where cancellation is honoured — "claim what you implement".
6. **No cancellation probe is added to `PublicationCoordinator.publish`**, for
   the reason in the second finding: phase two does not suspend, so the check
   would be unreachable. The atomicity claim is verified by test rather than
   asserted.
7. **`.final` is checked before publication, so cancellation prevents publication
   by construction.** The session returns nothing publishable when cancelled;
   there is no partial aggregate for a caller to publish by mistake.
8. **A typed, payload-free cancellation case**, consistent with every other
   failure family in the project. Cancellation is an outcome, not an error to be
   dressed up with diagnostics that could disclose extents.
9. **No algorithm specification and no oracle accompany this record.** There is
   no numeric boundary — no arithmetic, no rounding, no representability
   question. `ADR-0198` and `ADR-0209` set the precedent that a vocabulary or
   ordering increment needs no `ALG`, and `ADR-0208` decision 1 requires one only
   where a numeric boundary is fixed. Minting one here would be ceremony.

## An ordering question this record deliberately leaves open

`MPRSliceCoordinator.extractSlice` publishes **twice** — the slab, then the
squeezed slice. Cancellation arriving between those two publications would leave
the slab published and the slice absent. Whether that is "partial" is a real
question, and it belongs to the *view* path rather than the import path: the
import session publishes once.

It is recorded here rather than answered because answering it would require
deciding whether a multi-stage publication is a transaction, which is a
provenance-graph question with consequences well beyond this row. Naming it is
what stops a later increment from assuming this record settled it.

## Alternatives considered

### Wire `RenderGeneration` into the publication path

Rejected, and this was the plan `ADR-0248` implied. A render generation counts
scene versions for presentation; `ADR-0122` says so and rejects conflating it
with anything else. Publication is not presentation, and threading a
presentation-layer counter through the publication path would tie ingest
lifetime to viewport state — the exact conflation `ADR-0122`'s alternatives
already rejected once.

### Put the session in `VoxeliaDICOMKit`

Rejected; see decision 3. It reads as the natural home because the import is a
DICOM import, but it would make the row's own test obligation dependent on both
the optional product and patient data.

### Add a cancellation probe to every existing imaging operation

Deferred rather than rejected. `RegionExtraction`, `SqueezeAxes` and
`WindowLevel` genuinely lack cancellation, and long-running view work should be
cancellable. But each is a public signature with call sites across five test
targets, no parameter may be defaulted under house style, and none of it is what
`VOX-VS1-017` asks for. Bundling it here would make an unrelated API sweep a
hidden part of a cancellation record.

### Check `Task.isCancelled` directly instead of taking a probe

Rejected. The accepted pattern takes an injected probe precisely so a test can
drive cancellation deterministically at a chosen checkpoint; `Task.isCancelled`
alone makes the property testable only by racing. The DICOM-backed closure will
pass `{ _ in Task.isCancelled }`, which is how the `VoxeliaCPU` operations
already bridge the two.

## Consequences

`VOX-VS1-017` becomes a buildable row with a test obligation that needs neither
the optional DICOM product nor patient data.

`ADR-0248`'s framing is corrected without editing it. The generation vocabulary
stays where `ADR-0122` put it.

The multi-stage publication question is named and left open.

## Affected modules

`VoxeliaImaging` gains the session, its checkpoint vocabulary and its failure
case. `VoxeliaDICOMKit` gains the DICOM-backed frame source. No module's
dependencies change, and no existing public signature changes.

## Compatibility impact

Additive.

## Security impact

Neutral to positive. The failure family is payload-free, and a cancelled import
publishes nothing — so a partially assembled volume can never reach the registry
and be mistaken for a complete one.

## Performance and memory impact

The probe is one closure call per checkpoint. Cadence matters at the frame loop,
which is where the measured time is: the real 899-frame series spends about
`3.77 s` in transfer. A per-frame checkpoint is therefore both cheap relative to
the work and frequent enough to be responsive.

## Validation impact

```text
swift build && swift test
swift test --filter "CTImportSession"
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The publication-atomicity claim of decision 6 is to be **verified by test, not
asserted**: a publication cancelled at the surrounding task must leave the
registry either fully updated or untouched, with no intermediate state
observable.

## Migration

1. This record.
2. Stage one: the checkpoint vocabulary, the failure case and the session in
   `VoxeliaImaging`, with cancellation tests driven by a synthetic frame source
   at every checkpoint.
3. Stage two: the DICOM-backed frame source in `VoxeliaDICOMKit`, and a real-data
   run confirming a cancelled import of the 899-frame series publishes nothing.
4. Stage three: the publication-atomicity test of decision 6.
5. **Open, not part of this row**: cancellation for the view-path operations, and
   the multi-stage publication question named above.

## Supersession

This record supersedes nothing. It **corrects `ADR-0248`'s framing** of why
`RenderGeneration` has no callers, recording the correction here rather than
editing that record.

## References

- [ADR-0122 - Render generations](ADR-0122-render-generations.md)
- [ADR-0195 - Triangle mesh enclosed volume design](ADR-0195-triangle-mesh-enclosed-volume-design.md)
- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [ADR-0248 - Linked crosshair verification](ADR-0248-linked-crosshair-verification.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
