---
document_id: "ADR-0258"
title: "Compressed decode admission"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SEC-001"
  - "VOX-CMP-010"
  - "VOX-CMP-011"
---

# ADR-0258 - Compressed decode admission

## Context

Compression increment (c). `VOX-CMP-010` requires codec adapters to validate
dimensions, component formats and decoded byte counts, declaring `T`.

`ADR-0255` distinguished this row from `VOX-CMP-011` and the distinction is what
shapes this increment: `VOX-CMP-010` is adapter-side and fully buildable, because
it validates values Voxelia holds; `VOX-CMP-011` is not fully achievable
adapter-side, because a codestream cannot be validated without parsing it and
parsing is the codec's job. This record builds the first and **narrows** the second
without claiming to close it.

## Decision

1. **Two checks at two different times, and the order is the substance.**
   `admitDestination(for:maximumDecodedByteCount:)` runs **before** a decode;
   `admit(_:against:)` runs after it. A caller that only ran the second would
   already have allocated.
2. **The pre-decode ceiling is caller-stated, not chosen here.** Voxelia's own
   allocation is bounded by a figure the caller supplies, so a declared shape of
   four gigabytes is refused against a caller's five-hundred-megabyte ceiling
   before any buffer exists. No default ceiling is invented: the right bound
   depends on the caller's budget, which this module cannot know.
3. **`CompressedPayload` gains a declared component count**, and the declared byte
   count now multiplies by it. `VOX-CMP-010` names "component formats", and a codec
   returning three components where one was declared is a disagreement the byte
   count alone can miss when extents differ to compensate. This is an additive
   change to a type introduced in `ADR-0256`, and the overflow check gained a third
   multiplication accordingly.
4. **Every comparison is exact equality, and there is no tolerance to apply.** A
   decoded byte count is a count; extents are counts; a scalar format and a
   component count are discrete. A near-miss on any of them is a disagreement about
   what the data *is*, not a rounding difference — so this row raises no tolerance
   question and touches no tolerance gate.
5. **The checks run dimensions, then component count, then format, then byte
   count**, so the most specific disagreement is reported. Wrong extents
   necessarily make the byte count wrong too, and a caller should learn that the
   dimensions disagree rather than that a figure derived from them does. Two tests
   pin the order.
6. **The decode's report is a value, not a codec call.** `DecodedSampleClaim` is
   filled in by whatever adapter wraps a codec, so the validation is testable with
   no codec linked — the same source-agnostic shape `ADR-0249` used for the import
   session, and the reason this increment can proceed while `ADR-0255`'s
   supply-chain questions are open.
7. **The failure family is payload-free**, and here that is load-bearing rather
   than habitual: the input that provokes these refusals is exactly the input that
   should learn nothing about what was expected.
8. **No algorithm specification and no oracle.** The arithmetic is equality
   comparisons and one checked multiplication.

## What this narrows of `VOX-CMP-011`, stated precisely

The ceiling is the genuinely bounded part of `VOX-CMP-011`: **Voxelia's own
allocation cannot exceed a figure the caller stated**, whatever a codestream
declares.

**It does not bound the codec.** If a codec allocates from the codestream's own
internal headers rather than from the parameters an adapter passes it, or faults on
malformed input, nothing in this file prevents either. That residual exposure stays
open, stays recorded, and stays part of the owner reconciliation `ADR-0255`
referred — it is not narrowed by going unmentioned, which is why both the record
and the source say so explicitly.

Two directions of byte-count disagreement are tested for the same reason. A **short**
decode is the case a truncated codestream produces, and admitting it would publish
uninitialised or stale destination bytes as samples. An **over-long** decode would
overrun a destination sized from the declarations. Neither is admitted.

## Alternatives considered

### Choose a default destination ceiling

Rejected; see decision 2. A default would be either so large it bounds nothing or
so small it refuses legitimate volumes, and the caller is the only party that knows
its budget. The real 899-frame CT volume is 449 MiB, so any figure this module
picked would be a guess about a caller's memory.

### Validate only the decoded byte count, since extents imply it

Rejected. The implication runs the wrong way: equal byte counts do not imply equal
extents. `2x3x4` and `4x3x2` hold the same sample count and are different images, and
a test pins that permuted extents are refused.

### Derive the ceiling from the payload itself

Rejected as circular. The declared shape is what the ceiling exists to bound; using
it as its own bound would admit everything.

### Fold the two checks into one call taken after the decode

Rejected; see decision 1. It would make the ceiling useless, because the allocation
it exists to prevent would already have happened.

### Claim `VOX-CMP-011` as narrowed enough to discharge

Rejected. The adapter-side bound is real but partial, and the row declares `T,A`
over adversarial codestreams. Claiming it on the strength of a ceiling would
overstate what a ceiling does.

## Consequences

`VOX-CMP-010` is discharged. Three of the compression arc's seven buildable rows
are now done: `002`, `007`, `013`, `010`.

`VOX-CMP-011`'s residual exposure is narrower and precisely described.

## Affected modules

`VoxeliaCompression` gains `CompressedDecodeValidator`, `DecodedSampleClaim` and a
failure family, and `CompressedPayload` gains a declared component count. No other
module changes.

## Compatibility impact

`CompressedPayload.init` gains a required parameter. Additive in effect, since the
type was introduced in this same arc and has no callers outside it — recorded as a
change rather than described as purely additive.

## Security impact

Positive, and this is the increment's purpose. A hostile or corrupt declared shape
cannot cause Voxelia to allocate beyond a caller-stated bound, a truncated decode
cannot be published as complete samples, and an over-long decode cannot overrun a
destination. The refusals disclose nothing.

## Performance and memory impact

None measurable: a handful of equality comparisons per decode, and one extra
checked multiplication at payload admission.

## Validation impact

```text
swift build && swift test
swift test --filter "CompressedDecodeValidator"
python3 Tools/Scripts/check_swift_safety.py
swift format lint --strict Sources/VoxeliaCompression/Public/CompressedDecodeValidator.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1045 tests in 194 suites pass after a clean rebuild, which a changed public stored
member requires.

## Migration

1. This record.
2. Increment (d): `VOX-CMP-009`, adapter cancellation, composing `ADR-0249`'s
   checkpoint and probe shape rather than inventing a second model.
3. Increment (e): `VOX-CMP-003` and `VOX-CMP-008`, the source, slice, slab and
   brick shapes and caller-provided destination storage — where a
   `CompressedRepresentation` becomes attached to a payload.
4. **Owner decisions, unchanged**: reconciling the six blocked rows, and whether a
   codec may be declared a direct dependency.

## Supersession

This record supersedes nothing. It **extends `ADR-0256`'s `CompressedPayload`** with
a declared component count, recorded here rather than by editing that record.

## References

- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [ADR-0255 - Open the compression arc](ADR-0255-open-the-compression-arc.md)
- [ADR-0256 - Compression module boundary](ADR-0256-compression-module-boundary.md)
- [ADR-0257 - Toolkit native representation labelling](ADR-0257-toolkit-native-representation-labelling.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
