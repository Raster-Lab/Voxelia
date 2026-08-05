---
document_id: "ADR-0178"
title: "Volume clipping design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DVR-009"
---

# ADR-0178 - Volume clipping design

## Context

The volume-rendering arc's fifth increment covers clipping planes
and cropping regions. Per the plan-first discipline this record
freezes the rules before implementation; per the arc's binding rule,
everything clipped is presentation, never a source of authoritative
quantitative measurement. It was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **The rendering module gets its own clip value, and the
   duplication is recorded.** The accepted clip box lives in the
   interaction module, which sits above rendering in the dependency
   graph and cannot be imported downward — the broker-generation
   precedent. `VolumeClipBounds` mirrors the accepted shape exactly:
   two world-space corners in one coordinate space with strictly
   ordered bounds on every axis, the same admission rules; the
   interaction layer converts at the host boundary, and the two
   values must never drift — this record binds them.
2. **Clipping and cropping are both ray-interval restrictions,
   frozen as more slabs in the one accepted intersection.** The
   world-space clip contributes three slabs over the world ray in
   the same frozen quotient form the sampler restates from the
   accepted rule; the index-space crop — an accepted region over the
   volume — tightens the pixel-centre support to
   `[lower_k - 0.5, upper_k - 0.5]` per axis. The declared slab
   order is volume support, then clip, then crop; the entry still
   starts at zero, so the inside-camera clamp composes unchanged,
   and an empty combined interval is the declared empty plan — a
   value, never an error. A parallel ray outside any slab is empty
   under the accepted parallel rule.
3. **The clip must share the volume's coordinate space, typed.** A
   foreign-space clip would silently cut in the wrong frame.
4. **Segmentation masks are their own record.** Masks are label
   volumes changing what composites, not where rays sample — a
   different mechanism sharing nothing with interval restriction,
   and `VOX-DVR-010`'s multi-volume compositing belongs with them.
5. **Implementation follows separately**, extending the sampler's
   plan admission and the request with the optional clip and crop —
   absence explicit at every call site.

## Alternatives considered

Clipping composited samples after the fact was rejected: restricting
the interval before sampling skips the work and cannot leak excluded
samples into gradients at the interval boundary the way post-hoc
masking could. Oriented clip planes were deferred: the accepted
vocabulary is the axis-aligned box, and arbitrary plane sets arrive
with a consumer that needs them.

## Consequences

The clip and crop rules are frozen with exact fixtures:

- the identity-volume axis ray clipped to world
  `x` in `[1/2, 3/2]` restricts entry and exit to exactly
  `2.5` and `3.5` with two samples at `2.75` and `3.25`;
- a clip entirely behind the volume, and a parallel ray outside a
  clip slab, are the empty plan;
- the index crop admitting `x` in `[1, 3)` tightens the support to
  `[0.5, 2.5]`, giving entry `2.5`, exit `4.5` and four samples at
  `2.75` through `4.25`;
- an all-containing clip changes nothing.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The implementing increment must reproduce every fixture exactly,
prove the unclipped request unchanged byte-for-byte, prove
bit-identical repetition, and reject a foreign-space clip and an
out-of-volume crop typed.

## Migration

None; implementation follows as its own increment.

## Supersession

Executes the fifth increment of accepted `ADR-0165`; no record is
superseded.

## References

- [ADR-0165 - Volume rendering arc](ADR-0165-volume-rendering-arc.md)
- [VOXELIA-ALG-0022 - Volume ray sampling binary64-v1](../../algorithms/VOXELIA-ALG-0022-ray-sampling.md)
- [VOXELIA-ALG-0001 - Ray axis-aligned bounds intersection](../../algorithms/VOXELIA-ALG-0001-ray-axis-aligned-bounds-intersection.md)
