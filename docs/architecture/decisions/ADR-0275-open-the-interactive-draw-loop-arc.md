---
document_id: "ADR-0275"
title: "Open the interactive draw loop arc"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-INT-007"
  - "VOX-INT-008"
  - "VOX-INT-010"
  - "VOX-R2D-014"
  - "VOX-VS1-016"
  - "VOX-PER-002"
  - "VOX-PER-003"
  - "VOX-PER-005"
---

# ADR-0275 - Open the interactive draw loop arc

## Context

`ADR-0122` froze the render-generation vocabulary and then deferred its use:

> **Presentation wiring stays with its loop.** Stamping frames and dropping stale ones is
> the interactive draw loop's behaviour, which remains gated on its own architecture; this
> vocabulary is the contract it will consume.

This record is that architecture. It is the last named gate in the ledger's actionable
queue now that every M5 compression row is discharged.

`RenderGeneration` and `RenderGenerationCounter` have **no product callers** — only their
own file, a DocC cross-reference, and their own tests. That is the deferral, visible in
the source.

The ledger names the rows this arc gates: `VOX-INT-008`, `VOX-R2D-014`, `VOX-VS1-016` and
the `VOX-PER-002/003/005` targets, plus `VOX-INT-007`'s presentation half and
`VOX-INT-010`'s demonstration.

## The finding: this is not one blocked thing

The arc has been carried in the ledger as a single item gated on an application that does
not exist. Reading the rows against what actually gates each one shows something better:
**most of the work needs neither an application nor the owner.**

| Row | Declares | What actually gates it |
|---|---|---|
| `VOX-INT-007` | `T` | nothing — the vocabulary exists and wants wiring |
| `VOX-R2D-014` | `T` | nothing — it asserts two paths share semantics |
| `VOX-VS1-016` | `T` | nothing — same, for the first vertical slice |
| `VOX-INT-008` | `T,D` | the `T` is free; the `D` needs a host |
| `VOX-INT-010` | `I,D` | the `I` is met by the vocabulary's host-mapping design; the `D` needs a host |
| `VOX-PER-002` | `T,D` | **owner approval of reference hardware** |
| `VOX-PER-003` | `T,D` | **owner approval of reference hardware** |
| `VOX-PER-005` | `T,D` | **owner approval of reference hardware** |

Three observations follow, and they reorder the work:

1. **`VOX-R2D-014` and `VOX-VS1-016` require no interface at all.** Both say off-screen
   and interactive output shall use *the same presentation semantics*. That is a statement
   about one code path serving two callers, and the way to establish it is to have one
   path and test it — not to draw anything. They are P0 and they are free.
2. **`VOX-PER-002/003/005` cannot be discharged by any amount of work here.** Each names
   "reference workstation hardware", and that approval is one of the five decisions
   already open with the owner. Building a beautiful draw loop does not move them. Saying
   so now prevents the arc from being reported as more complete than it is.
3. **Only two halves genuinely need a host application**: `VOX-INT-008`'s `D` and
   `VOX-INT-010`'s `D`.

## The structural constraint, and why it is an owner decision

The package is **library-only** — `Package.swift` declares no executable target — and
`check_prohibited_imports.py` forbids `VoxeliaInteraction` from importing `SwiftUI`,
`AppKit`, `UIKit`, `RealityKit` and `MetalKit`. That prohibition is `VOX-INT-001`, a P0
row: interaction state must be independent of host event types.

So a reference application cannot go inside `VoxeliaInteraction`, and there is nowhere
else in this package for it to go. The three ways forward differ in what they change:

- **A new executable target here.** Changes the package from library-only and requires the
  import policy to permit `SwiftUI` in one target while still forbidding it in
  `VoxeliaInteraction`. That is a governance change to a P0 boundary gate.
- **A separate repository** consuming Voxelia as a package dependency. Keeps the library
  clean and creates a second repository to own.
- **No application**, discharging both `D` halves by instrumented headless
  demonstration.

**Deciding between these is not mine.** The first changes a P0 gate's shape, the second
creates a repository, and the third narrows what "Demonstration" means for two P0/P1 rows.
This record therefore raises it as a **sixth owner decision** and proceeds with everything
that does not depend on the answer.

## Decision

1. **The arc opens, and it opens with the library-only tier**, because that tier is
   unblocked, contains three P0 rows, and produces the thing any application would consume
   anyway. Nothing waits on the owner that need not.
2. **Increment order, each with its own record:**
   1. **`VOX-INT-007`'s presentation wiring.** Stamp frames with the generation they were
      requested at, drop stale ones, and make "stale" a property of the stamp rather than
      of a caller's diligence. This ends `ADR-0122` decision 3's deferral and gives
      `RenderGeneration` its first product caller.
   2. **`VOX-R2D-014` and `VOX-VS1-016` — one presentation path, two callers.** Establish
      that off-screen and interactive output are the same semantics by construction, and
      test the equality rather than asserting it in prose.
   3. **`VOX-INT-008`'s `T` half.** Responsiveness while background work continues,
      measured through an injected clock and a deterministic probe — the shape `ADR-0249`
      and `ADR-0259` already use for cancellation, reused rather than reinvented.
3. **`VOX-PER-002/003/005` are declared out of scope for this arc's implementation
   increments** and remain owner-gated on reference hardware. They will not be reported as
   progressing.
