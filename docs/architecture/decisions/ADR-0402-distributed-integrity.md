---
document_id: "ADR-0402"
title: "Distributed integrity"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DST-006"
  - "VOX-DST-007"
  - "VOX-DST-008"
  - "VOX-DST-009"
  - "VOX-DST-011"
  - "VOX-DST-012"
---

# ADR-0402 - Distributed integrity

## Context

The `ADR-0397` integrity arc: checksummed partial results, merge
detection, order-independent accumulator merging, declared reduction
semantics, worker-side rejection, and pre-emption. The `ADR-0401`
descriptions are the substrate; this record adds what makes assembling
their outputs honest.

## Decision

1. **`PartialResult` carries checksum, producer and partition
   identity** (`VOX-DST-006`): the job identifier, the validated
   partition, the payload's `ContentID` and the producer's
   `SoftwareIdentity` — provenance in the accepted vocabulary,
   `Codable` with revalidating decode.

2. **`MergeValidator` audits before anything merges** (`VOX-DST-007`):
   given the declared expected partition set and the received partial
   results, it refuses typed on a **foreign job**, a **duplicated
   partition**, an **unexpected partition** or a **missing partition**
   — in that fixed precedence, so one audit failure never masks
   another's category.

3. **The accumulator merge is Chan's combination, frozen**
   (`VOX-DST-008`, `VOXELIA-ALG-0083`): it consumes states, not
   samples, so no sample ordering is required. The analysis half is
   recorded in the specification: the merge is a different frozen model
   from sequential accumulation (one ulp on the fixture, pinned), which
   is exactly why —

4. **Reduction semantics are declared, never assumed** (`VOX-DST-009`):
   `ReductionSemantics` names the numerical model identifier and a
   closed ordering rule (`ascendingPartitionIdentityLeftFold` in v1),
   and the merge plan requires the declaration. A distributed reduction
   without declared semantics is unrepresentable.

5. **Workers reject incompatible jobs typed** (`VOX-DST-012`):
   `WorkerCompatibility.require` checks a job's embedded `ADR-0380`
   contract against the worker's declared one — rank envelope within,
   scalar support within, geometry requirement satisfiable, quality
   profiles and capability requirements subsets. Silent best-effort
   acceptance is the prohibited shape.

6. **Pre-emption is a typed cooperative seam** (`VOX-DST-011`):
   `WorkerPreemption` is an actor an external fabric flips; the worker
   checks between partitions and receives a typed `preempted` refusal —
   no partial publication races, because the `ADR-0399` stale-drop
   already guards publication. The `D` half is this record.

## Alternatives considered

### Auditing merges with a single boolean validity

Rejected. Missing, duplicated and incompatible are different failures
with different operator responses; one bit erases the difference.

### Best-effort worker acceptance with downgrade

Rejected — decision 5.

## Consequences

M9 arc 4 closes; the plug-in and adapter arcs remain.

## Affected modules

`VoxeliaExecution` gains the integrity vocabulary;
`VoxeliaPhotorealistic` gains the accumulator merge.

## Compatibility impact

Additive only.

## Security impact

Strengthened: unaudited merges and undeclared reductions are
unrepresentable.

## Performance and memory impact

`O(partitions)` audits; `O(1)` merges.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0402-welford-merge-oracle.py
swift test --filter DistributedIntegrityTests
swift test --filter MergeableAccumulationTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0083`, the vocabulary, the witness suites
   and the register updates, in the same increment.
2. **Next**: the runtime plug-in decision record, then the Apple
   adapter and energy rows.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0083 - Welford merge](../../algorithms/VOXELIA-ALG-0083-welford-merge.md)
- [ADR-0401 - Distributed job descriptions](ADR-0401-distributed-job-descriptions.md)
- [ADR-0399 - Progressive frames and cancellation](ADR-0399-progressive-frames-and-cancellation.md)
