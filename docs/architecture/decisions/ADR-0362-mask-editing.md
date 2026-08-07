---
document_id: "ADR-0362"
title: "Mask editing"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-SEG-008"
---

# ADR-0362 - Mask editing

## Context

`VOX-SEG-008` requires segmentation editing to be explicit, undoable by the
host where history is retained, and provenance-producing.
`VOXELIA-ALG-0066` freezes the three-verb rule; this record maps the row's
three adjectives to structure.

## Decision

1. **`MaskEditOperation`** (`org.voxelia.op.mask-edit`, CPU twenty-ninth
   implementation): `union`, `subtract`, `intersect` over a base and an
   edit mask, the verb a defaultless closed enum — *explicit* is the type
   system's doing, not documentation's.

2. **Provenance-producing is the operation pattern itself**: every edit
   publishes a new object whose derivation and provenance carry both input
   edges and the verb — CDMS section 52.11's editing rule, structural.

3. **Undo is the host's re-reference of the retained prior object.** The
   library's immutable lifecycle means editing cannot destroy the base; a
   host that retains history undoes by pointing back, and the suite proves
   the base byte-identical after an edit. No undo stack enters the library
   — a second history authority would drift from the host's.

4. **`VOX-SEG-008` is discharged at `I` and `T` by this increment.**

## Alternatives considered

### A library-side undo stack

Rejected; see decision 3. The host owns interaction history
(`ADR-0345`'s clock discipline, applied to memory), and immutability
already guarantees the invariant an undo stack would re-implement.

### Reusing ArithmeticOperation with mask semantics widened

Rejected. Arithmetic saturates and counts; editing selects. One operation
whose warnings sometimes mean saturation and sometimes nothing would blur
both vocabularies.

## Consequences

`VOX-SEG-008` is discharged; the arc continues with statistics
(`VOX-SEG-009`).

## Affected modules

`VoxeliaExecution` gains the operation; `VoxeliaCPU` registers it
(twenty-nine implementations; the combined registry thirty-two).

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One boolean pass; one mask allocation.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0362-mask-edit-oracle.py
swift test --filter "MaskEditOperationTests|CPUBackendRegistrationsTests|CombinedRegistryTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0066` and the oracle.
2. The operation, registration and fixture tests, in the same increment.
3. **Next**: segmentation statistics (`VOX-SEG-009`).

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0066 - Mask editing](../../algorithms/VOXELIA-ALG-0066-mask-editing.md)
- [ADR-0361 - Region growing](ADR-0361-region-growing.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
