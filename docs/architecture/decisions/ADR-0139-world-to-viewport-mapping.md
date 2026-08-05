---
document_id: "ADR-0139"
title: "World-to-viewport mapping"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-INT-006"
  - "VOX-SPA-004"
  - "VOX-MPR-005"
---

# ADR-0139 - World-to-viewport mapping

## Context

Accepted `ADR-0138` gave the multiplanar coordinator its world-point
crosshair surface; the pick resolver still maps only one direction —
viewport pixels to physical positions under the `ADR-0129` claim.
Cross-viewport crosshair synchronisation needs the reverse: the pixel
in another viewport whose claimed geometry contains a shared world
point. This record adds it. It was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **The claims stay the map.** The presentation's claimed geometry
   is the final object's, so its indices are viewport indices — the
   reverse mapping applies the frozen `ADR-0138` composition through
   `AffineWorldToIndexMap` and takes the slots the geometry's own
   axis mapping assigns to presented axes zero and one. No scaling or
   crop inversion exists on this path because the claim already
   describes the presented object.
2. **Out-of-plane components do not gate admission.** A viewport
   presents its own plane's projection of a shared crosshair — the
   `ADR-0138` symmetry, where components that do not select the pixel
   do not reject it.
3. **Rounding and admission are declared.** Ties-to-even per the
   accepted `ADR-0130` rule, a double-domain range check before
   integer conversion, and three typed rejections join the
   interaction vocabulary: `presentationNotCalibrated` for a claim
   without geometry — the forward path's optional position is
   supplementary data on a successful pick, but here the mapping is
   the entire operation — `viewportAxisNotMapped` when the geometry
   does not map both presented axes, and `crosshairOutsideViewport`
   for a pixel that left the view, because a nearest pixel would
   misreport where the crosshair is. A foreign-space point surfaces
   the map's own typed mismatch.

## Alternatives considered

Returning an optional target for the uncalibrated case was rejected:
the caller must distinguish a presentation that cannot sync from a
crosshair that left one view, and typed cases carry that distinction
where `nil` cannot. Reusing `pickOutsideViewport` was rejected: an
invalid pick input and a crosshair leaving a synced view demand
different handling, and one case for both would misreport which
happened.

## Consequences

Linked viewports can follow one world crosshair through honest
claims; the interaction vocabulary gains three cases with no change
to any existing surface.

## Affected modules

`VoxeliaInteraction`.

## Compatibility impact

Additive: one method and three error cases.

## Security impact

None.

## Performance and memory impact

One inverse construction and three dot products per mapping.

## Validation impact

The resolver suite gains the exact round trip mirroring the claimed
forward fixture, the off-plane projection, the ties-to-even boundary
and all four typed rejections.

## Migration

None.

## Supersession

Extends `ADR-0125` and `ADR-0129` with the reverse mapping; no record
is superseded.

## References

- [ADR-0138 - World-to-index mapping](ADR-0138-world-to-index-mapping.md)
- [ADR-0129 - Physical pick resolution](ADR-0129-physical-pick-resolution.md)
- [ADR-0125 - Pick resolution](ADR-0125-pick-resolution.md)
- [ADR-0130 - Crosshair slice mapping](ADR-0130-crosshair-slice-mapping.md)
