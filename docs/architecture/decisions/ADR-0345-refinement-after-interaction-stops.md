---
document_id: "ADR-0345"
title: "Refinement after interaction stops"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DVR-013"
---

# ADR-0345 - Refinement after interaction stops

## Context

Arc step 3 of `ADR-0343`: `VOX-DVR-013` requires interactive quality to refine
towards requested diagnostic quality after interaction stops. Under the arc's
principle — the representation degrades, the execution never does — refinement
is a representation upgrade: the idle view re-renders from the full-resolution
volume, and "towards" is satisfied by *reaching* diagnostic quality, provably.
`ADR-0344`'s selection rule already produces the right source in every case;
what the row adds is the **trigger** and the **obligation**.

## Decision

1. **`InteractionPhase` is host-supplied state** — `active` or `idle` — owned by
   whatever drives the view (the gated draw loop's business). The library never
   acquires a clock, so debouncing "stopped" into `idle` is the host's act; the
   library owns everything downstream of the phase.

2. **The refinement rule is total and frozen**, an extension of the accepted
   selection:
   `refinementDecision(phase:studyCacheGenerationComplete:)` returns the
   `ADR-0344` interactive source unchanged, plus `refinementDue`, true exactly
   when the phase is `idle` and generation is incomplete — the one case where
   interaction has stopped but diagnostic quality cannot yet be reached, so a
   pass is owed when loading completes. An `active` view owes nothing yet; an
   `idle` view over completed generation discharges the obligation **by that
   render**, which is full-resolution by the selection rule.

3. **The obligation is byte-identity, asserted not argued.** The idle render
   over completed generation must produce **the same bytes** a direct
   `.full`-quality render of the same request produces. Render-path purity
   (`VOX-VS1-016`'s reading) makes this structural — one entry point, the same
   request, the same volume — and the suite proves it on published bytes,
   never on object identifiers, which the naming contract makes the host's to
   mint.

4. **`VOX-DVR-013`'s `T` is discharged by this increment**; the `D` half — the
   owner watching an idle view sharpen — joins the release demonstrations. The
   `ADR-0103` guard remains in force, untouched, per `ADR-0344`'s conditional
   reading of arc step 4.

## Alternatives considered

### A time-based quiescence trigger inside the library

Rejected. A debounce interval is presentation policy and needs a clock; the
operations discipline is clockless, and a host that knows its input stream is
the only honest owner of "stopped".

### Multi-step refinement through intermediate levels

Rejected for version one. One level exists; "towards" reaches diagnostic
quality in one pass, and a pyramid schedule would be designed against
representations nobody has built. `ADR-0343`'s selection representation admits
additional levels later without reopening this rule.

## Consequences

The refinement contract is complete: interactive views degrade to the level
while loading, owe a diagnostic pass once interaction stops, and provably reach
requested diagnostic quality when generation completes. Arc steps 1-3 are done;
step 4 remains conditional and untriggered.

## Affected modules

`VoxeliaRendering` gains `InteractionPhase`, `RefinementDecision` and the
decision extension. Nothing else changes shape.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One comparison per decision; the refinement render is the accepted path.

## Validation impact

```text
swift test --filter InteractiveLevelRenderTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record.
2. The vocabulary, the decision extension and the obligation test, in the same
   increment.
3. **Next**: `VOX-PER-004` on the named device, both representations measured
   and labelled.
4. **Owner**: the `D` half joins the release demonstrations.

## Supersession

This record supersedes nothing. It completes `ADR-0343` step 3 by composing
`ADR-0344`'s selection unchanged.

## References

- [ADR-0343 - Open the progressive refinement arc](ADR-0343-open-the-progressive-refinement-arc.md)
- [ADR-0344 - Interactive level render path](ADR-0344-interactive-level-render-path.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
