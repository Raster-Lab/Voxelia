---
document_id: "ADR-0176"
title: "Gradient lighting design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DVR-008"
---

# ADR-0176 - Gradient lighting design

## Context

The volume-rendering arc's fourth increment is gradient estimation
and lighting. Per the plan-first discipline this record freezes the
model before implementation; per the arc's binding rule, everything
it shades is presentation, never a source of authoritative
quantitative measurement. It was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **`VOXELIA-ALG-0025` composes accepted authorities end to end.**
   Central differences use the accepted trilinear sample at unit
   index offsets, and the world gradient is the chain rule through
   the accepted inverse's transpose — spacing and shear absorbed
   exactly, so a per-axis spacing division was rejected as a partial
   restatement of what the inverse already carries.
2. **The version-one light is the headlight.** No light vocabulary
   exists yet; the headlight — the negated unit ray direction the
   accepted sampler already computes — lights what the viewer faces
   without inventing one, and positionable lights arrive with their
   own records. The ambient floor is declared exactly one quarter,
   not parameterised: a tunable ambient with no consumer is
   speculative surface.
3. **Flat regions stay unshaded by declaration.** A zero-magnitude
   gradient uses factor exactly one, because shading a surface that
   does not exist would fabricate one; opacity is never modulated,
   because lighting changes appearance, never coverage.
4. **The closed lighting vocabulary is `none` and `headlight`**, and
   the unshaded mode must composite byte-identically to the accepted
   unshaded model — an obligation, so the new mode can never
   silently change existing renders.
5. **Implementation follows separately**, extending the renderer
   with the mode and the shaded per-sample path.

## Alternatives considered

Phong and specular terms were deferred: diffuse-plus-ambient is the
diagnostic baseline and specular highlights on presentation data
invite misreading structure into shine. Precomputed gradient volumes
were deferred to the acceleration arc, which must prove image
identity.

## Consequences

The renderer gains honest surface shading with exact fixtures; the
lighting vocabulary has its extension point.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The obligations are recorded in the specification and bind the
implementing increment, including the unshaded byte-identity and the
never-modulated opacity.

## Migration

None; implementation follows as its own increment.

## Supersession

Executes the fourth increment of accepted `ADR-0165`; no record is
superseded.

## References

- [VOXELIA-ALG-0025 - Gradient lighting binary64-v1](../../algorithms/VOXELIA-ALG-0025-gradient-lighting.md)
- [ADR-0165 - Volume rendering arc](ADR-0165-volume-rendering-arc.md)
