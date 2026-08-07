---
document_id: "ADR-0356"
title: "Binary morphology"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-IMG-012"
---

# ADR-0356 - Binary morphology

## Context

`VOX-IMG-012` requires morphology foundations including erosion and dilation.
`VOXELIA-ALG-0061` freezes the binary rules over the mask domain; this record
designs the operation and settles the boundary question the ledger named.

## Decision

1. **Version one is binary, over masks** — the segmentation arc's actual
   need. Greyscale min/max morphology generalises later by its own record;
   folding it in now would freeze a value-domain question no consumer has
   asked.

2. **`MorphologyOperation`** (`org.voxelia.op.morphology`, CPU twenty-fourth
   implementation) takes the operator (`erode`/`dilate`), a caller-supplied
   `0`/`1` structuring element with odd rank-matched extents, and the
   explicit defaultless boundary. **Under `zero`, border-touching foreground
   erodes** — out-of-image is background, the conservative mask reading;
   under `replicate` the border extends and all-ones is a fixed point. The
   all-ones fixture witnesses both.

3. **Corrupt inputs reject fail-closed**: mask bytes and element bytes other
   than `0`/`1`, and an element with no `1` at all — an empty element makes
   *any* vacuously false and *all* vacuously true, which is a trap, not a
   morphology.

4. **`VOX-IMG-012` is discharged by this increment.**

## Alternatives considered

### Greyscale morphology now

Rejected; see decision 1.

### Implement erosion as complemented dilation

Rejected. The duality is recorded as a property in the specification; using
it as the implementation would couple the two paths' bugs while looking like
reuse.

## Consequences

`VOX-IMG-012` is discharged; the arc continues with connected components
(`VOX-IMG-013`).

## Affected modules

`VoxeliaExecution` gains the operation; `VoxeliaCPU` registers it
(twenty-four implementations; the combined registry twenty-seven).

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One boolean pass; element extents ceilinged.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0356-morphology-oracle.py
swift test --filter "MorphologyOperationTests|CPUBackendRegistrationsTests|CombinedRegistryTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0061` and the oracle.
2. The operation, registration and fixture tests, in the same increment.
3. **Next**: connected-component analysis (`VOX-IMG-013`).

## Supersession

This record supersedes nothing. It continues the arc `ADR-0352` opened.

## References

- [VOXELIA-ALG-0061 - Binary morphology](../../algorithms/VOXELIA-ALG-0061-binary-morphology.md)
- [ADR-0352 - Open the processing foundations arc](ADR-0352-open-the-processing-foundations-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
