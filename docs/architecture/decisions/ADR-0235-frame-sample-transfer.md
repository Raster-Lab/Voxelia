---
document_id: "ADR-0235"
title: "Frame sample transfer"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-003"
  - "VOX-DCM-005"
  - "VOX-SEC-001"
  - "VOX-VS1-001"
  - "VOX-VS1-004"
---

# ADR-0235 - Frame sample transfer

## Context

`ADR-0232` built the addressing contract for direct-write frame transfer and
deliberately defined no destination buffer, because there was no producer to
satisfy one. `ADR-0233` built the producer. This record adds the transfer, which
is the last part of the first vertical slice never exercised.

## The finding: ADR-0230 decision 10 chose a model DICOMKit cannot serve

`ADR-0230` decision 10 read the First Vertical Slice Plan's §16.1, which
enumerates three sample-ownership models — direct-write into a caller-provided
destination, an owned immutable buffer, or a borrowed buffer requiring a copy —
and chose **direct-write**, reasoning that only it achieves the plan's stated goal
of transfer "without unnecessary intermediate copies".

**DICOMKit implements the second model.** Its pixel surface is
`pixelData() -> PixelData?` with `data: Data`, and `frameData(at:) -> Data?`.
Both return an owned `Data`. There is no entry point that writes into a
caller-provided destination.

So decision 10 is **not implementable at the DICOMKit boundary**, and the reason
is instructive: it was decided in increment (d), before increment (e) read
DICOMKit's API. It is the same unstated-assumption failure this project keeps
catching in its own records, and this time the assumption was mine.

**The correction, and why the plan's goal is still met.** The achievable model is
DICOMKit returns an owned frame buffer and Voxelia copies it into that frame's
slice of the volume. That is **one copy per frame, and it is not an unnecessary
one**: the volume has to be materialised somewhere, and the copy is the
materialisation. What direct-write would have avoided is a *second* copy, and
there is none. The plan's requirement is satisfied as well as the dependency
permits.

A true direct-write path would need an upstream addition to DICOMKit — a decode
entry point taking a destination. DICOMKit is a Raster-Lab repository, so that is
available to the owner as a future option; it is recorded here and not assumed.

## Decision

1. **The destination is a byte buffer, not a typed sample buffer.**
   `CTVolumeByteBuffer` holds exactly `CTVolumeLayout.byteCount` bytes and the
   layout that describes them.
2. **The transfer is byte-level, and that is a deliberate scope boundary rather
   than laziness.** Moving a frame's bytes into its slice requires **no**
   interpretation: no endianness decision, no signedness decision, no rescale.
   Every one of those is a value-transformation question belonging to the stage
   `VOX-DCM-006` requires — the same stage `ADR-0227` decision 5 assigned the
   degenerate rescale slope and `ADR-0229` decision 10 assigned contradictory
   rescale terms. Interpreting values here would be the fourth time this arc
   pulled that question into the wrong increment.
3. **No pointer or unsafe API is used.** The Swift safety policy reserves the
   bare `unsafe` marker, and `-strict-memory-safety` diagnoses pointer APIs, so
   the copy is a plain element-wise write over a `ContiguousArray<UInt8>`. A
   reference path in this project is deterministic and safe before it is fast, and
   the transfer is memory-bandwidth-bound rather than arithmetic-bound anyway.
4. **Admission is exact equality, and there is no new numeric boundary.** The
   byte arithmetic was frozen by `VOXELIA-ALG-0050`; the transfer adds only three
   exact checks — the placement's layout equals the buffer's, the frame's byte
   count equals `samplesPerSlice * bytesPerSample`, and the destination range
   lies inside the buffer. No algorithm specification accompanies this record,
   for the same reason `ADR-0227` carried none.
5. **The destination range check is retained even though admission makes it
   unreachable**, because it is the one check standing between a wrong layout and
   an out-of-range write. `ADR-0232` decision 4 discharged offset overflow by
   argument; a write is where being wrong is unrecoverable, so this one is
   checked rather than argued.
6. **The buffer is zero-filled on creation.** A frame that is never written
   leaves zeros rather than arbitrary memory, so a partially assembled volume is
   deterministic. Whether *unwritten* slices should be detectable is decided in
   decision 7 rather than left to the reader's inspection of zeros.
7. **The buffer tracks which slices have been written.** A volume assembled from
   a series must have every slice filled, and "the bytes look plausible" is not a
   check. `writtenSliceCount` and `isComplete` make an incomplete transfer a
   fact the caller can assert rather than a silence.
