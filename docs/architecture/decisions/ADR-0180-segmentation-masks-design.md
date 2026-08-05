---
document_id: "ADR-0180"
title: "Segmentation masks design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DVR-010"
  - "VOX-ERR-001"
---

# ADR-0180 - Segmentation masks design

## Context

The volume-rendering arc's sixth increment covers `VOX-DVR-010`: the
renderer shall support segmentation masks and multi-volume
compositing. Accepted `ADR-0178` deferred masks from the clipping
record, recording that they are a different mechanism — masks change
what composites, not where rays sample — and that this record would
also decide multi-volume compositing's placement. Per the plan-first
discipline this record freezes the rules before implementation; per
the arc's binding rule, everything masked is presentation, never a
source of authoritative quantitative measurement. It was authored and
accepted on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

1. **`VolumeMaskSelection` joins `VoxeliaRendering`.** It pairs one
   mask volume's identity with a non-empty set of visible label
   values — an allow-list, not a deny-list, so an unrecognised label
   defaults to hidden rather than shown, the no-permissive-defaults
   discipline applied to segmentation. An empty visible set is
   rejected typed at construction (`RenderModelError`, joining the
   clip and crop admission cases): a mask that hides every label is
   almost certainly a caller error, and the fully-hidden case is
   already reachable by omitting the mask entirely.
2. **Label lookup is nearest-neighbour, restated, not reused.** The
   accepted `VOXELIA-ALG-0017` trilinear sampling authority is wrong
   for labels — interpolating identifiers is meaningless — so the
   mask gets its own minimal sampler over the same continuous
   index-space positions the ray plan already produces: round each
   axis half-away-from-zero, clamp to the extent, mirroring
   `VOXELIA-ALG-0017`'s flat-indexing and out-of-support-zero
   convention without its interpolation. This is restated rather than
   composed with `VOXELIA-ALG-0008`'s nearest-neighbour rule too,
   because that rule assumes a different grid convention (continuous
   output-pixel space) and would silently misalign labels against
   voxel centres.
3. **Masking is realised entirely above the sampler, as a compositing
   decision.** `VolumeRaySampler` is untouched by this record — masks
   do not restrict where a ray travels, only which of its already-
   planned samples contribute. The renderer computes one inclusion
   flag per sample (visible-label membership of the nearest-neighbour
   mask lookup at the same index position already used for
   intensity) and `VolumeRayCompositor` gains two additional sibling
   entries — masked-unshaded and masked-shaded — mirroring the
   existing unshaded/shaded pair exactly, with an excluded sample's
   colour and opacity never reaching the accumulation while it is
   still counted as consumed. The two accepted entries are not
   modified, so the no-mask path stays structurally byte-identical.
4. **The request carries the mask, digested.** `VolumeRenderRequest`
   gains the explicit optional `mask: VolumeMaskSelection?` with
   absence stated at every call site; the parameter collection
   digests the mask's object identity and its visible labels —
   ascending-sorted, since the set's iteration order is not a stable
   representation — only when a mask is declared, the padding-entry
   precedent, so an undeclared mask leaves the document and digest
   unchanged.
5. **The renderer validates the mask against the volume, typed.** The
   mask must share the primary volume's extents and be a
   single-component byte-labelled format; both reject typed
   (`VolumeRenderError`, joining the existing volume-admission
   cases), mirroring how the primary volume is already validated
   before use.
6. **Multi-volume compositing is deferred to its own future record.**
   No consumer-driven blend rule exists yet: whether a second
   modality should compose by alpha-over, maximum-intensity, additive
   blending or a fixed-opacity colour overlay is a domain decision
   that should be driven by an actual consumer request, not
   speculated — the same reasoning accepted `ADR-0178` used to defer
   oriented clip planes. `VOX-DVR-010`'s "belongs with them" placement
   from `ADR-0178` is satisfied by deciding this here, not by
   designing an under-motivated blend rule.
