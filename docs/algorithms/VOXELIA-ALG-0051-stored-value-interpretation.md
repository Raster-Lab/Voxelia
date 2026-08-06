---
document_id: "VOXELIA-ALG-0051"
title: "CT stored-value interpretation binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# CT stored-value interpretation binary64-v1

## Purpose

This specification defines `ct-value-interpretation/binary64-v1`, the conversion
of one stored CT sample into a real measured value, selected by accepted
[`ADR-0236`](../architecture/decisions/ADR-0236-stored-value-interpretation.md).

It serves `VOX-DCM-006` and `VOX-DCM-008`, and it is the stage four accepted
records deferred value questions to: `ADR-0227` decision 5, `ADR-0229`
decision 10, `ADR-0232` and `ADR-0235` decision 2.

## Two kinds of arithmetic, kept apart

Stored-value decoding is **exact integer work** — byte assembly, masking and sign
extension. No rounding is possible and no tolerance exists.

The rescale is **IEEE-754 binary64** in a frozen expression order. Keeping the
two separate matters, because it makes clear that everything before the rescale is
bit-exact by construction and only the final expression needs an ordering rule.

## Stage 1: the container

```text
container = sum over i of ( byte[i] << (8 * i) )
```

Little-endian, because DICOM explicit VR little endian is what the adapter
records. **No other byte order is claimed**, and a format declaring one is
refused rather than reinterpreted.

## Stage 2: the stored value

```text
mask  = (1 << bitsStored) - 1
value = container & mask
if signed and (value & (1 << (bitsStored - 1))) != 0:
    value = value - (1 << bitsStored)
```

**Only `highBit == bitsStored - 1` is supported** — the stored value in the low
bits. Any other High Bit is **refused**, not guessed: DICOM permits the stored
value to sit elsewhere in the container, and implementing a case with no fixture
and no observed instance would be a claim beyond the implementation.

Sign extension is the boundary this specification most needs fixtures for. A
twelve-bit signed `0x0FFF` is **-1**, not 4095, and the same bits unsigned are
4095.

## Stage 3: padding, compared before the rescale

```text
if padding is present and value == padding:  the sample is padding
```

The comparison is on the **stored** value, never the rescaled one. Fixture V10
exists to catch the alternative: a sample whose *rescaled* value happens to equal
the padding number is a measured sample, and treating it as padding would delete
real signal.

## Stage 4: the rescale

```text
measured = (slope * Double(value)) + intercept
```

Frozen order, no fused multiply-add. The integer-to-`Double` conversion is exact
for every format this specification admits, so the only inexactness is in the
product and sum.

## The zero-slope finding

A slope of exactly zero maps every stored value to the intercept. `ADR-0227`
decision 5 admitted it and assigned the judgement here.

**It is computed and reported, not refused.** `0 * x + b` is well defined, and the
result is a constant volume — which is useless but not undefined. Following the
measurement-and-judgement split `ADR-0229` established, the arithmetic proceeds
and a `degenerateSlope` finding records the fact for the caller. Fixture V11 is
that case.

## Numeric rules

- Integer stages: exact, no rounding, no tolerance.
- Rescale: IEEE-754 binary64, frozen expression order, no fused multiply-add.
- No epsilon anywhere.

## Frozen fixtures

Computed by the independent oracle at
`docs/progress/evidence/ADR-0236-value-interpretation-oracle.py`.

| Fixture | Bytes | Bits | Signed | Slope / intercept | Stored | Result |
|---|---|---|---|---|---|---|
| V1 | `18 FC` | 16 | yes | 1 / 0 | `-1000` | `-0x1.f400000000000p+9` |
| V2 | `18 00` | 16 | no | 1 / -1024 | `24` | `-0x1.f400000000000p+9` |
| V3 | `FF 0F` | 12 | yes | 1 / 0 | **`-1`** | `-0x1.0p+0` |
| V4 | `00 08` | 12 | yes | 1 / 0 | `-2048` | `-0x1.0p+11` |
| V5 | `FF 07` | 12 | yes | 1 / 0 | `2047` | `0x1.ffc0000000000p+10` |
| V6 | `FF 0F` | 12 | **no** | 1 / 0 | **`4095`** | `0x1.ffe0000000000p+11` |
| V7 | `FF FF` | 12 | no | 1 / 0 | `4095` | `0x1.ffe0000000000p+11` |
| V8 | `64 00` | 16 | no | 2.5 / -1024 | `100` | `-0x1.8300000000000p+9` |
| V9 | `30 F8` | 16 | yes | 1 / -1024, pad `-2000` | `-2000` | **padding** |
| V10 | `00 00` | 16 | yes | 1 / -2000, pad `-2000` | `0` | **measured** `-0x1.f400000000000p+10` |
| V11 | `64 00` | 16 | no | **0** / -1024 | `100` | `-0x1.0p+10`, `degenerateSlope` |
| V12 | `7F` | 8 | no | 1 / 0 | `127` | `0x1.fc00000000000p+6` |
| V13 | `FF` | 8 | yes | 1 / 0 | **`-1`** | `-0x1.0p+0` |
| V14 | `03 00` | 16 | no | 0.1 / 0 | `3` | `0x1.3333333333334p-2` |

Five fixtures carry the specification's weight.

**V1 and V2 reach the same -1000 HU by the two conventions real scanners use** —
signed samples with a zero intercept, and unsigned samples with a -1024
intercept. An implementation that handled only one would pass half this corpus.

**V3 against V6** is the sign-extension boundary: identical bytes, identical bit
depth, opposite Pixel Representation, and results differing by 4096.

**V7** proves the mask: bits above `bitsStored` are discarded rather than
contributing.

**V10 against V9** is the padding-order discriminator described above.

**V14** shows the rescale is genuinely binary64: `0.1 * 3` is
`0.30000000000000004`, not `0.3`.

## Conformance

An implementation conforms when, for every fixture, it reproduces the stored
value exactly, the measured value bit-for-bit, the padding classification, and
the finding set.

## References

- [ADR-0227 - Neutral CT frame description](../architecture/decisions/ADR-0227-neutral-ct-frame-description.md)
- [ADR-0229 - CT series geometry validation](../architecture/decisions/ADR-0229-ct-series-geometry-validation.md)
- [ADR-0235 - Frame sample transfer](../architecture/decisions/ADR-0235-frame-sample-transfer.md)
- [ADR-0236 - Stored value interpretation](../architecture/decisions/ADR-0236-stored-value-interpretation.md)
