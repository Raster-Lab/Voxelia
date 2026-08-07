---
document_id: "ADR-0361"
title: "Region growing"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-SEG-007"
---

# ADR-0361 - Region growing

## Context

`VOX-SEG-007` requires region-growing operations to record seeds, thresholds,
connectivity and implementation version. `VOXELIA-ALG-0065` freezes the
growth rule as a composition of the threshold's in-range test and the
components' connectivity vocabulary; this record designs the operation whose
parameter document is the recording the row demands.

## Decision

1. **`RegionGrowOperation`** (`org.voxelia.op.region-grow`, CPU
   twenty-eighth implementation) grows from caller-supplied seeds over the
   stored-value domain, including exactly the in-range samples connected to
   an in-range seed under the chosen `ComponentConnectivity`, and publishes
   a mask image.

2. **The recording is the parameter document**: every seed coordinate in
   order, both bounds, the padding sentinel only when declared, and the
   connectivity token — with operation and implementation versions bound
   structurally by the derivation and provenance the pattern always
   carries. Reproducing the growth needs nothing outside the record.

3. **An out-of-range seed founds nothing and is not an error** —
   interactive seeding must not throw on a miss; an empty mask is the
   visible, honest answer.

4. **`VOX-SEG-007` is discharged by this increment.**

## Alternatives considered

### Reject an out-of-range seed

Rejected; see decision 3.

### An adaptive (statistics-driven) growth criterion

Deferred, not refused. The row asks for recorded thresholds; an adaptive
criterion whose effective threshold evolves would need its own recording
design, and belongs to a future record if a consumer asks.

## Consequences

`VOX-SEG-007` is discharged; the arc continues with editing provenance
(`VOX-SEG-008`) and statistics (`VOX-SEG-009`).

## Affected modules

`VoxeliaExecution` gains the operation; `VoxeliaCPU` registers it
(twenty-eight implementations; the combined registry thirty-one).

## Compatibility impact

Additive only.

## Security impact

None. The fill visits each sample at most once.

## Performance and memory impact

One widening pass plus one bounded fill; a queue and the mask buffer.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0361-region-grow-oracle.py
swift test --filter "RegionGrowOperationTests|CPUBackendRegistrationsTests|CombinedRegistryTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0065` and the oracle.
2. The operation, registration and fixture tests, in the same increment.
3. **Next**: segmentation editing provenance (`VOX-SEG-008`).

## Supersession

This record supersedes nothing. It composes the threshold and components
contracts unchanged.

## References

- [VOXELIA-ALG-0065 - Region growing](../../algorithms/VOXELIA-ALG-0065-region-growing.md)
- [ADR-0360 - Nearest label resampling and the operation set](ADR-0360-nearest-label-resampling.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
