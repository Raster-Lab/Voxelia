---
document_id: "ADR-0329"
title: "Interactive refinement is deferred"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-BRK-009"
  - "VOX-DVR-013"
---

# ADR-0329 - Interactive refinement is deferred

## Context

Two of the three rows left in `ADR-0319`'s queue are the same capability seen from two sides:

- **`VOX-BRK-009`** — "interactive rendering shall be able to use a lower-resolution
  representation". P0, `T,D`, M6.
- **`VOX-DVR-013`** — "interactive quality shall refine towards requested diagnostic quality".
  P0, `T,D`, M6.

## The measurement

**These are not unbuilt by oversight. They are unbuilt by an accepted decision.**

`RenderQuality` exists with `interactive` and `full` cases, and `SceneSnapshot`'s own
documentation states the position:

```text
version-one renderers are deterministic single-pass, and per `ADR-0103` the two requests
execute identically: the request is a hint, stage claims record the quality that actually
ran, and a future degraded interactive path will claim its own quality tokens through its
own decisions.
```

A `[Pipeline]` test asserts it directly — *"both qualities execute identically"*. So the
vocabulary is in place, the equality is deliberate, and the degraded path is named as future
in the source rather than merely absent from it.

## Decision

1. **Neither row is discharged**, and neither is recorded as an oversight. `ADR-0103` decided
   that version one is single-pass; these rows describe the version that supersedes that
   decision.
2. **The distinction from the other unbuilt rows is recorded.** `VOX-PER-006`, `VOX-CON-008`
   and `VOX-IMG-008` are unbuilt with nothing having decided they should be; these two are
   unbuilt **because a record said so**, and the difference matters when the work is scheduled.
3. **The existing test is the guard, not a gap.** "Both qualities execute identically" will
   **fail** the day a degraded path lands — which is correct. It is the assertion that keeps
   `ADR-0103` honest while it holds, and the first thing the superseding increment must
   consciously replace rather than quietly delete.
4. **Both `D` obligations remain with the owner**, as with every Demonstration in this sweep.

## Alternatives considered

### Record them as ordinary unbuilt rows

Rejected; see decision 2. It would lose the fact that an accepted record chose this, and would
invite a future increment to "fix" a deliberate design as though it were an omission.

### Supersede `ADR-0103` now

Rejected as far beyond an increment's scope. A degraded interactive path changes what a stage
claim means, and `ADR-0103`'s equality is load-bearing for the provenance those claims carry.

### Weaken the identical-execution test to unblock the rows

Refused. That test is the evidence `ADR-0103` is still true. Weakening it in advance would
remove the signal that the design had changed.

## Consequences

The queue's last two testable rows are characterised: both wait on a decision to supersede
`ADR-0103`, not on missing effort.

**`VOX-PER-004`** is the only row now unaccounted for — 512³ volume rendering at 30–60 frames
per second, `P1`, `T,D`, which is a measurement on reference hardware the owner has yet to
name.

## Affected modules

None.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: `VOX-PER-004`, which needs the reference-hardware decision already on the owner's
   list.
3. **Owner**: unchanged. Both Demonstrations join the existing list.

## Supersession

This record supersedes nothing. It **characterises** two rows as deferred by `ADR-0103` rather
than neglected.

## References

- [ADR-0103 - Interactive quality equivalence](ADR-0103-interactive-quality-equivalence.md)
- [ADR-0307 - First useful image is unbuilt](ADR-0307-first-useful-image-is-unbuilt.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0325 - Grid resampling is unbuilt](ADR-0325-grid-resampling-is-unbuilt.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
