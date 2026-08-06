---
document_id: "ADR-0278"
title: "Presentation semantics equality"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-R2D-014"
---

# ADR-0278 - Presentation semantics equality

## Context

`VOX-R2D-014` requires off-screen and interactive output to use the same presentation
semantics, declaring `T`. `ADR-0277` enumerated plan §35.1's nine shared semantics, found
padding the only one not carried by the request, and concluded the row would discharge
"when the transit is unconditional" — that is, once padding travelled from the image
through storage to the window stage.

Two findings made while starting that work change the answer.

## The measurement `ADR-0277` promised

`ADR-0277` said explicitly that whether the padding gap has a visible effect on the
owner's data "is not claimed here and is worth measuring in the implementation
increment". Measured, over the owner's **entire** DICOM input tree rather than one series:

| | |
|---|---:|
| Files scanned | 30,347 |
| Frames described | 29,651 |
| Frames declaring `PixelPaddingValue` | **0** |
| Scalar types present | `uint16` only |

**Not one frame declares padding.** The adapter reads tag `(0028,0120)` correctly and
populates `CTFrameDescription.pixelPadding`; there is simply nothing to populate it with.

So the transit gap is entirely latent: `paddingValue: nil` produces byte-identical output
to a fully wired transit on every frame available to this project. Building the transit
now would add machinery to the import and storage path that no data exercises, verifiable
only synthetically.

## The second finding: the divergence `ADR-0251` guarded against is not publicly reachable

`ADR-0251` stated off-screen equivalence as conditional on identical renderer
construction, reasoning that "two callers injecting different stages could therefore
diverge". Checking the access levels rather than the shape:

- `ExactSliceRenderer` is `public final class` and its **convenience** initialiser is
  `public`.
- Its **designated** initialiser — the one taking `windowStage`, `invertStage` and
  `compositeStage` — is **internal**.
- `WindowStageExecutor` is **internal**, so the parameter's type cannot even be named
  outside the module.

All eleven construction sites in the repository use the convenience initialiser, and both
it and `MetalSliceRenderer`'s hard-code the same `paddingValue: nil`.

**No caller outside `VoxeliaMetal` can inject a stage at all.** An export path and a
viewport, both being external callers, cannot construct renderers that disagree on padding
or on any other stage-carried semantic. The only choice left to them is *which renderer
type* to build.

## The reading: the condition restates §35.1's eighth semantic

That remaining choice is not a residual gap either. §35.1's eighth shared semantic is
"**shader or CPU implementation**" — the plan itself requires both paths to use the same
one. `ADR-0251`'s condition, "identical renderer construction", *is* that requirement
expressed in code rather than a qualification of the claim.

So the nine semantics resolve cleanly: seven travel in the request, one is fixed
identically by the only public construction path, and the ninth is the plan's own
same-implementation requirement.

## Decision

1. **`VOX-R2D-014` is discharged.** Its evidence is the two-independently-constructed-
   renderers test — which models an export path and a viewport each building their own —
   now carrying the row's tag alongside `VOX-VS1-016`'s. The same evidence discharges
   both rows because both ask the same question of the same path.
2. **A positive control is added, because the equality claim was otherwise about a knob
   that might do nothing.** A new test builds a renderer through the internal designated
   initialiser with `paddingValue: 11` — a value the fixture actually contains — and
   asserts the unpadded render puts something non-zero there, that declaring it as padding
   makes that byte **exactly zero** per `ALG-0002` revision 1.2, and that **no other byte
   moves**. Without it, "both paths use the same padding policy" would be unfalsifiable.
3. **`ADR-0277` decision 6 is withdrawn.** It required the unconditional transit before
   this row could discharge. The measurement shows the transit changes nothing for any
   available data, and the access-level finding shows the divergence it was meant to
   prevent is not publicly reachable. `ADR-0277` is **not edited**; its enumeration, its
   §28.4 separability finding and its correction of `ADR-0275` all stand.
4. **The transit remains the right eventual architecture and is not built here.** It
   becomes necessary the moment any ingested data declares padding, and `ADR-0277` already
   records its design and the two boundaries it must settle. Building it now would be
   machinery with no exercisable path.
