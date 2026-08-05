---
document_id: "ADR-0097"
title: "End-to-end pipeline archival evidence"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-007"
  - "VOX-STO-004"
  - "VOX-VS1-017"
---

# ADR-0097 - End-to-end pipeline archival evidence

## Context

`ADR-0095` proved the archival boundary against hand-built record
fixtures. Hand-built fixtures cannot prove that the records the real
pipeline actually produces — operation recipes, multi-parent
composites, resample chains — survive the emit-persist-load-ingress
cycle, and the `ADR-0076` precedent records evidence obligations as
decisions. This record was authored and accepted on 2026-08-05 under
the project owner's recorded broadened autonomous delegation.

## Decision

The suite gains a standing end-to-end archival obligation: render a
multi-layer scene to a differing viewport through the accepted
renderer — producing the full stage history of window-levelled
layers, composite and resample — then archive every published
bundle's records through a real directory store, load every document
back under its receipt identity, and decode it through the strict
ingress to the exact published record. Every future pipeline stage
that publishes a new record shape joins this obligation.

## Alternatives considered

Trusting the per-boundary tests was rejected: each boundary is proven
in isolation, and the composed cycle over real operation output is
exactly what none of them exercises. Archiving inside the render test
suites ad hoc was rejected in favour of one recorded obligation.

## Consequences

The complete rendered history — five records including a two-parent
composite recipe — is proven durable and independently verifiable
from real pipeline output.

## Affected modules

Test evidence only; no source change.

## Compatibility impact

None.

## Security impact

None beyond existing disciplines.

## Performance and memory impact

Test-time only.

## Validation impact

The new suite must publish an origin, render a two-layer scene to a
doubled viewport, archive all five published bundles — origin without
a derivation name, every stage with one — and prove every document
ingress-exact against its published record.

## Migration

Implemented in this increment.

## Supersession

Extends the `ADR-0076` evidence discipline to the archival cycle; no
record is superseded.

## References

- [ADR-0095 - Canonical record archival](ADR-0095-canonical-record-archival.md)
- [ADR-0076 - Recorded fuzz and differential oracle evidence](ADR-0076-recorded-fuzz-and-oracle-evidence.md)
