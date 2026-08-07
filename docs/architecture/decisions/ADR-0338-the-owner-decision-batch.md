---
document_id: "ADR-0338"
title: "The owner decision batch"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PER-004"
  - "VOX-PER-006"
  - "VOX-CON-008"
  - "VOX-IMG-008"
  - "VOX-SPA-010"
  - "VOX-BRK-009"
  - "VOX-DVR-013"
  - "VOX-REP-002"
---

# ADR-0338 - The owner decision batch

## Context

`ADR-0319`'s criterion found the entered-milestone queue exhausted: every one of the 356
rows in M0-M6 was claimed, discharged, characterised, or waiting on a named owner
decision. The open decisions were consolidated and put to the owner as a single batch on
2026-08-07, each with a recommendation. The owner replied:

> "Approve all your recommendations, ship at M6, restart the loop."

That message is the authorisation this record captures, in the same pattern as the
authorisations quoted verbatim in `ADR-0194` and `ADR-0266`. Two of the batch's items
turned out to restate authorisations `ADR-0266` had already granted and later
increments had already executed; decision 9 records them as confirmations rather than
letting them read as new grants, so no future increment re-derives finished work from
this record.

## Decision

1. **Reference hardware is named** (`VOX-PER-004`). The v0.x reference device is this
   development machine: model identifier `Mac17,4`, Apple M5, 24 GiB unified memory,
   macOS 26.5.1. `ADR-0330`'s four measurement constraints stand unchanged: the named
   device, a 512-cubed volume, a clean process per `ADR-0271` d4, and the quality the
   frames ran at. The naming is a v0.x decision; the 1.0 baseline may name a different
   reference device and must then re-measure.

2. **The two definitions gating `VOX-PER-006` and `VOX-CON-008` are fixed.** A *study
   cache* is the decoded brick store generated from an ingested study; the row's clock
   starts when that generation starts. The *first useful image* is the first fully
   decoded two-dimensional plane at full resolution published for presentation. These
   are v0.x working definitions chosen by the owner; a clinical revision would be a
   controlled correction, not a silent edit. With the definitions fixed, both rows —
   which `ADR-0329` d2 recorded as unbuilt with nothing having decided they should be
   — are now decided: they shall be built.

3. **Interactive refinement shall be built** (`VOX-BRK-009`, `VOX-DVR-013`). The
   owner's approval decides the question `ADR-0329` left open: the degraded
   interactive path that `ADR-0103` named as future work now proceeds for v0.x, as the
   superseding decisions `SceneSnapshot`'s documentation predicts. The consequences
   `ADR-0329` d3 states apply in full: the *"both qualities execute identically"*
   guard test is the first thing the superseding increment must consciously replace —
   with per-quality claims of its own — rather than quietly delete. Both `D` halves
   remain owner-witnessed.

4. **The tolerance profile is approved.** The provisional profile the plan requires to
   be approved before acceptance is approved as `voxelia.m4.ct.diagnostic` version
   `1.0.0`, and reformats are required product capability. The standing discipline is
   unchanged by the approval: an approved tolerance is a ceiling, not a target, and
   where a measurement comes out exact the test asserts exact.

5. **The reference application lives in this repository** under `Examples`, resolving
   the application-location question the draw-loop arc raised, as an example target
   beside the package it demonstrates.

6. **The Raster-Lab licence files are an owner action on the owner's repositories.**
   The first-vertical-slice checkpoint recorded `LICENSE` files missing from the
   Raster-Lab `JLSwift` and `CompressionFamily` repositories; the owner approved
   adding them. Those repositories are outside this working tree and inside the
   supply-chain boundary this project reserves to the owner, so the action is recorded
   here and executed there.

7. **Three smaller questions are settled.** `VOX-SPA-010` completes its physical half
   on the sample-centre convention, matching DICOM. `VOX-IMG-008`'s grid resampling
   pads with zero and records the padding in provenance, composing the existing
   padding-entry precedent rather than inventing a second shape. `CODEOWNERS` moves to
   the repository root, which is what `VOX-REP-002`'s frozen text says and one of the
   locations GitHub resolves; `check_required_files.py` is updated to require it
   there, closing the discrepancy `ADR-0320` recorded rather than resolved.

8. **The finish line for this release series is M6.** Milestones M7-M10 remain
   unentered; `HIGHEST_ENTERED_MILESTONE` stays at 6 until the owner explicitly
   raises it. "Complete" for v0.x means: the rows this record unblocks discharged,
   the outstanding owner-witnessed Demonstrations (`VOX-HLS-001`, `VOX-MTL-009`,
   `VOX-API-008`, `VOX-MPR-002`, `VOX-BRK-009`, `VOX-DVR-013`) and pending Reviews
   (`VOXELIA-VAL-0001`, `VOXELIA-BEN-0001`, and the `R` halves of `VOX-VAL-006`,
   `VOX-ARC-009`, `VOX-DOC-009`, `VOX-DOC-011`) presented for the owner at release,
   and a tagged release produced by the existing release tooling.

