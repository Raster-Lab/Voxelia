---
document_id: "ADR-0272"
title: "Codec output and interoperability status"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CMP-006"
  - "VOX-CMP-013"
  - "VOX-SEC-001"
---

# ADR-0272 - Codec output and interoperability status

## Context

`VOX-CMP-006` is conditional: JP3D and HTJ2K combinations "shall be used only when the
actual Raster-Lab codec output and interoperability status are documented". It declares
`I,T,R`.

`ADR-0269` evaluated the codecs for ratio and speed and deliberately deferred two
questions to this row: what the output actually *is*, and why `levelsZ` appeared to have
no effect. `VOXELIA-BEN-0002` recorded the same deferral, noting that encoding and
decoding used one library so its figures "say nothing about interoperability with other
implementations".

This record answers both, and the answer changes what the compression arc is allowed to
claim.

## What the output actually is

Measured with the `jp3deval` harness in `interop` mode against a `512x512x16` volume
imported from the owner's thoracic CT series.

| | JP3D lossless | HTJ2K lossless |
|---|---|---|
| Encoded size | 3,248,558 B | 3,409,952 B |
| Container | RAW codestream, no JP2 boxes | RAW codestream, no JP2 boxes |
| Main header | `SOC → SIZ → COD → QCD → SOT` | `SOC → SIZ → COD → QCD → CAP → CPF → SOT` |
| `CAP` present | no | **yes** |

The main headers are standards-shaped, and HTJ2K correctly signals itself through `CAP`
and `CPF` so another decoder can recognise the high-throughput block coder.

**The tile payloads are not standard.** Each opens with the four bytes
`4A 33 44 53` — `J3DS` — a proprietary slice-stack container whose wire format the
library documents in `Sources/J2K3D/JP3DSliceStackCodec.swift`: magic, version, flags
(HTJ2K, lossless, Z-delta), slice count, tile dimensions, component count, bit depth,
then per-slice `[flags][length][codestream]` records holding **2D** codestreams.

The library is candid about this. Its own comments describe the envelope as
a "standards-shaped JP3D wrapper" and place the slice-stack codec "inside the JP3D outer
codestream as the SOD payload of each tile".

**So the output is a toolkit-native format wearing JPEG 2000 marker clothing.**

## Interoperability is path-dependent, and that distinction matters

Tested against the two third-party codestreams `J2KSwift` ships,
`blackbuck-5.j2k` (153,481 B) and `ct512_L4.j2k` (150,563 B), both standard-shaped RAW
codestreams:

| Decoder | `blackbuck-5.j2k` | `ct512_L4.j2k` |
|---|---|---|
| `JP3DDecoder` (volumetric) | **refused** | **refused** |
| `J2KDecoder` (2D) | decoded, `512x512`, 3 components | decoded, `512x512`, 1 component |

`JP3DDecoder`'s refusal is explicit: *"not a JP3D slice-stack payload (missing 'J3DS'
magic)"*, and it names its own older output as equally unsupported.

**The 2D codec is interoperable; the volumetric one is not.** Recording that split is
the point — a blanket "J2KSwift is not interoperable" would be false and would
misdirect any future decision about the 2D path.

## The serious finding: outbound failure is silent, not loud

A format another decoder *rejects* is an inconvenience. This one is accepted.

Feeding Voxelia-encoded JP3D and HTJ2K output to the standards-shaped 2D `J2KDecoder`:

- It **succeeds**. No error, no warning.
- It reports `512x512`, one component — **one plane for a sixteen-slice volume**. A 2D
  `SIZ` marker has nowhere to carry depth, so fifteen slices vanish without a signal.
- Every returned sample is the constant `0x0080`. The returned plane holds exactly two
  distinct byte values, `[0, 128]`; the source holds many.
- `SIZ` declares `512x512`, bit depth 16, unsigned — **self-consistent**, which is
  precisely why nothing raises an error.

Reproduced at `64x64x4`: 8,192 bytes returned of 32,768, same constant. So the failure
is structural, not a large-volume artefact.

**Two independent silent failures in one artefact**: the depth is dropped, and the pixel
data is unrelated to the source. For diagnostic imaging this is the worst shape a defect
can take — a receiving system that trusts the label gets no error to act on.

One honest qualification: *this* corruption happens to be a uniform frame, which a human
reader would very likely notice. That is a property of this codestream and this decoder,
not a guarantee, and it must not be generalised into "you would always notice". The
finding is that a conformant decoder accepts the codestream and returns contents
unrelated to the source.

## `levelsZ`, answered — and a correction to my own record

`ADR-0269` asked why `levelsZ` made no difference. Measured exactly, at `512x512x16`:

| | levelsZ=1 | levelsZ=3 | Differing bytes |
|---|---:|---:|---:|
| JP3D lossless | 3,248,558 B | 3,248,558 B | **1**, at offset 64 |
| HTJ2K lossless | 3,409,952 B | 3,409,952 B | **1**, at offset 64 |

