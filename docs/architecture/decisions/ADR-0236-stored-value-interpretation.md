---
document_id: "ADR-0236"
title: "Stored value interpretation"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-005"
  - "VOX-DCM-006"
  - "VOX-DCM-008"
  - "VOX-VS1-004"
---

# ADR-0236 - Stored value interpretation

## Context

`ADR-0235` completed the first vertical slice's byte path: a real 899-slice series
assembles into a 449 MiB volume with every slice byte-exact. What the bytes
**mean** is still undefined, and that is now the only substantive gap between the
buffer and a usable CT volume.

This is the stage **four accepted records deferred value questions to**:

- `ADR-0227` decision 5 admitted a zero rescale slope and assigned the judgement
  here.
- `ADR-0229` decision 10 classified contradictory rescale terms as a warning and
  assigned them here.
- `ADR-0232` kept value interpretation out of the addressing contract.
- `ADR-0235` decision 2 kept endianness, signedness, rescale and padding out of
  the transfer.

Deferring four times to a stage that did not exist would be a way of never
deciding. This record makes it exist.

## Decision

1. **Interpretation is per sample, not per volume.** `CTValueInterpreter` maps one
   stored sample to one interpreted value. Transforming a whole volume is a
   performance-sensitive concern with its own trade-offs — `ADR-0235` measured the
   safe copy at 120 MiB/s, so a 235-million-sample transform is not a detail — and
   binding a volume-wide representation here would decide that by accident.
2. **The two kinds of arithmetic are kept apart.** Decoding is exact integer work;
   only the rescale is binary64 with a frozen order. `VOXELIA-ALG-0051` states
   both, and the separation makes clear that everything before the rescale is
   bit-exact by construction.
3. **Little-endian only.** DICOM explicit VR little endian is what
   `DICOMFrameAdapter` records. A format declaring another byte order is
   **refused**, not reinterpreted.
4. **Only `highBit == bitsStored - 1` is supported**, the stored value in the low
   bits. DICOM permits it elsewhere; implementing a case with no fixture and no
   observed instance would claim more than the implementation delivers. Other
   High Bit values are refused with their own case.
5. **Padding is compared on the stored value, before the rescale.** Fixture V10
   exists to catch the alternative: a sample whose *rescaled* value happens to
   equal the padding number is a measured sample, and treating it as padding would
   delete real signal at exactly one Hounsfield value.
6. **A zero slope is computed and reported, not refused** — closing `ADR-0227`
   decision 5. `0 * x + b` is well defined and yields a constant volume: useless
   but not undefined. Following the measurement-and-judgement split `ADR-0229`
   established, the arithmetic proceeds and a `degenerateSlope` finding records
   the fact. Refusing would have been the easier choice and would have made this
   stage the only one in the arc that judges rather than reports.
7. **The interpreted value is a two-case enum, not a sentinel.** `measured(Double)`
   or `padding`. A NaN sentinel would propagate silently through any later
   arithmetic, and a magic number would collide with real Hounsfield values.
8. **The interpreter is admitted once and reused.** Its parameters come from a
   `CTFrameDescription`, are validated on construction, and every sample then
   costs four integer operations and two floating-point ones with no
   per-sample re-validation.

## The finding: two scanner conventions reach the same value

Fixtures V1 and V2 both produce **-1000 HU** — air — by different routes: signed
samples with a zero intercept, and unsigned samples with a `-1024` intercept.
`ADR-0235`'s real-data run found this scanner emits **unsigned** samples, which
means the second route is the one the corpus actually exercises, and an
implementation that handled only the textbook signed case would have been wrong on
every study measured.

This is why signedness is read from Pixel Representation rather than assumed, and
why both routes have fixtures.

## What the real data added

The interpreter was run over the middle slice of `ADR-0235`'s 899-slice series.
The distribution is **clinically plausible** — 45.3% air, 16.3% lung and fat,
15.1% soft tissue, 3.3% dense soft tissue, 1.5% bone — so the values are the right
values and not merely well-formed ones.

Two findings, both recorded in
`docs/progress/evidence/VOX-VS1-001-real-ct-demonstration-2026-08-06.md`:

**The intercept is `-8192`, not the textbook `-1024`** that every hand-built
fixture in this repository uses. The adapter reads the attribute, so the result is
correct — but this is the second time real data has contradicted an assumption
baked into fixtures, after `ADR-0235` found the samples unsigned. The pattern is
worth naming: **fixtures written from domain convention encode the convention,
not the data.**

**The out-of-field region is not declared as padding, and `VOX-DCM-008`'s
mechanism therefore cannot exclude it.** 18.4% of the slice sits at or near the
`-8192` floor — the corners outside the circular reconstruction field, which
geometry puts at roughly 21.5% of a square array. The scanner declares **no**
Pixel Padding Value, so those samples are indistinguishable from measurements by
attribute alone. Padding exclusion is implemented correctly and verified by
fixtures V9 and V10; it simply has nothing to act on here. Excluding the region
would mean inferring it from the values — a segmentation decision with a
threshold, and so an owner decision of the same shape as the geometry tolerance.
It is recorded, not worked around.

## Alternatives considered

### Refuse a zero rescale slope

Rejected; see decision 6. It is defensible and it would make this stage
inconsistent with the rest of the arc, which measures and reports.

### Use NaN for padding

Rejected; see decision 7. It converts an explicit exclusion into a value that
poisons sums and comparisons silently.

### Compare padding after the rescale

Rejected; see decision 5, and fixture V10.

### Interpret a whole volume in one call

Rejected; see decision 1. It is the obviously useful API and it decides a
representation and a performance trade-off this record has no evidence for yet.

### Support any High Bit by shifting

Rejected; see decision 4. The shift is easy; the confidence is not.

## Consequences

The byte buffer becomes interpretable, so the first vertical slice can produce
Hounsfield values rather than bytes.

Four accepted deferrals are discharged. A whole-volume transform is not provided
and is named as the next question rather than implied.

## Affected modules

`VoxeliaImaging` gains `CTValueInterpreter`, `CTInterpretedValue`,
`CTValueInterpretationFinding` and a failure family. No module's dependencies
change.

## Compatibility impact

Additive.

## Security impact

None new. The failure family is payload-free, and the interpreter allocates
nothing per sample.

## Performance and memory impact

Per sample: a mask, a conditional subtraction, an equality test, one
multiplication and one addition. The interpreter is a value type holding six
fields.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0236-value-interpretation-oracle.py
swift build && swift test
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This increment: the interpreter, verified against all fourteen fixtures.
2. **Next**: a whole-volume transform, which must decide an output representation
   and confront the 120 MiB/s figure `ADR-0235` measured.
3. **Still open, unchanged**: the geometry tolerance rule (`ADR-0229`,
   `ADR-0234`).

## Supersession

This record supersedes nothing. It **discharges** the deferrals in `ADR-0227`
decision 5, `ADR-0229` decision 10, `ADR-0232` and `ADR-0235` decision 2.

## References

- [ADR-0227 - Neutral CT frame description](ADR-0227-neutral-ct-frame-description.md)
- [ADR-0229 - CT series geometry validation](ADR-0229-ct-series-geometry-validation.md)
- [ADR-0232 - CT volume sample layout](ADR-0232-ct-volume-sample-layout.md)
- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [VOXELIA-ALG-0051 - CT stored-value interpretation](../../algorithms/VOXELIA-ALG-0051-stored-value-interpretation.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
