---
document_id: "ADR-0273"
title: "Bounded failure on adversarial codestreams"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CMP-011"
  - "VOX-SEC-001"
---

# ADR-0273 - Bounded failure on adversarial codestreams

## Context

`VOX-CMP-011` requires that malformed or adversarial codestreams "produce bounded
failure without uncontrolled allocation or unsafe memory access". It declares `T,A` and
is the last undischarged row of the M5 compression arc.

The owner released the gate on adversarial codec testing for this row specifically. It
was held until last so the adapter, the scope vocabulary, the decode session and
`ADR-0272`'s marker walk were all settled before any of them was attacked.

The standing instruction applies: defects found here are to be **fixed**, not merely
reported.

## Method

A 41-case corpus was built from a real encoder output — a `64x64x4` `uint16` volume
producing a 988-byte JP3D codestream — and mutated: empty and near-empty inputs,
truncation at four fractions, an all-zero buffer of the same length, three `SIZ`
dimension attacks, a `COD` decomposition-level attack, seven attacks on the `J3DS`
slice-stack container's own fields, a valid header with a garbage payload, and a
deterministic single-byte inversion sweep across the whole header at stride seven.

Each case ran in **its own process** with an external watchdog capping resident memory
at 2 GiB and wall time at 25 s, because the honest way to measure an unbounded
allocation is to let it happen somewhere it cannot hurt the host. `RLIMIT_AS` is not
enforced on this platform, so the bound is applied by the parent rather than by
`setrlimit` — stated because the harness attempts both and only one works here.

## What the sweep found

**The slice-stack container is well hardened, and that deserves saying first.** Every
attack on its slice count, tile dimensions, component count, bit depth, per-slice
lengths and magic threw a clean, specific, bounded error — as did every truncation, the
all-zero buffer, and the garbage payload. 28 of 41 cases threw cleanly and 11 decoded
successfully.

**The weakness is one layer out, in the standards-shaped `SIZ` envelope**, whose
declared dimensions are read as 32-bit quantities and used without an upper bound.
Three findings:

| Attack | Outcome | Why it matters |
|---|---|---|
| `Xsiz`/`Ysiz` = `0xFFFF` | **Process killed.** Allocation passed 2,163 MiB before the watchdog; `SIGKILL` when run without one | ~32 GiB implied from a 988-byte input — uncontrolled allocation |
| `Xsiz`/`Ysiz` = `0x7FFFFFFF` | **`SIGTRAP`** (exit 133), immediately, with **no** allocation | the dimension product overflows a 64-bit integer and traps |
| **Single bit flip** at one `Ysiz` byte | **Silent success.** Decoded `64x65344x4`, 33,456,128 bytes, self-consistent | a thousandfold amplification that reports success and that a caller cannot detect by checking the result against itself |

The third is the one worth dwelling on. `0x40` becomes `0xFF40`; the decode reports
success, and its declared geometry and its byte count **agree with each other**. Nothing
inside the result reveals the corruption. Only a comparison against what the caller
expected can catch it, and by then 31.9 MiB has already been allocated from 988 bytes.

None of the three is a bounded failure.

## Decision

1. **`CodestreamHeaderBudget` reads the geometry a codestream declares and bounds it.**
   `SIZ` is parsed with every read bounds-checked; the only loop is bounded by the
   declared component count, itself bounded by the declared segment length, itself
   bounded by the codestream length. No allocation depends on any declared value.
2. **The implied byte count is computed with checked multiplication and returns `nil`
   on overflow.** That single choice is the whole difference between the second finding's
   `SIGTRAP` and a refusal. `impliedDecodedByteCount` is therefore optional rather than
   an `Int`, which is deliberately inconvenient at the call site.
3. **The bound is applied inside
   `CompressedDecodeValidator.admitDestination(for:maximumDecodedByteCount:)`**, which
   is already documented as the stage that runs "before any allocation". Every decode
   routed through Voxelia is now bounded without a caller having to remember a second
   call. A rule that must be invoked separately is a rule that will eventually be
   skipped.
4. **The declared *payload* shape and the declared *codestream* geometry are both
   checked, because they are different claims.** `declaredExtents` come from whoever
   built the payload; the dimensions a decoder acts on come from the bytes. A test
   constructs a payload whose own declarations are honest and well within the ceiling
   while its codestream header is hostile, and shows the pre-existing check admitting it
   and only the new one refusing it.
5. **The largest component bit depth is used, not the last.** A budget must never be
   under-estimated. The pinned decoder keeps only the final component's depth; this
   takes the maximum, and a test asserts the difference rather than assuming the two
   agree.
6. **`Ssiz` bit depths are bounded to 1...38, the standard's range.** The field can
   *encode* up to 128, and a bit flip was measured declaring 113 bits — which the pinned
   decoder ignored and which the budget alone would refuse only when the ceiling
   happened to be tight. Bounding the field refuses it under **any** ceiling, including
   `Int.max`, and a test asserts exactly that.