That byte holds literally `1` and `3` — the `COD` marker's Z-decomposition field. Every
other byte of 3,248,558 is identical, and the same single-byte difference appears at
`64x64x4`.

The library explains it: the encoder routes each tile through the slice-stack codec, and
"the 3D DWT and JP3DRateController are skipped"; the recorded decomposition levels are
"**advisory only**". A genuine 3D wavelet transform exists in `JP3DWaveletTransform` and
is not on the encode path. Z correlation is exploited, when it is, by opportunistic
per-slice signed-residual coding under `zDeltaMode` — not by `levelsZ`.

**Which means a codestream encoded at `levelsZ: 3` declares three levels of Z
decomposition that its payload does not have.** The header misdescribes the data. That
is a second way this output misleads a conformant reader, and it is independent of the
`J3DS` payload.

**The correction.** `VOXELIA-BEN-0002` v0.1 stated that `levelsZ` `1` and `3` "produced
byte-identical **output**". The harness printed `count / 1_048_576` — integer mebibytes —
so it observed equal *rounded sizes* and I wrote a stronger claim than the measurement
supported. Corrected in `VOXELIA-BEN-0002` v0.2.

`ADR-0269`, `VOX-VS1-001`'s evidence document and the ledger all say "byte-identical
encoded **sizes**", which is exactly right — the sizes are identical to the byte. Those
stand unedited, and are deliberately not restated here.

## Decision

1. **`VOX-CMP-006`'s `I` and `T` are discharged; its `R` is the owner's.** The condition
   the row imposes is now satisfiable: the output and its interoperability status are
   documented, above, from measurement.
2. **The documented status is that this output is toolkit-native.** Any use of it is
   therefore governed by `VOX-CMP-013`, not by a transfer syntax UID.
3. **`ToolkitNativeCodestream.inspect` detects the container from the bytes.** `ADR-0257`
   made `VOX-CMP-013` structural for the *name*; this makes it checkable against the
   *payload*. The gap was real: a caller could label a `J3DS` codestream
   `1.2.840.10008.1.2.4.90` — a genuine, well-formed JPEG 2000 Lossless UID that
   `CompressedRepresentation` admits without complaint — and nothing refused it. A test
   constructs exactly that representation, shows the name rule admitting it, and shows
   only the new rule refusing the pairing.
4. **The main header is parsed, never scanned.** In one measured 988-byte codestream the
   marker pair `FF 93` appeared at **five** offsets of which exactly one was a real
   marker; the other four were chance byte pairs inside entropy-coded data. `J3DS`
   appeared exactly once, two bytes after the genuine `SOD`. A test builds a codestream
   with decoy magic and a decoy `SOD` inside a `COM` segment body, asserts the structural
   verdict, **and asserts that both naive implementations would get it wrong** — so the
   test is a discriminator rather than a restatement.
5. **`CodestreamLabellingRule` refuses exactly one pairing**: a toolkit-native container
   labelled as a standard transfer syntax. Everything else is admitted, including a
   standard label over bytes that are not a JPEG 2000 codestream — JPEG-LS, RLE and
   uncompressed syntaxes are standard and are not JPEG 2000, so the tempting rule
   *treat anything unparseable as suspect* would refuse legitimate objects. That
   narrowing is a decision, not an omission.
6. **The rule stands alongside `CompressedRepresentation` rather than changing it.** A
   representation must remain constructible from a source's *declared* syntax when no
   bytes are in hand, so the byte check applies only where bytes exist. `ADR-0257` is
   unedited.
7. **No algorithm specification and no oracle.** Marker walking and a four-byte
   comparison.

## Two observations for the owner, who owns `J2KSwift`

Neither is fixable from this repository, and both are recorded rather than worked around:

1. **The `COD` marker declares Z-decomposition levels the payload does not have.** A
   caller passing `levelsZ: 3` gets a codestream asserting three levels over data coded
   with none. Refusing the parameter, or clamping the recorded value to the truth, would
   both be honest; recording a value that is "advisory only" is not.
2. **The volumetric output is accepted by conformant 2D decoders and silently yields
   wrong pixels.** Emitting something a standard decoder *rejects* — a distinguishing
   marker, or a private `SIZ`/profile signal — would convert a silent misread into a
   clean refusal.

The standing instruction is that library defects get fixed rather than reported. These
sit in a dependency rather than in Voxelia, so what this increment can do is detect the
hazard and refuse the mislabel, which decision 3 does. The library change itself is the
owner's call.

## Alternatives considered

### Declare the row discharged by documentation alone

Rejected. `VOX-CMP-006` declares `T`, and the measurement exposed a live gap in
Voxelia's own rules. Documenting the hazard while leaving the mislabel constructible
would have been the weaker half of the work.

### Scan the whole codestream for the container magic

Rejected on evidence; see decision 4. Over megabytes of entropy-coded data a four-byte
sequence appears by chance, and the `FF 93` measurement shows the false-positive rate is
not hypothetical.

