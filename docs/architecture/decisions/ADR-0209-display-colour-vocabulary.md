---
document_id: "ADR-0209"
title: "Display colour vocabulary"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-ERR-001"
  - "VOX-R2D-015"
---

# ADR-0209 - Display colour vocabulary

## Context

`ADR-0208` decision 2(a) makes the colour vocabulary and the declared output
colour space the arc's first increment, serving the first half of
`VOX-R2D-015`: "Display colour transformation and output colour space shall be
explicit in render requests and provenance."

This record defines the vocabulary that every later increment publishes. Wiring
it into `RenderRequest` and `PresentationProvenance`, and closing the
requirement, is increment (f).

**A finding recorded now for increment (f):** `RenderRequest` today carries
`scene`, `viewport`, `crop`, `interpolation` and `quality` — and **no colour
claim of any kind**. `ColourOutputConfiguration` exists only on
`PresentationProvenance`, and the two renderers hard-code it (`greyscale8` in
the slice path, `rgba8` in the volume path). So the "explicit in render
requests" half of `VOX-R2D-015` is not merely undeclared, it is absent. That is
increment (f)'s work, not this record's, but it is written down here so the
scope is not rediscovered later.

## Decision

1. **This record freezes no numeric boundary, so it carries no algorithm
   specification and registers no oracle.** A vocabulary of declarations
   involves no arithmetic. This follows `ADR-0198`, which defined the surface
   scene vocabulary the same way, and `ADR-0208` decision 1, which requires an
   algorithm specification only where a numeric boundary is fixed. Evidence for
   this increment is its migration's tests.
2. **`DisplayColourSpace` is a namespaced declaration and grants no conversion
   authority.** It carries a `namespace`, a `code` and an optional
   `displayName`. It is modelled directly on `MeasurementUnit`, which pairs a
   namespace with a code and — in the `PoweredLengthUnit` precedent — is carried
   verbatim without ever being raised, scaled or combined. Declaring a colour
   space says what the output *is*, never how to turn it into another one.
3. **No conversion, gamma, primaries, white point or transfer characteristic is
   carried or applied.** `ADR-0208` decisions 4 and 9 bind this arc, and this
   record adds nothing to them. A conversion is a separate claim needing
   separate evidence, and calibration is out of scope entirely.
4. **Comparison is exact and byte-for-byte, with no case folding and no Unicode
   normalisation.** A code is an identifier drawn from an external namespace,
   and folding case would silently merge two distinct registry entries into one.
   Two declarations differing only in case are two declarations.
5. **The display name is excluded from equality.** It is human-readable text
   with no semantic weight, exactly as `MeasurementUnit` already treats it.
   Semantic identity is the namespace and the code.
6. **Absence means undeclared, and never a default.** The declaration is
   optional wherever it appears, and `nil` means *no claim has been made* — not
   sRGB, not "the usual one". `ADR-0208` decision 5 forbids inferring a space,
   because doing so would attach an unverified claim to every image the project
   has already published.
7. **`DisplayColourTransform` is a closed set naming the colour transform that
   actually produced an output, and it has exactly two cases today.**
   - `none` — the values are presented as produced, which is what the slice
     path does when it emits eight-bit greyscale.
   - `transferFunction` — an accepted one-dimensional transfer function mapped
     the values to colour, which is what the volume compositor does today under
     `VOXELIA-ALG-0023`.
   Both describe something that exists **now**. Carrying only `none` would force
   the volume renderer to declare that no colour transform ran while it
   demonstrably applies one, which would put a false claim into provenance.
8. **The set is widened additively by later increments, never rewritten.**
   Increment (c) adds the palette case and increment (d) the RGB case, following
   the way `ADR-0174` widened `ColourOutputConfiguration` and `RenderMode`
   rather than replacing them.
9. **The vocabulary lives in `VoxeliaRendering`.** Its only consumers are the
   render request and the presentation provenance, both of which already live
   there beside `ColourOutputConfiguration`. This is the `PoweredLengthUnit`
   placement decision — put a vocabulary with one consumer next to that
   consumer, not in a shared module on speculation. If a later increment gives
   an image descriptor a colour space, that increment moves it and records why.
10. **The failure family is exactly two payload-free cases**, `emptyNamespace`
    and `emptyCode`, mirroring `MeasurementUnitError`'s admission of the same
    two fields. There is no invalid-code case: this project does not hold a
    registry of colour-space codes, and pretending to validate against one
    would be a claim with no basis.
11. **No `Codable` conformance.** Persistence and content identity are separate
    governed contracts, as `TriangleMeshPositionDomain` records for the same
    reason. `Sendable` and `Hashable` are required, because
    `PresentationProvenance` is `Hashable` and increment (f) will carry the
    declaration inside it.

## Alternatives considered

### Define an enumeration of known colour spaces

Rejected. A closed enumeration would either be wrong the first time a real
namespace is needed, or would grow into an unmaintained registry the project
cannot attest. A namespaced code defers naming to whoever owns the namespace,
which is the same reason `MeasurementUnit` is not an enumeration of units.

### Fold case when comparing codes

Rejected; see decision 4.

### Default an absent declaration to sRGB

Rejected; see decision 6. It is the single most likely way for an unverified
colour claim to enter the project.

### Carry gamma, primaries and a white point on the declaration

Rejected; see decision 3. Those are the inputs to a conversion, and carrying
them would invite one to be written without a record.

### Ship only the `none` transform case now

Rejected; see decision 7. The volume path already applies a transfer function,
so a single-case set would make provenance lie about work that already happens.

### Put the vocabulary in `VoxeliaCore` or `VoxeliaSpatial`

Rejected for version one; see decision 9.

## Consequences

Later increments have a declaration to publish and a transform case to name.
Increment (f) can wire both into the request and the provenance and close
`VOX-R2D-015`, including the request-side gap this record documents.

The deliberate limitations are declaration only, no conversion, no registry
validation, no persistence, and no wiring into the request or provenance yet.

## Affected modules

Migration adds the vocabulary to `VoxeliaRendering`. No dependency edge changes.

## Compatibility impact

None. Nothing existing changes shape in this increment; the vocabulary is new
and unreferenced until increment (f).

## Security impact

Errors are payload-free and disclose no namespace or code content.

## Performance and memory impact

None beyond two small immutable values.

## Validation impact

No oracle, because no numeric boundary is frozen. The migration must prove the
two admissions, that equality is exact and case-sensitive, that the display name
is excluded from equality, and that both transform cases exist and are
payload-free. Documentation, register, index, link, manifest and
release-integrity checks apply.

## Migration

1. Add `DisplayColourSpace`, `DisplayColourTransform` and
   `DisplayColourSpaceError` to `VoxeliaRendering`.
2. `ADR-0208` increment (b) assesses VOI LUT application.

## Supersession

This record executes `ADR-0208` decision 2(a) and supersedes no accepted record.

## References

- [ADR-0085 - Render request, result and protocol](ADR-0085-render-request-result-and-protocol.md)
- [ADR-0174 - Volume render vocabulary](ADR-0174-volume-render-vocabulary.md)
- [ADR-0198 - Surface scene vocabulary](ADR-0198-surface-scene-vocabulary.md)
- [ADR-0203 - Surface colour map design](ADR-0203-surface-colour-map-design.md)
- [ADR-0208 - Colour and overlay arc](ADR-0208-colour-and-overlay-arc.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing](../../algorithms/VOXELIA-ALG-0023-front-to-back-compositing.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