7. **Bytes that are not a JPEG 2000 codestream draw no opinion.** A payload may carry
   JPEG-LS, RLE or an uncompressed syntax. This is the same narrowing `ADR-0272`
   decision 5 made, and for the same reason: the tempting rule *treat anything
   unparseable as hostile* refuses legitimate objects. Bytes that **do** open as JPEG
   2000 and then fail to parse **are** refused, because handing precisely those to the
   codec is what crashed.
8. **`VOX-CMP-011`'s `T` and `A` are both discharged.** The analysis is below; the tests
   are `CodestreamHeaderBudgetTests`.
9. **No algorithm specification and no oracle.** A bounded header parse and checked
   multiplication.

## The analysis half, stated as bounds rather than as assurances

Every path in `VoxeliaCompression` from untrusted bytes to an allocation or an index:

| Surface | Bound |
|---|---|
| `CompressedPayload.init` | extents ≥ 1, components ≥ 1, and **three checked multiplications**; the codestream is stored, never sized from a declaration |
| `CodestreamHeaderBudget.read` | fixed offsets plus one loop bounded by segment length; every read bounds-checked; **no allocation** |
| `ToolkitNativeCodestream.inspect` | marker walk advancing ≥ 2 bytes per iteration, so it terminates without a step limit; every read bounds-checked; **no allocation** |
| `admitDestination` | ceiling ≥ 1, declared shape ≤ ceiling, **and** declared geometry ≤ ceiling |
| `CompressedDecodeValidator.admit` | exact equality on the decode's report; no allocation |
| `CompressedDecodeSession.decode` | report self-consistency before the validator; the decode itself is a caller-supplied closure |
| `DecodeDestination.prepare`/`fill` | refuses beyond capacity and refuses a length mismatch |
| `CompressedScope.init` | extents non-empty and ≥ 1, rank match, every region bound inside the volume, and the payload's own extents equal to the region's; `classify` then only compares already-admitted values |
| `J2KVolumeAdapter` | `tolerateErrors: false`; `byteWidth(forBitDepth:)` yields `nil` outside 1...16 |

**Memory safety is structural, not argued.** `VoxeliaCompression` contains **no**
pointer API — no `withUnsafeBytes`, no `withContiguousStorageIfAvailable`, no
`UnsafePointer` family, no `unsafeBitCast` — and **no** unchecked arithmetic operator
(`&*`, `&+`, `&-`). Verified by search, and kept that way by
`check_swift_safety.py` rather than by convention. So the "unsafe memory access" half of
this row is excluded by construction; the substantive half was always allocation.

**`ADR-0272`'s marker walk was re-tested under this corpus** now that it is itself a
target: all 41 cases returned a verdict — 30 toolkit-native, 8 not JPEG 2000, 3 no
container — with no trap, no hang and no unbounded read.

## Verification that the fix binds

The three findings, put through the gate with a ceiling equal to the true volume
(32,768 bytes):

| Case | Gate verdict | Declared geometry |
|---|---|---|
| the unmodified codestream | **admitted** | `64x64x4`, 1 component, 16 bits, implies exactly 32,768 |
| `Xsiz`/`Ysiz` = `0xFFFF` | refused, `declaredGeometryExceedsCeiling` | implies 34,358,689,800 |
| `Xsiz`/`Ysiz` = `0x7FFFFFFF` | refused, `declaredGeometryNotRepresentable` | product not representable |
| single bit flip at `Ysiz` | refused, `declaredGeometryExceedsCeiling` | `64x65344x4`, implies 33,456,128 |
| `Ssiz` = 113 bits | refused, `headerNotReadable`, at any ceiling | — |
| not a JPEG 2000 codestream | admitted, no opinion | — |

Two independent cross-checks make this more than self-agreement. The gate computes
exactly **32,768** for the unmodified codestream, which is the uncompressed volume to
the byte. And it computes exactly **33,456,128** for the bit-flipped one, which is the
byte count the *decoder itself* was measured returning — so two separately written
parsers agree on what the corrupt header means.

Across the whole corpus the gate refuses 7 and admits 34, and the 34 are precisely the
cases the decoder already handled in bounded fashion. The two hardened layers
complement rather than duplicate: the container is defended by the library, the envelope
by Voxelia.

## A defect in this increment's own first draft

The first version of the parser counted `SIZ` offsets from the **marker** while the code
addressed them from the **length field**, two bytes earlier — so it read `Ysiz` where
`Xsiz` sits and **refused every valid codestream**. All three adversarial cases were
refused too, for entirely the wrong reason, so a test that only checked "the attacks are
refused" would have passed and shipped a gate that rejected all real data.

It was found by running the unmodified codestream through the gate and requiring it to
be *admitted*. That is recorded because the positive case was the only thing that could
have caught it, and because I had confirmed those offsets empirically an hour earlier
and still transcribed them against the wrong origin.

## Alternatives considered

### Leave it to the codec, since the container layer is well hardened

