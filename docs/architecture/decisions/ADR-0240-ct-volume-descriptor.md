---
document_id: "ADR-0240"
title: "CT volume descriptor"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-003"
  - "VOX-DCM-006"
  - "VOX-DCM-007"
  - "VOX-VS1-004"
---

# ADR-0240 - CT volume descriptor

## Context

`ADR-0238` opened the bridge arc; `ADR-0239` settled its hardest question and
corrected its increment order so that the bit-count decision precedes the
descriptor. This record performs the descriptor increment.

The descriptor's slots existed already and had never been filled:
`ImageDescriptor.spatialGeometry` takes the affine `ADR-0230` builds, and
`ImageDescriptor.valueTransform` takes the rescale as `ValueTransform.linear`,
governed by `VOXELIA-ALG-0003` per `ADR-0237`.

## Decision

1. **Image axis 0 is the column index, 1 the row index, 2 the slice.** This is not
   a free choice: `VOXELIA-ALG-0050` made the column index fastest-varying, and
   `ContiguousImageStorage` reads "contiguous axis-zero runs". Any other order
   would make one frame's samples strided in storage, which is the copy the whole
   direct-write design avoids. Extents are therefore
   `[columns, rows, sliceCount]`, and every fixture uses three **distinct**
   extents so a transposition changes an asserted value.
2. **Axis sampling is `.indexOnly`.** The affine already carries the spacing;
   declaring a regular per-axis sampling as well would state one fact twice and
   let the two drift. This is the same reasoning `ADR-0237` had to apply
   retroactively to a duplicated numeric boundary, applied in advance this time.
3. **The published scalar format drops the meaningful-bit narrowing**, which is
   truthful only because `ADR-0239` normalises the samples to full-width
   containers. The two decisions are joined here rather than left to a reader to
   connect.
4. **A unit slope with a zero intercept is published as `.identity`, not
   `.linear(1, 0)`.** This is not a shortcut: `VOXELIA-ALG-0003` states that a
   linear mapping with `scale = 1, offset = 0` is bit-identical to no mapping, so
   the declarations are equivalent and the simpler one spares every consumer a
   multiplication that cannot change a value. Anything off unity — including
   `1.0.nextUp` — is linear.
5. **A length unit for the samples is refused as a category error.**
   `ImageDescriptor` requires a present unit to describe authoritative sample
   values rather than spatial coordinates, so declaring millimetres would claim the
   Hounsfield numbers are lengths.
6. **Sample units are absent by default**, for the reason in the finding below.
7. **The semantic is `.intensity` with one interleaved scalar component.**

## The finding: the corpus declares Hounsfield units and the adapter does not read them

`ImageDescriptor.units` is the natural place to say a CT volume's samples are
Hounsfield units. DICOM says so in **Rescale Type (0028,1054)**, and rather than
assume either way, the corpus was measured: **all forty sampled files declare
`HU`**.

**`DICOMFrameAdapter` does not read that attribute**, so the builder declines to
assert a unit it has not seen. Declaring HU because CT usually means HU would be
exactly the fixtures-encode-the-convention mistake `ADR-0236` recorded twice —
once for signed-versus-unsigned samples, once for the `-1024` intercept that turned
out to be `-8192`.

Deriving the unit from Rescale Type is a **named next increment**. It needs a
fourth field on `CTFrameDescription`, and `ADR-0234` already observed that a value
type which keeps gaining fields is a sign its boundary was drawn early — so it
deserves its own record rather than a quiet addition here.

## Alternatives considered

### Make image axis 0 the row index

Rejected; see decision 1. It would contradict the layout and make every frame's
samples strided in storage.

### Declare regular axis sampling from the spacings

Rejected; see decision 2. The affine is the single statement of the geometry.

### Declare `units` as Hounsfield units because the volume is CT

Rejected; see the finding. The corpus happens to agree, which is precisely why
asserting it without reading the attribute would be untested luck rather than
evidence.

### Publish `.linear(1, 0)` for the identity case

Rejected; see decision 4. It is equally correct and strictly more work downstream.

### Accept any unit the caller supplies

Rejected; see decision 5. A length unit is not a stricter or looser claim, it is a
wrong one.

## Consequences

An ingested CT volume can now be described in the accepted vocabulary, carrying its
patient-space affine and its rescale where every existing operation already looks
for them.

The unit remains unstated, and the path to stating it truthfully is recorded.

## Affected modules

`VoxeliaImaging` gains `CTVolumeDescriptorBuilder` and its failure family. No
accepted type is modified.

## Compatibility impact

Additive.

## Security impact

None. The failure family is payload-free and the builder allocates only the
descriptor.

## Performance and memory impact

Negligible: three axis descriptors and a shape.

## Validation impact

```text
swift build && swift test
swift test --filter CTVolumeDescriptorBuilder
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This increment.
2. The remaining `ADR-0238` increments: the storage binding, provenance for an
   ingested volume, identity and publication, and end-to-end slice extraction on
   the real series.
3. **Named, not done**: deriving `units` from DICOM Rescale Type, which the corpus
   declares as `HU`.

## Supersession

This record supersedes nothing. It performs increment (a) of `ADR-0238` in the
order `ADR-0239` corrected.

## References

- [ADR-0230 - CT affine volume construction](ADR-0230-ct-affine-volume-construction.md)
- [ADR-0234 - Geometry tolerance source assessment](ADR-0234-geometry-tolerance-source-assessment.md)
- [ADR-0236 - Stored value interpretation](ADR-0236-stored-value-interpretation.md)
- [ADR-0237 - Duplicate rescale freeze correction](ADR-0237-duplicate-rescale-freeze-correction.md)
- [ADR-0238 - Published volume bridge arc](ADR-0238-published-volume-bridge-arc.md)
- [ADR-0239 - Stored sample normalisation](ADR-0239-stored-sample-normalisation.md)
- [VOXELIA-ALG-0003 - Linear stored-to-real value mapping](../../algorithms/VOXELIA-ALG-0003-linear-value-transform.md)
- [VOXELIA-ALG-0050 - CT volume sample layout](../../algorithms/VOXELIA-ALG-0050-volume-sample-layout.md)