5. **`ALG-0002` revision 1.2's padding exclusion is now demonstrated reachable and
   correct**, through the internal stage, by decision 2's test. It remains unreachable
   from any *production* path, which is a documented gap rather than an unknown one.
6. **No algorithm specification and no oracle.** `ALG-0002` revision 1.2 already registers
   the rule this exercises.

## A verification trap worth recording

`swift test --filter` matches test **function names**, not the display strings in
`@Test("…")`. Filtering on a display string runs **zero** tests and prints
`Test run with 0 tests in 0 suites passed` — a green line that means nothing ran.

That is the silent-pass failure mode this project has hit before, wearing a new hat. It
was caught here only by counting `@Test(` occurrences in the file against the reported
total. When a filtered run's count is not what you expect, the filter is the first
suspect, and a green tick on zero tests is not evidence.

## Alternatives considered

### Build the padding transit as `ADR-0277` planned

Deferred on measurement, not rejected. It is still the right architecture, and it would be
the right increment the day a series arrives declaring padding. Today it would thread a
value that is `nil` in 29,651 of 29,651 frames through the import path, the volume
builders and the renderer, verified only against synthetic fixtures.

### Discharge the row on `ADR-0251`'s tests alone, without the positive control

Rejected. The whole content of the row is that two paths agree on nine semantics, and one
of those semantics had never been shown to affect output. A test suite that cannot
distinguish "both paths handle padding identically" from "padding does nothing" is not
evidence about padding.

### Make padding an explicit parameter of the public convenience initialisers

Rejected, and it was the first idea. It would make padding exercisable publicly — but it
would make divergence *easier*, not harder, by turning a semantic no external caller can
vary into a knob every caller must set consistently. That is the opposite of what §35.1
asks for.

### Add a `SliceRenderRequest` padding field

Rejected in `ADR-0277` decision 3 and still rejected: it puts a data-interpretation fact
in a viewport request, letting a caller render an image under a sentinel its own data does
not declare.

### Report the row as blocked on the transit

Rejected. It would carry a P0 row as outstanding when its evidence exists, on the strength
of a gap that no data exercises and no public caller can reach.

## Consequences

`VOX-R2D-014` is discharged. **The interactive draw-loop arc's unblocked library tier now
has one row left: `VOX-INT-008`'s `T`.**

The padding question is quantified rather than open: the exclusion rule is accepted,
reachable internally, demonstrated correct, unexercised by all available data, and
unreachable from production. Whoever ingests a padded series next has a record telling
them exactly what to wire and why it was not wired sooner.

A verification trap — `--filter` matching function names, not display names — is on the
record.

## Affected modules

None. `VoxeliaMetalTests` gains one test and a shared naming helper; no source changed.

## Compatibility impact

None.

## Security impact

None. The measurement read the owner's data in a scratch harness with a recorded run; no
repository test reads that path.

## Performance and memory impact

None.

## Validation impact

```text
swift build && swift test
swift test --filter "paddingSemanticChangesOutput"
swift format lint --strict Tests/VoxeliaMetalTests/ExactSliceRendererTests.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1125 tests in 203 suites pass.

## Migration

1. This record and its test.
2. **Next**: `VOX-INT-008`'s `T` — responsiveness while background processing continues,
   through an injected clock and a deterministic probe.
3. **Owner**: the application-location decision from `ADR-0275`, §28.4's padding-aware
   interpolation rule, `VOX-CMP-006`'s and `VOX-CMP-012`'s Reviews, the five `J2KSwift`
   items, and the five decisions already open.

## Supersession

This record supersedes nothing. It **withdraws `ADR-0277` decision 6** on new
measurement, and **strengthens `ADR-0251`'s conditional** by showing the divergence it
guarded against is not publicly reachable. Neither record is edited.

## References

- [ADR-0113 - Pixel padding exclusion](ADR-0113-pixel-padding-exclusion.md)
- [ADR-0251 - Off-screen equivalence reading](ADR-0251-off-screen-equivalence-reading.md)
- [ADR-0275 - Open the interactive draw loop arc](ADR-0275-open-the-interactive-draw-loop-arc.md)
- [ADR-0277 - Padding transit design](ADR-0277-padding-transit-design.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
