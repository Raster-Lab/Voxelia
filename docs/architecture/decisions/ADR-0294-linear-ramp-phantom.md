---
document_id: "ADR-0294"
title: "Linear ramp phantom"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-003"
---

# ADR-0294 - Linear ramp phantom

## Context

`ADR-0293` opened the analytical phantom arc and set the order: plan §55.1's linear ramp
first, because it is exact integer arithmetic and unblocks the intensity kind of
`VOX-VAL-003`. This builds it, and it is `VoxeliaValidation`'s first public surface.

```text
value(i, j, k) = 2i + 3j - 5k + 100
```

## Decision

1. **`LinearRampPhantom` is public in `VoxeliaValidation`**, per `ADR-0293` decision 4: a
   phantom locked inside a test target cannot serve the validation reports this project
   publishes.
2. **No algorithm specification governs it**, per `ADR-0293`'s assessment. Every term is an
   integer product of a small constant and an index, integer addition is associative and
   exact, so no evaluation order can change the result and there is nothing to freeze. Its
   sibling §55.2 is a binary64 sum whose order *is* observable and will get one.
3. **The range is checked, not bounded by a derived constant.** The formula increases in `i`
   and `j` and decreases in `k`, so its extremes sit at opposite corners of the box; both
   are computed in `Int` and refused if either escapes `Int16`. That is exact, and it avoids
   a magic extent limit that would need re-deriving if the coefficients ever changed.
4. **Sample order composes `VOXELIA-ALG-0050` rather than restating it** — slice-major, then
   row-major within a slice, column varying fastest. That specification notes `row * columns`
   and `row * rows` agree for every square frame and differ otherwise, which is why the
   tests use a non-cubic `7 × 5 × 3`.
5. **An index outside the phantom is refused**, because a phantom that answered for a
   position it does not contain would let a test assert against a value the volume never
   held.
6. **`VOX-VAL-003` is not discharged.** This supplies the intensity kind; spatial and
   measurement remain, and the row needs all three with tests that consume them.

## The test that matters, and why it is written twice

The suite transcribes the plan's formula **independently** rather than calling into the
type. A test that asked the phantom what it contains and compared the answer with itself
would pass for any formula at all, including a wrong one.

Beyond that:

- **Linearity is asserted as exact integer differences** — `+2`, `+3`, `-5` per axis step,
  everywhere. That property is what the plan's named purposes rest on: an interpolator's
  expected value at a continuous position is available in closed form only because the
  differences are constant.
- **Every materialised byte is decoded and compared to the formula**, and the walk is
  asserted to consume the buffer exactly, so a length or ordering error cannot hide in an
  unvisited tail.
- **Negative values are exercised deliberately.** The `-5k` term takes the ramp below zero
  once the slice index passes twenty, and a zero-extending encoder would turn those into
  large positives. A phantom shallow enough never to go negative would not detect that, so
  the test uses forty slices and asserts `-95` and `-90` exactly.
- **The refusals carry a positive control.** The largest extents that *do* fit are
  admitted — `16,334` columns reaching exactly `32,766`, and `6,574` slices reaching exactly
  `-32,765` — so the overflow refusals discriminate on the range rather than on size alone.

No tolerance appears anywhere in the suite, because nothing in it is inexact.

## Alternatives considered

### Store the phantom as a fixture file

Rejected in `ADR-0293` decision 3 and unchanged here: a generated volume cannot drift from
its own definition, a checked-in file can, and the file would then need integrity coverage
to notice that it had.

### Use a cubic phantom in the tests

Rejected. `VOXELIA-ALG-0050` says plainly that `row * columns` and `row * rows` agree for
every square frame, so a cubic fixture is blind to exactly the addressing mistake that
specification exists to catch.

### Bound the extents by a derived constant

Rejected; see decision 3. A constant like "at most 6,574 slices" is correct only for these
coefficients and would silently become wrong if they changed, where computing the corners
stays correct by construction.

### Return `Int` rather than `Int16` from the accessor

Rejected. The phantom's samples are `Int16` because that is what it materialises, and an
accessor returning a wider type would let a caller read a value the stored volume cannot
hold — the range check exists precisely so that cannot happen.

## Consequences

`VoxeliaValidation` has its first public surface, and the intensity kind of `VOX-VAL-003`
has a phantom whose expected values are known in closed form.

**The arc's next increment is §55.4's distance phantom**, which `ADR-0293` placed second
because `ADR-0292` has just verified the measurement chain it feeds.

## Affected modules

`VoxeliaValidation` gains `LinearRampPhantom` and `LinearRampPhantomError`, both listed in
its DocC catalogue. No other module changes and nothing new is imported.

## Compatibility impact

Additive.

## Security impact

None. The phantom is synthetic by definition and touches no patient data.

## Performance and memory impact

`storedBytes` materialises two bytes per sample on demand and the phantom itself holds three
integers. Callers wanting one value use the closed form and materialise nothing.

## Validation impact

```text
swift build && swift test
swift test --filter "LinearRampPhantom"
swift format lint --strict Sources/VoxeliaValidation/Public/LinearRampPhantom.swift
python3 Tools/Scripts/check_swift_safety.py
python3 Tools/Scripts/check_prohibited_imports.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1180 tests in 211 suites pass, up from 1172 in 210.

## Migration

1. This record, the phantom and eight tests.
2. **Next**: §55.4's distance phantom, then §55.2's physical-coordinate ramp design-first
   with its specification and oracle.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **implements plan §55.1** under `ADR-0293`'s frozen arc
decisions.

## References

- [ADR-0292 - Reconstructed measurement geometry](ADR-0292-reconstructed-measurement-geometry.md)
- [ADR-0293 - Open the analytical phantom arc](ADR-0293-open-the-analytical-phantom-arc.md)
- [VOXELIA-ALG-0050 - Volume sample layout](../../algorithms/VOXELIA-ALG-0050-volume-sample-layout.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