### Refuse a standard label whenever the codestream cannot be parsed

Rejected, and this is the alternative worth naming because it was my first instinct. It
sounds like the conservative choice and is simply wrong: JPEG-LS, RLE and uncompressed
transfer syntaxes are standard and are not JPEG 2000 codestreams, so the rule would
refuse entirely legitimate objects. The refusal is narrowed to the measured hazard.

### Tighten `CompressedRepresentation` to require bytes

Rejected. A source's declared transfer syntax is often all Voxelia has — during metadata
reading there is no codestream in hand — so requiring bytes would make the type
unusable at its main call site.

### Add the codec to the test target so tests encode real codestreams

Rejected. It would give `VoxeliaCompressionTests` external products it does not have,
touching three gate scripts, and it would make the repository suite assert a
*dependency's* defect as expected behaviour — failing when `J2KSwift` improves. The
codec-dependent facts belong in recorded harness runs, as every other codec measurement
in this project does; the repository tests assert Voxelia's own rules over hand-built
bytes.

### Report the `levelsZ` finding as "no effect", matching the earlier claim

Rejected. "Exactly one byte, and it is the field that describes the data" is both more
accurate and more useful than "no effect", because it identifies the header as
misdescribing the payload.

## Consequences

`VOX-CMP-006` is discharged but for its owner Review. Compression rows now stand at
`002`, `003`, `004`, `005`, `006` (`I,T`), `007`, `009`, `010`, `012` (`T`), `013`,
`014`, and `008` (`T`).

**Remaining: `VOX-CMP-011`**, plus `008`'s `A` half and `006`/`012`'s Reviews.

`VOX-CMP-013` moves from a rule about names to a rule about names *and* bytes. Two
dependency observations are on the record for the owner.

The compression arc's practical conclusion is now complete: these codecs compress this
CT data losslessly at roughly `2.2` to `2.5` to one and serve one axial plane in
`0.014` s (`ADR-0271`), and their output is **toolkit-native and must never be presented
as a standard transfer syntax**. Both halves are needed before any decision to use them.

## Affected modules

`VoxeliaCompression` gains `ToolkitNativeCodestream`, `CodestreamContainerVerdict`,
`CodestreamLabellingRule` and `CodestreamLabellingError`. No other module changes and
nothing new is imported — the detector is byte inspection over
`RandomAccessCollection<UInt8>`.

## Compatibility impact

Additive.

## Security impact

Positive, and specific. The measured harm — a toolkit-native codestream labelled with a
genuine transfer syntax UID, decoded without error by a receiving system into pixel data
unrelated to the patient's study — is now refused at the boundary rather than prevented
only by a caller choosing the right name.

## Performance and memory impact

One bounded walk of the main header per admission, no allocation beyond the verdict.
The walk advances at least two bytes per iteration and every read is bounds-checked, so
it terminates on any input without a step limit.

## Validation impact

```text
swift build && swift test
swift test --filter "ToolkitNativeCodestream"
python3 Tools/Scripts/check_swift_safety.py
python3 Tools/Scripts/check_prohibited_imports.py
python3 Tools/Scripts/check_package_graph.py
python3 Tools/Scripts/check_licence_policy.py
swift format lint --strict Sources/VoxeliaCompression/Public/ToolkitNativeCodestream.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1101 tests in 201 suites pass. Interoperability measurements are recorded harness runs
against the owner's data; no repository test reads that path.

## Migration

1. This record, the detector and the labelling rule, and `VOXELIA-BEN-0002` v0.2.
2. **Next**: `VOX-CMP-011`'s adversarial work, which closes the arc and which this
   record's bounded marker walk is itself now a target for.
3. **Owner**: `VOX-CMP-006`'s and `VOX-CMP-012`'s Reviews, the two `J2KSwift`
   observations above, and the five decisions already open.

## Supersession

This record supersedes nothing. It **answers `ADR-0269`'s deferred `levelsZ` question**
and **corrects a claim in `VOXELIA-BEN-0002` v0.1** that overstated a size comparison as
a byte comparison. `ADR-0269` and `ADR-0257` are unedited; this record extends the latter
from names to bytes.

## References

- [ADR-0255 - Open the compression arc](ADR-0255-open-the-compression-arc.md)
- [ADR-0257 - Toolkit-native representation labelling](ADR-0257-toolkit-native-representation-labelling.md)
- [ADR-0269 - JP3D and HTJ2K evaluation](ADR-0269-jp3d-and-htj2k-evaluation.md)
- [ADR-0270 - Cache preservation rule](ADR-0270-cache-preservation-rule.md)
- [ADR-0271 - Compression benchmark and random access](ADR-0271-compression-benchmark-and-random-access.md)
- [VOXELIA-BEN-0002 - Compression benchmark](../../benchmarks/VOXELIA-BEN-0002-compression-benchmark.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
