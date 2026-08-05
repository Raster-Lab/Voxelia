---
document_id: "ADR-0141"
title: "Oblique extraction design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MPR-003"
  - "VOX-MPR-004"
  - "VOX-SPA-004"
---

# ADR-0141 - Oblique extraction design

## Context

The M4 sweep re-assessment records oblique multiplanar extraction as
the one open reconstruction gap: axis-aligned planes extract and
squeeze exactly, and world points map through the accepted inverse,
but no decided model samples a plane that cuts the grid. Per the
plan-first discipline of `ADR-0136`, this record freezes the model
before any implementation exists. It was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **The request is the output's geometry.** An oblique slice is
   requested as the output's own affine geometry — origin as
   translation, two in-plane step columns — and the output claims
   that geometry verbatim, so the claim records exactly what ran and
   `VOX-MPR-004` reproducibility is the request value itself.
2. **Sampling composes only accepted models.** `VOXELIA-ALG-0017`
   fixes the chain: the claimed forward evaluation positions each
   output sample in world space, the `VOXELIA-ALG-0016` inverse and
   its frozen composition map it to continuous volume indices, and a
   trilinear reduction over ascending volume axes — the
   `VOXELIA-ALG-0015` per-axis tap rule extended to rank three —
   produces the byte. Trilinear was chosen over composing the
   two-dimensional bilinear rule because an oblique sample sits
   between eight voxels; a two-dimensional rule would misreport the
   interpolation that actually runs.
3. **Support and padding are declared.** Outside the closed
   pixel-centre support the sample is exactly zero, stated in
   version one rather than parameterised; inside, border coordinates
   replicate the border sample under the accepted tap rule. Typed
   rejection of every escaping plane was rejected as unusable —
   rotated planes routinely overhang volume corners — and silent
   clamping of escaped samples was rejected as fabrication.
4. **Implementation follows separately.** The Swift operation, its
   typed admissions and the fixture harness are their own increment,
   and no consumer may embed an ad-hoc oblique sampler meanwhile.

## Alternatives considered

Parameterising the plane as origin-normal-rotation was rejected: the
output geometry form carries the same information in the vocabulary
consumers already claim. Nearest-neighbour version one was rejected:
the display-policy row already distinguishes policies, and the
linear model is the one with an open reconstruction obligation.

## Consequences

The reconstruction arc has a frozen oblique model with exact
fixtures; `VOX-MPR-003`'s remainder becomes an implementable queue
item.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The obligations are recorded in the specification's validation
section and bind the implementing increment.

## Migration

None; implementation follows as its own increment.

## Supersession

Plans the remaining reconstruction opening; no record is superseded.

## References

- [VOXELIA-ALG-0017 - Oblique slice sampling binary64-v1](../../algorithms/VOXELIA-ALG-0017-oblique-slice-sampling.md)
- [ADR-0136 - Affine inverse design](ADR-0136-affine-inverse-design.md)
- [ADR-0138 - World-to-index mapping](ADR-0138-world-to-index-mapping.md)
