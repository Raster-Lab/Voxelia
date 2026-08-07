---
document_id: "ADR-0026"
title: "Ray to axis-aligned bounds intersection"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-ARC-002"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-SPA-001"
  - "VOX-SPA-003"
  - "VOX-SPA-011"
  - "VOX-DVR-002"
  - "VOX-DOC-006"
  - "VOX-ERR-001"
  - "VOX-VAL-002"
  - "VOX-VAL-007"
---

# ADR-0026 - Ray to axis-aligned bounds intersection

## Context

`VoxeliaSpatial` already provides finite, explicit-space `Ray3D` and
`AxisAlignedBounds3D` values. A ray preserves its supplied non-zero direction
without normalisation. Axis-aligned bounds are closed, permit point, line and
plane degeneracy, and do not infer whether they describe sample centres or
full sample support.

`VOX-SPA-011` requires intersections used by rendering and interaction. The
Master Technical Architecture requires conventional volume renderers to
intersect rays with actual volume bounds, and the Validation and Benchmark
Strategy calls for analytic ray-box oracles and entry/exit evidence. None of
those documents defines the API receiver, result shape, ray parameter domain,
inside-origin behaviour, closed-boundary policy, parallel-axis rule or numeric
failure semantics.

Ordinary slab code is not a sufficient unstated contract. Finite `Double`
inputs can overflow while subtracting a boundary from an origin even when the
final quotient is representable. A non-zero quotient can also underflow to
zero. Returning nil for either condition would conflate a model-classified
miss with a failed numerical evaluation. Introducing an epsilon would make
classification scale-dependent and would conflict with the project's explicit
tolerance governance.

This record selects one bounded public operation and a deterministic
binary64 reference policy. It does not define ray-plane,
ray-oriented-bounds, plane-plane, clipping or coordinate-transform overloads.
It was reviewed and accepted by the project owner on 2026-08-04.

## Decision

`VoxeliaSpatial` adds this computed result and query:

```swift
public struct RayAxisAlignedBoundsIntersection3D: Sendable, Hashable {
    public let entryParameter: Double
    public let exitParameter: Double
}

public enum RayIntersectionParameterFailureReason: Sendable, Equatable {
    case overflow
    case underflow
}

extension AxisAlignedBounds3D {
    public func intersection(
        with ray: Ray3D
    ) throws -> RayAxisAlignedBoundsIntersection3D?
}
```

The result will have no public initializer and will not conform to `Codable`.
It is a transient value produced only by the validated query, not a persistent
descriptor or wire record. Both parameters will be finite, signed zero will be
canonicalised to positive zero, and every returned value will satisfy:

```text
0 <= entryParameter <= exitParameter
```

The ray is the closed half-line

```text
point(t) = ray.origin + t * ray.direction, t >= 0
```

using the direction exactly as supplied. Parameters are coefficients in that
parameterisation, not physical distances. Mathematically, multiplying the
direction by a positive finite factor rescales both parameters inversely while
preserving the half-ray, provided every scaled component remains finite and
the direction remains non-zero. The binary64 results need not obey that
relationship bit-for-bit for arbitrary scaling. The query will not normalise
the direction.

The bounds are a caller-supplied closed Cartesian set. The query will not
expand them, infer centre-versus-sample-support semantics, select units, apply
a clipping range or perform a coordinate transform. The ray and bounds must
have exactly equal `CoordinateSpaceID` values. A mismatch will throw the
existing
`SpatialBoundsError.coordinateSpaceMismatch(expected:actual:)`, with the
bounds space as expected and the ray-origin space as actual, before any
numeric work.

The closed-set behaviour will be:

- nil means a miss under the versioned binary64 model defined below;
- an intersection wholly at negative parameters is a miss;
- an origin inside or on the bounds has entry parameter zero;
- an origin on a boundary moving immediately outward produces `[0, 0]` when
  no later point is inside;
- face, edge, corner and tangent contact are intersections, including a
  singleton parameter interval; and
- point-, line- and plane-degenerate bounds use the same rule, including a
  non-singleton interval where a ray is coincident with a degenerate axis.

