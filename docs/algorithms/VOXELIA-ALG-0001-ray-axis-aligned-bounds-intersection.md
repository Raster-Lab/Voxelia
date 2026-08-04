---
document_id: "VOXELIA-ALG-0001"
title: "Ray to axis-aligned bounds intersection binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-04"
owner: "Voxelia Project"
---

# Ray to axis-aligned bounds intersection binary64-v1

## Purpose

This specification defines the versioned reference operation
`ray-axis-aligned-bounds-intersection/binary64-v1` selected by accepted
[`ADR-0026`](../architecture/decisions/ADR-0026-ray-axis-aligned-bounds-intersection.md).
It computes the closed half-ray parameter interval over which a `Ray3D`
intersects an `AxisAlignedBounds3D`, distinguishing a model-classified miss
(`nil`) from a typed numerical representability failure. The public receiver
is `AxisAlignedBounds3D.intersection(with:)` in `VoxeliaSpatial`.

## Supported rank and formats

Three-dimensional Cartesian values only. All arithmetic uses IEEE-754
binary64 (`Double`). No other rank, scalar format or precision is covered.

## Inputs and outputs

Inputs:

- one validated `Ray3D` (finite origin, finite non-zero unnormalised
  direction, one coordinate space); and
- one validated `AxisAlignedBounds3D` (finite closed component-wise ordered
  minimum/maximum points, one coordinate space; point, line and plane
  degeneracy permitted).

Output: an optional `RayAxisAlignedBoundsIntersection3D` carrying finite
`entryParameter` and `exitParameter` with
`0 <= entryParameter <= exitParameter` and signed zero canonicalised to
positive zero. The result is transient: it has no public initializer and no
`Codable` conformance. `nil` is a model-classified miss. Selected
non-representable parameters throw the typed `SpatialBoundsError` cases
below instead of returning a value.

## Parameters

The ray is the closed half-line `point(t) = origin + t * direction` for
`t >= 0`, using the direction exactly as supplied. Parameters are
coefficients in that parameterisation, not physical distances. The query
performs no normalisation, no unit selection, no bounds expansion, no
clipping range and no coordinate transform.

## Coordinate conventions

The ray and bounds must have exactly equal `CoordinateSpaceID` values. A
mismatch throws
`SpatialBoundsError.coordinateSpaceMismatch(expected:actual:)` with the
bounds space as expected and the ray-origin space as actual, before any
numeric work.

## Boundary behaviour

The bounds are a caller-supplied closed Cartesian set:

- an intersection wholly at negative parameters is a miss;
- an origin inside or on the bounds has entry parameter zero;
- an origin on a boundary moving immediately outward produces `[0, 0]` when
  no later point is inside;
- face, edge, corner and tangent contact are intersections, including a
  singleton parameter interval; and
- point-, line- and plane-degenerate bounds use the same rule, including a
  non-singleton interval where a ray is coincident with a degenerate axis.

For each axis in fixed X, Y, Z order, an exactly zero direction component is
parallel. If its origin component is outside that closed slab the query
returns `nil`; if it is inside or on the slab, that axis imposes no
parameter constraint. A subnormal non-zero direction component is not
parallel. No epsilon, tolerance expansion or near-zero classification is
permitted.

## Precision and determinism

`binary64-v1` requires IEEE-754 binary64, round-to-nearest-ties-to-even,
gradual subnormal handling, no flush-to-zero and no unsafe reassociation or
fast-math mode. An altered thread rounding environment or flush-to-zero
execution is unsupported and nonconforming unless the implementation
isolates the operation and still produces the specified result.

A boundary parameter is `(boundary - origin) / direction`. When the direct
subtraction overflows, the equivalent scaled expression
`(boundary * 0.5 - origin * 0.5) / (direction * 0.5)` is evaluated;
multiplication by one half is the only scaling step. If the scaled direction
becomes zero in this overflow branch, the quotient is outside the finite
binary64 range and is tagged as unrepresentable rather than divided by zero.

The evaluator retains internal signed overflow and underflow tokens instead
of clamping. A quotient is tagged as underflow when the boundary and origin
differ but the evaluated quotient is zero; its sign derives from the ordered
boundary/origin comparison and the direction sign before zero
canonicalisation. An infinite evaluated quotient becomes the corresponding
signed overflow token. The normative token order is:

