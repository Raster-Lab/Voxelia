---
document_id: "VOXELIA-ALG-0066"
title: "Mask editing exact-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Mask editing exact-v1

## Purpose

`VOX-SEG-008` — explicit, host-undoable, provenance-producing segmentation
editing. The model is `mask-edit/exact-v1`; `ADR-0362` records how each of
the row's three adjectives is made structural.

## The rule

A closed three-verb vocabulary over two aligned `0`/`1` `mask` images —
the base and the edit mask — per sample:

- **`union`** (paint): `1` when either is `1`;
- **`subtract`** (erase): `1` when the base is `1` and the edit is `0`;
- **`intersect`** (keep-within): `1` when both are `1`.

The verb is a defaultless parameter — *explicit* is structural. Shapes must
match exactly; corrupt mask bytes reject fail-closed; the output claims the
base's geometry verbatim and carries `mask` semantic. Pure boolean
selection: no warnings can arise.

## Undo and provenance, structurally

Editing **never mutates**: every edit publishes a new object whose
derivation and provenance name both inputs (`base` and `edit` roles) and
the verb in the parameter document — CDMS section 52.11's "segmentation
editing shall create new provenance", satisfied by the operation pattern
itself. **Undo is the host's act of re-referencing the retained prior
object**, which immutability keeps intact — the suite's witness edits a
mask and then proves the base's bytes unchanged.

## Determinism and failure classification

Failure cases are admission-only: `unsupportedLayerFormat`,
`shapeMismatch`, `invalidMaskValue`.

## Conformance fixtures

Base `1, 1, 0, 0` with edit `1, 0, 1, 0`:
`union` → `1, 1, 1, 0`; `subtract` → `0, 1, 0, 0`;
`intersect` → `1, 0, 0, 0`
(`docs/progress/evidence/ADR-0362-mask-edit-oracle.py`).

## Validation obligations

The implementing increment must reproduce the three fixtures exactly,
verify the base is byte-identical after the edit (the undo witness),
verify the provenance carries both input edges and the verb, and verify
the admission rejections typed.

## References

- [VOXELIA-ALG-0058 - Mask application and arithmetic](VOXELIA-ALG-0058-mask-application-and-arithmetic.md)
- [ADR-0362 - Mask editing](../architecture/decisions/ADR-0362-mask-editing.md)
