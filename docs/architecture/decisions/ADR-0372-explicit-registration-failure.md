---
document_id: "ADR-0372"
title: "Explicit registration failure"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-008"
---

# ADR-0372 - Explicit registration failure

## Context

`VOX-REG-008` (P0, `T`, M7): registration failure or non-convergence
shall be reported explicitly and shall not be presented as a successful
transform. The `ADR-0366` result record is deliberately complete — it
records what ran even when the run failed, and it carries the estimated
transform because a durable record that lost its transform identifies
nothing. But completeness at the record is presentation risk at the
host: a caller that reads `result.transform` without reading
`result.convergenceStatus` has silently presented a failure as success.
The row demands a seam where that mistake is not expressible.

## Decision

1. **`RegistrationOutcome` is a closed two-case vocabulary**:
   `succeeded(RegistrationResult)` and
   `notConverged(RegistrationFailureReport)`. The failure report carries
   the identities, metric, optimiser, status, iteration count and the
   honest optional final metric value — **and no transform**. A
   non-converged run structurally cannot hand out a transform; the
   compiler enforces what the row demands.

2. **Only `converged` is success.** An iteration-limit stop, a user
   stop and a failure are all non-convergence and classify into the
   failure case. Accepting a limit-reached estimate is a decision the
   host must take explicitly against the report, never implicitly by
   reaching for a transform that classification quietly surrendered.

3. **`classify` is total and non-throwing**: every `ADR-0366` result
   sorts into exactly one case, so there is no path around the seam for
   a result in hand. `RegistrationFailureReport`'s own admission refuses
   a `converged` status typed — a "failure report" of a success is a
   contradiction, not a value.

4. **The record stays complete; the outcome is the presentation seam.**
   `ADR-0366` is not amended: provenance and audit keep the full record,
   including a failed run's estimated transform, because audit and
   presentation are different consumers with different honesty rules.

## Alternatives considered

### Making the result record's transform optional on failure

Rejected. It would break the record's completeness for audit and turn
every audit consumer into an unwrapping exercise; the seam belongs at
presentation, not at the record.

### Treating `iterationLimitReached` as success

Rejected — decision 2. Non-convergence presented as success is exactly
the prohibited shape.

## Consequences

Hosts consume outcomes; the intensity-driven members return outcomes;
audit keeps records. Nothing presents failure as a transform.

## Affected modules

`VoxeliaCore` gains `RegistrationOutcome`,
`RegistrationFailureReport` and their error family.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

Negligible.

## Validation impact

```text
swift test --filter RegistrationOutcomeTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the vocabulary, the fixture suite and the register
   updates, in the same increment.
2. **Next**: the remaining registration rows per the `ADR-0351` order.

## Supersession

This record supersedes nothing; it composes `ADR-0366` unchanged.

## References

- [ADR-0366 - The registration result record](ADR-0366-the-registration-result-record.md)
- [ADR-0370 - The registration metric architecture](ADR-0370-the-registration-metric-architecture.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
