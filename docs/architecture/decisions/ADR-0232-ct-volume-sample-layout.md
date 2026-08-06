---
document_id: "ADR-0232"
title: "CT volume sample layout"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-003"
  - "VOX-DCM-005"
  - "VOX-VS1-004"
---

# ADR-0232 - CT volume sample layout

## Context

`ADR-0231` split increment (e) of the `ADR-0226` arc after finding that DICOMKit
brings four gated codec libraries and one unlicensed package transitively. Its
supply-chain half (e2) is blocked on two owner decisions. This record performs
the unblocked half, **(e1)**: the Voxelia-owned addressing contract that makes
direct-write frame transfer possible.

`ADR-0230` decision 10 chose direct-write into a caller-provided destination,
because the plan's §16.1 requires transfer "without unnecessary intermediate
copies" and only direct-write achieves it. A frame decoder can only write
directly if it knows where its slice begins and how a row advances. That
knowledge is this increment.

## The finding: direct-write removes the plan's `CTFrameRecord`

The First Vertical Slice Plan sketches `CTFrameRecord` with a
`decodedSamples: CTFrameSamples` member, and `ADR-0227` decision 2 deferred that
type to increment (d), which in turn deferred its implementation to (e).

**Choosing direct-write makes that shape unnecessary rather than pending.** A
record holding decoded samples presupposes an intermediate owned buffer — which
is precisely one of §16.1's other two candidates, and precisely the copy
direct-write exists to avoid. If each frame decodes straight into its slice
offset, there is no owned sample buffer for a record to hold.

So this record implements the *placement* a frame needs and **does not implement
the plan's `CTFrameRecord`**. The plan describes its own sketch as "a planning
contract, not a final public API", so this is a permitted consequence of an
accepted decision rather than a contradiction — but it is a visible departure and
is recorded as one rather than left for a reader to notice.

## Decision

1. **`CTVolumeLayout` is the addressing contract**: `rows`, `columns`,
   `sliceCount` and one shared `ScalarFormat`. It holds no samples, allocates
   nothing, and computes offsets. `VOXELIA-ALG-0050` freezes its arithmetic.
2. **Addressing is slice-major, then row-major within a slice**, with the offset
   `((sliceIndex * samplesPerSlice) + (row * columns)) + column`. Fixture L5's
   complete offset table fixes the order unambiguously, and L7 exists because
   `row * columns` and `row * rows` agree for every square frame.
3. **The byte count is admitted, not just the sample count.** A sample count can
   be representable while its byte count is not. Fixtures L4 and L6 are the same
   extents differing only in the scalar format's width: one is refused and the
   other is admitted at exactly `Int.max`. An implementation checking only the
   sample count admits both, which is a heap overflow waiting for a wide format.
4. **Offset arithmetic after admission is discharged, not assumed.** The largest
   offset equals `sampleCount - 1`, which admission already established is
   representable, so no offset can overflow. Every fixture asserts that identity,
   which also means a layout leaving gaps or overlapping slices fails.
5. **This specification does not claim a frozen floating-point expression
   order, because there is no floating-point arithmetic and no ordering hazard.**
   For strictly positive factors any association of a product overflows exactly
   when the product overflows, since every intermediate is bounded by the total.
   Restating the house "frozen order, no FMA" rule here would claim a risk that
   does not exist, and a specification that guards against imaginary hazards
   teaches readers to skim the real ones.
6. **`CTFramePlacement` pairs a `CTFrameDescription` with the slice index it
   occupies**, and is admitted only when the description's extents and scalar
   format match the layout exactly and the slice index is in range. It is named
   for what it is — a placement — rather than borrowed from the plan's
   sample-holding `CTFrameRecord`.
7. **The plan's `CTFrameRecord` is not implemented**, and the reason is decision
   10 of `ADR-0230` rather than an omission. See the finding above.
8. **No destination buffer type is defined here.** The layout describes *where*
   to write; the buffer the adapter writes into belongs to (e2), where the
   producer lives, and defining a speculative buffer protocol with no producer
   to satisfy it would be an untested claim. This is the same boundary
   `ADR-0231` drew, applied one level down.
9. **`VOX-DCM-005`'s sixteen-bit scope is not baked in.** The layout accepts any
   `ScalarFormat`, because the byte-count rule works from the format's width. The
   slice's support level is a statement about the pipeline, not about what an
   addressing contract may describe — the same reasoning as `ADR-0227`
   decision 6.

## Alternatives considered

### Implement the plan's `CTFrameRecord` with an owned sample buffer

Rejected; see the finding and decision 7. It would reintroduce exactly the copy
per frame that `ADR-0230` decision 10 chose direct-write to avoid.

### Define a destination buffer protocol now

Rejected; see decision 8. With no adapter to implement it, its shape would be
guessed and its tests would exercise only a stub written to fit it.

### Use row-major-with-slices-innermost, or column-major

Rejected. Slice-major matches how frames arrive — one at a time, each contiguous —
so a decoder writes one contiguous span per frame. Any other order would make a
single frame's samples strided in the destination, which is the copy this whole
design avoids.

### Check only the sample count for overflow

Rejected; see decision 3.

### Restate the frozen-expression-order rule for consistency with the other specs

Rejected; see decision 5. Consistency of *form* is not worth a false claim about
risk.

### Narrow the layout to sixteen-bit formats for the first vertical slice

Rejected; see decision 9.

## Consequences

The direct-write mechanism `ADR-0230` chose now has its addressing half
implemented and frozen, with no dependency and no third-party code. When the two
owner decisions in `ADR-0231` land, (e2) has a contract to write against rather
than a design to invent under time pressure.

The plan's `CTFrameRecord` will not appear. Anyone looking for it will find this
record explaining that direct-write removed the need for it.

## Affected modules

`VoxeliaImaging` gains `CTVolumeLayout`, `CTFramePlacement` and their failure
families. No module's dependencies change. **`Package.swift` is unchanged and
this repository still declares no external dependency.**

## Compatibility impact

Additive only.

## Security impact

Positive: the byte-count admission of decision 3 is the check that stands between
a wide scalar format and an allocation-size overflow. The failure families are
payload-free.

## Performance and memory impact

Offsets are a fixed two multiplications and two additions. The layout stores four
values and allocates nothing.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0232-volume-layout-oracle.py
swift build && swift test
python3 Tools/Scripts/check_swift_safety.py
python3 Tools/Scripts/check_licence_policy.py    # unmodified, still passes
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This increment: `VOXELIA-ALG-0050`, its oracle, this record, and the two
   value types with tests covering every frozen fixture.
2. **Owner decisions** on the codec-library graph and the JLSwift licence, per
   `ADR-0231`.
3. (e2) once unblocked: the manifest dependency, the shim writing through this
   layout, the licence-gate update, the notices entries and an SBOM regeneration.

## Supersession

This record supersedes nothing. It performs increment (e1) of the split
`ADR-0231` made, and records that `ADR-0230` decision 10 removed the need for the
plan's `CTFrameRecord` without editing either record.

## References

- [ADR-0226 - DICOM ingest arc](ADR-0226-dicom-ingest-arc.md)
- [ADR-0227 - Neutral CT frame description](ADR-0227-neutral-ct-frame-description.md)
- [ADR-0230 - CT affine volume construction](ADR-0230-ct-affine-volume-construction.md)
- [ADR-0231 - DICOMKit supply-chain assessment](ADR-0231-dicomkit-supply-chain-assessment.md)
- [VOXELIA-ALG-0050 - CT volume sample layout](../../algorithms/VOXELIA-ALG-0050-volume-sample-layout.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
