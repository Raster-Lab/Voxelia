---
document_id: "ADR-0353"
title: "Mask application and image arithmetic"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-IMG-010"
  - "VOX-R2D-004"
---

# ADR-0353 - Mask application and image arithmetic

## Context

`ADR-0352` opened the processing foundations arc with the threshold and the
arc's stored-value domain; `VOX-IMG-010`'s remaining halves are mask
application and image arithmetic. `VOXELIA-ALG-0058` freezes both; this record
designs the operations and settles the overflow question the ledger named.

## Decision

1. **The integer overflow rule is saturate-and-count, never silent and never
   fatal**: results round ties-to-even, clamp to the type range, and every
   saturation lands in the aggregated `arithmetic-saturated` warning, absent
   at zero. Float32 stores non-finite results verbatim and counts them into
   `arithmetic-non-finite` — binary32 has a vocabulary for infinity, and
   substituting finite values would fabricate data. Both mirror the
   established padding/NaN warning pattern.

2. **`MaskApplyOperation`** (`org.voxelia.op.mask-apply`) keeps masked-in
   samples byte-verbatim, writes an exactly-representable fill under mask
   zero, and rejects any mask byte other than `0`/`1` fail-closed — a
   corrupted mask must never silently threshold. The fill's exact
   round-trip requirement (`fillValueNotRepresentable`) keeps the written
   value the declared one.

3. **`ArithmeticOperation`** (`org.voxelia.op.image-arithmetic`) applies
   `add`/`subtract`/`multiply` between two same-shape same-type images or an
   image and one finite scalar, computing in binary64 over the domain's exact
   widening. Version one requires identical operand types; mixed-type
   arithmetic is a future widening with its own promotion rule, not an
   accident of this one.

4. **`VOX-IMG-010` is discharged by this increment** — threshold, mask and
   arithmetic all exist under one domain with oracle evidence — and
   `VOX-R2D-004` advances again (both operations admit `float32`).

## Alternatives considered

### Reject on integer overflow

Rejected. One hot sample would fail a whole volume, making the operation
unusable on real data; the saturation count keeps the distortion visible
where rejection would merely relocate it.

### Silent saturation

Rejected. Distorting stored values invisibly is the exact dishonesty the
warning vocabulary exists to prevent.

### Any-nonzero mask inclusion

Rejected; see decision 2. `VOXELIA-ALG-0057` emits exactly `0`/`1`, so any
other value is corruption, and fail-closed is the diagnostic posture.

## Consequences

`VOX-IMG-010` is discharged; the arc continues with convolution
(`VOX-IMG-011`).

## Affected modules

`VoxeliaExecution` gains two operations; `VoxeliaCPU` registers them
(twenty-one implementations; the combined registry twenty-four).

## Compatibility impact

Additive only.

## Security impact

None. Admission bounds every input before the read.

## Performance and memory impact

Single passes; one output allocation each.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0353-mask-arithmetic-oracle.py
swift test --filter "MaskApplyOperationTests|ArithmeticOperationTests|CPUBackendRegistrationsTests|CombinedRegistryTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0058` and the oracle.
2. Both operations, registrations and fixture tests, in the same increment.
3. **Next**: convolution and Gaussian foundations (`VOX-IMG-011`), where the
   frozen decisions are the boundary conditions the row itself names.

## Supersession

This record supersedes nothing. It completes `VOX-IMG-010` under
`ADR-0352`'s domain.

## References

- [VOXELIA-ALG-0058 - Mask application and arithmetic](../../algorithms/VOXELIA-ALG-0058-mask-application-and-arithmetic.md)
- [ADR-0352 - Open the processing foundations arc](ADR-0352-open-the-processing-foundations-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
