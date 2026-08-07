---
document_id: "ADR-0366"
title: "The registration result record"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-002"
---

# ADR-0366 - The registration result record

## Context

`VOX-REG-002` (P0, `T`, M7): registration results shall identify fixed
data, moving data, metric, optimiser, multi-resolution schedule and
convergence status. The row is about the **record** — no metric or
optimiser implementation exists yet, and the record must not pretend
otherwise: it identifies what ran, it does not run anything.

## Decision

1. **`RegistrationResult` is a record over identities, not images**: fixed
   and moving data are full `DataIdentity` values — object, content and
   source identities, the same vocabulary every provenance consumer
   already reads — not retained `ImageData`. A result outlives the
   images it came from.

2. **Metric and optimiser are identified, not enumerated**:
   `RegistrationMetricID` and `RegistrationOptimiserID` follow the
   `VoxeliaStringIdentifier` pattern (255-byte ceiling, whitespace-only
   refused). A closed enum today would freeze a vocabulary this arc has
   not built; identifier plus an optional version string records exactly
   what the row asks — identity — without inventing semantics.

3. **The multi-resolution schedule is structural**: a non-empty ordered
   list of levels, each a positive integer shrink factor plus a finite
   non-negative smoothing sigma. Single-resolution runs are one level —
   the schedule is never optional, because "unknown schedule" is not a
   reproducible result.

4. **Convergence status is a closed defaultless vocabulary**:
   `converged`, `iterationLimitReached`, `stoppedByUser`, `failed`.
   Beside it the record carries the iteration count and, when finite
   measurement exists, the final metric value; a failed run without a
   value records `nil`, never a fabricated number.

5. **The record carries its produced transform**: the `ADR-0365`
   `RegistrationTransform`, so the result names the category and the
   source/destination spaces of what it estimated. A result that lost
   its transform identifies nothing worth keeping.

## Alternatives considered

### Closed metric/optimiser enums

Rejected. The arc has no implementations to enumerate; a premature closed
vocabulary would need a case renamed or retired the moment one is built.

### An optional schedule defaulting to single-resolution

Rejected. Defaultless is the project's rule; one explicit level states the
same thing honestly.

### Referencing fixed and moving data as retained `ImageData`

Rejected. A result is a durable record; identities are what provenance
already exchanges.

## Consequences

The arc's remaining rows (initialisation, metrics, optimisation,
validation) gain the record they publish into.

## Affected modules

`VoxeliaCore` gains `RegistrationResult` and its part vocabulary.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

Negligible.

## Validation impact

```text
swift test --filter RegistrationResultTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the types, the fixture suite and the register updates, in
   the same increment.
2. **Next**: the remaining registration rows per the `ADR-0351` order.

## Supersession

This record supersedes nothing.

## References

- [ADR-0365 - The registration transform categories](ADR-0365-the-registration-transform-categories.md)
- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
