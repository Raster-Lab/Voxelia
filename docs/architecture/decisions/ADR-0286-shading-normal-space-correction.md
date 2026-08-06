---
document_id: "ADR-0286"
title: "Shading normal space correction"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SUR-004"
  - "VOX-SPA-008"
---

# ADR-0286 - Shading normal space correction

## Context

`ADR-0285` designed the correction for the defect `ADR-0280` found: `VOXELIA-ALG-0033`
transforms vertex positions into world space while `VOXELIA-ALG-0036` reads object-space
normals and dots them against a world-space forward, with nothing transforming the normal
between. This is the migration increment.

## Decision

1. **`SurfaceNormalTransform` is a new file, and nothing existing changed.**
   `SurfaceShader` keeps its reader, its arithmetic and its `normalsMissing` rejection.
   `ADR-0202` and `VOXELIA-ALG-0036` are unedited, as `ADR-0285` decision 6 required.
2. **The four things `ADR-0285` asked the implementation to show are shown**:
   - `ADR-0280`'s measurement as a test — under a pure rotation the uncorrected path gives
     `1.0` and the corrected path `0.0`, a difference of exactly `1.0`;
   - the normalisation-order divergence, asserted above `0.29` of the full range;
   - `ALG-0036`'s own suites passing unchanged — 17 tests across the five surface suites;
   - the identity transform leaving world normals **exactly equal** to the object ones,
     which is what makes "nothing existing changes" checkable rather than claimed.
3. **The inverse is hoisted, and the hoisting shares one traversal.**
   `AffineTransformAlgebra.transformNormal` gained an overload taking a precomputed
   `AffineSpatialInverse`, and the matrix-taking overload now delegates to it. One
   implementation of the column traversal, two entry points, so the two cannot drift — and
   `ADR-0284`'s eleven tests passed unchanged after the refactor, which is what makes it a
   refactor rather than a rewrite.
4. **The unit-length assertion is exact, not a tolerance.** An axis-aligned normal under a
   diagonal transform scales to `(0, 0, 0.2)`, whose scaled normalisation is exactly
   `(0, 0, 1)`. The test asserts that exact value **and** asserts the raw transformed value
   is `(0, 0, 0.2)`, so it distinguishes "normalised" from "returned unchanged" — which a
   unit-length tolerance would not. This follows the standing preference for provably exact
   cases over an epsilon.
5. **No failure case was added.** `normalsMissing` is inherited from the existing reader,
   `singularMatrix` from `VOXELIA-ALG-0016`, and `nonAffineOperand` from
   `VOXELIA-ALG-0052`. All three are tested here and none is new.

## Two things found while implementing

**`SurfaceShader.normals(of:facetOrdinal:)` had no caller and no test.** Every reference to
`SurfaceShader` outside its own file was to `intensity`, which the existing suite exercises
directly with hand-built directions. The reader — including its `normalsMissing` rejection —
was unexercised until this increment called it. That is the same
existence-wiring-verification split `ADR-0248` and `ADR-0282` both turned on, appearing a
third time.

**A pointer API reached a test and the gate did not object.** The fixture first encoded
binary64 components with `withUnsafeBytes`. `check_swift_safety.py` passed, because it does
not scan `Tests/`. The policy forbids the API regardless, so it was replaced with explicit
shifts — but the gap is worth recording as a third instance of the `ADR-0196` pattern:
an enforced-looking rule that nothing enforces in that location. Widening the scan is not
done here because it is a tooling change with its own blast radius, and this increment is a
rendering correction; it is recorded for its own increment.

## Alternatives considered

### Change `SurfaceShader.normals(of:facetOrdinal:)` to take the transform

Rejected, as `ADR-0285` decision 4 settled. It would change existing behaviour where an
addition suffices, and would force a matrix on callers that want object space.

### Compute the inverse inside the per-normal helper

