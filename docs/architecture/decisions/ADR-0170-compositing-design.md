---
document_id: "ADR-0170"
title: "Compositing design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DVR-001"
  - "VOX-DVR-004"
  - "VOX-DVR-007"
---

# ADR-0170 - Compositing design

## Context

The volume-rendering arc's third increment is the per-ray
compositing model. Per the plan-first discipline this record freezes
it before implementation; per the arc's binding rule, everything it
produces is presentation, never a source of authoritative
quantitative measurement. It was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **`VOXELIA-ALG-0023` composes the accepted sample and table
   authorities.** Each midpoint sample is the accepted trilinear
   sample byte — reusing that model's rounding and support exactly,
   because the transfer table is defined per eight-bit sample and a
   second quantisation rule would fork the accepted one — and the
   binary64 conversion the table vocabulary deliberately deferred is
   declared in this model, where it is used.
2. **The accumulation order and termination threshold are frozen
   exactly**: the declared front-to-back sequence with no fused
   multiply-add, and the exact dyadic threshold of
   two hundred fifty-five two-hundred-fifty-sixths, with remaining
   samples never consumed — the consumed count is part of the frozen
   behaviour and the fixtures pin it.
3. **The table opacity is per-sample at the full-quality interval,
   declared.** With one registered quality token there is one
   interval per volume, so an interval-correction exponent would
   always be one — an untestable no-op parameter; the quality tokens
   that change intervals must bring the correction rule in their own
   records. Speculative parameters are compatibility debt.
4. **The renderer surface follows separately.** Rendering an image
   needs per-pixel ray generation from the accepted camera
   vocabulary, which is its own model to freeze; this record's scope
   is the per-ray composite, its implementation is the next
   increment, and the renderer record after that freezes ray
   generation and carries the presentation claims.

## Alternatives considered

Compositing over unquantised binary64 samples was rejected: the
transfer table is defined per eight-bit sample, and inventing an
interpolated table lookup would smuggle a second transfer model in.
Back-to-front accumulation was rejected: front-to-back is what early
termination requires, and the row names it.

## Consequences

The compositing implementation is mechanical; the renderer record
has its declared scope.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The obligations are recorded in the specification and bind the
implementing increment, including the consumed-sample counts and the
exact threshold boundary.

## Migration

None; implementation follows as its own increment.

## Supersession

Executes the third increment of accepted `ADR-0165`; no record is
superseded.

## References

- [VOXELIA-ALG-0023 - Front-to-back compositing binary64-v1](../../algorithms/VOXELIA-ALG-0023-front-to-back-compositing.md)
- [ADR-0165 - Volume rendering arc](ADR-0165-volume-rendering-arc.md)
