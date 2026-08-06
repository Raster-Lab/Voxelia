---
document_id: "ADR-0203"
title: "Surface colour map design"
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
  - "VOX-GEO-004"
  - "VOX-SUR-003"
  - "VOX-SUR-005"
---

# ADR-0203 - Surface colour map design

## Context

`ADR-0197` decision 4(f) makes scalar colour maps the arc's sixth increment,
governed by `VOX-SUR-005`: "Surface rendering shall support scalar colour maps
where geometry carries scalar attributes."

This increment also carries a debt. `ADR-0201` produced compositing weights
without colour and `ADR-0202` produced a shading intensity without colour, each
deferring the colour representation here on the stated grounds that this
increment must settle it regardless. That deferral is only legitimate if the
question is actually answered now.

Investigating it produced a better answer than expected: **the representation
is already settled by accepted records**, so the deferral resolves to
composition rather than invention.

- `TransferFunctionEntry` (`ADR-0083`) is four `UInt8` channels — red, green,
  blue, opacity.
- `VOXELIA-ALG-0023` normalises each by exactly `/ 255.0`.
- Colour is **straight, not premultiplied**, which `ALG-0023` demonstrates
  structurally: it multiplies an entry's colour by the accumulation weight at
  composite time, and that is only correct for unpremultiplied colour.
- `ColourOutputConfiguration.rgba8` (`ADR-0085`) is the accepted output shape.
- `ALG-0023` already has a **shaded** variant whose rule is
  `(component * factor) / 255` with opacity explicitly never modulated —
  precisely the shape `ADR-0202`'s intensity fits.

The surface arc's colour pipeline is therefore structurally the same as the
volume arc's, and the honest move is to compose it rather than restate it.

## Decision

1. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0037` defines `surface-scalar-colour-map/binary64-v1`.
2. **The colour representation is composed from accepted records**, as set out
   above: four `UInt8` channels, `/ 255.0` normalisation, straight
   (non-premultiplied) colour, `rgba8` output. The deferrals in `ADR-0201` and
   `ADR-0202` are discharged by this decision.
3. **No colour space is declared, and that is stated rather than left
   silent.** No accepted record declares one, the channels are the supplied
   table's own values, and inventing a colour space here would bind every
   consumer to a claim this project has not made. Colour-space interchange is
   a separate contract.
4. **Entry selection is nearest-entry with round-half-away-from-zero**,
   reusing the rule `VOXELIA-ALG-0026` accepted rather than inventing a
   rounding convention. Interpolated table lookup is a different algorithm
   identity and is not version one.
5. **Out-of-domain scalars clamp, and the clamp is what makes the mapping
   total.** A value below the minimum yields a negative index that clamps to
   the first entry; above the maximum clamps to the last. There is deliberately
   no out-of-domain branch and no out-of-domain failure, because a clamped
   lookup is well defined and rejecting would make a legitimate scene
   unrenderable.
6. **A degenerate domain is rejected typed.** `minimum` must be strictly less
   than `maximum`; equality would divide by zero. This is admission, not
   arithmetic, and it is checked once per request rather than once per
   fragment.
7. **A non-finite interpolated scalar is rejected typed.** Unlike positions,
   which `TriangleMesh` admits finite, a vertex attribute is raw bytes with no
   accepted finiteness guarantee, so this check is real rather than defensive.
8. **Shading modulates colour and never opacity**, composing `ALG-0023`'s
   accepted shaded rule verbatim. This is the property that makes shading a
   lighting effect rather than a transparency effect: a fully shadowed surface
   is black but still occludes what is behind it. The registered
   `zero-intensity-keeps-opacity` fixture proves it.
9. **Per-object and per-value opacity compose by multiplication**, in that
   order. `VOX-SUR-003`'s layer opacity and the table entry's own opacity are
   different things and both are real; multiplying is the only composition that
   preserves each one's meaning. `VOXELIA-ALG-0035` takes the product as the
   fragment opacity it weighs, so the two records compose rather than compete.
10. **The failure family is exactly four cases** — `invalidDomain`,
    `invalidTable`, `scalarNotRepresentable` and `cancelled` — payload-free,
    `Sendable` and `Equatable`, all reachable. Overflow is unreachable: the
    scalar is admitted finite, the span is a difference of finite values with a
    strict inequality, and every colour operand is a `UInt8` over 255.
11. **Admission precedence puts per-request checks before per-fragment ones**,
    so a caller with a bad domain or table learns once rather than once per
    pixel.
12. **This stage publishes nothing** — no image, no identity, no provenance.
13. **Independent analytical evidence is registered now.** Sixteen fixtures,
    thirteen successful and three failures, with two SHA-256 digests frozen in
    `ALG-0037`.

## Alternatives considered

### Invent a colour representation for the surface arc

Rejected, and the investigation is the reason. `ADR-0083`, `ADR-0085` and
`ALG-0023` already settle channels, normalisation, premultiplication and output
shape. Inventing a second representation would have created two colour models
in one renderer and made the volume and surface paths gratuitously
incompatible.

### Declare a colour space

Rejected; see decision 3. Declaring one would be a claim no accepted record
supports and would bind consumers to it.

### Interpolate between table entries

Rejected for version one. It is a different algorithm identity with its own
endpoint and rounding rules, and nearest-entry is what `ALG-0026` already
establishes as this project's lookup convention. A future record may add it.

### Reject out-of-domain scalars

Rejected; see decision 5. Clamping is well defined, and rejecting would make a
scene unrenderable because one vertex sat outside a caller-chosen window.

### Let shading modulate opacity too

Rejected. It would make a shadowed surface transparent, so geometry would
disappear where it is unlit — and it would contradict `ALG-0023`'s accepted
shaded rule, which the volume path already relies on.

### Replace layer opacity with entry opacity, or ignore one of them

Rejected. Both are real and requirement-backed: `VOX-SUR-003` mandates
per-object opacity and the transfer function carries per-value opacity.
Dropping either would silently discard a caller's stated intent.

## Consequences

The next migration can implement one bounded, stateless, bit-exact CPU
reference with no remaining choice about representation, selection, clamping,
modulation, opacity composition or failure. `VOX-SUR-005` becomes
dischargeable, and the colour deferrals `ADR-0201` and `ADR-0202` recorded are
closed.

The deliberate limitations are nearest-entry lookup only, no colour space, no
interpolated lookup and no per-vertex colour attribute.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds the colour-map reference to `VoxeliaRendering`, composing the
accepted `TransferFunction1D`. No dependency edge changes.

## Compatibility impact

None in this design-only increment. Interpolated lookup or a declared colour
space would each be a new algorithm identity.

## Security impact

No allocation beyond one colour per fragment; traversal is cancellable; errors
are payload-free and disclose no scalars, domains, table contents or scene
data.

## Performance and memory impact

`O(1)` per fragment. No benchmark or throughput claim is made.

## Validation impact

The oracle registers:

```text
fixtureSHA256=1c6b807ea1bc930d00398946db2342476258c799732aeb81492fbd00fe62a63f
colourSHA256=0337dbc24117ac54e875c838ef2703d7813917eefc43ff24f59edaacfd72d506
fixtures=16 successful=13 failures=3
```

Migration must reproduce all sixteen fixtures bit-exactly, prove the clamp at
both ends, prove that zero intensity leaves opacity intact, prove the
layer-times-entry opacity product, and prove the admission precedence and
cancellation cadence. This design increment requires oracle reproduction,
documentation, register, index, link, manifest and release-integrity checks. It
discharges the **Test** half of `VOX-SUR-005`'s verification methods only; no
demonstration is claimed.

## Migration

1. Add the colour-map reference to `VoxeliaRendering` with every fixture from
   `ALG-0037`.
2. `ADR-0197` increment (g) freezes clipping and section views.

## Supersession

This record executes `ADR-0197` decision 4(f) and discharges the colour
deferrals recorded by `ADR-0201` and `ADR-0202`. It supersedes no accepted
record.

## References

- [ADR-0083 - Rendering transfer function](ADR-0083-rendering-transfer-function.md)
- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [ADR-0201 - Surface compositing design](ADR-0201-surface-compositing-design.md)
- [ADR-0202 - Surface shading design](ADR-0202-surface-shading-design.md)
- [VOXELIA-ALG-0023 - Front-to-back compositing](../../algorithms/VOXELIA-ALG-0023-front-to-back-compositing.md)
- [VOXELIA-ALG-0026 - Segmentation mask sampling](../../algorithms/VOXELIA-ALG-0026-segmentation-mask-sampling.md)
- [VOXELIA-ALG-0037 - Surface scalar colour map](../../algorithms/VOXELIA-ALG-0037-surface-scalar-colour-map.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