For each axis in fixed X, Y, Z order, an exactly zero direction component is
parallel. If its origin component is outside that closed slab, the query
returns nil; if it is inside or on the slab, that axis imposes no parameter
constraint. A subnormal non-zero direction component is not parallel. No
epsilon, tolerance expansion or near-zero classification is permitted.

The reference operation version will be
`ray-axis-aligned-bounds-intersection/binary64-v1`. It will use the standard
closed-slab interval intersected with `[0, +infinity]` and a fixed IEEE-754
binary64, round-to-nearest-ties-to-even evaluation order. It will calculate a
boundary parameter from `(boundary - origin) / direction`. When the direct
subtraction overflows, it will evaluate the equivalent scaled expression:

```text
(boundary * 0.5 - origin * 0.5) / (direction * 0.5)
```

Multiplication by one half is the only scaling step. If the scaled direction
becomes zero in this overflow branch, the quotient is outside the finite
binary64 range and is tagged as unrepresentable rather than divided by zero.

The evaluator will retain internal signed overflow and underflow tokens instead
of clamping them to infinity or zero. A quotient is tagged as underflow when
the boundary and origin differ but the evaluated quotient is zero; its sign is
derived from the ordered boundary/origin comparison and direction sign before
zero canonicalisation. An infinite evaluated quotient becomes the corresponding
signed overflow token.

The normative token order is:

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
of the same non-finite category compare equal. On an equal comparison, the
existing candidate is retained, so the initial half-ray bound and then the
earliest X/Y/Z axis win ties.

The exact evaluation sequence is:

```text
1. Reject a coordinate-space mismatch.
2. Scan X, Y and Z for exact-zero direction components. If any such origin
   component is outside its closed slab, return nil before quotient work.
3. Set entry to finite(+0) and exit to positiveInfinitySentinel.
4. For each non-zero X, Y and Z component, select its near and far quotient
   tokens from the direction sign. Replace entry only when near > entry, and
   replace exit only when far < exit. Do not exit the loop early.
5. If entry > exit under the token order, return nil.
6. If entry is an overflow or underflow token, throw the entry error below.
7. If exit is an overflow or underflow token, throw the exit error below.
8. Return the two finite parameters.
```

Because `Ray3D` has at least one non-zero component, the exit sentinel cannot
remain selected after step 4. This sequence intentionally gives a parallel-
outside miss precedence over unrelated quotient failures, a binary64-model
empty interval precedence over selected representability failures, and an
entry failure precedence over an exit failure. Overflow or underflow that is
not selected does not fail the query.

The new typed failures will be:

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

The retained token provenance supplies the axis, and its category supplies
`.overflow` or `.underflow`. The query will never return infinity or a clamped
finite parameter for these conditions. Finite quotient ordering follows the
versioned binary64 reference operations; this decision does not claim an
exact-real predicate for arbitrarily ill-conditioned ratios. Consequently,
nil is a model-classified miss and not a guarantee that an exact-rational
predicate over the same binary64 inputs would also miss.

`binary64-v1` requires round-to-nearest-ties-to-even, gradual subnormal
handling, no flush-to-zero, and no unsafe reassociation or fast-math mode. An
altered thread rounding environment or flush-to-zero execution is unsupported
and nonconforming unless the implementation isolates the operation and still
produces the specified result. A Metal or SIMD path may not substitute for the
reference operation when its floating-point mode cannot meet these rules.

Conformance to the versioned reference algorithm is bit-exact: a conforming
implementation must produce the same nil/error classification and the same
finite parameter bit patterns. This zero-tolerance algorithmic comparison is
separate from spatial-tolerance comparisons used when independently evaluating
derived physical points. Changing the arithmetic order or classification
policy requires a distinct public API or an explicitly breaking compatibility
change. This method remains permanently bound to `binary64-v1`; a wider test
tolerance cannot silently turn it into a later version.

Acceptance establishes the contract only for `Ray3D` and
`AxisAlignedBounds3D`; the migration steps below are authorised as of the
2026-08-04 acceptance and are executed through the progress ledger.

