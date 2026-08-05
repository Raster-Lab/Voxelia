---
document_id: "ADR-0118"
title: "Concurrency storm evidence"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CON-009"
  - "VOX-VAL-007"
---

# ADR-0118 - Concurrency storm evidence

## Context

`VOX-CON-009` requires concurrency tests covering race detection,
cancellation storms, repeated generation changes and memory-pressure
scenarios. The coordinators were proven correct under small
deterministic loads; nothing stormed them. This record was authored
and accepted on 2026-08-05 under the project owner's recorded
broadened autonomous delegation, extending the `ADR-0076` evidence
discipline.

## Decision

The suite gains a standing storm campaign with seeded-LCG
determinism:

1. **Read-coordinator storm.** Many concurrent coalescing reads
   through one small budget with a deterministic subset cancelled
   mid-flight; the invariant is throw-typed-or-return-exact — every
   surviving read yields the exact bytes — and the coordinator ends
   fully released, proven by a zero charged-byte count and a
   subsequent successful read.
2. **Identity-coordinator storm.** Many concurrent identity requests
   for one collection with a cancelled subset; every survivor yields
   the golden identity, and the started-computation count proves
   coalescing held under the storm.
3. **Publication storm.** Concurrent distinct publishes interleaved
   with concurrent duplicates of one bundle; exactly one duplicate
   wins, the rest reject typed, and the registry count is exact.
4. **Generation churn.** A long strictly-increasing successor chain
   with stale and equal generations rejected typed at every step.
5. **Memory pressure honestly open.** No synthetic memory-pressure
   injection exists on this platform surface without process-level
   tooling; the scenario stays recorded open rather than simulated
   with fabricated signals, and race detection beyond the actor
   isolation the compiler enforces remains the sanitizer campaign's
   subject, recorded with it.

## Alternatives considered

Random unseeded storms were rejected: irreproducible failures are not
evidence. Simulated pressure callbacks were rejected as fabricated
signals.

## Consequences

`VOX-CON-009` is discharged for every subject that exists, with the
open subjects recorded.

## Affected modules

Test evidence only; no source change.

## Compatibility impact

None.

## Security impact

None beyond existing disciplines.

## Performance and memory impact

Test-time concurrency only.

## Validation impact

The storm suite must run its four phases with printed evidence counts
and the stated invariants asserted.

## Migration

Implemented in this increment.

## Supersession

Extends the `ADR-0076` evidence discipline; no record is superseded.

## References

- [ADR-0076 - Recorded fuzz and differential oracle evidence](ADR-0076-recorded-fuzz-and-oracle-evidence.md)
- [ADR-0067 - Result publication coordinator](ADR-0067-result-publication-coordinator.md)
