---
document_id: "ADR-0295"
title: "Distance phantom"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-003"
---

# ADR-0295 - Distance phantom

## Context

`ADR-0293` placed plan §55.4's distance phantom second in the analytical phantom arc,
because `ADR-0292` had just verified the measurement chain it feeds — so the phantom arrives
with a tested consumer rather than needing one built for it.

The plan asks for "two or more endpoints at known physical distances and oblique
orientations", for the patient-space measurement purpose.

`ADR-0293` numeric boundary 4 stated the obligation this record has to discharge: **the
oblique orientations must give exact distances**, because endpoints chosen carelessly produce
irrational lengths and force a tolerance.

## The finding that decided the design

The obvious way to certify a length as exact is to square the root back: admit a segment when
`fl(√s)² == s`. That certificate is **wrong**, and it fails at the smallest scale.

```text
s = 11        fl(√11)² == 11.0   →  true
√11 = 3.3166…                     →  irrational
```

Eleven is not a contrived value. It is the squared length of the delta `(1, 1, 3)` — an
entirely plausible oblique segment in a phantom. Under a round-trip certificate that segment
would be admitted as exact, and every distance measured against it would then be wrong in a
way no test could see, because the phantom itself would be asserting the wrong expected value.

So the exactness certificate is an **integer identity**, not a floating-point round trip.

## Decision

1. **The frozen table is four Pythagorean quadruples in whole millimetres**, and the exactness
   claim is `a² + b² + c² = d²` checked in `Int`. Integer arithmetic is the only arithmetic
   that can certify this without a tolerance, and the tests re-derive the identity from the
   endpoints rather than trusting the declared length.

   | Physical delta (mm) | Length (mm) | Shape |
   |---|---|---|
   | `(3, 4, 0)` | `5` | in-plane oblique |
   | `(1, 2, 2)` | `3` | fully oblique |
   | `(2, 3, 6)` | `7` | fully oblique |
   | `(1, 4, 8)` | `9` | fully oblique |

2. **The table is frozen in physical space, not index space.** The plan asks for endpoints at
   *known physical distances*, so the distances must not depend on the sampling. Index
   separations are derived by dividing by the spacing, which makes "does this endpoint land on
   a sample" a check the phantom performs rather than an assumption it makes.
3. **Spacing must be a power of two** within `2⁻¹⁰ … 2¹⁰`. Division by a power of two is
   exact, so testing the quotient for integrality is a real alignment test rather than a
   rounded one. Without this the alignment check would itself be an approximation, and the
   whole point of the record is that nothing here is.
4. **The origin must be an integer with magnitude at most `2³⁰`.** Together with decision 3
   this keeps every coordinate a dyadic rational spanning at most 42 significant bits, so
   every sum and difference from origin to measured length is exact in binary64. The bound is
   probed at both extremes in the tests rather than asserted in prose.
5. **No `VOXELIA-ALG` specification governs this phantom.** `ADR-0293` said §55.2 needs one
   because its summation order is observable. Here there is no summation to order: the lengths
   are declared constants certified by an integer identity, and the only floating-point
   arithmetic is one addition per axis, whose result is exact by decisions 3 and 4. The
   measurement itself is `VOXELIA-ALG-0010`, already frozen, and is **composed rather than
   restated**.
6. **Every z component of the table is even**, so a realistic anisotropic geometry — 0.5 mm in
   plane, 2 mm between slices — stays voxel-aligned. A phantom that only worked at isotropic
   spacing would not resemble the data the measurement path actually sees.
7. **The shared base index is `(1, 2, 1)`**, distinct in each axis. A base at the corner reads
   correctly under a transposed addressing mistake, which is the mistake `VOXELIA-ALG-0050`
   exists to catch.
8. **`VOX-VAL-003` is still not discharged.** This supplies the measurement kind and
   `ADR-0294` supplied intensity; spatial remains, and the row needs all three with tests that
   consume them.

## The tests

Fourteen, and the ones that carry weight are:

- **The declared length is never trusted.** Each segment's delta is recovered from its own
  endpoints, converted to `Int`, and the Pythagorean identity checked there. A phantom
  declaring a wrong length fails even if it is internally consistent.
- **The round-trip certificate is falsified in the suite**, not only in this record: `s = 11`
  passes `fl(√s)² == s` and is not a perfect square. The rule the code follows is the one the
  test proves is necessary.
