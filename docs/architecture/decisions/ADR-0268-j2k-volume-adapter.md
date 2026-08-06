---
document_id: "ADR-0268"
title: "J2K volume adapter"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SEC-001"
  - "VOX-CMP-002"
  - "VOX-CMP-009"
  - "VOX-CMP-010"
  - "VOX-CMP-011"
---

# ADR-0268 - J2K volume adapter

## Context

`ADR-0267` linked `J2KSwift` into `VoxeliaCompression`. This is the adapter that
turns a `JP3DDecoder` result into the arc's `DecodedSamples`.

Following the rule `ADR-0267` recorded after making the same mistake twice, the
codec's public surface was read **before** any adapter was designed. Four of the five
decisions below come directly from what that reading found, and none of them would
have been obvious from the requirement text.

## What reading the API found

**1. `J2KVolume` carries `spacingX/Y/Z` and `originX/Y/Z`.** The codec supplies
geometry.

**2. `J2KVolumeMetadata` carries `patientID`, `modality`, `windowCenter`,
`sliceThickness` and more.** The codec supplies patient identity and display
parameters.

**3. `JP3DDecoderConfiguration` defaults `tolerateErrors` to `true`.** The decoder's
out-of-the-box behaviour is to produce output from a codestream it could not fully
parse.

**4. `JP3DDecoderResult` carries `isPartial`, `tilesDecoded`, `tilesTotal` and
`warnings`.** The codec reports incompleteness explicitly.

**5. `J2KVolumeComponent` admits bit depths of 1 to 38 and per-axis subsampling.**
A component's dimensions need not match its volume's.

## Decision

1. **The adapter reads no geometry from the codec, and this is its most important
   property.** Voxelia's patient-space mapping comes from DICOM attributes through
   `CTFrameDescription` and `CTAffineVolumeBuilder`, governed by accepted records with
   an independent oracle. Taking spacing or origin from a codestream would create a
   second source of truth for the most safety-critical mapping in the system.
   `ADR-0255`'s binding rules already said a decode is a value transformation and not
   a geometry decision; finding that the codec *offers* geometry is what makes the rule
   load-bearing rather than theoretical. **The convenience is the hazard.**
2. **The adapter reads no patient metadata either.** Identity belongs to the DICOM
   path, which admits it under `ADR-0227`.
3. **`tolerateErrors` is set to `false` explicitly and never left to the default.**
   For a diagnostic viewer, accepting error-tolerated pixel data is wrong. The other
   configuration values are restated rather than defaulted, so an upstream change to a
   default cannot silently alter what Voxelia asks for. A test asserts both that the
   codec's default is `true` and that the adapter's is `false`, so a silent adoption
   of the default fails.
4. **A decode the codec reports as incomplete is refused** — `isPartial`, or
   `tilesDecoded != tilesTotal`. This is a signal the arc's existing checks **cannot
   see**: `ADR-0258`'s validator compares byte counts and shape, and a partial decode
   can be exactly the right length with wrong data. `ADR-0259` found a similar gap one
   layer down; this is a third.
5. **A decode that produced warnings is refused.** "Skipped tiles" is among the
   codec's documented warnings, and a diagnostic path does not silently accept pixel
   data the decoder itself flagged.
6. **Subsampled components are refused.** A subsampled component's data does not
   correspond to the volume's extents, so reading it as though it did would misplace
   every sample rather than fail loudly.
7. **Bit depths wider than Voxelia's scalar types are refused, never truncated.** A
   24-bit sample narrowed to 16 is a quantitative error in diagnostic data, not a
   formatting detail.
8. **The sample layout is checked, not assumed.** The expected byte count is derived
   from the component's own dimensions and bit depth and compared against the data it
   returned, so the adapter encodes no guess about how the codec packs samples.
9. **Multiple components are refused rather than interleaved.** No accepted record
   has decided that layout.
10. **The checkable core takes plain values, not `JP3DDecoderResult`** — see below.
11. **No algorithm specification and no oracle.** The adapter freezes no numeric rule;
    every check is an equality or a range test.

## A testability constraint that shaped the design

`JP3DDecoderResult` has only `public let` properties and **no public initialiser**, so
its memberwise initialiser is internal to its own module. **An adapter accepting only
that type could not be tested without real codestreams.**

