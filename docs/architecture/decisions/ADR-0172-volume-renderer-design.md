---
document_id: "ADR-0172"
title: "Volume renderer design"
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

# ADR-0172 - Volume renderer design

## Context

The compositing engine is live and the arc needs its renderer
surface. Per the plan-first discipline this record freezes the ray
generation and decides the surface shape before implementation; per
the arc's binding rule, the rendered image is presentation, never a
source of authoritative quantitative measurement. It was authored
and accepted on 2026-08-05 under the project owner's recorded
broadened autonomous delegation.

## Decision

1. **`VOXELIA-ALG-0024` freezes orthographic ray generation** from
   the accepted camera vocabulary: the basis construction with the
   accepted norm and cross forms, the pixel-centre grid with row
   zero at the top, and the componentwise origin composition, with
   exact fixtures. The perspective projection is deferred and
   recorded: the camera vocabulary carries it, but perspective rays
   change no compositing semantics while doubling the fixture
   surface, and no consumer distinguishes them yet — it arrives as
   its own revision when the interactive arc wants it, rejected
   typed until then.
2. **The surface is a sibling, not a forced conformance.** The
   slice-request vocabulary describes windowed slice scenes — crops,
   scaling claims, per-layer window functions — and a volume scene
   is a different request: one calibrated volume, one transfer
   table, the camera, the viewport and the quality token. Forcing it
   through the slice request would misdescribe both, so
   `VolumeRenderRequest` and a `VolumeRenderer` surface arrive
   beside the slice renderers, revising the arc-opening record's
   conformance expectation explicitly.
3. **The closed presentation vocabularies widen honestly.** The
   render-mode claim gains `volumeDirect` and the colour-output
   claim gains `rgba8` — the compositor emits four channels — as
   additive cases recorded here; the presentation provenance for a
   volume render claims the mode, the colour output, the camera, the
   viewport, the quality token and the volume's claimed geometry,
   with the transfer table digested into the operation parameters so
   what ran is reproducible.
4. **Implementation follows separately**: the ray-generation model,
   then the renderer composing the accepted sampler, trilinear
   sampling and compositor per pixel through the coordinated read
   boundary, publishing the output image with complete provenance.

## Alternatives considered

Reusing the slice request with optional volume fields was rejected:
optional fields that must be present for one mode and absent for
another are a shape error the closed vocabularies exist to prevent.
Renormalising the true-up vector was rejected: the basis is
orthonormal up to rounding by construction and a second
normalisation would add rounding without meaning.

## Consequences

The renderer implementation is scoped and mechanical; the interactive
arc inherits a recorded perspective extension point.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None in this increment; the widened claim cases arrive with the
implementation.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The obligations are recorded in the specification and bind the
implementing increments, including the end-to-end tiny-viewport
render against composed per-ray expectations.

## Migration

None; implementation follows as its own increments.

## Supersession

Executes the renderer step of accepted `ADR-0165`, revising its
conformance expectation as recorded; no record is superseded.

## References

- [VOXELIA-ALG-0024 - Orthographic ray generation binary64-v1](../../algorithms/VOXELIA-ALG-0024-orthographic-ray-generation.md)
- [ADR-0165 - Volume rendering arc](ADR-0165-volume-rendering-arc.md)
- [ADR-0171 - Volume ray compositor](ADR-0171-volume-ray-compositor.md)
