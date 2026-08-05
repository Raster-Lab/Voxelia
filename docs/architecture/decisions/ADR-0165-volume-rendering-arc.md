---
document_id: "ADR-0165"
title: "Volume rendering arc"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DVR-001"
  - "VOX-DVR-014"
  - "VOX-DVR-015"
---

# ADR-0165 - Volume rendering arc

## Context

The M6 assessment queues the direct-volume-rendering reference arc —
`VOX-DVR-001` through `010` with `014` and `015` — as the largest
actionable arc. This record opens it with the decomposition alone,
per the sweep precedent of assessing before executing: it orders the
increments, names the accepted authorities each composes, and
freezes the one rule that must bind everything that follows. No
numeric model is frozen here; each increment freezes its own with
python-verified fixtures. It was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **`VOX-DVR-015` is frozen now and binds the whole arc.**
   Volume-rendered pixels are presentation, never a source of
   authoritative quantitative measurement: measurements flow through
   the accepted measurement models over authoritative geometry and
   stored values, picks resolve to source data through the accepted
   resolver, and no consumer may cite a rendered pixel as
   measurement input. Every increment's claims record quality and
   approximation honestly, and this rule appears in each record that
   follows.
2. **`VOX-DVR-014` is structural in the reference.** Every increment
   is a pure frozen function, so the CPU reference's determinism is
   bit-identical repetition — the declared tolerance for the
   reference is exactness, and device implementations later declare
   their own.
3. **The ordered increments, each design-first:**
   - *Transfer functions* (`VOX-DVR-005/007`): the one-dimensional
     transfer-function value with exact table lookup and clamped
     indexing whose out-of-range behaviour is declared — the
     window-function vocabulary's admission style.
   - *Ray sampling* (`VOX-DVR-002/003`): rays intersect the actual
     volume bounds through the accepted ray-bounds intersection
     model over the claimed affine geometry, and the sampling
     interval derives from physical spacing and the quality policy
     by a declared formula — never a fixed normalised constant.
   - *Front-to-back compositing* (`VOX-DVR-001/004`): the frozen
     accumulation order with a declared early-termination threshold,
     over samples taken through the accepted trilinear model.
   - *Gradient and lighting* (`VOX-DVR-008`): declared central
     differences over the claimed spacing and a declared shading
     model.
   - *Clipping and masks* (`VOX-DVR-009/010`): the accepted clip box
     and crop vocabulary composed into ray admission, then
     segmentation masks and multi-volume compositing over the
     accepted layer rules.
   - *Acceleration* (`VOX-DVR-012`): empty-space skipping consuming
     the accepted brick statistics where available, with skipped and
     unskipped renders proven identical — acceleration must never
     change the image.
4. **The renderer surface arrives with compositing**, conforming to
   the accepted renderer protocol beside the slice renderers, with
   its claims carried in presentation provenance like every accepted
   stage.

## Alternatives considered

Freezing the first specification inside this record was declined:
the transfer-function fixtures deserve their own verified freeze,
and the decomposition is itself the assessed increment, per the
sweep precedent. Opening with the compositing model was rejected:
compositing consumes transfer functions and sampling, and designing
consumers before their inputs inverts the arc's dependencies.

## Consequences

The arc has an ordered, authority-composing plan with its binding
honesty rule frozen; each following increment is scoped and
mechanical to open.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

Each increment carries its own obligations; the arc-wide rule is
that acceleration and device paths must prove image identity or
declared tolerances against the reference.

## Migration

None.

## Supersession

Opens the M6 volume-rendering arc; no record is superseded.

## References

- [VOXELIA-ALG-0001 - Ray axis-aligned bounds intersection](../../algorithms/VOXELIA-ALG-0001-ray-axis-aligned-bounds-intersection.md)
- [VOXELIA-ALG-0017 - Oblique slice sampling binary64-v1](../../algorithms/VOXELIA-ALG-0017-oblique-slice-sampling.md)
- [ADR-0162 - Brick statistics](ADR-0162-brick-statistics.md)
