---
document_id: "ADR-0246"
title: "Quantitative sample inspection"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-006"
  - "VOX-DCM-008"
  - "VOX-VS1-008"
  - "VOX-VS1-014"
---

# ADR-0246 - Quantitative sample inspection

## Context

`ADR-0245` assessed `VOX-VS1-014`, quantitative pixel inspection, as a **gap of
composition rather than capability**: `PickResolver` returns indices and an exact
physical position but no sample value, while the published slice holds the bytes
and `CTValueInterpreter` turns bytes into real values. Nothing joined them.

This record joins them.

## The decision that shaped the type: it computes no world position

The obvious design returns position *and* value from one call. **That would
re-freeze a boundary that already has an owner.** `PickResolver` resolves a
viewport pick to indices and an exact physical position under the rule `ADR-0129`
governs, computing `origin + Σ element × index` in a fixed order.

Recomputing that here is exactly the mistake `ADR-0237` had to correct one arc ago,
where `VOXELIA-ALG-0051` restated the rescale that `VOXELIA-ALG-0003` already froze.
The register was searched for the boundary before any code was written, and it was
found.

So the composition is explicit and each part answers one question:
**`PickResolver` says where, `CTSampleInspector` says what.**

## Decision

1. **`CTSampleInspector.inspect` takes indices, not a `PickResolution`.** That keeps
   it in `VoxeliaImaging` rather than forcing it up into `VoxeliaInteraction`, and it
   is the module order that makes the decision, not preference: `PickResolver` sits
   above `VoxeliaRendering`, and an inspection that consumed its result could not
   live beside the interpreter it needs.
2. **It computes no world position**; see above.
3. **The padding value is a caller parameter, not read from the descriptor.**
   `ImageDescriptor` has no padding slot, and `WindowLevelOperation` already takes
   `paddingValue: Int64?` as a parameter for the same reason. Following the accepted
   pattern beats inventing a descriptor field.
4. **Padding is compared on the stored value, before the rescale**, exactly as
   `VOXELIA-ALG-0051` requires. A test supplies a padding number equal to the
   *rescaled* value and asserts the sample is still measured — the alternative would
   delete real signal at one output value.
5. **Only `identity` and `linear` value transforms are evaluated.** A lookup table or
   composed chain is **refused with its own case**, because a general evaluator would
   duplicate the model `VOXELIA-ALG-0005` governs and `WindowLevelOperation` already
   implements privately. Refusing is honest until that evaluator is shared; guessing
   would be a third statement of one boundary.
6. **An identity transform is expressed as `scale = 1, offset = 0`** rather than as a
   separate code path, because `VOXELIA-ALG-0003` states the two are bit-identical.
7. **A rank-three image is refused.** This inspects slices; inspecting a volume
   directly is a different operation with a third index, and claiming it here would
   be untested.
8. **One sample is read as a 1×1 region**, not by reading a slice and indexing into
   it.

## Verified on real data

Three positions of the real axial slice, chosen for what they should contain:

| Position | Stored | Interpreted | Expected anatomy |
|---|---|---|---|
| centre (256, 256) | 8232 | **40.0 HU** | mediastinum — soft tissue |
| mid-left (128, 256) | 7237 | **-955.0 HU** | lung parenchyma |
| corner (2, 2) | 0 | **-8192.0 HU** | outside the reconstruction field |

**These are the right values, not merely well-formed ones.** 40 HU at the centre of
a thorax slice is mediastinum; -955 HU at mid-left is air-filled lung; and the corner
sits at the `-8192` floor, which is exactly what the earlier histogram predicted for
the region outside the circular reconstruction field.

An implementation that indexed the wrong axis, dropped the rescale, or mis-signed the
samples would produce plausible numbers in none of those three places.

## Alternatives considered

### Return the world position alongside the value

Rejected; see the finding. It duplicates `ADR-0129`.

### Take a `PickResolution` for convenience

Rejected; see decision 1. The module order forbids it, and the split is clearer
anyway.

### Read the padding value from the descriptor

Rejected; see decision 3. There is no slot, and adding one would diverge from the
accepted operation pattern.

### Evaluate lookup tables by writing an evaluator here

Rejected; see decision 5. `VOXELIA-ALG-0005` governs that model and
`WindowLevelOperation` already implements it privately. The right fix is to share
that evaluator, in its own record.

### Also inspect a volume directly

Not done. `VOX-VS1-014` is about the presented slice, and a volume inspection would
need its own indexing decision.

## Consequences

`VOX-VS1-014`'s quantitative half is implemented and verified on real patient data.
A caller composes `PickResolver` for the position with this for the value.

The lookup-table refusal names the shared-evaluator work rather than hiding it.

## Affected modules

`VoxeliaImaging` gains `CTSampleInspector`, `CTSampleInspection` and its failure
family. No accepted type is modified.

## Compatibility impact

Additive.

## Security impact

None. The failure family is payload-free, indices are bounds-checked before any
read, and one sample is read rather than a whole slice.

## Performance and memory impact

One 1×1 coordinated region read per inspection.

## Validation impact

```text
swift build && swift test
swift test --filter CTSampleInspector
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

Plus the real-data run recorded in
`docs/progress/evidence/VOX-VS1-001-real-ct-demonstration-2026-08-06.md`.

## Migration

1. This increment.
2. **`VOX-VS1-015`**: a patient-space distance measurement, which needs its own
   record and an oracle because a Euclidean distance has a square root and a frozen
   expression order.
3. **`VOX-VS1-013`**: verify the crosshair path end to end on the real volume.
4. **`VOX-VS1-016`**: settle the requirement's reading.
5. Later: share a `ValueTransform` evaluator so lookup tables and composed chains
   need not be refused, under `VOXELIA-ALG-0005`.

## Supersession

This record supersedes nothing. It closes the `VOX-VS1-014` gap `ADR-0245`
characterised.

## References

- [ADR-0129 - Physical pick resolution](ADR-0129-physical-pick-resolution.md)
- [ADR-0237 - Duplicate rescale freeze correction](ADR-0237-duplicate-rescale-freeze-correction.md)
- [ADR-0245 - Downstream slice requirement assessment](ADR-0245-downstream-slice-requirement-assessment.md)
- [VOXELIA-ALG-0003 - Linear stored-to-real value mapping](../../algorithms/VOXELIA-ALG-0003-linear-value-transform.md)
- [VOXELIA-ALG-0005 - Composed value transform chain](../../algorithms/VOXELIA-ALG-0005-composed-value-transform-chain.md)
- [VOXELIA-ALG-0051 - CT stored-value interpretation](../../algorithms/VOXELIA-ALG-0051-stored-value-interpretation.md)