## Alternatives considered

### Return only a Boolean

A Boolean is smaller but cannot provide the entry and exit interval required
for traversal, clipping, termination or the specified validation evidence.

### Return a ClosedRange<Double>

A standard range expresses inclusive endpoints, but its public construction
does not communicate the half-ray, finite-value, parameterisation or typed
failure invariants. The named result leaves room for documentation without
implying a persistent schema.

### Return entry and exit points

Points are convenient for validation but duplicate state derived from the ray
and parameters. Computing them can introduce a separate multiplication/addition
representability problem. This proposal keeps the minimal traversal result;
point evaluation requires its own explicit operation contract.

### Normalise every ray before intersection

Normalisation would make parameters resemble distance, but it would alter the
supplied semantic value, introduce magnitude conditioning and contradict the
existing explicit-normalisation rule.

### Treat near-zero direction components as parallel

An epsilon can improve conditioning for one scale while changing geometry at
another. It is not recommended without an operation-specific physical-unit and
tolerance policy. Exact zero is deterministic and preserves subnormal input.

### Use direct subtraction and division only

This is simple but rejects or misclassifies avoidable finite cases such as
opposite extreme boundaries with a representable scaled quotient. The fixed
half-scaling fallback handles subtraction overflow without hidden precision or
platform policy.

### Return nil for numerical failure

This would make a numerical limitation indistinguishable from a geometric
miss and could cause rendering or memory-access code to trust an invalid
classification. A typed failure is fail-closed and diagnostically actionable.

### Require an exact-real rational predicate

Interpreting every binary64 input as an exact dyadic rational and comparing all
slab ratios exactly would provide stronger classification at near ties. It is
not selected for this initial operation because it requires an arbitrary-
precision or formally reviewed adaptive comparator not present in the current
foundation. The versioned binary64 policy is explicit, deterministic and can
be replaced only through a reviewed compatibility decision.

### Include oriented bounds, planes or transforms

Those operations have independent representation, tolerance and result-shape
gaps. Combining them would make this proposal too broad and would not resolve
the missing `OrientedBounds3D` invariants.

## Consequences

- Rendering and interaction code gains one backend-neutral entry/exit contract
  after acceptance without taking a dependency on a renderer or Metal type.
- Closed boundaries and degenerate bounds have one consistent interpretation.
- Direction magnitude remains semantically visible through parameter scaling.
- Nil has one deterministic binary64-v1 meaning; selected non-representable
  arithmetic is a distinct typed failure.
- The long result name states that oriented bounds are not covered.
- The transient result has no stable wire format or public construction path.
- Extremely ill-conditioned finite cases follow a named binary64 algorithm,
  not an unstated exact-real guarantee.
- Plane, oriented-bounds, transformed-space and point-evaluation operations
  remain deferred.

## Affected modules

If accepted, `VoxeliaSpatial` owns and implements the result, failure-reason
enum, two additions to the existing `SpatialBoundsError` declaration and the
query. `VoxeliaCore` and the `Voxelia` umbrella are direct build consumers
through existing dependencies. Future `VoxeliaRendering` and `VoxeliaMetal`
code may consume the operation through separately reviewed dependency paths,
but this decision adds no dependency edge and does not authorise renderer
implementation.

## Compatibility impact

No public ray/bounds query or result currently exists, so the implementation is
an additive pre-1.0 source API. The result field names, receiver, half-ray
domain, closed-set behaviour, error distinction and binary64 operation version
become compatibility contracts once released. There is no persisted-data or
wire migration because the result deliberately omits `Codable`.

Adding a case to public `SpatialBoundsError` requires ordinary enum-evolution
review for exhaustive source switches, even though the enum is not frozen.

## Security impact

The operation accepts only already validated finite values and requires no
intentional allocation, unsafe memory access, I/O, logging or patient-data
processing. Failing explicitly on a selected non-representable parameter
prevents a fabricated interval from authorising downstream sampling or buffer
access. Callers must still validate every derived storage region separately.

