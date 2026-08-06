---
document_id: "ADR-0242"
title: "CT volume identity and provenance"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-003"
  - "VOX-VS1-004"
  - "VOX-VS1-019"
---

# ADR-0242 - CT volume identity and provenance

## Context

`ADR-0238` increments (d) and (e): provenance for an ingested volume, and its
identity and publication.

**They are performed together, and the merge is forced rather than convenient.**
A provenance record's subject is a reference to the identity's object ID, and
`ImageData` validates the two against each other, so neither can be built or
verified alone.

## The finding: an origin's source provenance is not in its inputs

`VOX-VS1-019` asks for provenance of the source frames. The obvious place is
`ProvenanceRecord.inputs`, and that is **prohibited**:

- `ProvenanceRecord` requires **`inputs.isEmpty` for an `.origin` activity**, and
  `.origin` requires `kind == .source`.
- `ImageData` separately requires an origin's identity to carry **at least one
  source identity**, throwing `missingOriginSource` otherwise.

Read together, the accepted model is explicit and was designed for exactly this
case: **provenance inputs describe Voxelia-to-Voxelia derivation, while an
origin's sources are the source locators on its `DataIdentity`.** And
`DataIdentity.sourceIdentities` is a *sequence*, so all 899 frames of a real
series fit.

So `VOX-VS1-019`'s source-frame provenance is discharged by the identity, not by
the record's inputs. That is a reading of two accepted types rather than a new
design, and finding it required reading both.

## The defect: the descriptor declared a byte order the storage does not speak

`ImageData` requires the storage representation's byte order to equal the
descriptor's. `ContiguousImageStorage` admits its representation as **`.native`**;
`ADR-0240`'s descriptor declared **`.littleEndian`**, because that is what
`DICOMFrameAdapter` records and what DICOM guarantees.

**Those are different enum cases, so `ImageData` construction would have thrown
`byteOrderMismatch`.** It was found by reading `ImageData`'s invariants before
attempting publication, and confirmed by probing the two values — `descriptor=littleEndian`,
`representation=native`, not equal — rather than inferred.

`ADR-0238` had recorded that byte order "works by platform coincidence". This is
that coincidence becoming concrete: the values agree in *meaning* on Apple Silicon
and disagree as *cases*.

## Decision

1. **The descriptor declares `.native`**, matching what the storage layer speaks.
   `ADR-0240`'s declaration is corrected here rather than by editing that record.
2. **The platform coincidence is enforced, not assumed.** The builder refuses with
   `unsupportedPlatformByteOrder` unless the executing platform is little-endian,
   checked in pure Swift. `ADR-0238` recorded the assumption; this makes a
   big-endian port fail loudly at the boundary instead of publishing a volume whose
   declared byte order silently misdescribes its bytes.
3. **Every contributing frame's `SourceIdentity` becomes a source locator on the
   identity**, in series member order.
4. **A repeated locator is refused, not deduplicated.** Two frames claiming one SOP
   Instance UID is a contradiction in the input; collapsing it silently would hide
   a duplicated frame. `DataIdentity` already refuses it, and a test asserts the
   refusal reaches the caller.
5. **The identity carries no derivation and no content ID.** An origin has no
   derivation — `ImageData` enforces it — and a content claim would assert a
   digest this increment does not compute.
6. **The ingest instant is a required parameter.** There is no clock in this
   project, and a self-stamping ingest would make every published volume's
   identity depend on the wall clock.
7. **The validation claim defaults to `.unknown`.** An ingest has run no
   validation, and any stronger claim would be the kind of unearned assertion
   these records exist to prevent. A caller with evidence may pass its own.
8. **`declaresZeroInputGenerator` is `false`.** That flag qualifies an
   `.operation` with no inputs; an origin is not a generator.
9. **Constructing an `ImageData` is the increment's proof.** Its admission checks
   the descriptor against the storage snapshot, the representation's byte order
   against the descriptor's, the provenance subject against the identity, and the
   origin source claim. A value that exists has passed all of them, so the test
   that builds one is worth more than any number of field-by-field assertions.

## What VOX-VS1-019 is not yet claimed to satisfy

The requirement names provenance for "source frames, transforms, operations,
implementations and backend". This increment records the **frames** (as source
locators) and the **transform** (as the descriptor's value transform and spatial
geometry). It claims **nothing** about operations, implementations or backends,
because the ingest ran none — those provenance records are produced by the
operations themselves when they run, and `ADR-0238` decision 6 bound this
increment to claim only what it can show.

## Alternatives considered

### Put the source frames in provenance inputs

Rejected: prohibited for an `.origin` activity, and the accepted model puts them
on the identity instead.

### Use `.operation` activity so inputs are permitted

Rejected. It would misdescribe an ingest as a Voxelia operation over Voxelia
inputs, and the frames are external files with no Voxelia identity to reference.

### Deduplicate repeated source locators

Rejected; see decision 4.

### Declare `.littleEndian` and change `ContiguousImageStorage` to match

Rejected. It would edit an accepted storage type to accommodate a bridge, when the
descriptor is the value that should describe what the storage actually holds.

### Assume the platform is little-endian without checking

Rejected; see decision 2. The assumption is true today and free to verify.

### Compute a content ID for the volume

Not done. It is a digest over 449 MiB with its own performance and canonicalisation
questions, and `DataIdentity` admits a source-only claim, so it is left to a record
that needs it.

## Consequences

An ingested CT volume is now a complete, valid `ImageData` — descriptor, storage,
identity and provenance — which is everything `PublicationCoordinator` needs.

`ADR-0240`'s byte-order declaration is corrected, with the platform assumption
behind it enforced rather than trusted.

## Affected modules

`VoxeliaImaging` gains `CTVolumePublicationBuilder` and its failure family, and
`CTVolumeDescriptorBuilder` gains the byte-order correction and its guard. No
accepted type is modified.

## Compatibility impact

The descriptor's declared byte order changes from `.littleEndian` to `.native`.
Nothing consumed it before this increment, and on every supported platform the two
denote the same order.

## Security impact

Positive: an origin volume cannot be published without a source claim, a
mismatched provenance subject is refused, and a duplicated source locator is
refused rather than hidden.

## Performance and memory impact

Negligible: the identity holds one locator per frame, so 899 for a real series.

## Validation impact

```text
swift build && swift test
swift test --filter CTVolumePublicationBuilder
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This increment.
2. `ADR-0238` increment (f): publish through `PublicationCoordinator` and extract
   axial, coronal and sagittal slices from the real 899-slice series through
   `MPRSliceCoordinator`, which is what makes `VOX-VS1-009` reachable.

## Supersession

This record supersedes nothing. It performs `ADR-0238` increments (d) and (e),
records why they merge, and **corrects `ADR-0240`'s byte-order declaration**
without editing that record.

## References

- [ADR-0037 - Claim-bearing data identity and cache admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0238 - Published volume bridge arc](ADR-0238-published-volume-bridge-arc.md)
- [ADR-0240 - CT volume descriptor](ADR-0240-ct-volume-descriptor.md)
- [ADR-0241 - CT volume storage binding](ADR-0241-ct-volume-storage-binding.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
