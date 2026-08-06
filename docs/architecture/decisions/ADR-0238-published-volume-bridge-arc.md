---
document_id: "ADR-0238"
title: "Published volume bridge arc"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-003"
  - "VOX-VS1-004"
  - "VOX-VS1-005"
  - "VOX-VS1-006"
  - "VOX-VS1-009"
  - "VOX-VS1-019"
---

# ADR-0238 - Published volume bridge arc

## Context

The ingest arc (`ADR-0226` to `ADR-0237`) takes real DICOM files to a
`CTVolumeByteBuffer`, an `AffineGridGeometry` and a `CTValueInterpreter`, all
verified against the owner's corpus.

Reading the requirement baseline reframes what remains. **The first vertical slice
has twenty requirements, not four.** `VOX-VS1-001` to `008` are covered.
`VOX-VS1-009` to `019` — axial, coronal and sagittal reconstruction, Metal
rendering, nearest-neighbour and linear interpolation, window centre and width
interaction, linked patient-space crosshairs, quantitative pixel inspection,
patient-space distance measurement, off-screen output, cancellation and provenance
— are capabilities **Voxelia already has** from milestones M2 to M6.

Every one of them operates on a **published `ImageData`** reached through
`PublicationCoordinator`. The ingested volume is a byte buffer and a geometry, and
**nothing connects the two**. That connection is the whole remaining distance, and
this record opens the arc that builds it.

## The pieces already fit, which is the encouraging half

Verified by reading the accepted types rather than assumed:

- **`ImageDescriptor` already carries `spatialGeometry: SpatialGeometry?`** — and
  `SpatialGeometry` is `.affine(AffineGridGeometry)`, exactly what
  `ADR-0230` builds.
- **`ImageDescriptor` already carries `valueTransform: ValueTransform?`** — and
  `ValueTransform.linear(LinearValueTransformDescriptor(scale:offset:))` is exactly
  the rescale, governed by `VOXELIA-ALG-0003` per `ADR-0237`.
- **`ContiguousImageStorage(binding:bytes:)` exists** in `VoxeliaStorage` and takes
  `[UInt8]` — which is what `CTVolumeByteBuffer.bytes` holds.

These slots were designed for this and have never been filled. The bridge is
mostly assembly, not invention.

## The finding that will decide the arc: the narrowed-bit-count trap

`ADR-0237` found that **nothing in the project masks by
`ScalarFormat.validBitCount`**: two adapters *refuse* a narrowed count and every
other operation constructs formats with `nil`.

That creates a genuine correctness trap for the descriptor this arc must publish.
When Bits Stored is narrower than Bits Allocated — a twelve-bit sample in a
sixteen-bit container — the transferred bytes hold full containers whose low twelve
bits are meaningful:

- Declaring `validBitCount: 12` is **accurate** and is **refused** by some accepted
  operations.
- Declaring `validBitCount: nil` is **accepted** and is **wrong for signed data**:
  a raw `0x0FFF` would be read by the pipeline as `4095` where the sample means
  `-1`. `VOXELIA-ALG-0051`'s sign extension exists precisely because those differ
  by 4096.

So the two available declarations are respectively unusable and incorrect. **The
third option — normalising the samples during transfer so the published container
holds sign-extended full-width values — is a change to the transfer, not to the
descriptor**, and it is the increment's real question.

The owner's corpus does not expose this: its Bits Stored equals the container
width, so `validBitCount` is `nil` and the trap is dormant. A twelve-bit CT would
spring it. **This arc must not conclude by publishing a descriptor that is correct
only for the data that happened to be measured.**

## A second constraint, verified: there is no clock

`CanonicalInstant` offers only `init(utcString:)`. There is no clock acquisition in
the project — memory recorded this as blocked by its own contract, and it still is.
`ProvenanceRecord` requires `createdAt: CanonicalInstant`.

**So the ingest instant must be a caller-supplied parameter**, and that is a
feature rather than a workaround: a bridge whose provenance timestamp comes from
its caller is reproducible in a test, and an ingest that stamped itself would make
every published volume's identity depend on the wall clock.

## A third constraint: byte order is a platform coincidence

`ContiguousImageStorage` admits its representation with `byteOrder: .native`. DICOM
explicit VR little endian is what `DICOMFrameAdapter` records, and
`PLATFORM_SUPPORT.md` scopes Voxelia to Apple Silicon, which is little-endian. So
the transferred bytes are directly admissible **today, by coincidence of platform
rather than by construction**. It is recorded here so that a future big-endian
target finds a stated assumption instead of silent corruption.

## Decision

1. **This record opens the arc and decides its decomposition and binding rules
   only.** It publishes nothing and changes no source, in the shape `ADR-0183`,
   `ADR-0197`, `ADR-0208` and `ADR-0226` used.
