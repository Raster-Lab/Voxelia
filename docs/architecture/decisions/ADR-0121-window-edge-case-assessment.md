---
document_id: "ADR-0121"
title: "Window edge-case assessment"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-R2D-006"
---

# ADR-0121 - Window edge-case assessment

## Context

`VOX-R2D-006` requires linear window centre and width behaviour with
defined edge cases. The behaviour and its edges have been registered
since the window model was accepted; the row lacked a recorded
assessment binding it to that evidence. Per the `ADR-0114`
documentation-only precedent, this record performs the assessment. It
was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

`VOX-R2D-006` is discharged by the registered `VOXELIA-ALG-0002`
model and its accepted extensions:

1. **The edges are frozen, not conventions.** The model defines
   `x <= lower` as exactly zero and `x > upper` as exactly 255 with
   the half-sample threshold, the frozen evaluation order and
   ties-to-even rounding; the degenerate unit-width window is a pure
   threshold whose interior branch is unreachable — a defined edge
   case with its own fixture, not a special case.
2. **The evidence already binds.** The operation suites pin the
   registered fixtures across `uint8`, `int16` and `uint16` domains,
   through the stored-to-real composition chain, under both
   presentation polarities and with the padding sentinel, and the
   device path carries measured differential evidence against the
   same frozen edges.
3. **Centre and width semantics are the DICOM-derived reals.** The
   parameters live in the input's real value domain per the model's
   own definition, with width at least one enforced typed everywhere
   a window enters.

## Alternatives considered

New edge tests were rejected as duplicative: the fixtures that pin
the edges already run in four suites, and this record's value is the
binding, not more copies.

## Consequences

`VOX-R2D-006` carries a recorded assessment bound to existing proven
evidence.

## Affected modules

Documentation only; no source change.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

No new obligations; the cited suites remain the evidence.

## Migration

None.

## Supersession

Records an assessment; no record is superseded.

## References

- [VOXELIA-ALG-0002 - Window-level linear binary64-v1](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
- [ADR-0114 - Clinical pipeline assessments](ADR-0114-clinical-pipeline-assessments.md)
