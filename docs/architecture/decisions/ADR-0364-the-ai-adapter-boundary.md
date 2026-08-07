---
document_id: "ADR-0364"
title: "The AI adapter boundary"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-SEG-010"
---

# ADR-0364 - The AI adapter boundary

## Context

`VOX-SEG-010` — AI inference integrated through optional adapters, never
embedded in the foundational segmentation model. P0, `I,R`: the row asks for
an inspected boundary, not an inference feature, and its `R` sits in the
owner's `ADR-0351` batch alongside the reference-adapter question.

## Decision

1. **`SegmentInferenceAdapter` is the one inference-facing surface**: a
   protocol beside the model taking authoritative `ImageData` and returning
   `SegmentInferenceResult` — descriptors (carrying `automatic` type and
   model identity through the accepted `SegmentAlgorithmDescriptor`) and
   per-segment fields. **The host assembles and publishes the
   `Segmentation`**, so admission and provenance stay with the accepted
   lifecycle; an adapter never publishes.

2. **"Never embedded" is enforced, not asserted**: `CoreML` and `CreateML`
   join `check_prohibited_imports.py` for **every** module — the `ADR-0328`
   Model I/O pattern — and the widened gate was negative-tested both ways
   in this increment. A conforming inference runtime can exist only in an
   optional adapter package outside this tree, which cannot enter without
   the owner's supply-chain decision.

3. **The inspection (`I`) is this record's measurement**: the foundational
   model references no inference vocabulary; the protocol references only
   accepted model types; the suite's stub conformance proves the protocol
   is implementable and its output assembles into a valid `Segmentation`
   through the ordinary admission.

4. **No reference adapter is built** — that question is the owner's, asked
   once in `ADR-0351`'s batch and not pre-empted here. `VOX-SEG-010`'s `I`
   is discharged; its `R` joins the owner's next review session.

## Alternatives considered

### An inference runtime behind a feature flag in the tree

Rejected. A flag is an embedding with a switch; the row says adapters, and
the supply chain stays owner-reserved.

### Waiting for the owner batch before building the boundary

Rejected. The boundary is what makes any future answer safe to act on; the
batch decides whether a *reference adapter* exists, not whether the
*boundary* does.

## Consequences

The segmentation arc's engineering is complete: `VOX-SEG-001` through
`VOX-SEG-009` discharged, `VOX-SEG-010` at `I` with `R` pending the owner.
The registration arc opens next.

## Affected modules

`VoxeliaCore` gains the protocol and result type; the import gate widens
for every module.

## Compatibility impact

Additive only.

## Security impact

Strengthened: no module can import an inference runtime, enforced and
negative-tested.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_prohibited_imports.py
swift test --filter SegmentInferenceTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the protocol, the gate widening and the stub-conformance
   test, in the same increment.
2. **Next**: open the registration arc (`VOX-REG-001`, the transform
   category model).
3. **Owner**: `VOX-SEG-010` `R`, with the reference-adapter question, in
   the `ADR-0351` batch.

## Supersession

This record supersedes nothing. It closes the segmentation arc's
engineering half.

## References

- [ADR-0328 - Model I/O is optional](ADR-0328-model-io-is-optional.md)
- [ADR-0359 - Open the segmentation arc](ADR-0359-open-the-segmentation-arc.md)
- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
