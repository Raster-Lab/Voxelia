---
document_id: "ADR-0389"
title: "The documented scattering approximation"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PRR-007"
---

# ADR-0389 - The documented scattering approximation

## Context

`VOX-PRR-007` (P1, `A,T,D`, M8): the progressive and reference modes
shall support multiple-scattering **or an explicitly documented
physically based approximation**. The row's own text offers the honest
branch, and the arc has built exactly the ingredients such a
documented approximation composes.

## Decision

1. **The v1 optical model for progressive and reference modes is
   single scattering**: per view-ray sample, the in-scattered radiance
   is the declared light set attenuated by that sample's
   `VOXELIA-ALG-0077` shadow transmittance (`VOXELIA-ALG-0078`
   accumulation), modulated by the sample's albedo, and carried to the
   eye by the `VOXELIA-ALG-0076` emission-absorption integral. One
   bounce: light, medium, eye.

2. **The analysis half, recorded here**: the approximation captures
   direct volumetric illumination, hard volumetric shadows and
   Beer-Lambert extinction on both path segments — the dominant terms
   of clinical volume appearance. It **omits** second- and
   higher-order scattering, so optically thick interiors render darker
   and translucency softer than a full transport solution; no ambient
   fudge term is added to hide that bias, because an undocumented
   correction would forfeit the "physically based" claim this row
   turns on. Adding scattering orders is an additive future model, not
   a change to this one.

3. **The witness composes only pinned pieces**: per-sample emission
   built from the lighting accumulator over shadow-walk
   transmittances, integrated front to back — every intermediate
   already bit-pinned by its own oracle, so the composition's expected
   values are exact by construction.

## Alternatives considered

### A stochastic multiple-scattering path tracer now

Rejected for v1. It would land unpinned (its determinism row and
convergence row come next in the queue) and the row's documented-
approximation branch exists precisely so the module need not gamble
its determinism story to open.

### An ambient term approximating indirect light

Rejected — decision 2. An undocumented correction is the prohibited
shape.

## Consequences

The physics arc's engineering is closed; the determinism and
progression arc is next, and it inherits a fully deterministic optical
model to seed and accumulate around.

## Affected modules

Documentation and the witness suite; the composition uses existing
types only.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter ScatteringApproximationTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the witness suite and the register updates, in the
   same increment.
2. **Next**: the determinism and progression arc — deterministic
   reference seeds first.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0076 - Emission-absorption integration](../../algorithms/VOXELIA-ALG-0076-emission-absorption.md)
- [VOXELIA-ALG-0077 - Shadow transmittance](../../algorithms/VOXELIA-ALG-0077-shadow-transmittance.md)
- [VOXELIA-ALG-0078 - Lighting and transillumination](../../algorithms/VOXELIA-ALG-0078-lighting-transillumination.md)
- [ADR-0384 - The M8 queue](ADR-0384-the-m8-queue.md)