## Performance and memory impact

The reference query is deterministic and constant-time over three axes, with
O(1) auxiliary storage and no intentional heap allocation. The overflow
fallback adds a bounded number of binary64 operations. Correct classification
and typed failure take precedence over micro-optimising the branch structure.
Any SIMD or Metal duplicate must prove bit-exact conformance before
substituting for the public reference operation.

## Validation impact

The focused suite after acceptance must cover:

- positive- and negative-axis hits with analytic entry and exit parameters;
- positive, finite, non-unit direction rescaling with dyadic fixtures and
  invariant geometric points under the declared comparison;
- misses wholly behind the origin and misses on each separated axis;
- origins inside, on every face, edge and corner, moving inward and outward;
- face, edge, corner and tangent singleton intervals;
- point-, line- and plane-degenerate bounds, including coincident intervals;
- parallel-inside, parallel-on and parallel-outside slabs for every axis;
- signed-zero direction components and non-zero subnormal directions;
- exact coordinate-space mismatch diagnostics;
- representable extreme cases whose direct subtraction overflows;
- selected parameter overflow and non-zero-to-zero underflow errors;
- irrelevant overflow or underflow constrained away by another slab;
- parallel-outside precedence before an unrelated overflow or underflow;
- positive-underflow entry versus zero exit, negative-underflow exit versus
  zero entry, equal signed tokens from different axes and both endpoints
  tagged;
- deterministic entry-before-exit and earliest-axis error selection;
- all finite ordered output invariants and positive-zero canonicalisation; and
- repeatability against an independent implementation of
  `ray-axis-aligned-bounds-intersection/binary64-v1`, including near-tie axis
  permutations.

Dyadic analytic fixtures will require exact parameter and derived-point
equality. High-precision rational oracles may additionally measure the chosen
binary64 model's error, but they must not silently replace its specified
nil/error classification with an unversioned tolerance.

Focused implementation checks will be strict formatting for changed Swift
files, `swift build --target VoxeliaSpatial`, direct-consumer builds for
`VoxeliaCore` and `Voxelia`, and
`swift test --filter RayAxisAlignedBoundsIntersection3DTests`. The full Swift
suite is not required for this isolated operation.

## Migration

After architecture and maintainer approval:

1. mark this ADR Accepted without changing the approved decision text;
2. add `RayAxisAlignedBoundsIntersection3D`,
   `RayIntersectionParameterFailureReason` and both entry/exit error cases to
   the existing `SpatialBoundsError` declaration in `VoxeliaSpatial`;
3. add a versioned algorithm specification under `docs/algorithms/` covering
   the identifier, inputs, outputs, coordinate and boundary behaviour,
   precision environment, normative reference sequence, failure policy,
   tolerance, validation, performance scenarios and provenance;
4. implement the versioned query on `AxisAlignedBounds3D`;
5. document the result, parameterisation, closed-boundary and numerical policy
   in the Spatial DocC catalogue;
6. add only the focused analytic and numerical Swift tests listed above;
7. run the affected formatting, build, documentation and test checks; and
8. update traceability, progress and release-integrity evidence.

These migration steps are authorised as of the 2026-08-04 acceptance and are
executed in order through the progress ledger.

## Supersession

This ADR neither supersedes nor is superseded by another file-backed ADR. It
refines an intersection contract left unspecified by the governing documents
without replacing those documents or any other decision. It is independent
of accepted ADR-0024 and retained `ADR-0026` through that registry
reconciliation.

## References

- [Voxelia Master Technical Architecture v0.1.1, sections 2, 8, 10 and 27](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 5 through 7, 28, 29, 58 and 64](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, architecture, API, spatial, rendering, error and validation requirements](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1, sections 10 through 12, 18 and 32](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1, sections 9.2 and 9.4](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
- [Current Ray3D implementation](../../../Sources/VoxeliaSpatial/Public/SpatialPrimitives.swift)
- [Current AxisAlignedBounds3D implementation](../../../Sources/VoxeliaSpatial/Public/Bounds3D.swift)
