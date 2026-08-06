---
document_id: "ADR-0260"
title: "Compressed scope and destination"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SEC-001"
  - "VOX-CMP-003"
  - "VOX-CMP-008"
---

# ADR-0260 - Compressed scope and destination

## Context

Compression increment (e), the last of `ADR-0255`'s buildable set. Two rows:

- `VOX-CMP-003` (`I,T`): support original compressed sources, compressed slices,
  compressed slabs and compressed three-dimensional bricks.
- `VOX-CMP-008` (`T,A`): the decode path shall support caller-provided or reusable
  destination storage **where the codec API permits it**.

## Decision

### `VOX-CMP-003`: four shapes are one region plus a frozen classification

1. **The four shapes are not four unrelated things.** Each is a region of a parent
   volume, and which name applies follows from the region's bounds. `CompressedScope`
   therefore stores the region — composing `ImageRegion` from `VoxeliaCore` rather
   than inventing a region type — and **derives** the kind.
2. **The kind is derived, never declared**, for the same reason
   `CompressedPayload.declaredDecodedByteCount` is: a declared classification could
   contradict the region it describes.
3. **The frozen classification, applied in order:** covering every axis fully is the
   original source; otherwise exactly one axis of extent one with the rest full is a
   slice; otherwise exactly one partial axis with the rest full is a slab;
   otherwise a brick.
4. **Clause order resolves a genuine ambiguity, and that is why it is frozen.** A
   volume whose slice axis has extent one is *simultaneously* the whole volume and a
   single plane — both descriptions are true. Covering everything is the stronger
   statement, so it takes precedence. A classification whose answer depended on which
   clause happened to be checked first would be ambiguous, and a test pins both the
   flat-volume case and the plane-of-a-taller-volume case so the rule is precedence
   rather than a special case for extent one.
5. **A payload whose declared extents disagree with its region is refused.** A
   codestream declaring `512x512x8` cannot describe a region of extent
   `512x512x899`; admitting it would surface later as a truncated decode.

**The classification is enumerated, not sampled.** Every region of a `2x2x2` volume
is classified — eight cases — and the test asserts which kinds that volume can
produce. It reaches `originalSource`, `slice` and `brick` but **not** `slab`, because
a partial axis of a two-deep volume always has extent one. That is stated as an
expectation rather than left as a silent gap in the coverage claim, with a taller
volume covering the fourth kind.

### `VOX-CMP-008`: build the reuse, and record what cannot be verified

6. **`DecodeDestination` is caller-allocated, admitted before a decode, and
   reusable.** `prepare(for:)` refuses a payload exceeding capacity **before** any
   fill — the same ordering `ADR-0258` decision 1 established — and records the
   length the fill must supply. A test observes capacity surviving two differently
   sized fills with contents replaced rather than appended.
7. **A partial fill is refused, and so is filling before preparing.** A destination
   that accepted fewer bytes than it was prepared for would hold a partial decode
   that `isComplete` could not distinguish — the `VOX-CMP-009` hazard arriving by a
   different route. Over-long fills are refused too, and a test confirms no refusal
   leaves partial contents behind.
8. **`prepare(for:)` clears previous contents**, so a decode that fails after
   preparation cannot expose the previous decode's samples.
9. **Whether any codec accepts a caller-provided destination is not verified, and
   this record says so plainly.** `VOX-CMP-008`'s qualifier — "where the codec API
   permits it" — is load-bearing. No codec is linked (`ADR-0255`), so the question is
   unanswerable here, **and the project already has a precedent for the answer being
   no**: `ADR-0235` found DICOMKit's pixel surface returns an owned `Data` with no
   entry point taking a destination, which made `ADR-0230` decision 10's direct-write
   model unimplementable. The same may prove true of the codecs, in which case this
   destination serves reuse on Voxelia's side and one copy per decode remains —
   exactly `ADR-0235`'s conclusion for frames. Recording that now is the point: the
   alternative is discovering it when a codec is linked, against a record that reads
   as though direct decode into this buffer were established.