So the adapter is split: a thin public entry point that unwraps the result, and an
internal core taking `volume`, `isPartial`, `tilesDecoded`, `tilesTotal` and
`warnings` as plain values. `J2KVolume` and `J2KVolumeComponent` *do* have public
initialisers, so every refusal is exercised — twelve tests, no codestream required.

This is worth recording as a pattern rather than a workaround: when a dependency's
result type cannot be constructed by a consumer, the consumer's logic should not take
it directly, or that logic becomes untestable by construction.

## How the no-geometry claim is tested

Asserting an absence is easy to do badly. The fixture supplies **deliberately
non-zero** spacing (`0.75, 0.75, 2.5`) and origin (`-120.5, -119.0, 42.0`), because a
fixture of zeros could not distinguish "the adapter ignored them" from "the adapter
read zeros". The resulting `DecodedSamples` has no field that could carry them, and
the test asserts the claim's whole surface is voxel counts and bytes.

## Alternatives considered

### Use the codec's spacing when DICOM spacing is absent

Rejected, and it is the tempting one. A fallback would mean patient-space geometry
sometimes came from a codestream and sometimes from DICOM attributes, with no
indication in the published object which. `ADR-0229`'s tolerance gate exists precisely
because geometry provenance matters.

### Accept `tolerateErrors: true` and rely on `isPartial` to catch problems

Rejected. Error tolerance and partiality reporting are different mechanisms, and
relying on one to police the other assumes a relationship the codec does not document.
Turning tolerance off is the direct expression of what a diagnostic path needs.

### Treat warnings as informational and publish anyway

Rejected for now, and it may deserve revisiting when `VOX-CMP-006` documents actual
codec output. Some warnings may prove benign — but "may prove benign" is a reason to
find out, not a reason to accept them in advance.

### Support subsampled components by upsampling

Rejected. Upsampling is a resampling decision with its own accepted rules
(`VOXELIA-ALG-0008`, `ALG-0015`), and doing it invisibly inside a decode adapter would
hide a value transformation the project governs explicitly.

## Consequences

`VoxeliaCompression` can turn a real JP3D decode into validated samples, with the
codec's geometry and metadata deliberately left at the boundary.

Three findings are now recorded that the requirement text does not mention: the codec
offers geometry, it defaults to tolerating errors, and it reports partiality the arc's
other checks cannot see.

## Affected modules

`VoxeliaCompression` gains `J2KVolumeAdapter` and its failure family. No other module
changes.

## Compatibility impact

Additive.

## Security impact

Positive, and concentrated in decisions 3 to 8. Error-tolerated output, partial
decodes, warned decodes, subsampled components, over-wide bit depths and
self-inconsistent byte counts are each refused rather than accommodated. Every one of
those is a path by which a malformed codestream could otherwise have produced
plausible-looking diagnostic data.

## Performance and memory impact

One `ContiguousArray(component.data)` conversion per decode. `Data` is the fast
collection type per `ADR-0264`, and the component's `data` is already `Data`.

## Validation impact

```text
swift build && swift test
swift test --filter "J2KVolumeAdapter"
python3 Tools/Scripts/check_prohibited_imports.py
python3 Tools/Scripts/check_licence_policy.py
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1079 tests in 199 suites pass after a clean rebuild.

## Migration

1. This record.
2. **Next**: `VOX-CMP-004` and `VOX-CMP-005` — JP3D and HTJ2K evaluated with real
   codestreams, which needs test data this project does not yet have.
3. Then `VOX-CMP-006`'s documented codec output, `012`, `014`, and `011`'s adversarial
   work last.
4. **Owner decisions still open**: the remaining five.

## Supersession

This record supersedes nothing.

## References

- [ADR-0227 - Neutral CT frame description](ADR-0227-neutral-ct-frame-description.md)
- [ADR-0255 - Open the compression arc](ADR-0255-open-the-compression-arc.md)
- [ADR-0258 - Compressed decode admission](ADR-0258-compressed-decode-admission.md)
- [ADR-0259 - Cancellable decode session](ADR-0259-cancellable-decode-session.md)
- [ADR-0264 - Range replacement frame transfer](ADR-0264-range-replacement-frame-transfer.md)
- [ADR-0267 - Direct codec declaration](ADR-0267-direct-codec-declaration.md)