Rejected. Three normals per facet under one `objectToWorld` would recompute
`VOXELIA-ALG-0016`'s adjugate three times per facet and thousands of times per frame, for
an identical result. `ADR-0285` named the hoisting and this does it.

### Reimplement the column traversal in the renderer to hoist the inverse

Rejected, and it was the obvious shortcut. A second copy of the traversal is exactly what
`ADR-0283` decisions 5 and 6 warned about — the transpose is expressed *by* the traversal
order, so a duplicate is one edit away from silently becoming `Inv × n`. Adding the
overload in the spatial module keeps one implementation.

### Assert unit length with a tolerance

Rejected; see decision 4. `VOXELIA-ALG-0030` states that no unit-length tolerance
correction is applied, so a tolerance in the test would assert something the specification
deliberately does not promise.

## Consequences

The composition defect `ADR-0280` measured is corrected, with its measurement now a test
rather than a record.

The normalisation-order decision is guarded: a later "simplification" to the cheaper
ordering fails a test whose comment says why, and cites the record that measured it.

`VOX-SUR-004`'s test half was discharged by `ADR-0202`'s increment and stays discharged.
This corrects a composition its tests could not see, because `SurfaceShader` has no
production caller and nothing composed it with a non-identity `objectToWorld`.

**Two tooling gaps are on the record** for their own increments: `check_swift_safety.py`
does not scan `Tests/`, and `SurfaceShader`'s reader went untested because nothing called
it.

## Affected modules

`VoxeliaRendering` gains `SurfaceNormalTransform`, internal. `VoxeliaSpatial` gains one
overload on `AffineTransformAlgebra`, which the existing overload now delegates to. No
behaviour of any existing symbol changes.

## Compatibility impact

Additive. The `AffineTransformAlgebra` refactor preserves behaviour, verified by
`ADR-0284`'s eleven tests passing unchanged.

## Security impact

None.

## Performance and memory impact

One `VOXELIA-ALG-0016` inverse per facet request rather than three, and three scaled
normalisations. A caller shading many facets under one transform can hoist further by
holding the inverse itself, which the new overload now permits.

## Validation impact

```text
swift build && swift test
swift test --filter "SurfaceNormalTransform"
swift test --filter "SurfaceShader|SurfaceVisibility|SurfaceCompositor|SurfacePicker|SurfaceClipper"
swift test --filter "AffineTransformAlgebra"
python3 Tools/Scripts/check_swift_safety.py
python3 Tools/Scripts/check_prohibited_imports.py
swift format lint --strict Sources/VoxeliaRendering/Internal/SurfaceNormalTransform.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1152 tests in 207 suites pass, up from 1145 in 206.

## Migration

1. This record, `SurfaceNormalTransform`, the hoisting overload and seven tests.
2. **Next**: the two tooling gaps above, and then a re-derived queue — the affine arc's
   named work is complete.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **implements `ADR-0285`** and corrects a composition
defect between `VOXELIA-ALG-0033` and `VOXELIA-ALG-0036` without editing either.

## References

- [ADR-0202 - Surface shading design](ADR-0202-surface-shading-design.md)
- [ADR-0280 - Open the affine transform arc](ADR-0280-open-the-affine-transform-arc.md)
- [ADR-0284 - Affine algebra implementation](ADR-0284-affine-algebra-implementation.md)
- [ADR-0285 - Shading normal space design](ADR-0285-shading-normal-space-design.md)
- [VOXELIA-ALG-0030 - Triangle area weighted vertex normals](../../algorithms/VOXELIA-ALG-0030-triangle-area-weighted-vertex-normals.md)
- [VOXELIA-ALG-0036 - Surface diagnostic shading](../../algorithms/VOXELIA-ALG-0036-surface-diagnostic-shading.md)
- [VOXELIA-ALG-0052 - Affine composition and directions](../../algorithms/VOXELIA-ALG-0052-affine-composition-and-directions.md)
