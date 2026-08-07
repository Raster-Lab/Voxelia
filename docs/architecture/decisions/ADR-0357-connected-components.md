---
document_id: "ADR-0357"
title: "Connected components"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-IMG-013"
---

# ADR-0357 - Connected components

## Context

`VOX-IMG-013` requires connected-component analysis. `VOXELIA-ALG-0062`
freezes the closed connectivity vocabulary, the first-encounter labelling and
the sixteen-bit label ceiling; this record designs the operation.

## Decision

1. **`ConnectedComponentsOperation`** (`org.voxelia.op.connected-components`,
   CPU twenty-fifth implementation) labels a mask image under an explicit
   `ComponentConnectivity`, producing a `uint16` `label`-semantic image with
   background exactly zero and labels in first-encounter scan order — the
   determinism a segmentation identity can be built on.

2. **The label space is sixteen bits, ceilinged and typed**: more than
   `65535` components rejects (`componentCountExceeded`); widening is a
   future record's decision, never a silent re-type.

3. **`facesAndEdges` rejects in two dimensions** rather than silently
   aliasing `facesEdgesAndVertices` — a vocabulary that quietly means
   different things per rank is the trap the closed enum exists to prevent.

4. **`VOX-IMG-013` is discharged by this increment.**

## Alternatives considered

### Union-find two-pass labelling

Rejected as the contract, permitted as an implementation. The flood fill in
scan order makes first-encounter labelling structural; a union-find variant
must renumber to match, so the simple structure is also the honest one.

### uint32 labels

Rejected for version one; see decision 2. Sixteen bits cover any clinical
segmentation this series targets, and the ceiling is visible where a wider
type would merely defer the question.

## Consequences

`VOX-IMG-013` is discharged; the arc closes next with distance transforms
(`VOX-IMG-014`).

## Affected modules

`VoxeliaExecution` gains the operation; `VoxeliaCPU` registers it
(twenty-five implementations; the combined registry twenty-eight).

## Compatibility impact

Additive only.

## Security impact

None. The fill visits each sample at most once; the queue is bounded by the
foreground count.

## Performance and memory impact

One scan plus one fill visit per sample; a queue and the label buffer.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0357-connected-components-oracle.py
swift test --filter "ConnectedComponentsOperationTests|CPUBackendRegistrationsTests|CombinedRegistryTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0062` and the oracle.
2. The operation, registration and fixture tests, in the same increment.
3. **Next**: distance transforms (`VOX-IMG-014`), closing the foundations
   arc.

## Supersession

This record supersedes nothing. It continues the arc `ADR-0352` opened.

## References

- [VOXELIA-ALG-0062 - Connected components](../../algorithms/VOXELIA-ALG-0062-connected-components.md)
- [ADR-0352 - Open the processing foundations arc](ADR-0352-open-the-processing-foundations-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
