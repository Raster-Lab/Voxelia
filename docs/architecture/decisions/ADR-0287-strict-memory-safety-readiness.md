---
document_id: "ADR-0287"
title: "Strict memory safety readiness"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SEC-001"
---

# ADR-0287 - Strict memory safety readiness

## Context

`ADR-0286` recorded that a pointer API reached a test without the safety gate objecting,
and attributed it to `check_swift_safety.py` not scanning `Tests/`. Investigating that for
its own increment found the attribution wrong and the real situation more interesting.

## Correcting `ADR-0286`

**`Tests` is scanned.** It is the second entry in the script's scan roots, alongside
`Sources`, `Benchmarks`, `Tools` and `Validation`. That claim in `ADR-0286` is withdrawn.

**And the camelCase exclusion is deliberate, not an oversight.** The policy states it
outright: reserved spellings are `@unchecked`, `@preconcurrency`, `StrictMemorySafety` and
the bare Swift word `unsafe`, while "ordinary checked vocabulary such as `free`,
`UnsafePointer` in explanatory text outside manifests **or an identifier containing
`unsafe` is not reserved**".

So `withUnsafeBytes` passing is the policy working as written, not a hole in it. `ADR-0286`
also said "the policy forbids the API regardless", and that is over-strict: the policy
reserves *spellings*, and this project's preference for checked vocabulary over pointer
APIs is an engineering habit rather than a rule that document states.

`ADR-0286` is **not edited**; its correction of the rendering defect stands and only these
two claims are withdrawn.

## The real gap

The policy's model is stated in its first sentence: Voxelia permits "only one explicitly
approved **compiler-classified** memory boundary".

**No compiler was doing the classifying.** `StrictMemorySafety` appears nowhere in
`Package.swift` — zero occurrences — so the Swift 6 `unsafe` expression marker was never
compiler-required. The markers in `MetalBufferTransfer.swift` are written voluntarily, and
the word-based scan that finds them detects a **convention the codebase follows**, not a
property the compiler enforces.

Evidence rather than inference: the `withUnsafeBytes` in `ADR-0286`'s test compiled with no
marker at all.

## Measured, with a positive control first

`-strict-memory-safety` was confirmed live on this toolchain before any package number was
believed. A three-line probe using `withUnsafeBufferPointer` compiles clean without the
flag and emits `warning: expression uses unsafe constructs but is not marked with 'unsafe'
[#StrictMemorySafety]` with it.

That control mattered. The first package measurement counted **errors** and reported zero —
which proved nothing, because strict memory safety emits **warnings**. The number was
meaningless until the control established the flag fires at all.

Counting warnings on genuinely fresh builds into a scratch path:

| Build | Units | `StrictMemorySafety` diagnostics |
|---|---:|---:|
| product source | 895 | **0** |
| source **and tests**, before this increment | 1,150 | **14** |
| source **and tests**, after this increment | 1,150 | **0** |

All fourteen were in two files — `DICOMFrameAdapterTests` and `DICOMFrameTransferTests` —
from three `withUnsafeBytes(of:)` calls encoding a little-endian sixteen-bit value.

## Decision

1. **The two test files are rewritten to explicit shifts.** The encoding is now stated in
   the test rather than delegated to memory layout, which is clearer as well as clean, and
   it is the same replacement `ADR-0286` made in its own fixture.
2. **The whole package is now strict-memory-safety clean**, source and tests, at zero
   diagnostics over 1,150 units.
3. **`StrictMemorySafety` is not enabled in this increment**, and the reason is not
   reluctance. The manifest is lexed against a thirty-identifier declarative subset, and it
   permits **none** of `swiftSettings`, `SwiftSetting`, `enableExperimentalFeature` or
   `strictMemorySafety`. Enabling the mode therefore requires widening a safety control,
   which is a governed change and deserves its own increment with its own negative tests —
   not a tail-end addition to the increment that discovered it. This is the same reasoning
   `ADR-0286` used when it declined to widen the scan inside a rendering correction.
4. **The proposal is now evidence-backed rather than speculative.** Enabling the mode would
   cost **no code change at all**: the package already satisfies it. What it would buy is
   the policy's own stated model — a boundary the *compiler* classifies rather than one a
   regular expression looks for.
5. **No pattern is added to `check_swift_safety.py`.** Extending it to match camelCase
   identifiers would contradict the written policy, which excludes them explicitly. The
   right instrument is the compiler, not a wider regular expression.

## What the enabling increment must settle

Recorded so it has a scope rather than a direction:

- Which identifiers the manifest allowlist gains, and whether the addition stays inside the
  "deterministic declarative subset" the policy requires — it is configuration, not
  executable logic, which is the argument for it.
- Whether the setting is package-wide or per-target.
- A negative test that the widened allowlist still refuses everything it refused before —
  the discipline `ADR-0233` applied when the licence gate was widened.
- Whether `MetalBufferTransfer`'s governed exception needs its `expected_findings`
  revisited once the compiler, rather than convention, is requiring its markers.

## Alternatives considered

### Extend the safety scan to camelCase pointer identifiers

Rejected, and it was the plan when this increment began. The policy says identifiers
containing `unsafe` are **not** reserved, so adding them would make the tool enforce a rule
the policy does not state — the inverse of `ADR-0196`'s finding, and just as wrong.

### Enable `StrictMemorySafety` in this increment

Rejected on scope; see decision 3. The measurement makes it cheap, and cheap is not the
same as in-scope for an increment whose subject was a mis-attributed gate result.

### Leave the two test files alone, since the policy permits them

Rejected. They are the only thing standing between the package and a clean strict build, the
replacement is two lines each, and doing it now means the enabling increment is a pure
configuration change with nothing else entangled.

### Accept `ADR-0286`'s account and move on

Rejected. It named a scan scope that is not the problem, which would have sent the next
reader to widen a scan that already covers the directory.

## Consequences

Two claims in `ADR-0286` are withdrawn and the real gap is stated: the policy describes a
compiler-classified boundary and no compiler was classifying.

The package is strict-memory-safety clean at zero diagnostics, so enabling the mode is now
a configuration decision with a measured cost of nothing.

A third instance of the `ADR-0196` pattern is on the record — but inverted. The earlier two
were rules asserted and not enforced; this one is a rule enforced by convention where the
policy's own words describe compiler enforcement.

## Affected modules

None. Two test files change their byte encoding; no product source changes.

## Compatibility impact

None.

## Security impact

Neutral today and positive once the mode is enabled. Nothing about the package's actual
memory safety changed — it was already clean; what changed is that this is now known rather
than assumed.

## Performance and memory impact

None.

## Validation impact

```text
swift build && swift test
swift test --filter "DICOMFrameAdapter|DICOMFrameTransfer"
swift build --build-tests --scratch-path <scratch> -Xswiftc -strict-memory-safety
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1152 tests in 207 suites pass, unchanged. The strict build is a recorded fresh-scratch
measurement, and the flag was positive-controlled before its results were used.

## Migration

1. This record and the two rewritten test fixtures.
2. **Next**: the enabling increment, settling the four items above.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **withdraws two claims from `ADR-0286`** and replaces
them with a measured account. `ADR-0286` is unedited.

## References

- [ADR-0186 - Governed Metal buffer transfer](ADR-0186-governed-metal-buffer-transfer.md)
- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0282 - Decision register enforcement](ADR-0282-decision-register-enforcement.md)
- [ADR-0286 - Shading normal space correction](ADR-0286-shading-normal-space-correction.md)