8. **Re-writing a slice is permitted and overwrites.** It is not an error: a
   caller retrying a failed decode is legitimate, and the written-slice set makes
   the outcome observable either way.

## Alternatives considered

### Keep decision 10 and claim direct-write

Rejected. DICOMKit returns owned `Data`; claiming a direct-write path over it
would describe an implementation that does not exist.

### Ask for an upstream DICOMKit change first

Not rejected — deferred to the owner, and recorded in the finding above. Blocking
the last part of the vertical slice on a dependency change would idle work that
the current API supports perfectly well.

### Make the destination a typed `ContiguousArray<Int16>`

Rejected; see decision 2. It would force an endianness and signedness decision
into the transfer, and `VOX-DCM-005` admits both signed and unsigned sixteen-bit
samples, so the type would have to be a union or the buffer would have to be
generic over a decision this increment has no authority to make.

### Use `withUnsafeBytes` for a fast bulk copy

Rejected; see decision 3. It is the obvious performance answer and it collides
with two accepted policies at once.

### Omit the written-slice tracking

Rejected; see decision 7. A volume that is silently missing a slice is exactly
the class of plausible-but-wrong result this project's admissions exist to catch.

## Consequences

The first vertical slice is now exercisable end to end: parse, adapt, group,
validate, construct the affine, and fill the volume's bytes.

`ADR-0230` decision 10's ownership model is corrected in the record rather than
in the record that made it. A genuine direct-write path remains available as an
upstream option.

Value interpretation — endianness, signedness, rescale, padding — is still
unimplemented, and is now the only substantive gap between this arc and a usable
CT volume.

## Affected modules

`VoxeliaImaging` gains `CTVolumeByteBuffer` and its failure family.
`VoxeliaDICOMKit` gains the frame-bytes transfer. No module's dependencies
change.

## Compatibility impact

Additive.

## Security impact

Positive, and this is the decision's most load-bearing part. The destination
range is checked on every write rather than trusted, no pointer or unsafe API is
used, and the failure family is payload-free. `VOX-SEC-001` is served by the
buffer being sized from the admitted layout and never grown.

## Performance and memory impact

One copy per frame, which is the materialisation. The buffer allocates
`byteCount` once and never reallocates.

**The cost of decision 3 is measured, not estimated.** A real 512x512x899 uint16
series — 449 MiB — transferred in 3.77 s, about 120 MiB/s. A bulk memory copy
would be one to two orders of magnitude faster. For a single study that is a few
seconds; for a workflow loading several it would be noticeable. The options are an
upstream DICOMKit decode-into-destination entry point or a governed exception to
the safety policy, and neither is taken here — but the number is recorded so the
trade-off can be argued from evidence rather than from intuition.

## Validation impact

```text
swift build && swift test
swift test --filter "CTVolumeByteBuffer|DICOMFrameTransfer"
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

Plus a recorded run against the owner's real CT data: a 899-slice series
assembled into a 449 MiB volume with **899 of 899 slices byte-exact** against
DICOMKit's own frame bytes, verified independently of the transfer. Evidence in
`docs/progress/evidence/VOX-VS1-001-real-ct-demonstration-2026-08-06.md`.

That run also found that this scanner's samples are **unsigned** — Pixel
Representation `0`, so `uint16` — while every hand-built fixture in the
repository defaults to `int16`. The adapter reads the attribute rather than
assuming, so it was correct; the assumption in the fixtures was not
representative.

## Migration

1. This increment: the buffer, the transfer, and a real-data verification.
2. **Open**: value interpretation under `VOX-DCM-006` — endianness, signedness,
   rescale and padding — which four records have now deferred to it and which
   should be the next arc rather than a footnote.
3. **Owner option**: an upstream DICOMKit decode-into-destination entry point,
   which would make true direct-write available.

## Supersession

This record supersedes nothing. It **corrects `ADR-0230` decision 10's ownership
model** — recording the correction here rather than editing that record.

## References

- [ADR-0230 - CT affine volume construction](ADR-0230-ct-affine-volume-construction.md)
- [ADR-0232 - CT volume sample layout](ADR-0232-ct-volume-sample-layout.md)
- [ADR-0233 - DICOMKit adapter and dependency](ADR-0233-dicomkit-adapter-and-dependency.md)
- [VOXELIA-ALG-0050 - CT volume sample layout](../../algorithms/VOXELIA-ALG-0050-volume-sample-layout.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