```text
negativeOverflow
< finite negative values
< negativeUnderflow
< finite(+0)
< positiveUnderflow
< finite positive values
< positiveOverflow
< positiveInfinitySentinel
```

Finite values use ordinary numeric order after zero canonicalisation. Tokens
of the same non-finite category compare equal. On an equal comparison the
existing candidate is retained, so the initial half-ray bound and then the
earliest X/Y/Z axis win ties.

## Reference implementation

The normative evaluation sequence is:

1. Reject a coordinate-space mismatch.
2. Scan X, Y and Z for exact-zero direction components. If any such origin
   component is outside its closed slab, return `nil` before quotient work.
3. Set entry to `finite(+0)` and exit to `positiveInfinitySentinel`.
4. For each non-zero X, Y and Z component, select its near and far quotient
   tokens from the direction sign. Replace entry only when near > entry, and
   replace exit only when far < exit. Do not exit the loop early.
5. If entry > exit under the token order, return `nil`.
6. If entry is an overflow or underflow token, throw the entry error below.
7. If exit is an overflow or underflow token, throw the exit error below.
8. Return the two finite parameters.

Because `Ray3D` has at least one non-zero component, the exit sentinel
cannot remain selected after step 4. A parallel-outside miss takes
precedence over unrelated quotient failures, a binary64-model empty interval
takes precedence over selected representability failures, and an entry
failure takes precedence over an exit failure. Overflow or underflow that is
not selected does not fail the query.

The reference implementation is
`AxisAlignedBounds3D.intersection(with:)` in
[`Sources/VoxeliaSpatial/Public/RayAxisAlignedBoundsIntersection.swift`](../../Sources/VoxeliaSpatial/Public/RayAxisAlignedBoundsIntersection.swift).

## Accelerated implementations

None. Any SIMD or Metal duplicate must prove bit-exact conformance to this
specification (identical nil/error classification and identical finite
parameter bit patterns) before substituting for the reference operation, and
may not substitute when its floating-point mode cannot meet the precision
rules above.

## Failure behaviour

The typed failures are members of `SpatialBoundsError`:

```swift
case rayIntersectionEntryParameterNotRepresentable(
    axis: Int,
    reason: RayIntersectionParameterFailureReason
)
case rayIntersectionExitParameterNotRepresentable(
    axis: Int,
    reason: RayIntersectionParameterFailureReason
)
```

The retained token provenance supplies the axis (0, 1, 2 for X, Y, Z) and
its category supplies `.overflow` or `.underflow`. The query never returns
infinity or a clamped finite parameter for these conditions. `nil` is a
model-classified miss under this binary64 model, not a guarantee that an
exact-rational predicate over the same inputs would also miss.

## Validation datasets and tolerances

Conformance is bit-exact and zero-tolerance: a conforming implementation
must produce the same nil/error classification and the same finite
parameter bit patterns as this reference. Dyadic analytic fixtures require
exact parameter equality. High-precision rational oracles may additionally
measure the binary64 model's error but must not silently replace its
specified classification with an unversioned tolerance. The focused suite
is `Tests/VoxeliaSpatialTests/RayAxisAlignedBoundsIntersection3DTests.swift`
and covers the complete evidence list in accepted `ADR-0026`.

## Benchmarks

The reference query is deterministic and constant-time over three axes with
O(1) auxiliary storage and no intentional heap allocation. No dedicated
benchmark scenario is claimed at M1; correct classification and typed
failure take precedence over micro-optimising the branch structure.

## Provenance fields

Operations recording provenance for derived values must record the
operation identifier `ray-axis-aligned-bounds-intersection/binary64-v1`.
This method remains permanently bound to `binary64-v1`; changing the
arithmetic order or classification policy requires a distinct public API or
an explicitly breaking compatibility change.

## References

- [ADR-0026 - Ray to axis-aligned bounds intersection](../architecture/decisions/ADR-0026-ray-axis-aligned-bounds-intersection.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1, sections 10 through 12](../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [Current Ray3D implementation](../../Sources/VoxeliaSpatial/Public/SpatialPrimitives.swift)
- [Current AxisAlignedBounds3D implementation](../../Sources/VoxeliaSpatial/Public/Bounds3D.swift)
