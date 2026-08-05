---
document_id: "ADR-0174"
title: "Volume render vocabulary"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DVR-001"
  - "VOX-DVR-015"
  - "VOX-ERR-001"
---

# ADR-0174 - Volume render vocabulary

## Context

Accepted `ADR-0172` decided the sibling surface; this record
delivers its vocabulary ahead of the renderer, split for atomicity.
Everything this vocabulary describes is presentation, never a source
of authoritative quantitative measurement, per the arc's binding
rule. It was authored and accepted on 2026-08-05 under the project
owner's recorded broadened autonomous delegation.

## Decision

1. **`VolumeRenderRequest` joins `VoxeliaRendering`** as the closed
   volume-scene value: the volume object identifier, the transfer
   table, the camera, the viewport and the quality token — the
   sampler validates the token against the declared table at render
   time, so the request carries it as supplied.
2. **The closed claims widen additively**: the render mode gains
   `volumeDirect` and the colour output gains `rgba8`, the four
   channels the compositor emits. No exhaustive switch exists over
   either vocabulary, so the widening is purely additive.
3. **The trilinear sample rule becomes the one public sampling
   entry.** The renderer needs the accepted `VOXELIA-ALG-0017`
   sample rule that lived internal to the oblique operation;
   restating it would fork the authority, so the operation's sample
   function becomes public with its documentation naming it the one
   sampling authority consumers compose.

## Alternatives considered

A package-access sampling entry was considered and declined: the
renderer precedent lives in the metal module, which is a separate
target the package keyword would serve, but the sampling rule is an
accepted public model and hiding a frozen registered rule behind
package access communicates less than the documentation naming it
the authority.

## Consequences

The renderer increment composes the vocabulary, the generator, the
sampler, the public sampling entry and the compositor.

## Affected modules

`VoxeliaRendering`, `VoxeliaExecution`.

## Compatibility impact

Two additive enum cases, one value type, one visibility widening.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

The rendering suite gains the request construction and the widened
claim cases; the execution suite's fixtures already pin the sampling
rule the visibility widening exposes.

## Migration

None.

## Supersession

Delivers the vocabulary half of accepted `ADR-0172`; no record is
superseded.

## References

- [ADR-0172 - Volume renderer design](ADR-0172-volume-renderer-design.md)
- [VOXELIA-ALG-0017 - Oblique slice sampling binary64-v1](../../algorithms/VOXELIA-ALG-0017-oblique-slice-sampling.md)
