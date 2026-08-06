---
document_id: "ADR-0281"
title: "Singular transform typed errors"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SPA-009"
---

# ADR-0281 - Singular transform typed errors

## Context

`VOX-SPA-009` requires that "singular or non-invertible transforms shall produce typed
errors". P0, `T`, milestone M1.

`ADR-0280` assessed it as **implemented but untraced** and made it this arc's first
increment deliberately — the cheapest real discharge available, and a check that the
assessment holds before larger work depends on it.

## What already existed

Three typed errors across three layers, each thrown on a determinant magnitude below
`Double.leastNormalMagnitude`:

- `AffineSpatialInverseError.singularMatrix` (`VoxeliaSpatial`, `ALG-0016`),
- `SpatialGeometryError.singularTransform` (`VoxeliaSpatial`),
- `CTVolumeConstructionError.singularTransform` (`VoxeliaImaging`).

All three were already tested. **None carried this row's tag**, which is why a mechanical
sweep for untouched requirements found it.

**Every threshold is the same and none is an epsilon.** `Double.leastNormalMagnitude`
appears in all three admissions and nowhere is a tolerance introduced, which matches the
project's no-epsilon rule rather than merely happening to agree with it.

## The claim nobody had checked

`AffineWorldToIndexMap.init` documents its own `singularMatrix` throw as **"unreachable
for a validated geometry whose own admission computes the identical frozen determinant"**.

That rests on two separately written expressions agreeing bit-for-bit:

- `SpatialGeometry` computes `m0 * (m5*m10 − m6*m9) − m1 * (m4*m10 − m6*m8) + m2 * (m4*m9 − m5*m8)`.
- `AffineSpatialInverse` computes `((m0 * c0) − (m1 * c1)) + (m2 * c2)` over the same
  three cofactors.

They *are* the same order — Swift's left-associative `a − b + c` is `(a − b) + c` — but
nothing verified it, and a divergence would mean a geometry admitted by one layer is
refused by the next, firing a branch documented as unreachable.

## The verification

Both admissions were run over eight boundary cases and required to agree. Determinants
computed independently:

| Case | Determinant | Admitted |
|---|---:|:---:|
| identity | `1` | yes |
| exactly at the threshold | `2.2250738585072014e-308` | yes |
| one ulp below the threshold | `2.2250738585072009e-308` | **no** |
| exactly zero | `0` | **no** |
| subnormal factor | `4.9406564584124654e-324` | **no** |
| **underflowing product** | `5.5626846462680035e-309` | **no** |
| near-cancelling cofactors | `-7.1054273576010019e-15` | yes |
| rank deficient | `0` | **no** |

**Three admitted, five refused, and the two layers agreed on every one.**

Two cases earn their place:

- **The underflowing product.** `diag(tiny, 0.5, 0.5)` has no factor that is zero or
  subnormal, yet their product falls below the threshold. It is the case
  `CTAffineVolumeBuilder`'s own comment anticipates — spacing values that individually
  look ordinary and "make the determinant underflow".
- **Near-cancelling cofactors**, at `-7.1e-15`, is small enough that a different summation
  order would be visible in the result while still admitting. It is the case that would
  catch a divergence in expression order rather than in magnitude.

**Non-vacuity is asserted, not assumed.** The test requires at least one admitted and at
least one refused case, because a set that all fell the same way would make "the two
agree" true and empty. This follows `ADR-0249` stage three's lesson.

## Decision

1. **`VOX-SPA-009` is discharged.** Five tests carry the row: the typed error on a zeroed
   axis, on a geometry, on a rank-deficient block with no zero on its diagonal, the
   cross-layer agreement, and the exact threshold from both sides.
2. **The layering claim is now verified rather than asserted**, in the falsifiable form
   that needs no determinant to be exposed: the two admissions must never disagree.
3. **A rank-deficient case is included alongside the zeroed ones**, because "singular" and
   "has a zero on the diagonal" are not the same thing, and a test using only the second
   would pass against an implementation that checked for zeros rather than computing a
   determinant.
4. **The threshold is asserted from both sides** — the value itself admits and one ulp
   below refuses — which is what makes it a boundary test rather than a smoke test. The
   admitted case also asserts `determinant == tiny` exactly, so the value is checked, not
   just the outcome.
5. **No source changed and none needed to.** `ADR-0280`'s assessment said this row needed
   a test rather than code, and that held.
6. **No algorithm specification and no oracle.** `ALG-0016` already specifies the
   determinant; this verifies a consistency property between two of its consumers.

## Alternatives considered

### Add the row's tag to the existing tests and stop

Rejected. It would have been honest for the typed errors themselves — they were genuinely
tested — but it would have left the layering claim unverified, and that claim is what lets
a production path call a throw unreachable. The row's discharge was the occasion to check
it, not the reason to skip it.

### Expose the geometry's determinant so the two can be compared numerically

Rejected. It would widen an accepted public surface to serve a test, and the property that
matters is the agreement of the two *admissions*, which is observable without it.

### Test only the zeroed-axis cases

Rejected; see decision 3. A determinant check and a zero-scan behave identically on those
inputs, so the test would not distinguish them.

### Also tag `CTVolumeConstructionError.singularTransform`'s existing test

Deferred rather than rejected. It is a third typed error for the same class of input and
belongs to the imaging layer's own admission; tagging it would spread this row across two
test targets without adding evidence. Recorded so a later reader knows the third path
exists and was considered.

## Consequences

`VOX-SPA-009` is discharged, and `ADR-0280`'s assessment is confirmed by the increment it
predicted would be cheap.

A documented "unreachable" branch is now backed by a test rather than by reading two
expressions and judging them the same.

**The affine arc's remaining work is unchanged**: composition, vector transformation and
normal transformation, each needing an ADR, a `VOXELIA-ALG` specification and an
independent oracle before implementation — then the surface-shading correction
`ADR-0280` quantified.

## Affected modules

None. `VoxeliaSpatialTests` gains one suite of five tests; no source changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift build && swift test
swift test --filter "SingularTransformTypedError"
swift format lint --strict Tests/VoxeliaSpatialTests/SingularTransformTypedErrorTests.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1134 tests in 205 suites pass.

## Migration

1. This record and its tests.
2. **Next**: the affine design increment — an ADR and a `VOXELIA-ALG` specification with an
   independent Python oracle for composition, vector transformation and normal
   transformation, under `ADR-0280` decision 3's constraint that no existing consumer's
   bits change.
3. Then the surface-shading correction.
4. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **discharges `VOX-SPA-009`** and **verifies an
unreachability claim** in `AffineWorldToIndexMap`'s documentation that no test had checked.

## References

- [ADR-0136 - Affine inverse design](ADR-0136-affine-inverse-design.md)
- [ADR-0138 - World to index mapping](ADR-0138-world-to-index-mapping.md)
- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [ADR-0280 - Open the affine transform arc](ADR-0280-open-the-affine-transform-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
