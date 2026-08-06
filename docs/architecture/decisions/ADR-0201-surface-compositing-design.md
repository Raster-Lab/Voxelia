---
document_id: "ADR-0201"
title: "Surface compositing design"
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
  - "VOX-SEC-001"
  - "VOX-SUR-003"
---

# ADR-0201 - Surface compositing design

## Context

`ADR-0197` decision 4(d) makes per-object opacity and surface compositing the
arc's fourth increment, governed by `VOX-SUR-003`: "Surface rendering shall
support per-object opacity." That decision already named one obligation:
`VOXELIA-ALG-0023`'s front-to-back rule is per-sample along one ray and "does
not settle ordering between distinct objects; that ordering must be frozen
explicitly."

The `ADR-0200` migration surfaced a second, structural obligation that the arc
opening had not anticipated. `VOXELIA-ALG-0034` retains only the **single
nearest** facet per pixel. That is exactly right for an opaque scene, and it is
what an authoritative picking contract will want — but it cannot express
transparency at all, because a transparent surface requires knowing what is
behind it. Compositing therefore cannot simply consume the visibility buffer.

`SurfaceLayer` already carries a validated per-object opacity in `[0, 1]`, so
the input vocabulary needs no change.

## Decision

1. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0035` defines `surface-opacity-compositing/binary64-v1`.
2. **This increment retains all covering fragments, not just the nearest.**
   It reuses `ALG-0034`'s coverage, canonicalisation and fill rules unchanged
   and differs only in retention. A fragment carries the depth, barycentric
   weights, layer index and facet ordinal `ALG-0034` already defines, plus its
   layer's opacity.
3. **`ALG-0034` is not superseded.** Its nearest-only buffer stays correct and
   is strictly cheaper whenever every layer is fully opaque, and it is the
   natural input for picking. Two retention policies over one coverage rule is
   the honest shape here; replacing the nearest-only buffer with a fragment
   list would impose transparency's cost on every opaque render.
4. **The order is the strict total order `(depth, layerIndex, facetOrdinal)`.**
   This closes the obligation `ADR-0197` named. It can never tie, because one
   facet covers a pixel at most once, so `(layerIndex, facetOrdinal)` is unique
   among a pixel's fragments. No secondary rule and no arbitrary winner exist.
5. **The order is deliberately consistent with `ALG-0034`'s.** That record's
   strict-less comparison keeps the earlier `(layer, facet)` at equal depth, and
   this order sorts the same way. An opaque scene composited by this model
   therefore selects exactly the fragment the visibility resolver would have
   selected — the two contracts cannot disagree.
6. **Colour is absent by construction, and that is the increment's key
   separation.** A fragment's contribution weight is fixed by opacity and order
   alone. This model emits one weight per fragment plus the accumulated alpha;
   shading and colour mapping multiply colours into those weights later without
   changing them. It is what allows compositing to be frozen and evidenced
   before any material or colour-map contract exists, and it keeps `VOX-SUR-003`
   from being blocked behind `VOX-SUR-004` and `VOX-SUR-005`.
7. **Front-to-back accumulation is stated, not referenced as an operation.**
   The three ordered steps — `remaining`, `contribution`, accumulate — compose
   `ALG-0023`'s principle, but `ALG-0023` orders samples along a single ray by
   construction and never decides between distinct objects. Stating the rule in
   its new domain is honest; invoking `ALG-0023` as though it already covered
   this case would overstate what it settles.
8. **Occlusion falls out of the accumulation rather than being a case.** A
   fully opaque fragment drives `accumulatedAlpha` to exactly one, so every
   later `remaining` is exactly zero and every later contribution is exactly
   zero. There is no occlusion branch to get wrong.
9. **Early termination is explicitly permitted because it is bit-identical.**
   An implementation may stop once the accumulator equals one, since the
   remaining contributions are exactly positive zero. Permitting it in the
   record prevents a future implementer from adding it as an unrecorded
   optimisation, and prevents a reviewer from treating it as a divergence.
10. **A zero-opacity fragment is retained and weighs exactly zero.** Dropping it
    would make the published fragment list depend on a presentation parameter,
    so a caller could not reason about coverage independently of appearance.
11. **There is no representability failure, and that is proven rather than
    assumed.** `SurfaceLayer` admits only a finite opacity in `[0, 1]` and the
    accumulator starts at zero, so every intermediate lies in `[0, 1]`:
    infinity is unreachable and NaN would require `0 * infinity` or
    `infinity - infinity`. The registered `long-chain` fixture composites
    twenty-four fragments and asserts at every step that the accumulator never
    exceeds one. Carrying an unreachable failure case would be an error with no
    possible evidence.
12. **The failure family is exactly two cases** — `resourceLimitExceeded` and
    `cancelled` — payload-free, `Sendable` and `Equatable`, both reachable.
13. **The retained-fragment ceiling is genuinely necessary and differs in kind
    from `ALG-0034`'s.** The visibility buffer is bounded by the viewport
    alone; a fragment list is bounded by scene depth complexity, which no
    viewport bound constrains. A scene of one thousand overlapping layers
    retains one thousand fragments per covered pixel. The migration declares an
    explicit checked ceiling over the retained payload, and — learning from the
    `ADR-0200` decision 10 error — this record states plainly that the ceiling
    implies its rejection case, which is why the family has two cases and not
    one.
14. **Cancellation is checked before facet zero and every facet ordinal
    divisible by 64 during retention**, matching `ALG-0034`, **and before pixel
    zero and every pixel ordinal divisible by 4,096 during accumulation**,
    matching the per-pixel cadence the projector uses.
15. **This stage publishes nothing** — no colour, no image, no identity, no
    provenance.
16. **Independent analytical evidence is registered now.** The standard-library
    Python oracle records twelve fixtures whose two SHA-256 digests are frozen
    in `ALG-0035`.

## Alternatives considered

### Composite directly from the nearest-only visibility buffer

Rejected: it cannot express transparency, because a transparent surface needs
what is behind it, and `VOX-SUR-003` is a P0 requirement. This was the
structural finding that shaped the increment.

### Replace the nearest-only buffer with a fragment list everywhere

Rejected. It would impose transparency's retention cost on every opaque render
and on picking, both of which need only the nearest facet. Two retention
policies over one shared coverage rule is cheaper and states each purpose
plainly.

### Defer transparency and support only fully opaque objects

Rejected. `VOX-SUR-003` is P0 and says per-object opacity, not per-object
visibility. Shipping opaque-only and calling the requirement discharged would
overstate what was built.

### Order fragments by depth alone

Rejected. Coplanar and exactly-equidistant fragments are common in extracted
geometry, and depth alone leaves their order to the sort's stability — an
implementation detail, not a contract. Extending to the full triple costs
nothing and makes ties impossible.

### Order by layer first, then depth

Rejected. It would make a farther object composite over a nearer one whenever
it came first in the scene, which is not what front-to-back means and would
make the result depend on scene authoring order rather than geometry.

### Include colour in this model

Rejected; see decision 6. It would block a P0 requirement behind two P1 ones
and would force a premultiplied-versus-straight colour decision, a colour-space
decision and a material decision into a record about opacity.

### Use an order-independent transparency approximation

Rejected. Every such scheme is an approximation whose result depends on
weighting heuristics, and the arc's binding rule is that determinism is
structural. An accelerated backend may use one only by registering a separately
accepted approximation, exactly as the measurement records require.

### Carry a representability failure case for symmetry

Rejected; see decision 11.

## Consequences

The next migration can implement one bounded, stateless, bit-exact CPU
reference with no remaining choice about retention, ordering, blending,
occlusion, zero opacity or failure. `VOX-SUR-003` becomes dischargeable without
waiting on the material or colour-map contracts.

The deliberate limitations are that no colour is produced, that the fragment
list is retained in full rather than approximated, and that order-independent
transparency is unavailable.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds fragment retention and the compositing reference to
`VoxeliaRendering`. No dependency edge changes.

## Compatibility impact

None in this design-only increment. `ALG-0034` and its resolver are unchanged.

## Security impact

Retained payload is bounded by an explicit checked ceiling; both retention and
accumulation are cancellable; errors are payload-free and disclose no depths,
opacities, counts or scene contents.

## Performance and memory impact

`O(f log f)` per pixel for ordering plus `O(f)` accumulation, and one record
per retained fragment. The opaque fast path remains available through
`ALG-0034`'s cheaper buffer, and early termination is permitted where it is
bit-identical.

## Validation impact

The oracle registers:

```text
fixtureSHA256=43c71d094dcf0cb932d9789c6f5f8fafa254bb715ccf73d65111ef1c58611dc5
weightSHA256=860a28e69c4b797acaad62fb311a7ad60df96973eb8aa8a1773fd7fcd56a91d0
fixtures=12 successful=12 failures=0
```

Migration must reproduce all twelve fixtures bit-exactly, prove the total order
by depth, layer and facet, the retention of zero-opacity fragments, the
exactly-zero post-saturation weights, the checked ceiling and both cancellation
cadences. This design increment requires oracle reproduction, documentation,
register, index, link, manifest and release-integrity checks; product builds
and tests are not evidence for a documentation-only change. It discharges the
**Test** half of `VOX-SUR-003`'s verification methods only; no demonstration is
claimed.

## Migration

1. Add fragment retention and the compositing reference to `VoxeliaRendering`
   with an explicit checked ceiling and every fixture from `ALG-0035`.
2. `ADR-0197` increment (e) freezes vertex normals and diagnostic materials,
   which supply the colours these weights multiply.

## Supersession

This record executes `ADR-0197` decision 4(d) and supersedes no accepted
record. It explicitly does not supersede `VOXELIA-ALG-0034`.

## References

- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [ADR-0198 - Surface scene vocabulary](ADR-0198-surface-scene-vocabulary.md)
- [ADR-0200 - Surface visibility design](ADR-0200-surface-visibility-design.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing](../../algorithms/VOXELIA-ALG-0023-front-to-back-compositing.md)
- [VOXELIA-ALG-0034 - Surface visibility resolution](../../algorithms/VOXELIA-ALG-0034-surface-visibility-resolution.md)
- [VOXELIA-ALG-0035 - Surface per-object opacity compositing](../../algorithms/VOXELIA-ALG-0035-surface-opacity-compositing.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
