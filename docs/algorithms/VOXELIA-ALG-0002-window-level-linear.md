---
document_id: "VOXELIA-ALG-0002"
title: "Window-level linear mapping binary64-v1"
version: "1.1"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-04"
owner: "Voxelia Project"
---

# Window-level linear mapping binary64-v1

## Purpose

This specification defines the versioned reference operation
`window-level-linear/binary64-v1` selected by accepted
[`ADR-0065`](../architecture/decisions/ADR-0065-window-level-operation.md).
It maps stored scalar intensity samples through the DICOM-derived
linear window function to the eight-bit display range `0...255`. The
public receiver is `WindowLevelOperation.execute` in
`VoxeliaExecution`.

## Supported formats

The registered format set admits stored sample types `uint8`, `int16`
and — since revision 1.1 under accepted `ADR-0068` — `uint16`, each
with one scalar component per sample. All intermediate arithmetic uses
IEEE-754 binary64 (`Double`); every admitted stored sample value
converts to binary64 exactly. The output sample type is `uint8`.

## Inputs and outputs

Inputs:

- one admitted image whose canonical packed decoded bytes supply the
  stored samples;
- one finite binary64 window centre `c`; and
- one finite binary64 window width `w` with `w >= 1`.

Output: one canonical packed `uint8` sample per input sample, in the
same sample order.

## Model and evaluation order

For each stored sample value `x` converted exactly to binary64, the
following binary64 expressions are evaluated in exactly this order and
association:

```text
halfSpan   = (w - 1.0) / 2.0
threshold  = c - 0.5
lowerEdge  = threshold - halfSpan
upperEdge  = threshold + halfSpan

if x <= lowerEdge          -> y = 0
else if x > upperEdge      -> y = 255
else                       -> y = round(((x - threshold) / (w - 1.0)
                                          + 0.5) * 255.0)
```

The three branches are total for every `w >= 1`: when `w == 1.0` the
two edges coincide at `threshold`, the interior branch is unreachable
and the division never executes, so the degenerate window is a pure
threshold with no special case.

## Rounding and clamping

`round` is IEEE-754 `roundTiesToEven` to an integral binary64
(`FloatingPoint.rounded(.toNearestOrEven)`), after which the value is
clamped to `0...255` before conversion to `uint8`. Within the interior
branch the real-valued result lies in `[0, 255]`; the clamp guards the
one-ulp excursions binary64 evaluation can introduce and is part of
the model, not an error path.

## Byte-order resolution

`int16` and `uint16` stored samples are assembled from exactly two
bytes under the descriptor's declared byte order. The `littleEndian` and `bigEndian`
declarations assemble explicitly; the `native` declaration resolves to
little-endian on every supported Apple-silicon platform, and this
resolution is part of the version-one model.

## Determinism and failure classification

The mapping is a pure function of the stored bytes, the byte order,
`c` and `w`: repeated evaluation is bit-identical on every conforming
IEEE-754 binary64 implementation. A width below one is a typed
admission failure in the receiver, never a clamped or substituted
value; no branch of the model itself can fail.

## Conformance fixtures

Independently computed with binary64 arithmetic and half-to-even
rounding:

- `uint8` stored samples `0...11`, `c = 6`, `w = 8`:
  `[0, 0, 0, 36, 73, 109, 146, 182, 219, 255, 255, 255]`.
- `int16` stored samples
  `[-1024, -200, -100, 0, 20, 40, 60, 80, 120, 200, 1000, 3000]`,
  `c = 40`, `w = 400`:
  `[0, 0, 38, 102, 115, 128, 141, 153, 179, 230, 255, 255]`.
- The same `int16` samples with `c = 40`, `w = 1`:
  `[0, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255]`.
- `uint16` stored samples
  `[0, 100, 500, 1000, 2000, 4000, 8000, 16000, 32000, 48000, 60000, 65535]`,
  `c = 32000`, `w = 64000` (revision 1.1):
  `[0, 0, 2, 4, 8, 16, 32, 64, 128, 191, 239, 255]`.

## References

- [ADR-0065 - Window-level operation](../architecture/decisions/ADR-0065-window-level-operation.md)
- DICOM PS3.3 C.11.2.1.2 (the linear VOI LUT function this model
  derives from; this specification, not DICOM, is normative for
  Voxelia)
