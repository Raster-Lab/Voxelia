---
document_id: "ADR-0166"
title: "Transfer function design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DVR-005"
  - "VOX-DVR-007"
---

# ADR-0166 - Transfer function design

## Context

The volume-rendering arc's first increment is the transfer-function
vocabulary. Per the plan-first discipline this record freezes the
value model before implementation; per the arc's binding rule,
everything this vocabulary feeds is presentation, never a source of
authoritative quantitative measurement. It was authored and accepted
on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

1. **`TransferFunction1D` is a validated table of exactly two
   hundred fifty-six entries**, one per eight-bit display sample,
   each entry four eight-bit components — red, green, blue and
   opacity — so component ranges are structurally valid and the only
   table admission is the exact size, typed. Entries stay integer:
   the compositing model that consumes them declares its own
   binary64 conversion, keeping this vocabulary exact.
2. **Lookup is exact and clamped by declaration.** An eight-bit
   sample indexes its entry directly; the frozen rule for any wider
   integer index is `clamp(index, 0, 255)` — declared now, per
   `VOX-DVR-007`, so the wider stored domains that arrive with
   adapters compose a pre-frozen rule rather than an invention. For
   the version-one eight-bit domain the clamp is the identity, and
   the fixtures pin both clamp directions anyway.
3. **Deferred and recorded**: parameterised table sizes and wider
   index domains wait for the adapter-borne stored types that need
   them — a sixteen-bit windowed path indexes through the accepted
   window mapping first — and piecewise-linear control-point
   authoring is a host convenience outside the reference vocabulary.
   Speculative parameters are compatibility debt.

## Alternatives considered

Floating-point entries were rejected: integer entries keep the
vocabulary exact and push rounding decisions into the one compositing
model that owns them. A separate opacity-only table was rejected:
`VOX-DVR-005` asks for one-dimensional transfer functions and the
colour components cost nothing when unused.

## Consequences

The compositing increment has its input vocabulary; adapters get a
pre-frozen clamp rule.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The implementing increment must prove the exact identity lookup over
a ramp table, both clamp directions for wider indices, the typed
size rejection, and bit-identical repetition.

## Migration

None; implementation follows as its own increment.

## Supersession

Executes the first increment of accepted `ADR-0165`; no record is
superseded.

## References

- [ADR-0165 - Volume rendering arc](ADR-0165-volume-rendering-arc.md)