2. **The decomposition:**
   - **(a) The volume descriptor** — `ImageShape`, axis descriptors, the
     `spatialGeometry` from `ADR-0230`, the `valueTransform` carrying the rescale,
     and units. Unblocked.
   - **(b) The storage binding** — a `LogicalSampleBinding` and
     `ContiguousImageStorage`, erased to `AnyImageStorage`. Unblocked and small.
   - **(c) The narrowed-bit-count decision**, which is this arc's hardest question
     and is stated above. It must be settled with a rule and fixtures, **not** by
     observing that the measured corpus avoids it.
   - **(d) Provenance for an ingested volume** — `.origin` activity with `.source`
     kind, naming the source frames `VOX-VS1-019` requires. The largest part.
   - **(e) `DataIdentity` for the volume**, and publication through
     `PublicationCoordinator`.
   - **(f) End-to-end verification**: extract an axial, coronal and sagittal slice
     from the real 899-slice series through `MPRSliceCoordinator`, which is what
     makes `VOX-VS1-009` reachable.
3. **The ingest instant is a required caller parameter**, never acquired. See the
   second constraint.
4. **No accepted type is modified.** The descriptor's slots exist; this arc fills
   them. If a slot turns out to be missing, that is a finding for a record, not a
   licence to widen an accepted type.
5. **(c) must be decided before (e).** Publishing a volume whose declared bit count
   is wrong would put an incorrect object into a pipeline that trusts its
   descriptor, and every downstream requirement would then be verified against it.
6. **Provenance in (d) claims only what it can show.** `VOX-VS1-019` asks for
   provenance of source frames, transforms, operations, implementations and
   backend. An ingest record can name the frames and the transform; it cannot claim
   an operation or backend it did not run. Those belong to the records the existing
   operations already produce.
7. **The arc is verified on the owner's real corpus, not only on fixtures** —
   `ADR-0233` and `ADR-0235` established that habit, and it has corrected four
   assumptions so far.

## Alternatives considered

### Publish with `validBitCount: nil` and move on

Rejected; see the finding. It is correct for the measured corpus and wrong for
signed narrowed data, which is the worst combination: it would pass every test
available today.

### Publish with `validBitCount: 12` and let operations refuse it

Rejected. An accurate descriptor that the pipeline cannot consume delivers nothing,
and "correct but unusable" is not a resolution.

### Widen the accepted operations to mask by `validBitCount`

Not rejected — deferred to increment (c) as one of its candidate answers. It is a
change to accepted, tested operations, so it needs its own record and cannot be
smuggled in as part of a bridge.

### Acquire a clock so provenance can stamp itself

Rejected; see the second constraint. It would make every published volume's
identity depend on the wall clock and is blocked by its own contract regardless.

### Do the whole bridge in one increment

Rejected. Provenance alone carries ten constructor parameters with cross-field
invariants, and the narrowed-bit-count question needs fixtures. The ingest arc's
five-increment decomposition surfaced blockers early three separate times; the same
discipline applies here.

## Consequences

Eleven first-vertical-slice requirements become reachable through code that already
exists and is already tested, once the bridge is built.

The narrowed-bit-count trap is now recorded before it can be walked into, which is
the entire purpose of opening an arc with a record rather than a commit.

## Affected modules

Documentation only in this record. Later increments add bridge types to
`VoxeliaImaging`; no module's dependencies change and no third-party dependency is
added.

## Compatibility impact

None in this arc-opening increment.

## Security impact

None here. Increment (e) publishes an object into the coordinated pipeline, and
carries the admission obligations of the accepted publication contract.

## Performance and memory impact

None here. Increment (b) will hold the volume's bytes once more than the byte
buffer does unless the transfer hands ownership over, which is a question for that
increment given the 120 MiB/s figure `ADR-0235` measured.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

No oracle: this record freezes no numeric boundary.

## Migration

1. This record.
2. Increments (a) through (f) in the recorded order, with (c) before (e).
3. Then the remaining first-vertical-slice requirements, most of which are
   existing capability reached through the bridge.

## Supersession

This record supersedes nothing. It opens a new arc and composes the ingest arc's
output with the accepted publication pipeline.

## References

- [ADR-0226 - DICOM ingest arc](ADR-0226-dicom-ingest-arc.md)
- [ADR-0230 - CT affine volume construction](ADR-0230-ct-affine-volume-construction.md)
- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [ADR-0236 - Stored value interpretation](ADR-0236-stored-value-interpretation.md)
- [ADR-0237 - Duplicate rescale freeze correction](ADR-0237-duplicate-rescale-freeze-correction.md)
- [VOXELIA-ALG-0003 - Linear stored-to-real value mapping](../../algorithms/VOXELIA-ALG-0003-linear-value-transform.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
