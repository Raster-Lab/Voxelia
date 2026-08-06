---
document_id: "ADR-0202"
title: "Surface shading design"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-ERR-001"
  - "VOX-NUM-001"
  - "VOX-GEO-009"
  - "VOX-SUR-004"
---

# ADR-0202 - Surface shading design

## Context

`ADR-0197` decision 4(e) makes vertex normals and diagnostic materials the
arc's fifth increment, governed by `VOX-SUR-004`: "Surface rendering shall
support vertex normals and physically based or validated diagnostic
materials." That decision already recorded that a validated diagnostic material
is in scope and a physically based model is **not** pre-committed, because the
requirement's own wording permits either.

`ADR-0193` supplies deterministic vertex normals. `ALG-0034` and `ALG-0035`
supply barycentric weights per fragment. This increment joins them.

Implementing against those weights surfaced a defect in the accepted contract.
`ALG-0034` canonicalises a facet's winding by swapping its second and third
vertices whenever the projection mirrored it, and publishes weights in that
canonicalised order. `ADR-0200` decision 7 documented the hazard —
"a consumer that ignored the swap would mis-attribute attributes" — but the
published fragment records **no** swap flag, so a consumer cannot tell whether
it occurred. The hazard was named without publishing the datum needed to avoid
it. Shading is the first consumer of those weights, so it is the first place
the gap could be found.

## Decision

1. **The swap is published.** `SurfaceHit` and `SurfaceFragment` gain a flag
   recording whether the coverage rule exchanged the second and third
   vertices. This is additive and changes **no** registered `ALG-0034` or
   `ALG-0035` digest, because neither digest covers the flag: the fixture
   records pack layer, facet and depth, and the byte payloads pack depths and
   weights. The accepted records are left unedited and this decision is the
   correction of record, following the pattern used for `ADR-0194` decision
   13, `ADR-0195` decision 17 and `ADR-0200` decision 10.
2. **Consumers receive weights mapped back to original vertex order.** The
   canonicalisation stays an internal detail of the coverage rule, and the
   published flag is what makes the mapping recoverable. `ALG-0036` registers
   a `mis-mapped-weights` fixture proving the correspondence is observable, so
   a future implementation that got it wrong fails a test rather than
   producing subtly wrong shading on mirrored facets.
3. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0036` defines `surface-diagnostic-shading/binary64-v1`.
4. **The material is a two-sided Lambert headlight**, and both halves of that
   are deliberate. The light is a headlight at the camera, so there is no
   light position, colour or falloff to settle. The intensity is the
   **absolute** value of the normal-forward projection, which makes the
   material two-sided — and that is required, not convenient: extraction
   publishes open surfaces, `ALG-0034` deliberately does not cull back faces,
   and a one-sided `max(0, N·L)` would render the interior of every open
   surface black, hiding geometry a diagnostic reader needs.
5. **The output is a scalar intensity in `[0, 1]`; colour is deferred.** A
   colour representation forces channel-count, colour-space and
   premultiplication decisions that the scalar-colour-map increment must settle
   regardless. Making them here would risk that increment contradicting this
   one. This is the same factoring that let `ADR-0201` freeze compositing
   weights without colour, applied again.
6. **A mesh without a built-in normal attribute is rejected typed.** Falling
   back to a facet normal would give two meshes differing only in whether they
   carry normals two different shadings, and `ADR-0193` already provides an
   accepted operation to generate them. The caller runs that first.
7. **An undefined interpolated direction yields positive zero, not a
   failure.** Exactly cancelling normals leave a zero vector. This
   deliberately differs from `ADR-0193`, which rejects an undefined
   **published** normal: that is authoritative geometry, this is presentation,
   and failing an entire render because one sample's normals cancelled would be
   disproportionate. The contrast is recorded in both documents so it does not
   read as an inconsistency.
8. **The clamp to one is exact and reachable, not defensive.** Rounding in the
   renormalisation and the dot product can carry the magnitude above one even
   for a unit normal against itself; the registered fixture evaluates
   `1.0000000000000002`. An intensity above one is meaningless for
   presentation, and `min` with an exactly representable one is not an epsilon.
9. **Interpolation can lose a direction that normalisation would have kept.**
   A least-subnormal normal weighted by one third underflows to exactly zero.
   `ALG-0036` registers this as its own fixture, and registers the same normal
   at full weight surviving, so the two behaviours are distinguishable evidence
   rather than one blurred claim.
10. **There is no representability failure.** Every input is a unit normal or a
    barycentric weight, every intermediate is bounded, and the clamped output
    lies in `[0, 1]`. The failure family is exactly `normalsMissing` and
    `cancelled`, both reachable.
11. **Cancellation is checked before fragment zero and every fragment ordinal
    divisible by 4,096**, matching the per-sample cadence the projector uses.
12. **This stage publishes nothing** — no colour, no image, no identity, no
    provenance.

## Alternatives considered

### Leave the canonicalisation swap unpublished and document it harder

Rejected. `ADR-0200` already documented it, and documentation did not make it
recoverable. A hazard a consumer cannot detect is a defect, not a caveat.

### Republish weights in original order instead of adding a flag

Rejected. It would change the weight bytes for mirrored facets and therefore
change `ALG-0034`'s registered buffer digest, editing an accepted frozen
record. The additive flag reaches the same outcome for consumers while leaving
every registered digest intact.

### Adopt a physically based material

Rejected for version one, as `ADR-0197` decision 4(e) anticipated. It brings a
BRDF, an illumination model, tone mapping and colour-space obligations, none of
which any accepted record supplies, and a diagnostic viewer does not need them
to be correct.

### Use a one-sided Lambert with backface culling

Rejected; see decision 4. It would contradict `ALG-0034`'s deliberate decision
not to cull, and would hide the interior of open extracted surfaces.

### Add ambient or specular terms

Rejected for version one. Each adds a parameter whose value would be an
invented default, and neither is needed for a surface to be legible.

### Produce colour here

Rejected; see decision 5.

### Fail the render on an undefined interpolated normal

Rejected; see decision 7.

### Skip the clamp because the magnitude "should" be at most one

Rejected. The registered fixture shows it is not, and an unclamped intensity
above one would propagate into whatever colour model consumes it.

## Consequences

The next migration can implement one bounded, stateless, bit-exact CPU
reference with no remaining choice about interpolation, renormalisation,
lighting, two-sidedness, clamping, undefined directions or failure.
`VOX-SUR-004`'s diagnostic half becomes dischargeable.

The deliberate limitations are no colour, no ambient or specular term, one
fixed headlight, and no physically based model.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds the swap flag to the existing fragment and hit values and the
shading reference to `VoxeliaRendering`. No dependency edge changes.

## Compatibility impact

The swap flag is additive on internal values and changes no registered digest.
A physically based material would be a new algorithm identity.

## Security impact

No allocation beyond one intensity per fragment; traversal is cancellable;
errors are payload-free and disclose no normals, weights or scene contents.

## Performance and memory impact

`O(1)` per fragment. No benchmark or throughput claim is made.

## Validation impact

The oracle registers:

```text
fixtureSHA256=a1f8fd3ff7933c12bcd269b94c05d2919fb78801bf99fabf15dc29b7f0514330
intensitySHA256=c9dfc8df1e26cf1c4ebff61561fbc9c030290ecd426d79e72193fdb54c22cd37
fixtures=14 successful=14 failures=0
```

Migration must reproduce all fourteen fixtures bit-exactly, prove the swap flag
is set exactly when the coverage rule exchanged vertices, prove the
`ALG-0034` and `ALG-0035` digests still match after the additive change, and
prove the cancellation cadence. This design increment requires oracle
reproduction, documentation, register, index, link, manifest and
release-integrity checks; product builds and tests are not evidence for a
documentation-only change. It discharges the **Test** half of `VOX-SUR-004`'s
verification methods only; no demonstration is claimed.

## Migration

1. Add the swap flag to `SurfaceHit` and `SurfaceFragment`, re-running the
   `ALG-0034` and `ALG-0035` oracle tests to prove both digests are unchanged.
2. Add the shading reference to `VoxeliaRendering` with every fixture from
   `ALG-0036`.
3. `ADR-0197` increment (f) freezes scalar colour maps, which must settle the
   colour representation this record deferred.

## Supersession

This record executes `ADR-0197` decision 4(e) and supersedes no accepted
record. It corrects an omission in `ADR-0200` decision 7 additively.

## References

- [ADR-0193 - Deterministic triangle-mesh vertex normals design](ADR-0193-deterministic-triangle-mesh-vertex-normals-design.md)
- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [ADR-0200 - Surface visibility design](ADR-0200-surface-visibility-design.md)
- [ADR-0201 - Surface compositing design](ADR-0201-surface-compositing-design.md)
- [VOXELIA-ALG-0034 - Surface visibility resolution](../../algorithms/VOXELIA-ALG-0034-surface-visibility-resolution.md)
- [VOXELIA-ALG-0036 - Surface diagnostic shading](../../algorithms/VOXELIA-ALG-0036-surface-diagnostic-shading.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
