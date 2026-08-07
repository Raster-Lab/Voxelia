---
document_id: "ADR-0413"
title: "Thresholds and the session"
status: "Accepted"
date: "2026-08-08"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PER-012"
---

# ADR-0413 - Thresholds and the session

## Context

The owner directed (2026-08-08): regression thresholds at ten percent,
and the 1.0 release session scheduled. These are the last two open
batch items.

## Decision

1. **The approved regression threshold is ten percent** (closing the
   regression row's `R` half): a candidate regresses when latency or
   peak memory exceeds the baseline by more than 10%, or throughput
   falls more than 10% below it — evaluated by the `ADR-0407`
   `RegressionCheck` seam with `threshold: 0.1`. **The approved
   baseline is the 2026-08-08 campaign's steady-state record**
   (`docs/progress/evidence/benchmark-campaign-2026-08-08.json`);
   each stable release's campaign becomes the next baseline on
   acceptance. Enforcement is by explicit review against the seam at
   each release (the row's second branch): a timing gate inside the
   unit suite would trade determinism for theatre, and this project
   does not.

2. **The 1.0 release session is scheduled and staged**: the complete
   acceptance package is
   `docs/releases/v1.0-session-checklist.md` — every artefact the
   session accepts, with its location and its state. Conducting the
   session and cutting the tag remain the owner's act, exactly as
   v0.2.0 was cut after the owner's demonstration session.

3. **With this record, every owner-batch item is resolved or staged.**
   What remains is the session itself.

## Alternatives considered

### A CI timing gate on every push

Rejected — decision 1. Wall-clock assertions in the deterministic
suite would be the first flaky thing in it.

## Consequences

The project is one owner session from 1.0.

## Affected modules

None; documentation only.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the session checklist and the ledger entry, in the
   same increment.
2. **Next**: the owner conducts the 1.0 session.

## Supersession

This record closes the final `ADR-0407` owner half.

## References

- [ADR-0407 - Benchmark reporting and instrumentation](ADR-0407-benchmark-reporting-and-instrumentation.md)
- [ADR-0408 - The release policy](ADR-0408-the-release-policy.md)
- [The v1.0 session checklist](../../releases/v1.0-session-checklist.md)
