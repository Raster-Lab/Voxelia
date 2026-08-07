---
document_id: "ADR-0297"
title: "Phantoms through the shipped pipelines"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-003"
---

# ADR-0297 - Phantoms through the shipped pipelines

## Context

`ADR-0296` built the third analytical phantom and then **declined to discharge**
`VOX-VAL-003`, naming the reason precisely: all three kinds had a phantom, but only the
measurement one was fed into shipped product code. The other two suites verified that a
phantom is what it claims to be — necessary, and not the same thing.

Plan §46.2's exit criterion is a statement about a pipeline:

> known phantoms produce the expected CT values and physical distances independently of
> windowing and zoom

This supplies the missing half.

## Decision

1. **The intensity phantom runs through `WindowLevelOperation` and `CTSampleInspector`.**
   The §55.1 ramp is windowed twice with windows that disagree everywhere, and the CT values
   are then inspected and compared against the phantom's closed form. That is the criterion's
   first clause instantiated rather than paraphrased.
2. **The spatial phantom runs through `WindowLevelOperation` and then
   `ObliqueSliceOperation`.** The §55.2 ramp is reconstructed on a plane that is not
   axis-aligned, and the expected result is available **in closed form**, which is the entire
   reason an analytical phantom is worth building.
3. **`VOX-VAL-003` is discharged.** All three kinds now have a phantom **and** a test that
   drives it through shipped product code: intensity and spatial here, measurement in
   `ADR-0295` through `MeasurementConstruction`.
4. **No source changes.** This increment is the `T` the row declares, and nothing in
   `Sources/` moved.

## The identity window, and why it matters here

`ObliqueSliceOperation` admits only a `uint8` volume, so the `int16` phantom has to pass
through window and level first. A window that rescaled the samples would leave the
reconstruction validating a rescaled copy of the phantom rather than the phantom.

Under `VOXELIA-ALG-0002` a centre of `128` with a width of `256` reduces exactly to the
identity:

```text
y = round(((x - 127.5) / 255 + 0.5) * 255) = round(x)
```

The suite asserts this over the **entire** range `0...255` — 256 stored values, all mapping
to themselves — rather than inferring it from the two rows the other test checks. The
oblique stage therefore carries the phantom's own integers.

## The closed form, and why the reconstruction is exact

The volume geometry makes the ramp exactly `10 + i + 2j - k`. The oblique request steps
`(1, 0.5, 0)` per output column and `(0, 0, 2)` per output row, so:

```text
value(u, v) = 10 + 2u - v
```

Every odd output column lands at volume row `u / 2`, which is **not** an integer index — a
genuine trilinear blend, with weights of exactly one half. Trilinear interpolation reproduces
a function affine in the indices exactly, and half-weights on small integers are exact in
binary64, so the whole plane is asserted with `==` and no tolerance appears.

```text
10  12  14  16
 9  11  13  15
 8  10  12  14
 7   9  11  13
```

**The reconstruction is falsified against the mistake it could hide.** A pipeline that
ignored the in-plane `y` step and read volume row zero throughout would publish `10 + u - v`,
which differs at every column past the first.

## The finding: a planar request with a zero out-of-plane column is refused

Building the request the obvious way — the two in-plane directions in slots `0` and `1`,
zeros in slot `2` because the sampling loop never reads it — throws `singularTransform`.

`AffineGridGeometry` requires an invertible matrix, and the sampling loop's indifference to
slot `2` does not extend to the geometry's admission. The fix is to supply the plane normal,
here `(1, -2, 0)`, which moves not a single sample.

This is worth recording because it is exactly the shape a caller assembling a multiplanar
request from two direction cosines will hit, and the error name points at the matrix rather
than at the omission.

## Alternatives considered

### Feed the `int16` phantom straight to the oblique operation

Not available. `ADR-0142` restricts that operation to the display-policy value domain —
`uint8`, one component, no value transform — so the window stage is part of the pipeline
rather than a convenience.

### Use a narrow window before reconstructing

Rejected. It would quantise the ramp and destroy the closed form, leaving the reconstruction
comparable only against another implementation, which is what a phantom exists to avoid.

### Reconstruct an axis-aligned plane

Rejected. It would pass for a pipeline that ignored the in-plane step entirely, which is the
defect the spatial kind of this row is meant to catch.

### Assert the reconstruction with a tolerance

Not needed, and therefore not done. The geometry was chosen so the interpolation weights are
exactly one half over small integers.

## Consequences

`VOX-VAL-003` is discharged on pipeline evidence rather than on self-verifying phantom
suites, which is what `ADR-0296` said the row required.

**18 entered-milestone rows remain** from `ADR-0290`'s sweep.

Plan §55.3's fiducials and §55.5's padding border are **not** built. `ADR-0293` decision 2
scheduled them "after, as their consuming rows need them", and no row currently needs them —
building them now would be manufacturing coverage rather than answering a requirement.

## Affected modules

None. Four tests in `VoxeliaValidationTests`; no source file changes.

## Compatibility impact

None.

## Security impact

None. The phantoms are synthetic by definition and touch no patient data.

## Performance and memory impact

None.

## Validation impact

```text
swift build && swift test
swift test --filter "PhantomPipelineTests"
swift format lint --strict Tests/VoxeliaValidationTests/PhantomPipelineTests.swift
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1212 tests in 214 suites pass, up from 1208 in 213.

## Migration

1. This record and four tests. No source changed.
2. **Next**: the derived queue's remaining 18 rows.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **completes** `ADR-0293`'s arc for `VOX-VAL-003` and
discharges the obligation `ADR-0296` named.

## References

- [ADR-0142 - Oblique slice operation](ADR-0142-oblique-slice-operation.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0293 - Open the analytical phantom arc](ADR-0293-open-the-analytical-phantom-arc.md)
- [ADR-0294 - Linear ramp phantom](ADR-0294-linear-ramp-phantom.md)
- [ADR-0295 - Distance phantom](ADR-0295-distance-phantom.md)
- [ADR-0296 - Physical-coordinate ramp phantom](ADR-0296-physical-coordinate-ramp-phantom.md)
- [VOXELIA-ALG-0002 - Window level linear](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
