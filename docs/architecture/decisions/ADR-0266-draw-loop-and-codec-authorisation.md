---
document_id: "ADR-0266"
title: "Draw loop and codec authorisation"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CMP-002"
  - "VOX-CMP-004"
  - "VOX-CMP-005"
  - "VOX-CMP-006"
  - "VOX-CMP-011"
  - "VOX-CMP-012"
  - "VOX-CMP-014"
  - "VOX-VS1-010"
  - "VOX-VS1-012"
  - "VOX-VS1-013"
---

# ADR-0266 - Draw loop and codec authorisation

## Context

`ADR-0254` and `ADR-0255` referred eight decisions to the owner. Three were answered
together, and the answer releases the two largest blocked bodies of work in the
project.

The owner was given the eight questions enumerated, with options stated for the
compression one, and replied:

> "yes proceed with 1, 2 amd 3"

Numbered as put to them, that authorises:

1. **The interactive draw loop proceeds.**
2. **The six blocked compression rows are reconciled in favour of doing the work** —
   characterising, benchmarking and adversarially testing the Raster-Lab codecs.
3. **A codec may be declared a direct dependency.**

## The reading of authorisation 2, stated because it reverses a standing instruction

The owner previously instructed, verbatim:

> "These library are used and tested multiple times I dont need you to divert a new
> for testing the applicaition our target is to complete Voxiliea"

`ADR-0255` recorded the resulting conflict and referred it back with three options:
authorise the testing, waive the rows, or reduce their scope. "Proceed with 2" is read
as the **first** option, and two things support that reading rather than one: the
options were stated in the question, and authorisation 3 — a direct codec dependency —
is only useful if Voxelia actually decodes, which is what the blocked rows need.

**`VOX-CMP-011` is the sharpest case** and is called out rather than absorbed: it
means deliberately feeding malformed and adversarial codestreams to a Raster-Lab
library to find defects in it. That is precisely what the earlier instruction
excluded. It proceeds under this authorisation, and anything found is treated as
something to fix under the owner's other standing instruction — "If any bugs found on
the library the we need to address it and fix it" — rather than merely reported.

This reading is recorded so that if it is wider than intended, the record shows
exactly what was assumed and when.

## What was found before planning either arc

**The draw loop cannot live in `VoxeliaInteraction`.** That module is prohibited from
importing `SwiftUI`, `AppKit`, `UIKit`, `RealityKit` and `MetalKit` by
`check_prohibited_imports.py`. A draw loop needs a presentation surface, so it needs a
target that does not carry those prohibitions.

**The package has no executable target at all.** It is library-only, so the reference
application is a new target rather than an addition to an existing one.

**`RenderGenerationCounter` finally gets its consumer.** `ADR-0122` decision 3 said
"stamping frames and dropping stale ones is the interactive draw loop's behaviour,
which remains gated on its own architecture; this vocabulary is the contract it will
consume." That gate is now open, and `ADR-0248`/`ADR-0249` recorded the predicate as
having no production caller. This arc is where it acquires one.

**The reference application's scope is already specified.** Plan §65 lists seventeen
features — three simultaneous viewports, plane and orientation labels, linked
crosshair, slice scroll, pan, zoom, interpolation selector, window centre and width,
pixel inspection, one distance tool, source and validation status, current backend,
current generation, frame-time telemetry, import warnings — and states plainly that
it "is a reference integration, not the future DICOM Workstation user interface."

**`J2KSwift` is already resolved at `11.0.2`.** It sits in the licence policy's
`APPROVED_CLOSURE` as a transitive dependency of DICOMKit, so declaring it directly is
a manifest and gate change rather than a new download or a new trust decision.

## Decision

1. **Both arcs are opened.** The codec arc completes `ADR-0255`'s blocked half; the
   draw-loop arc discharges the Demonstration halves of `VOX-VS1-010`, `012` and
   `013`, and of `VOX-SUR-001`–`006`, `VOX-SUR-008` and `VOX-MPR-011`.
2. **The codec arc goes first, and the reason is not that it is more important.**
   Plan line 211 makes the reference application the M4 success criterion, so the draw
   loop matters more. But `VoxeliaCompression`'s boundary is already built and idle
   waiting for a codec, the first codec increment is small and mechanical, and the
   draw loop is a multi-increment application build that deserves its own
   architectural record rather than being started as a tail-end task. **The order is
   reversible on request.**
3. **The reference application is a new target**, not an extension of
   `VoxeliaInteraction`, and the prohibited-import policy stays as it is. Its exact
   shape — one app target, or a presentation library plus a thin app — is the
   draw-loop record's decision, not this one's.
4. **The reference application is a reference integration.** Plan §65 says so, and it
   bounds the work: it exists to demonstrate the library, not to become the product
   interface.
5. **`RenderGeneration` is wired into the draw loop's presentation path**, discharging
   `ADR-0122` decision 3's deferral. A frame stamped with an earlier generation than
   the current one is not presented.
