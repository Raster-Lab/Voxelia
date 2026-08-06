---
document_id: "ADR-0239"
title: "Stored sample normalisation"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-005"
  - "VOX-VS1-005"
  - "VOX-VS1-006"
---

# ADR-0239 - Stored sample normalisation

## Context

`ADR-0238` opened the bridge arc and named the narrowed-bit-count trap as its
hardest question. This record settles it.

**It also corrects that record's stated increment order.** `ADR-0238` listed the
descriptor as increment (a) and this decision as (c), but the descriptor *declares*
the scalar format, so it cannot be written before this question is answered. The
dependency runs the other way, and the order is corrected here rather than
silently rearranged.

## The trap, restated precisely

When Bits Stored is narrower than Bits Allocated — a twelve-bit sample in a
sixteen-bit container — the bytes `ADR-0235`'s transfer places in the volume hold
full containers whose low twelve bits are meaningful. A published
`ImageDescriptor` then has two available declarations and both fail:

- `validBitCount: 12` is **accurate** and is **refused**: `ADR-0237` established
  that `LabelledSurfaceSourceAdapter` and `TriangleMeshVertexNormalGeneration`
  reject a narrowed count, and every other accepted operation constructs formats
  with `nil`. Nothing in the project masks by it.
- `validBitCount: nil` is **accepted** and is **wrong for signed data**: a raw
  `0x0FFF` reads as `4095` where the sample means `-1`. That 4096 gap is exactly
  what `VOXELIA-ALG-0051`'s sign extension exists to close.

## Decision

1. **Samples are normalised before transfer**: each stored value is re-encoded as
   a **full-width container**, and the published descriptor declares
   `validBitCount: nil`. This is `ADR-0238`'s third option, and it is the only one
   that is both accepted by the pipeline and correct for signed data.
2. **Normalisation is a separate, named stage — not part of the transfer.**
   `ADR-0235` decision 2 keeps the transfer byte-level and ignorant of signedness,
   and that still holds: the caller normalises a frame's bytes and hands the result
   to the unchanged transfer. `CTVolumeByteBuffer` and `DICOMFrameTransfer` need no
   modification.
3. **It is a re-encoding, not an interpretation, and the distinction is load-bearing.**
   Normalisation applies no rescale, excludes no padding and produces no real
   value. It rewrites the *same stored integer* at the container's width. Value
   interpretation stays where `ADR-0236` put it.
4. **The property is verified exhaustively, not by fixtures.** The defining
   property — reading the normalised container at full width yields the same stored
   value as reading the original at its narrower width — was checked over **every**
   8-bit and 16-bit container value, **every** Bits Stored width from 1 to the
   container width, and **both** signedness choices: **2,101,248 cases, zero
   failures**. Evidence:
   `docs/progress/evidence/ADR-0239-sample-normalisation-exhaustive.py`.
5. **A fixture table would have been weaker and is deliberately not used.** The
   input space is small enough to enumerate completely, so enumerating it is
   strictly better evidence than any sample of it. Where exhaustion is available,
   this project should prefer it.
6. **Normalisation is the identity at full width**, verified for every value of
   both container widths and both signs. So a series whose Bits Stored equals its
   container width — which is the owner's entire measured corpus — pays **nothing**:
   the implementation detects the identity case and skips the pass.
7. **No new algorithm specification is issued.** Normalisation is defined by its
   round-trip relationship to `VOXELIA-ALG-0051` stage 2, which already freezes the
   masking and sign extension; the re-encoding is two's complement truncation to the
   container width, exact integer work with no rounding. Freezing it separately
   would be the duplicate-specification mistake `ADR-0237` just corrected.

## Consequences

The descriptor increment can now proceed: it declares `validBitCount: nil`
truthfully, because the bytes really do hold full-width values.

A twelve-bit signed CT — which the owner's corpus does not contain, and which would
otherwise have been misread by 4096 — is handled correctly, and the handling is
proved rather than sampled.

The measured corpus is unaffected in behaviour and in cost.

## Alternatives considered

### Declare `validBitCount: nil` and transfer bytes unchanged

Rejected; see the trap. It is correct for the measured corpus and silently wrong
for narrowed signed data, which is the most dangerous combination available: it
passes every test that exists today.

### Declare `validBitCount: bitsStored` and widen the accepted operations to mask

Rejected for now, and it is the respectable alternative. It would make the
descriptor accurate and push the work into the consumers — but it changes two
accepted, tested operations and every future consumer would have to remember to
mask. Normalising once at ingest means every consumer is correct by default.

### Normalise the whole buffer after transfer

Rejected. It is a second full pass over the volume — 449 MiB at the ~120 MiB/s
`ADR-0235` measured — where normalising per frame before the write is fused into
the existing pass.

### Put normalisation inside the transfer

Rejected; see decision 2. It would give the transfer knowledge of signedness that
`ADR-0235` decision 2 deliberately withheld, and the separation costs nothing.

### Write a fixture table for the record

Rejected; see decision 5.

## Affected modules

`VoxeliaImaging` gains `CTSampleNormalisation`. **No accepted type is modified**,
and neither `CTVolumeByteBuffer` nor `DICOMFrameTransfer` changes.

## Compatibility impact

None. At full width the transformation is the identity, so existing behaviour on
the measured corpus is bit-identical.

## Security impact

Positive: it removes a path by which a narrowed signed volume would have been
published with a descriptor that misdescribes it.

## Performance and memory impact

Zero for full-width formats, which the identity check skips. For a narrowed
format, one pass over a frame's bytes fused with the existing transfer, not a
second pass over the volume.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0239-sample-normalisation-exhaustive.py
swift build && swift test
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This record and `CTSampleNormalisation`.
2. Then the descriptor increment, which may now declare `validBitCount: nil`
   truthfully.
3. Then the remaining `ADR-0238` increments: storage binding, provenance,
   identity and publication, end-to-end slice extraction.

## Supersession

This record supersedes nothing. It settles `ADR-0238`'s increment (c) and
**corrects that record's stated increment order**, recording the correction here
rather than editing it.

## References

- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [ADR-0236 - Stored value interpretation](ADR-0236-stored-value-interpretation.md)
- [ADR-0237 - Duplicate rescale freeze correction](ADR-0237-duplicate-rescale-freeze-correction.md)
- [ADR-0238 - Published volume bridge arc](ADR-0238-published-volume-bridge-arc.md)
- [VOXELIA-ALG-0051 - CT stored-value interpretation](../../algorithms/VOXELIA-ALG-0051-stored-value-interpretation.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
