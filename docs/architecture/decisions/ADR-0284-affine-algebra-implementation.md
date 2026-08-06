---
document_id: "ADR-0284"
title: "Affine algebra implementation"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SPA-008"
---

# ADR-0284 - Affine algebra implementation

## Context

`ADR-0283` accepted `VOXELIA-ALG-0052`, `affine-composition/binary64-v1`, freezing
composition, vector transformation and normal transformation with five exactly
representable fixtures. This is the migration increment that implements it, discharging
`VOX-SPA-008`.

## Decision

1. **`VOX-SPA-008` is discharged.** All five capabilities the row names now exist:
   inversion from `VOXELIA-ALG-0016`, point transformation from `ADR-0138` and now from
   composing a vector transformation with the translation, and composition, vector and
   normal transformation from `AffineTransformAlgebra`.
2. **All five fixtures reproduce exactly, first run.** No value needed adjustment between
   the independent Python oracle and the Swift implementation, which is what the
   design-first order exists to produce rather than to hope for.
3. **Every assertion is exact equality.** Each registered fixture value is representable in
   binary64, so no tolerance appears in the suite and none is needed.
4. **Fixture 1 is tested twice, and the second test is the real one.** The first compares
   the composed matrix against the registered elements; the second composes, applies, and
   compares against **staged application** — `outer(inner(p))`. A transcription error in
   the first would be caught by the second, and the second tests the property the operation
   exists for.
5. **Coordinate spaces are deliberately not attributed.** `Point3D` and `Vector3D` carry a
   `CoordinateSpaceID` and a transform maps between spaces, so which space a result inhabits
   is a real question — and it is the consuming operation's, exactly as `VOXELIA-ALG-0016`
   left composition with a world offset to its consumers. The API therefore takes and
   returns plain components. A space-aware wrapper is a separate decision, and inventing
   one here would have put a rule in the algebra that no requirement asked for.
6. **No existing consumer changed, and this is verified rather than assumed.** `ADR-0280`
   decision 3 constrained the arc not to alter any accepted frozen step. Nothing existing
   was modified — the increment adds one file — and the suites of the operations this
   composes were re-run to confirm: `AffineSpatialInverse`, `AffineWorldToIndexMap`,
   `SpatialGeometry` and `SingularTransformTypedError`, 16 tests across 4 suites, all
   passing unchanged.
7. **`isAffine` is public.** A caller that must branch on affineness would otherwise have to
   provoke the throw to find out, and the predicate is the same exact comparison the
   admission uses rather than a second rule.

## Tests beyond the fixtures

Four cases the specification implies but does not enumerate:

- **A non-affine operand is refused in all four positions** — as the outer and inner
  operands of a composition, and as the operand of a vector and a normal transformation.
  Testing one position would leave three guards unexercised.
- **A singular matrix surfaces `ALG-0016`'s own error**, `singularMatrix`, not a new one.
  That is the observable consequence of composing the accepted inverse rather than
  reimplementing it, and it is the only way a test can tell the two apart.
- **A transformed normal is not normalised**, asserted by checking a result whose squared
  length is not one. Without it, "deliberately not normalised" is a comment rather than a
  behaviour.
- **Composing with the identity returns the operand exactly**, in both positions, over a
  matrix of distinct primes so a transposition or an index slip cannot pass.

## What the design-first order bought

The oracle was written before the Swift, in the frozen expression order, with
`ALG-0016`'s adjugate reproduced rather than imported. Every one of the five fixtures matched
on the first run.

That is worth recording because the alternative failure is silent: an implementation written
first, then an oracle written to agree with it, produces the same green suite while proving
nothing about the arithmetic. The order is what makes the agreement evidence.

## Alternatives considered

### Take and return `Vector3D` and `Point3D`

Rejected; see decision 5. Those types carry a coordinate space, and the transform's
destination space is a decision no requirement here makes. Accepting them would have forced
the algebra either to invent a space rule or to ignore a field the type guarantees, and both
are worse than staying out of it.

### Add a point transformation to this type

Rejected as redundant. `ADR-0138` already froze one for its consumer, and a point
transformation is the vector transformation plus the translation — which the test helper
demonstrates in four lines. Adding a second frozen point step would create exactly the
duplicate-authority problem `ALG-0016` avoided by leaving composition to consumers.

### Assert the fixtures with a tolerance

Rejected. Every registered value is exactly representable, so a tolerance would only hide a
future divergence. This is the `ADR-0229`-era discipline: where a measurement comes out
exact, assert exact.

### Normalise inside `transformNormal` for caller convenience

Rejected, as `ADR-0283` decision 7 already settled. Implementing it would have been one line
and would have broken the correspondence between transforming twice and transforming by the
composition.

## Consequences

`VOX-SPA-008` is discharged, and with `ADR-0281`'s discharge of `VOX-SPA-009` **both M1
spatial rows the derivation surfaced are now closed**.

`VoxeliaSpatial` gains a public algebra that the surface-shading correction can consume.
That correction — `ADR-0280` measured it at the maximum possible error under rotation — is
now unblocked and is the arc's remaining work.

Non-associativity is a test rather than a warning, so a consumer that later assumes
associativity has a failing case to read.

## Affected modules

`VoxeliaSpatial` gains `AffineTransformAlgebra` and `AffineTransformError`, both listed in
its DocC catalogue. No other module changes and nothing new is imported.

## Compatibility impact

Additive. No existing type, signature or frozen step changes.

## Security impact

None. The operations are arithmetic over already-admitted finite values.

## Performance and memory impact

Composition is nine three-term products plus three four-term chains; a vector
transformation is three three-term chains; a normal transformation adds `ALG-0016`'s
existing inverse. Each allocates one small `ContiguousArray` for its result.

## Validation impact

```text
swift build && swift test
swift test --filter "AffineTransformAlgebra"
swift test --filter "AffineSpatialInverse|AffineWorldToIndex|SpatialGeometry|SingularTransformTypedError"
python3 Tools/Scripts/check_swift_safety.py
python3 Tools/Scripts/check_prohibited_imports.py
swift format lint --strict Sources/VoxeliaSpatial/Public/AffineTransformAlgebra.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1145 tests in 206 suites pass, up from 1134 in 205.

## Migration

1. This record, `AffineTransformAlgebra` and its eleven tests.
2. **Next**: the surface-shading correction. `ADR-0280` established that
   `SurfaceVertexProjector` transforms positions into world space while `SurfaceShader`
   reads object-space normals and dots them against a world-space forward, and quantified
   the error at `1.000000` against a correct `0.000000` under a pure rotation. The
   correction consumes `transformNormal` and must not edit `ADR-0202` or `ALG-0036`.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **implements `VOXELIA-ALG-0052`** and composes
`VOXELIA-ALG-0016` without altering it.

## References

- [ADR-0138 - World to index mapping](ADR-0138-world-to-index-mapping.md)
- [ADR-0280 - Open the affine transform arc](ADR-0280-open-the-affine-transform-arc.md)
- [ADR-0283 - Affine composition and direction design](ADR-0283-affine-composition-and-direction-design.md)
- [VOXELIA-ALG-0016 - Affine spatial inverse](../../algorithms/VOXELIA-ALG-0016-affine-inverse.md)
- [VOXELIA-ALG-0052 - Affine composition and directions](../../algorithms/VOXELIA-ALG-0052-affine-composition-and-directions.md)
