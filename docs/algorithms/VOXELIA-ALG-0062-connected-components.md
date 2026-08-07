---
document_id: "VOXELIA-ALG-0062"
title: "Connected components exact-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Connected components exact-v1

## Purpose

`VOX-IMG-013` — connected-component analysis over the mask domain. The model
is `connected-components/exact-v1`; `ADR-0357` records the design.

## The connectivity vocabulary

A closed three-case choice, named by the shared adjacency dimension:

- **`faces`** — offsets of Manhattan distance one: `4` neighbours in two
  dimensions, `6` in three;
- **`facesAndEdges`** — Manhattan distance up to two: `18` in three
  dimensions; **rejected in two** (`invalidConnectivity`), where no edge
  adjacency distinct from vertices exists;
- **`facesEdgesAndVertices`** — every non-zero offset: `8` in two
  dimensions, `26` in three.

The diagonal pair is the witness: two components under `faces`, one under
`facesEdgesAndVertices`.

## The frozen labelling

The canonical scan (axis zero fastest) visits every sample; the first
unlabelled foreground sample encountered founds a new component and receives
the **next label in first-encounter order, starting at one**; its component is
then filled completely before the scan continues. Background stays exactly
zero. Determinism is structural: component membership is order-independent,
and the only order-sensitive fact — which component gets which label — is
fixed by the scan.

The fill's internal visit order is not observable in the output and is
therefore not part of the contract.

## The output and its ceiling

A `uint16` image with `label` semantic, the input geometry claimed verbatim —
labels are identities, so the type is the counting type, not the input's.
More than `65535` components rejects typed (`componentCountExceeded`): a
sixteen-bit label space is the frozen version-one ceiling, and widening it is
a recorded future decision, never a silent re-type.

Input mask bytes other than `0`/`1` reject fail-closed (`invalidMaskValue`).

## Determinism and failure classification

Pure integer traversal; no warnings can arise. Failure cases are
admission-only plus the ceiling: `unsupportedLayerFormat`,
`invalidMaskValue`, `invalidConnectivity`, `componentCountExceeded`.

## Conformance fixtures

Computed by `docs/progress/evidence/ADR-0357-connected-components-oracle.py`.

1. **The diagonal witness**: `1, 0, 0, 1` on `2 x 2` → labels `1, 0, 0, 2`
   under `faces`; `1, 0, 0, 1` under `facesEdgesAndVertices`.
2. **First-encounter order**: two bars on `5 x 2` → the scan-earlier bar is
   `1`, the later `2`.
3. **The three-dimensional witness**: samples at `(0,0,0)` and `(0,1,1)` on
   `2 x 2 x 2` → two components under `faces`, one under `facesAndEdges` and
   under `facesEdgesAndVertices`.
4. **The L shape** is one component under `faces`.

## Validation obligations

The implementing increment must reproduce all four fixtures exactly, verify
`facesAndEdges` rejects in two dimensions, verify the component ceiling
rejects typed on a generated worst case, and verify corrupt mask bytes
reject.

## References

- [VOXELIA-ALG-0061 - Binary morphology](VOXELIA-ALG-0061-binary-morphology.md)
- [ADR-0357 - Connected components](../architecture/decisions/ADR-0357-connected-components.md)
