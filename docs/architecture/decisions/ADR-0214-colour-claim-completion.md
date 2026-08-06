---
document_id: "ADR-0214"
title: "Colour claim completion"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-ERR-001"
  - "VOX-R2D-002"
  - "VOX-R2D-015"
---

# ADR-0214 - Colour claim completion

## Context

`ADR-0208` decision 2(f) makes request and provenance completion the arc's last
increment, closing `VOX-R2D-015`: "Display colour transformation and output
colour space shall be explicit in render requests and provenance." The row
declares **I,T**, so it carries both an inspection and a test obligation and
this record must say which evidence discharges which.

`ADR-0209` recorded the gap this increment exists to close: `RenderRequest`
carries `scene`, `viewport`, `crop`, `interpolation` and `quality` and **no
colour claim of any kind**. `ColourOutputConfiguration` lives only on
`PresentationProvenance`, and both renderers hard-code it — `greyscale8` in the
slice path, `rgba8` in the volume path.

## Decision

1. **This record freezes no numeric boundary, so it carries no algorithm
   specification and registers no oracle.** Widening a vocabulary and wiring
   declarations through two value types involves no arithmetic. This is the
   `ADR-0198` and `ADR-0209` precedent. Evidence is this increment's tests.
2. **`RenderRequest` gains three fields**: the intended
   `ColourOutputConfiguration`, the intended `DisplayColourTransform`, and an
   optional `DisplayColourSpace`. Every one is passed explicitly at every call
   site; no default is supplied, following the house rule that a permissive
   default is a claim nobody made.
3. **`PresentationProvenance` gains two**: the `DisplayColourTransform` that
   actually ran and the `DisplayColourSpace` actually attested. It already
   carries `colourOutput`.
4. **`DisplayColourTransform` is widened additively with `palette` and `rgb`**,
   the two cases increments (c) and (d) built. The existing `none` and
   `transferFunction` cases are untouched, following the way `ADR-0174` widened
   the render mode rather than replacing it.
5. **A renderer that cannot produce the requested colour rejects it, typed.**
   This is what makes the request's claim mean anything: without a rejection, a
   renderer could silently ignore the request and still report a provenance that
   looked correct. The failure is `RenderModelError.unsupportedColourOutput`,
   added to the existing family rather than given a new one.
6. **Provenance reports what the renderer did, never what was asked.** This is
   `ADR-0100`'s accepted rule for `PresentationScaling`, applied to colour: each
   renderer constructs its own claim from its own knowledge. Because decision 5
   makes a mismatch impossible, the two agree on the success path — but they
   agree by construction, not by copying, and a future renderer that gains a
   second output mode inherits the right behaviour.
7. **The declared colour space is carried, never converted.** `ADR-0209`
   decision 2 and `ADR-0208` decision 4 already bind this: the declaration
   grants no conversion authority, and no renderer acquires one here.
8. **An absent colour space stays absent through the whole pipeline.** A
   request that declares none produces a provenance that declares none. No
   renderer substitutes a default, because `ADR-0208` decision 5 forbids
   inferring one.
9. **Only the two-dimensional request is widened.** `VOX-R2D-015` is a
   `VOX-R2D` row, so `RenderRequest` is the request it names.
   `VolumeRenderRequest` and `SurfaceRenderRequest` belong to other requirement
   families and are not widened on speculation; the volume renderer still
   constructs a complete provenance, declaring the `transferFunction` transform
   it genuinely applies.
10. **`VOX-R2D-015`'s two verification methods are discharged separately, and
    this record states which is which.** **Inspection** is discharged by this
    record plus `ADR-0209`: the vocabulary exists, it is carried in both the
    request and the provenance, it grants no conversion authority, and no
    implicit space is ever assumed. **Test** is discharged by the migration's
    suite: the fields are present and required at every call site, a renderer
    rejects a colour output it cannot produce, provenance reports what ran, and
    an absent declaration stays absent. Neither half stands in for the other.
11. **This is a cross-module layout change**, so the migration clean-rebuilds
    before final verification and greps the whole repository for every
    construction site rather than the obvious ones.

## Alternatives considered

### Give the new request fields defaults so existing call sites compile

Rejected; see decision 2. A default colour claim is a claim nobody made, and it
would let a call site that never considered colour appear to have declared one.

### Let a renderer ignore a colour output it cannot produce

Rejected; see decision 5. It would make the request's declaration decorative and
would let provenance report a colour the caller never got.

### Copy the request's colour claim into the provenance

Rejected; see decision 6. Provenance is an attestation, not an echo, and copying
is exactly how a future second output mode would start reporting the wrong
thing.

### Widen `VolumeRenderRequest` and `SurfaceRenderRequest` too

Rejected; see decision 9. Neither is the request `VOX-R2D-015` names, and
widening them would be speculative expansion into other requirement families.

### Default an absent colour space to the output configuration's implied space

Rejected; see decision 8. There is no implied space — that is the entire point
of `ADR-0208` decision 5.

## Consequences

`VOX-R2D-015` is discharged in both methods, and with it **the `ADR-0208`
colour and overlay arc closes**: `VOX-R2D-007`, `VOX-R2D-010`, `VOX-R2D-011` and
`VOX-R2D-015` are all complete.

M6 does **not** close: `VOX-MPR-011` remains unassessed, as `ADR-0208` recorded,
and the gated rows remain gated.

The deliberate limitations are the two-dimensional request only, no conversion
authority anywhere, and no colour space defaulting.

## Affected modules

`VoxeliaRendering` (the two value types and the vocabulary) and `VoxeliaMetal`
(both renderers' provenance construction and the slice renderer's admission).
No dependency edge changes.

## Compatibility impact

`RenderRequest` and `PresentationProvenance` gain required fields, so every
construction site changes. That is intended: a call site that cannot say what
colour it wants has not thought about it, and the compiler now asks.

## Security impact

Errors are payload-free and disclose no colour space content.

## Performance and memory impact

Two additional stored values per provenance and three per request.

## Validation impact

No oracle, because no numeric boundary is frozen. The migration must prove that
the request and provenance both carry the claim, that a renderer rejects a
colour output it cannot produce, that provenance reports what ran rather than
what was asked, that an absent colour space stays absent, and that the widened
transform set still has exactly the cases the arc built. A clean rebuild and the
full unfiltered suite are required before pushing.

## Migration

1. Widen the vocabulary and both value types, update every construction site,
   and add the renderer admission.
2. The arc closes. `VOX-MPR-011` needs its own assessment record.

## Supersession

This record executes `ADR-0208` decision 2(f) and supersedes no accepted record.
It composes `ADR-0100`'s provenance rule rather than restating it.

## References

- [ADR-0085 - Render request, result and protocol](ADR-0085-render-request-result-and-protocol.md)
- [ADR-0100 - Presentation scaling claim](ADR-0100-presentation-scaling-claim.md)
- [ADR-0174 - Volume render vocabulary](ADR-0174-volume-render-vocabulary.md)
- [ADR-0208 - Colour and overlay arc](ADR-0208-colour-and-overlay-arc.md)
- [ADR-0209 - Display colour vocabulary](ADR-0209-display-colour-vocabulary.md)
- [ADR-0213 - Overlay compositing design](ADR-0213-overlay-compositing-design.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