4. **No performance threshold will be claimed anywhere in this arc.** Frame-time
   telemetry may be *produced* — plan §34 lists it as a reference-application feature —
   but a produced number is not an acceptance against a target, and this arc has no
   approved hardware to accept against.
5. **The two `D` halves are held, not quietly redefined.** They stay open until the owner
   answers the application question, rather than being discharged by declaring a headless
   harness sufficient. That option is on the table for the owner; taking it unilaterally
   would narrow two P0/P1 rows by my own convenience.
6. **`VoxeliaInteraction`'s import prohibitions are not relaxed by this record.** Whatever
   the owner decides, `VOX-INT-001` holds: interaction state stays independent of host
   event types.
7. **No algorithm specification and no oracle in this record.** It opens an arc and
   sequences it. The increments it names will each carry their own numeric boundaries, and
   `VOX-INT-007`'s staleness rule is the first that needs one.

## What plan §34 actually asks for, checked rather than remembered

The M4 macOS reference application is specified in **plan §34 "Interactive output"** and
names **sixteen** features: three simultaneous viewports; axial, coronal and sagittal
labels; patient orientation labels; linked crosshair; slice scroll; pan; zoom; a
nearest/linear selector; window centre and width; pixel inspection; one distance
measurement tool; source and validation status; current backend; current generation;
frame-time telemetry; and import warnings. The plan closes the section with the sentence
that governs the whole arc:

> The application is a reference integration, not the future DICOM Workstation user
> interface.

A note carried through several ledger increments cited "§65, seventeen features". §65 is
"Benchmark scenarios", and the count is sixteen. Corrected here and in the ledger, and
recorded because the wrong section number would send a later reader to the wrong place.

Two of the sixteen are already-built vocabulary awaiting a caller — **current generation**
is `ADR-0122`'s counter and **linked crosshair** is `ViewportSyncGroup` — which is further
evidence that the library tier is the right place to start.

## Alternatives considered

### Build the reference application first, since the arc is named after it

Rejected. It is the one part that cannot start, and it would leave three unblocked P0 rows
waiting on a decision they do not depend on. The application consumes the library tier; the
order follows from that, not from the arc's name.

### Discharge both `D` halves with a headless demonstration and close the arc

Rejected as **my** decision, offered as the owner's. It is a defensible reading —
instrumented latency measurement under background load is more rigorous than watching a
window — but narrowing what Demonstration means for two P0/P1 rows to avoid an owner
question is the kind of quiet scope reduction this project has consistently refused.

### Relax `VoxeliaInteraction`'s import prohibition to host the application

Rejected outright. `VOX-INT-001` is a P0 row requiring interaction state to be independent
of SwiftUI, AppKit, UIKit and RealityKit event types, and the gate is how that is enforced
rather than promised. If the owner chooses an executable target in this package, the
permission belongs to *that target*, and `VoxeliaInteraction`'s prohibition stays exactly
as it is.

### Treat `VOX-PER-002/003/005` as dischargeable on this machine with a recorded caveat

Rejected, consistently with `VOXELIA-BEN-0001` and `VOXELIA-BEN-0002`, which both measure
freely and both state that no measurement is an acceptance because the hardware is not
approved. Producing numbers is fine; calling them a pass is not.

### Fold `VOX-INT-007`'s wiring into the first presentation increment

Rejected. It ends a deferral `ADR-0122` made explicitly, and the staleness rule needs its
own frozen boundary. Bundling it under a broader record is how a numeric rule ends up
undocumented.

## Consequences

The interactive draw-loop arc is open, sequenced, and its blockers are separated from its
work. **Three unblocked P0 rows** — `VOX-INT-007`, `VOX-R2D-014`, `VOX-VS1-016` — plus
`VOX-INT-008`'s `T` can proceed immediately with no owner input and no application.

**A sixth owner decision is raised**: where a reference application lives, or whether a
headless demonstration may discharge the two `D` halves.

`VOX-PER-002/003/005` are explicitly parked rather than carried as arc progress, and no
performance acceptance will be claimed in this arc.

`RenderGeneration`'s zero-caller state is now scheduled to end rather than merely noted.

Nothing is discharged by this record.

## Affected modules

None yet. The named increments will touch `VoxeliaInteraction` and `VoxeliaRendering`;
this record changes no source.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None. Decision 4 records that no performance claim will be made in this arc.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1116 tests in 202 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: `VOX-INT-007`'s presentation wiring, with its own record and its own frozen
   staleness rule, ending `ADR-0122` decision 3's deferral.
3. Then one presentation path shared by off-screen and interactive output
   (`VOX-R2D-014`, `VOX-VS1-016`), then `VOX-INT-008`'s `T`.
4. **Owner**: the new application-location decision above; `VOX-CMP-006`'s and
   `VOX-CMP-012`'s Reviews; the five `J2KSwift` items from `ADR-0272` and `ADR-0273`; and
   the five decisions already open — report approval, reference hardware, the
   `voxelia.m4.ct.diagnostic 1.0.0` tolerance profile, the geometry tolerance rule, and
   the two `LICENSE` files.

## Supersession

This record supersedes nothing. It **satisfies `ADR-0122` decision 3's condition** by
supplying the architecture that decision waited on, and **corrects a plan citation**
carried in the ledger. `ADR-0122` is unedited.

## References

- [ADR-0111 - Interaction command vocabulary](ADR-0111-interaction-command-vocabulary.md)
- [ADR-0122 - Render generations](ADR-0122-render-generations.md)
- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
