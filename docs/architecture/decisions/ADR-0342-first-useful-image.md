---
document_id: "ADR-0342"
title: "First useful image"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PER-006"
---

# ADR-0342 - First useful image

## Context

`VOX-PER-006` — the first useful image available before full study cache generation
completes, P0, `T,D`, M4 — was measured unbuilt by `ADR-0307`: no study cache
existed, no generation had a completion to be earlier than, and the import
session's checkpoints were cancellation probes that must not be reused as
publication seams (`ADR-0249` decision 7). Since then, `ADR-0338` decision 2
defined both terms — the study cache is the decoded brick store, and the first
useful image is the first fully decoded two-dimensional plane at full resolution
published for presentation — and `ADR-0341` built the generation stage with
ordered per-brick progress and a completion. What remains is exactly the
composition, built as its own thing outside the import session, as `ADR-0307`
decision 3 requires.

## Decision

1. **`FirstUsefulImagePlan` nominates the plane and owns the sweep order.** Given
   a rank-three `BrickGridDescriptor`, a plane axis and a plane index at full
   resolution (level zero, per the definition's "full resolution"), the plan
   computes the **plane-brick layer** — the coordinates whose core region covers
   the plane index — and emits the sweep order **plane bricks first**, each half
   in lexicographic coordinate order (slot 0 fastest), every brick exactly once.
   The plan carries its `planeBrickCount`; because `ADR-0341`'s sweep is
   sequential in caller order with ordered progress, **the milestone is the
   progress callback reaching that count** — no new callback surface, no change
   to the generator. The plan owning both the order and the count is what keeps
   them from drifting apart.

2. **`FirstUsefulImageAssembly` publishes the plane from the store.** At or after
   the milestone, it assembles the nominated plane by slicing each plane brick's
   decoded core bytes into a two-dimensional image: output axes are the two
   non-plane axes in ascending axis order, output layout is the canonical
   lower-axis-fastest order, and the frozen local offset within a brick's core of
   extents `(c0, c1, c2)` is `l0 + c0 * (l1 + c1 * l2)` — the same canonical
   layout rule the store's decoded representation declares. Every value is
   integer index arithmetic; the independent oracle
   (`ADR-0342-first-useful-image-oracle.py`) computes both fixtures, including
   edge bricks smaller than nominal on every axis.

3. **The decoded-representation layout is a stated precondition, not an
   assumption.** The assembly consumes bricks whose bytes are the core region in
   canonical layout — the contract of the `decoded-u8` representation the
   computation supplies. A byte count that does not match the brick's core extent
   product rejects typed (`brickByteCountMismatch`) rather than slicing garbage.

4. **A missing plane brick rejects typed** (`planeBrickMissing`), never assembles
   partially, and never fabricates padding: this is a publication of decoded
   study data, not a resampling with a padding rule. Absence is an ordering bug
   or an eviction, and the caller must know which rather than receive a plausible
   image.

5. **The before-completion property requires a proper subset, and the plan says
   so.** With one plane layer among several, the milestone precedes the
   completion structurally; a volume whose plane layer is every brick makes the
   property vacuous, and the plan exposes both counts so a caller — and the test
   — can see which case holds. The suite's witness uses a proper subset and
   proves availability while the remaining sweep is still gated.

6. **`ADR-0249` decision 7 is untouched.** Nothing here touches
   `CTImportSession` or its checkpoints; the progressive path is its own surface
   over the store, exactly as `ADR-0307` decision 3 required. A cancelled sweep
   still publishes nothing; an assembled plane is only ever produced from
   admitted store entries on request.

7. **`VOX-PER-006`'s `T` is discharged by this increment**; its `D` — the owner
   watching a first image appear during a real study's generation — joins the
   release demonstrations per `ADR-0338` decision 11.

## Alternatives considered

### A milestone callback added to the generator

Rejected. The generator's ordered progress already carries the information; a
second callback would be a parallel channel that can disagree with the first.
The plan's count against the existing progress is the same milestone with one
source of truth.

### Emit the plane from inside the sweep automatically

Rejected. Publication is the caller's act — the presentation layer chooses when
to look — and an automatic emission would couple the generator to image assembly
and mint outputs nobody requested. The store plus an explicit assembly keeps the
generator's contract unchanged.

### Reuse the import session's decode checkpoints

Rejected before design, by `ADR-0307` decision 3 and `ADR-0249` decision 7; the
record exists to make that refusal binding and it binds here.

## Consequences

`VOX-PER-006` is discharged at `T`: a caller nominates a plane, sweeps
plane-first, and provably holds a full-resolution presentation plane before
generation completes. Every M4 row is now accounted for.

## Affected modules

`VoxeliaExecution` gains `FirstUsefulImagePlan`, `FirstUsefulImageAssembly` and
their error family. No existing type changes shape.

## Compatibility impact

Additive only.

## Security impact

None. Assembly reads only admitted store entries.

## Performance and memory impact

One plane allocation at assembly; the plan is index arithmetic over brick
counts.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0342-first-useful-image-oracle.py
swift test --filter FirstUsefulImageTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The before-completion witness is gate-driven and deterministic. The full suite
must show the literal pass line before push.

## Migration

1. This record with the oracle.
2. The plan, the assembly and the deterministic suite, in the same increment.
3. **Next**: the remaining unblocked rows per `ADR-0338`'s migration order — the
   progressive-refinement arc.
4. **Owner**: the `D` half joins the release demonstrations.

## Supersession

This record supersedes nothing. It composes `ADR-0341`'s stage under `ADR-0338`
decision 2's definitions, honouring `ADR-0307` decision 3 and `ADR-0249`
decision 7 unchanged.

## References

- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [ADR-0307 - First useful image is unbuilt](ADR-0307-first-useful-image-is-unbuilt.md)
- [ADR-0338 - The owner decision batch](ADR-0338-the-owner-decision-batch.md)
- [ADR-0341 - Study cache generation and priority](ADR-0341-study-cache-generation-and-priority.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