- **The measurement runs through `MeasurementConstruction`**, the shipped type, and the result
  is compared with `==`. No length is computed inside the test.
- **Both per-axis fallacies are falsified on every segment.** Summing the axis distances gives
  `7, 5, 11, 13` against the true `5, 3, 7, 9`, and reporting the longest axis gives
  `4, 2, 6, 8`. An axis-aligned segment would let both mistakes pass, which is why none is in
  the table.
- **The length is invariant to sampling**: halving the spacing doubles every index separation
  and leaves the measured distance identical. That is the patient-space claim in one
  assertion.
- **Every refusal carries a positive control** — the admitted powers of two, the 2 mm slice
  spacing that does align, the largest admitted origin, and the exact minimum extents
  `8 × 11 × 6`.

Writing the extents test found that the reference fixture `9 × 12 × 7` has a sample of slack
in every axis, so the triples first chosen as "one short" were all still large enough and
**refused nothing**. The boundary is now pinned at the true minimum.

No tolerance appears anywhere in the suite.

## Alternatives considered

### Certify exactness with `fl(√s)² == s`

Rejected, and it is the alternative that mattered. See the finding above: it admits `s = 11`,
whose root is irrational, and the failure is reachable from a plausible delta.

### Allow any spacing and any origin

Rejected. The alignment and exactness checks would then themselves be approximate, and the
phantom would be asserting expected values it could not prove. The constraint costs nothing
because a phantom's geometry is chosen rather than observed.

### Freeze the table in index space

Rejected; see decision 2. The physical distance would then depend on the spacing, which is
the opposite of what "endpoints at known physical distances" means, and the phantom would
refuse isotropic 1 mm spacing while silently changing its own lengths elsewhere.

### Include an axis-aligned segment

Rejected. It would be measured correctly by a pipeline that summed axis distances or reported
the longest axis, so it weakens exactly the discrimination the plan's word "oblique" asks for.

### Give the phantom no materialised volume

Rejected. Without samples the endpoints cannot be located by picking, which is how a
measurement is actually made, and the extents would have no purpose.

## Consequences

The measurement kind of `VOX-VAL-003` has a phantom whose expected distances are exact
integers, and a false certificate that would have quietly admitted irrational lengths is
recorded before it was ever used.

`VoxeliaValidationTests` gains a dependency on `VoxeliaInteraction`, because the row's subject
is the shipped measurement type and a test that re-implemented it would prove nothing.
Test targets are outside `check_package_graph.py`'s layered graph by design, so the library
graph is unchanged.

## Affected modules

`VoxeliaValidation` gains `DistancePhantom` and `DistancePhantomError`, both listed in its
DocC catalogue, and imports `VoxeliaSpatial` for `Point3D` — the same transitive import
`VoxeliaInteraction` and `VoxeliaRendering` already use. No library dependency changes.

## Compatibility impact

Additive.

## Security impact

None. The phantom is synthetic by definition and touches no patient data.

## Performance and memory impact

`storedBytes` materialises two bytes per sample on demand against a five-element set. The
phantom itself holds four segments.

## Validation impact

```text
swift build && swift test
swift test --filter "DistancePhantomTests"
swift format lint --strict Sources/VoxeliaValidation/Public/DistancePhantom.swift
python3 Tools/Scripts/check_swift_safety.py
python3 Tools/Scripts/check_prohibited_imports.py
python3 Tools/Scripts/check_package_graph.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1194 tests in 212 suites pass, up from 1180 in 211.

## Migration

1. This record, the phantom and fourteen tests.
2. **Next**: §55.2's physical-coordinate ramp, design-first with a `VOXELIA-ALG` specification
   and an independent oracle, because its summation order and its quantisation are both
   observable.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **implements plan §55.4** under `ADR-0293`'s frozen arc
decisions, and discharges that record's numeric boundary 4.

## References

- [ADR-0292 - Reconstructed measurement geometry](ADR-0292-reconstructed-measurement-geometry.md)
- [ADR-0293 - Open the analytical phantom arc](ADR-0293-open-the-analytical-phantom-arc.md)
- [ADR-0294 - Linear ramp phantom](ADR-0294-linear-ramp-phantom.md)
- [VOXELIA-ALG-0050 - Volume sample layout](../../algorithms/VOXELIA-ALG-0050-volume-sample-layout.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
