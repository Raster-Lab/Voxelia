---
document_id: "ADR-0291"
title: "Stored signedness"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-R2D-003"
---

# ADR-0291 - Stored signedness

## Context

`VOX-R2D-003` requires the presentation pipeline to "support signed and unsigned integer
input values required by supported modalities". P0, `T` alone, milestone M4, and one of the
23 rows `ADR-0290`'s sweep found with no record, no test and no source mention.

## What the plan means by it

The row's own sentence is generic; the plan is not. It names "Source signedness — Signed
and unsigned", lists validation fixtures for "synthetic signed 16-bit CT" and "synthetic
unsigned 16-bit CT", and includes "correct signedness" among acceptance items.

CT genuinely arrives both ways — signed stored values, or unsigned with a rescale intercept
carrying the same Hounsfield range. Both must present correctly.

## What the product already does

`WindowLevelOperation` admits exactly `uint8`, `int16` and `uint16`, refusing anything else
as `unsupportedScalarType`, and its decode branches on signedness:
`Int64(Int16(bitPattern:))` sign-extends where `Int64(UInt16)` zero-extends.

So the same sixteen bits are a different number under each declaration. That was
implemented and untested, which is what this increment supplies.

## Decision

1. **`VOX-R2D-003` is discharged** by six tests.
2. **The central test uses one bit pattern under both declarations.** `0xFC18` is `-1000`
   as `int16` and `64536` as `uint16`. Under a window centred on zero the signed reading is
   black and the unsigned reading clamps white, and both are asserted exactly. A pipeline
   that ignored signedness would return identical bytes for both.
3. **A control asserts the two paths agree below `0x8000`,** where sign extension is a
   no-op. Without it, the divergence above is equally consistent with two unrelated code
   paths that happen to differ. The control also asserts the window spreads its inputs
   across more than one output value, so it is not comparing two uniform images.
4. **Both extremes are exercised.** `0x8000` is `Int16.min`, which is where a naive
   negation or magnitude step traps, and `0xFFFF` is the unsigned maximum. Alternating
   samples are asserted to differ, so the decode is shown to distinguish them rather than
   merely to complete.
5. **A non-modality scalar type is asserted refused, not coerced**, following `ADR-0290`'s
   fail-closed property: silently coercing a wider or floating-point input would present
   something whose stored interpretation nobody declared.
6. **No source changed.** The behaviour existed; the row's `T` did not.
7. **No algorithm specification and no oracle.** `VOXELIA-ALG-0002` already governs the
   stored-to-display rule, including the native-byte-order resolution this relies on.

## Two fixture faults worth recording

Both were mine, and both were caught by running rather than by reading.

**The declared byte order must be `.native`.** Declaring `.littleEndian` explicitly — which
is what the layout actually is on this platform — was refused with `byteOrderMismatch`,
because the storage binding and the descriptor must agree on the declaration rather than on
the resulting bytes. `ALG-0002` resolves native to little-endian on every supported
platform, which is why the byte layout is still what the test assumes.

**The refusal test was asserting the wrong guard.** Sizing every buffer at two bytes per
sample meant a `float32` or `int64` input failed `incompatibleBinding` in the storage
contract before `WindowLevelOperation`'s scalar admission ever ran. The test passed the
wrong reason. Sizing the buffer from the binding is what makes it reach the guard it names
— an instance of the same lesson as `ADR-0290`'s exact-token assertions: a refusal is only
evidence when you know which refusal fired.

## Alternatives considered

### Test signedness through `CTValueInterpreter` instead

Rejected as the wrong layer for this row. `VOX-R2D-003` names the **pipeline**, and the
rescale interpreter converts stored values to real ones — a separate concern already
governed by `ALG-0003` and `ADR-0237`. Presentation is where the stored declaration is
consumed.

### Assert only that both types are admitted

Rejected. Admission without correct interpretation is precisely the failure the row
guards: a pipeline could accept `int16` and read it as unsigned, and every test that only
checked acceptance would pass while the display was wrong.

### Cover `uint8` with its own case

Folded in rather than rejected: `uint8` has no signed counterpart, so a signedness suite
has nothing to compare it against. It is admitted and already exercised by the existing
`WindowLevelOperation` suite.

## Consequences

`VOX-R2D-003` is discharged, and a wrong-signedness regression now fails a test that states
the clinical consequence rather than only the byte difference.

**21 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. `VoxeliaExecutionTests` gains one suite of six tests; no source changed.

## Compatibility impact

None.

## Security impact

None directly. The row is a correctness property: a mis-signed CT would display soft tissue
where bone belongs, which is a diagnostic hazard rather than a disclosure one.

## Performance and memory impact

None.

## Validation impact

```text
swift build && swift test
swift test --filter "StoredSignedness"
swift format lint --strict Tests/VoxeliaExecutionTests/StoredSignednessTests.swift
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
Tools/Scripts/test-repository-scripts.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1164 tests in 209 suites pass, up from 1158 in 208.

## Migration

1. This record and its tests.
2. **Next**: `VOX-MPR-014` — measurements in reconstructed views use authoritative physical
   geometry — is the next `P0`, `T`-only row with no gate.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **tests behaviour `VOXELIA-ALG-0002` already governs**
and that `WindowLevelOperation` already implements.

## References

- [ADR-0113 - Pixel padding exclusion](ADR-0113-pixel-padding-exclusion.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [VOXELIA-ALG-0002 - Window level linear](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