Rejected on measurement. The container layer is genuinely good; the envelope killed the
process. "The dependency validates its input" is a claim that has to be tested per
layer, and testing it found two layers with different answers.

### Refuse any codestream the gate cannot parse

Rejected, as in `ADR-0272`: JPEG-LS, RLE and uncompressed transfer syntaxes are
legitimate and are not JPEG 2000.

### Compare the header's geometry against the payload's declared extents

Deferred, not rejected. It would catch the bit-flip case by *disagreement* rather than
by size, which is sharper. But `declaredExtents` is a variable-length list whose
relationship to a 2D-plus-depth header needs its own rule, and the byte ceiling already
refuses all three findings. The existing post-decode extents comparison remains a
genuine second layer. Worth doing when a caller needs it, with its own record.

### Patch the vendored `J2KSwift` checkout

Rejected; it is not a fix. `.build/checkouts` is regenerated on resolution, so the
change would evaporate and the pinned dependency would still be the thing shipped.
Voxelia's obligation under `VOX-CMP-011` is that *Voxelia* fails boundedly, and it now
does — by never handing the codec a header it has not bounded.

### Raise the corpus to a generative fuzzer

Deferred. A deterministic 41-case corpus found three defects in one pass and is
reproducible from a recorded harness, which a random fuzzer's findings are not without
seed discipline. A generative sweep is the right next escalation if this surface grows.

## Consequences

`VOX-CMP-011` is discharged. **The M5 compression arc's requirement rows are now all
discharged**: `002`, `003`, `004`, `005`, `006` (`I,T`), `007`, `008` (`T`), `009`,
`010`, `011`, `012` (`T`), `013`, `014`.

**Remaining on the arc: owner Reviews for `006` and `012`, and `008`'s `A` half**, which
needs a codec API analysis of caller-provided destinations.

Three dependency defects are on the record for the owner, who owns `J2KSwift`, none
fixable from this repository: an unbounded allocation from `SIZ` dimensions, a trap on
their overflow, and a silent thousandfold amplification from a one-bit change.
Voxelia refuses all three before the codec runs, so they are contained rather than
outstanding — but they remain live for any other consumer of that library.

## Affected modules

`VoxeliaCompression` gains `CodestreamHeaderBudget`, `CodestreamGeometry`,
`CodestreamHeaderReading` and `CodestreamBudgetError`, and
`CompressedDecodeValidator.admitDestination` now also bounds the codestream header. No
other module changes and nothing new is imported.

## Compatibility impact

`admitDestination` can now refuse inputs it previously admitted — specifically, payloads
whose codestream header is a malformed JPEG 2000 stream or declares a geometry beyond
the ceiling. That is the intended behaviour change and the reason for the record. No
signature changes; the existing 1101-test suite passes unaltered, because its synthetic
payloads carry non-JPEG-2000 codestreams which the gate correctly declines to judge.

## Security impact

Positive and specific. Three measured process-level failures — a kill, a trap, and a
silent thousandfold amplification — become typed refusals raised before the codec is
invoked. `VOX-SEC-001`'s bounded-resource obligation is served on the compression path
by a check, not by a caller's diligence.

## Performance and memory impact

One bounded pass over the `SIZ` segment per admission — tens of bytes read, no
allocation — against a decode measured in seconds.

## Validation impact

```text
swift build && swift test
swift test --filter "CodestreamHeaderBudget"
python3 Tools/Scripts/check_swift_safety.py
python3 Tools/Scripts/check_prohibited_imports.py
python3 Tools/Scripts/check_package_graph.py
swift format lint --strict Sources/VoxeliaCompression/Public/CodestreamHeaderBudget.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1116 tests in 202 suites pass. The adversarial sweep is a recorded harness run in a
scratch workspace; no repository test invokes the codec, reads the owner's data, or
depends on the dependency's failure behaviour.

## Migration

1. This record, `CodestreamHeaderBudget`, and its wiring into `admitDestination`.
2. **Next**: the compression arc has no further requirement rows. The M5 queue's
   remaining work is `008`'s `A` half; after that the interactive draw-loop arc, which
   needs its own architectural record before any code.
3. **Owner**: `VOX-CMP-006`'s and `VOX-CMP-012`'s Reviews, the three `J2KSwift` defects
   above alongside `ADR-0272`'s two observations, and the five decisions already open.

## Supersession

This record supersedes nothing. It **extends** `ADR-0258`'s destination admission with a
second, independent bound, and **re-tests `ADR-0272`'s marker walk** under an adversarial
corpus. Neither record is edited.

## References

- [ADR-0258 - Compressed decode admission](ADR-0258-compressed-decode-admission.md)
- [ADR-0259 - Cancellable decode session](ADR-0259-cancellable-decode-session.md)
- [ADR-0268 - J2K volume adapter](ADR-0268-j2k-volume-adapter.md)
- [ADR-0272 - Codec output and interoperability status](ADR-0272-codec-output-and-interoperability-status.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