7. **Implementation follows separately**, extending
   `VolumeRenderRequest`, `VolumeRayCompositor` and
   `ExactVolumeRenderer` with the mask path — absence explicit at
   every call site.

## Alternatives considered

Reusing `VOXELIA-ALG-0017`'s trilinear authority for mask sampling was
rejected: averaging label one and label two produces neither, so
interpolating identifiers would fabricate labels that do not exist.
Folding masks into `VolumeRaySampler` as a fourth slab-like
restriction beside the volume, clip and crop was rejected: masks
decide *what* composites, not *where* the ray travels, and forcing a
categorical, non-interpolable field through the sampler's continuous
interval math would conflate two different mechanisms for no benefit.
A single compositor overload with optional shading-factor and
inclusion parameters was rejected in favour of two additional sibling
entries, consistent with the existing one-entry-per-mode-combination
shape and leaving the two accepted entries completely untouched. A
deny-list (excluded labels) vocabulary was rejected in favour of an
allow-list: unknown or newly-added labels should default to hidden,
not silently shown. Designing multi-volume compositing's blend rule
now was rejected for the reason given in Decision item 6.

## Consequences

The mask and compositing rules are frozen with exact fixtures over
the arc's standard six-sample axis-ray fixture:

- the nearest-neighbour voxel-`x` indices for index positions `-0.25,
  0.25, 0.75, 1.25, 1.75, 2.25` are exactly `0, 0, 1, 1, 2, 2`;
- masking samples `[10, 10, 200, 200, 250, 250]` to include only the
  two `200` samples composites to output bytes `(192, 0, 0, 192)`
  with six samples consumed, identical in colour and alpha to
  compositing the filtered pair `[200, 200]` alone through the
  accepted unmasked entry (two samples consumed) — the two differ
  only in how many positions were visited;
- the same masked selection with per-sample shading factors `[1, 1,
  0.6, 0.9, 1, 1]` gives output bytes `(134, 0, 0, 192)`, identical in
  colour and alpha to the accepted shaded entry over the filtered
  pair alone with factors `[0.6, 0.9]`;
- including every label reproduces the accepted unmasked entry's
  complete result, including the consumed count;
- excluding every label composites to fully transparent black `(0, 0,
  0, 0)` with every sample still consumed.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

One additional nearest-neighbour lookup and one inclusion check per
sample when a mask is declared; none when absent.

## Validation impact

The implementing increment must reproduce every fixture exactly,
prove the no-mask path unchanged byte-for-byte through the untouched
sampler and the untouched unmasked compositor entries, prove the
all-included case equals the unmasked entry as a complete tuple
including the consumed count, prove bit-identical repetition, and
reject the empty visible-label set, the extent-mismatched mask volume
and an unsupported mask scalar format, each typed.

## Migration

None; implementation follows as its own increment.

## Supersession

Executes the masks half of the sixth increment of accepted
`ADR-0165`; no record is superseded. Multi-volume compositing, the
other half of `VOX-DVR-010`, remains open and is deferred to a future
record.

## References

- [ADR-0165 - Volume rendering arc](ADR-0165-volume-rendering-arc.md)
- [ADR-0178 - Volume clipping design](ADR-0178-volume-clipping-design.md)
- [VOXELIA-ALG-0008 - Nearest-neighbour resampling binary64-v1](../../algorithms/VOXELIA-ALG-0008-nearest-neighbour-resampling.md)
- [VOXELIA-ALG-0017 - Oblique slice sampling binary64-v1](../../algorithms/VOXELIA-ALG-0017-oblique-slice-sampling.md)
- [VOXELIA-ALG-0022 - Volume ray sampling binary64-v1](../../algorithms/VOXELIA-ALG-0022-ray-sampling.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing binary64-v1](../../algorithms/VOXELIA-ALG-0023-front-to-back-compositing.md)
- [VOXELIA-ALG-0026 - Segmentation mask sampling binary64-v1](../../algorithms/VOXELIA-ALG-0026-segmentation-mask-sampling.md)