10. **It is a value type, so "reuse" means the caller keeps and re-prepares one
    value** rather than sharing a mutable buffer across concurrent decodes. A shared
    mutable destination would need an ownership story no requirement in this arc
    calls for, and the project's concurrency policy admits no escape hatch to fake
    one.
11. **No algorithm specification and no oracle.** The classification is a comparison
    of extent lists; no numeric boundary is frozen.

## Alternatives considered

### Model the four shapes as four types, or as a declared enum on the payload

Rejected; see decisions 1 and 2. Four types would duplicate the region logic four
times, and a declared kind could disagree with its own bounds.

### Define a compression-local region type

Rejected. `ImageRegion` already admits non-negative, non-empty bounds and is
Core-owned, so composing it costs nothing and avoids a second region vocabulary that
could drift.

### Let the slice clause win over the covering-everything clause

Rejected; see decision 4. It would classify a single-plane volume as a slice of
itself, which reads as though something were extracted when nothing was.

### Make `DecodeDestination` a class so one buffer can be shared

Rejected; see decision 10. Sharing invites concurrent mutation, and nothing in the
arc requires it.

### Claim `VOX-CMP-008` fully discharged

**Partially rejected, and stated precisely rather than glossed.** The `T` half is
discharged: caller-provided and reusable destination storage exists and is tested.
The `A` half — the analysis of whether the codec API permits direct decode into it —
**cannot be performed without a codec**, so it is recorded as outstanding rather
than claimed. This is the honest reading of a row whose own wording is conditional
on a fact this project cannot yet establish.

## Consequences

**All seven of `ADR-0255`'s buildable rows are now discharged**: `VOX-CMP-002`,
`003`, `007`, `009`, `010`, `013`, and `008` in its `T` half.

**Everything remaining in the compression arc is owner-blocked**: `VOX-CMP-004`,
`005`, `006`, `011`, `012`, `014`, plus `VOX-CMP-008`'s `A` half, plus the
supply-chain question of whether a codec may be declared directly. The arc cannot
advance further without the owner reconciliation `ADR-0255` referred.

## Affected modules

`VoxeliaCompression` gains `CompressedScope`, `CompressedScopeKind`,
`DecodeDestination` and two failure families. No other module changes.

## Compatibility impact

Additive.

## Security impact

Positive. A payload cannot claim a region it does not describe, a destination cannot
hold a partial decode indistinguishable from a complete one, and preparation cannot
leave a previous decode's samples visible.

## Performance and memory impact

The destination allocates once at its stated capacity and reuses it across fills;
`prepare` and `fill` both clear with `keepingCapacity: true`, so repeated decodes do
not reallocate. Classification is one comparison of extent lists.

## Validation impact

```text
swift build && swift test
swift test --filter "CompressedScope|DecodeDestination"
python3 Tools/Scripts/check_swift_safety.py
swift format lint --strict Sources/VoxeliaCompression/Public/CompressedScope.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1064 tests in 197 suites pass.

## Migration

1. This record. **The compression arc's buildable half is complete.**
2. **Owner decisions, now blocking all further compression work**:
   - Reconcile `VOX-CMP-004`, `005`, `006`, `011`, `012` and `014` with the standing
     instruction not to characterise or adversarially test the Raster-Lab codecs.
   - Whether any codec may be declared a **direct** dependency, given the current
     approval covers them transitively through DICOMKit.
   - `VOX-CMP-008`'s `A` half depends on the first two, since it needs a codec API to
     analyse.

## Supersession

This record supersedes nothing.

## References

- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [ADR-0255 - Open the compression arc](ADR-0255-open-the-compression-arc.md)
- [ADR-0258 - Compressed decode admission](ADR-0258-compressed-decode-admission.md)
- [ADR-0259 - Cancellable decode session](ADR-0259-cancellable-decode-session.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
