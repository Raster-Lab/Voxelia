---
document_id: "ADR-0299"
title: "Lossless equality and random access correctness"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-013"
---

# ADR-0299 - Lossless equality and random access correctness

## Context

`VOX-VAL-013` requires that "compression validation shall include lossless equality and
random-access correctness". P0, `T` alone, milestone M5, from `ADR-0290`'s sweep.

`ADR-0271` measured random-access decode in a scratch benchmark and reported its cost. A
measurement is not a correctness test, and `VOXELIA-BEN-0002` is not a repository suite. This
row asks for the test.

## The assessment

`VoxeliaCompression` links `J2KCodec` and `J2K3D`, and its existing suites cover the arc's
own vocabulary — scopes, payloads, destination admission, header budgets, the volume adapter.
Every one of those tests **constructs** a `J2KVolume` by hand.

Nothing in the repository had ever run the codec: no test encoded anything, and no test
decoded anything. The adapter suite's own comment says so plainly, noting that
`JP3DDecoderResult` has no public initialiser and that its fixtures are therefore built
around that.

So both halves of this row were untested, and this increment runs the codec for the first
time inside the test suite.

## Decision

1. **The fixture is a positional phantom.** Every voxel holds `100i + 10j + k`, so its value
   names its own index. Every extent is below ten, so the three place values never carry into
   one another and the map from index to value is **injective** — asserted, not assumed.
2. **Injectivity is what makes the random-access half discriminating.** A region decode that
   returned the right shape from the wrong offset would be invisible against noise or against
   a constant, and is immediate against this.
3. **Lossless equality is asserted byte-for-byte**, not sample-by-sample with a tolerance.
   That is what the word means.
4. **The semantic round trip is asserted separately**, because byte equality alone would hold
   even if the codec had read every sample in the wrong byte order — it would then write them
   back the same way and the bytes would still match.
5. **The region is deliberately not anchored at the origin.** A region at `(0, 0, 0)` is
   returned correctly by a decoder that ignores the offset entirely, so it cannot demonstrate
   random access.
6. **The tile counts are asserted exactly** — one decoded, seven skipped of an eight-tile
   grid. `tilesSkipped > 0` would also hold for a decoder that skipped a single tile and
   decoded everything else, which is not random access.
7. **`VOX-VAL-013` is discharged** by six tests.

## What the tests establish about the dependency

All six passed on the first run. On this fixture, `J2KSwift`'s JP3D path is **correct in both
respects**: the lossless round trip is byte-exact, and a region decode returns that region's
own samples from a genuinely partial decode.

That is worth stating plainly, because `ADR-0272` and `ADR-0273` recorded real defects and
observations in the same dependency. Those findings stand and this one does not soften them;
it records a different part of the surface behaving correctly under test.

## The tests

- **Injectivity of the fixture**, so the comparisons below cannot pass on a coincidence.
- **Byte-exact lossless round trip**, with the tile count and extents also asserted.
- **Value-exact round trip** at every index, which byte equality does not imply.
- **A region decode away from the origin**, compared against the closed form at **absolute**
  indices, and against `decodedRegion` rather than the requested region so a clamped or
  expanded region is checked where it actually landed.
- **Two disjoint regions return different samples** — the falsification for a decoder that
  served one block regardless of the request.
- **The region agrees with the full decode it subsets**, so the two code paths are compared
  against each other as well as against the closed form.

## Alternatives considered

### Use random bytes as the fixture

Rejected, and this is the choice that mattered. Random data makes lossless equality easy to
check and random-access correctness nearly impossible: a wrong offset returns bytes that look
exactly as valid as the right ones. The positional phantom makes the offset readable.

### Assert `tilesSkipped > 0`

Rejected; see decision 6. It is satisfied by a decoder doing almost all the work.

### Compare only against the full decode

Rejected as insufficient on its own. Two paths agreeing shows consistency, not correctness —
they could share a defect. The closed form is the independent reference, and the cross-check
is kept as well because it costs nothing.

### Test lossy modes too

Out of scope. The row names lossless equality, `ADR-0271` decision 5 already declined to
benchmark lossy modes, and no requirement asks for lossy diagnostic data.

## Consequences

`VOX-VAL-013` is discharged, and the repository suite now exercises the codec rather than
only the vocabulary around it.

**16 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. Six tests in `VoxeliaCompressionTests`; no source file changes.

## Compatibility impact

None.

## Security impact

None. The fixture is generated in the test and no patient data is read.

## Performance and memory impact

None to the product. The suite encodes and decodes an `8 x 6 x 4` volume, which completes in
well under a tenth of a second.

## Validation impact

```text
swift build && swift test
swift test --filter "LosslessAndRandomAccessTests"
swift format lint --strict Tests/VoxeliaCompressionTests/LosslessAndRandomAccessTests.swift
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1224 tests in 216 suites pass, up from 1218 in 215.

## Migration

1. This record and six tests. No source changed.
2. **Next**: the derived queue's remaining 16 rows.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **discharges** `VOX-VAL-013` with the correctness tests
`ADR-0271`'s measurements deliberately were not.

## References

- [ADR-0271 - Compression benchmark and random access](ADR-0271-compression-benchmark-and-random-access.md)
- [ADR-0272 - Codec output and interoperability status](ADR-0272-codec-output-and-interoperability-status.md)
- [ADR-0273 - Bounded failure on adversarial codestreams](ADR-0273-bounded-failure-on-adversarial-codestreams.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