9. **Two batch items are confirmations, not grants.** The compression measurements
   and the direct codec declaration were authorised by `ADR-0266`, executed by
   `ADR-0267` through `ADR-0273`, and the M5 arc closed with `ADR-0274` — including
   `VOX-CMP-011`, which was discharged by adversarial testing under that
   authorisation, not waived. The draw-loop go-ahead was likewise `ADR-0266`'s first
   released gate. The owner's renewed approval of these items changes nothing and is
   recorded so this record cannot be read as reopening them.

10. **The restarted loop carries process bounds.** No new gate, ratchet or register is
    created unless a requirement row demands one. An increment must advance a
    requirement row whenever any row is unblocked. When the queue is empty and nothing
    is unblocked, the loop stops and surfaces the open owner questions instead of
    generating work about the repository itself.

## Alternatives considered

### Record each decision as its own ADR

Rejected for this batch. The decisions arrived as one owner message answering one
consolidated list, and ten records would scatter a single authorisation across the
register. Where a decision opens real design work (the progressive-refinement arc, the
resampling design, the first-useful-image path), that work still gets its own
design-first records; this record is the authorisation they cite.

### Treat the owner's approval as discharging the pending Reviews and Demonstrations

Refused. The approval answered the decision batch; it did not witness a demonstration
or read a validation report. `R` and `D` verification methods stay pending until the
owner actually reviews and witnesses at release, per the standing rule that a Review is
never self-approved.

### Omit the items that were already resolved

Rejected. The owner's message approved the batch as put, and silently dropping two
items would leave a gap between what was asked and what was recorded. Naming them as
confirmations is what prevents the misreading either way.

## Consequences

Every entered-milestone row that was waiting on an owner decision is now unblocked.
The remaining work to the M6 finish line is engineering, not governance: spatial
bounds' physical half, grid resampling, first useful image, priority propagation, the
progressive-refinement arc, the frame-rate measurement on the named device, the
reference application, and the release assembly.

## Affected modules

None directly; this record authorises work in `VoxeliaSpatial`, `VoxeliaImaging`,
`VoxeliaExecution`, `VoxeliaRendering`, `VoxeliaInteraction`, `Examples` and the
repository scaffold.

## Compatibility impact

None. No public API changes in this record.

## Security impact

None. The adversarial-codestream coverage recorded by `ADR-0273` is unchanged.

## Performance and memory impact

None from this record. Decisions 1 and 2 make the two performance rows measurable.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/generate_requirement_index.py --check
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged - this record adds no code. The `CODEOWNERS`
move in decision 7 is verified by `check_required_files.py` failing when the file is
absent from the root.

## Migration

1. This record, with the `CODEOWNERS` move and gate update in the same increment.
2. Spatial bounds' physical half and grid resampling (`VOX-SPA-010`, `VOX-IMG-008`).
3. First useful image and priority propagation (`VOX-PER-006`, `VOX-CON-008`).
4. The progressive-refinement arc (`VOX-BRK-009`, `VOX-DVR-013`), superseding
   `ADR-0103`'s single-pass position through its own design records.
5. The frame-rate measurement on the named device (`VOX-PER-004`), after the
   refinement arc so both quality profiles can be measured and labelled.
6. The reference application under `Examples`.
7. Release assembly at M6 with the owner-witnessed Demonstrations and Reviews.
8. **Owner**: `LICENSE` files on the two Raster-Lab repositories.

## Supersession

This record supersedes nothing. It resolves the open questions recorded by `ADR-0320`
(the `CODEOWNERS` discrepancy), `ADR-0329` (the refinement deferral, decided to build
by decision 3) and `ADR-0330` (the unnamed reference device), leaving those records'
own decisions intact. `ADR-0103`'s single-pass position will be superseded by the
refinement arc's own design records, not by this one.

## References

- [ADR-0103 - Interactive quality equivalence](ADR-0103-interactive-quality-equivalence.md)
- [ADR-0266 - Draw loop and codec authorisation](ADR-0266-draw-loop-and-codec-authorisation.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0320 - Repository baseline rows](ADR-0320-repository-baseline-rows.md)
- [ADR-0329 - Interactive refinement is deferred](ADR-0329-interactive-refinement-is-deferred.md)
- [ADR-0330 - Frame rate target needs its hardware](ADR-0330-frame-rate-target-needs-its-hardware.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