6. **Direct codec declaration is limited to what a row actually needs**, one package
   at a time with the licence policy updated per package. `J2KSwift` first, because
   `VOX-CMP-004` (JPEG 2000 Part 10) and `VOX-CMP-005` (HTJ2K) both need it. The other
   four stay transitive until a row requires them.
7. **The licence gate is updated, never bypassed.** Moving a package from
   `APPROVED_CLOSURE` to `APPROVED_DECLARED` is an explicit edit with the owner
   authorisation cited, and the gate's negative tests must still fire.
8. **No algorithm specification and no oracle.** This record opens arcs and freezes no
   numeric boundary.

## Binding rules carried into both arcs

- **Adversarial codec testing produces fixes, not just findings.** `VOX-CMP-011`'s
  work is authorised on the basis that defects get addressed; a record listing crashes
  without addressing them would not honour the authorisation.
- **A demonstration is an interactive act, and an off-screen render is not one.**
  Ten Demonstration halves are about to become dischargeable, and the standing
  discipline — recorded through the whole `VOX-SUR` arc — is that a byte-exact
  off-screen render discharges Test and never Demonstration. That does not relax now
  that a draw loop exists; it becomes checkable.
- **The compression boundary's invariants hold once a codec is real.**
  `VOX-CMP-007`'s three enforcements — no `ImageStorageContract` conformance, no Metal
  import in `VoxeliaCompression`, no `VoxeliaCompression` import in `VoxeliaMetal` —
  were built before any codec existed precisely so a codec could not erode them.
- **The reference application publishes nothing to the registry that the library
  would not.** It is an integration, so it exercises accepted contracts rather than
  reaching around them.

## What is not authorised

Five decisions remain open and are unaffected by this one: report approval,
reference-hardware approval, the `voxelia.m4.ct.diagnostic` tolerance profile, the
geometry tolerance rule and reformat support, and the two dependency `LICENSE` files.

**Reference-hardware approval still blocks all formal performance acceptance**, so
the draw loop's frame-time telemetry will produce a baseline and not an acceptance,
exactly as `VOXELIA-BEN-0001` does for import.

**The two absent `LICENSE` files remain release prerequisites.** Declaring `J2KSwift`
directly does not touch them — that package is not one of the two — but a release
still cannot ship until `Raster-Lab/JLSwift` and `Raster-Lab/CompressionFamily` carry
their files.

## Alternatives considered

### Start with the draw loop, since it is the M4 success criterion

Not rejected on merit; see decision 2. It is the larger unlock and the order is
reversible. The codec arc simply has a built, idle boundary and a small first step.

### Declare all five codec packages directly at once

Rejected. Each direct declaration is a linkage claim in the manifest, and declaring
four packages no row yet needs would assert dependencies Voxelia does not use.

### Treat authorisation 2 as licence to fuzz the codecs broadly

Rejected. It authorises the work six specific rows require. A general fuzzing campaign
across libraries no row names would be the "divert into testing the libraries" the
owner objected to, now with a permission slip attached to different work.

### Put the draw loop in `VoxeliaInteraction` and relax the import policy

Rejected. The policy exists so the interaction model stays platform-neutral, and a
reference application is exactly the thing that should carry platform dependencies
instead.

## Consequences

The project has substantive unblocked work again, for the first time since
`ADR-0265`.

Ten Demonstration halves become dischargeable once the draw loop exists. Six
compression rows become dischargeable once a codec is linked.

`ADR-0122` decision 3's deferral ends.

## Affected modules

None yet. This record adds no source, no target and no dependency.

## Compatibility impact

None yet. The next increment changes `Package.swift`.

## Security impact

None yet, and two are coming: a direct codec dependency widens the linked attack
surface, which is why `VOX-CMP-011`'s adversarial testing is part of the same
authorisation rather than deferred behind it.

## Performance and memory impact

None yet.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This record.
2. **Codec arc**: declare `J2KSwift` directly with the licence gate updated and
   negative-tested; a real decode adapter behind `CompressedDecodeSession`; then
   `VOX-CMP-004`, `005`, `006`, `012`, `014`, and `011`'s adversarial work last so
   the adapter is settled before it is attacked.
3. **Draw-loop arc**: its own architectural record — target shape, platform surface,
   generation wiring, and what evidence discharges a Demonstration half — then the
   plan §65 feature set.
4. **Owner decisions still open**: the remaining five.

## Supersession

This record supersedes nothing. It **releases** the gates `ADR-0254` and `ADR-0255`
referred, and records the reading of authorisation 2 against the earlier instruction
it reverses.

## References

- [ADR-0122 - Render generations](ADR-0122-render-generations.md)
- [ADR-0254 - First slice validation and benchmark reports](ADR-0254-first-slice-validation-and-benchmark-reports.md)
- [ADR-0255 - Open the compression arc](ADR-0255-open-the-compression-arc.md)
- [ADR-0256 - Compression module boundary](ADR-0256-compression-module-boundary.md)
- [ADR-0259 - Cancellable decode session](ADR-0259-cancellable-decode-session.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
