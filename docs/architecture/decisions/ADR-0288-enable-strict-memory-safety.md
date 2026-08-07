---
document_id: "ADR-0288"
title: "Enable strict memory safety"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SEC-001"
---

# ADR-0288 - Enable strict memory safety

## Context

`ADR-0287` established that the safety policy describes "one explicitly approved
**compiler-classified** memory boundary" while no compiler was classifying: the Swift 6
`unsafe` expression marker was never required, so the word-based scan detected a convention
rather than a property. It measured the package strict-memory-safety clean at zero
diagnostics over 1,150 units and left enabling the mode to its own increment, with four
items to settle.

This settles them.

## A correction to my own working assumption

Investigating whether the setting was reachable, a probe reported
`'strictMemorySafety' is unavailable` and the conclusion drawn was that enabling it needed a
tools-version raise. **That was wrong**: the probe was written at
`swift-tools-version:6.0`, and **Voxelia's manifest has been at `6.2` all along**. The
setting was available the whole time. Recorded because the wrong conclusion would have
turned a two-identifier change into a manifest-semantics migration.

## The four items

**1 — which identifiers the allowlist gains.** Exactly two: `swiftSettings` and
`strictMemorySafety`. Both are declarative configuration, not executable logic, which is
the argument for admitting them into a subset whose purpose is to keep SwiftPM's
pre-compilation execution deterministic.

**2 — package-wide or per-target.** Per-target, and not by choice. The manifest lexer
permits **exactly one `let` and one `=`**, so the natural single-sourcing —
`let safety: [SwiftSetting] = [.strictMemorySafety()]` referenced by every target — is
structurally forbidden. The setting is therefore written inline on all **29** targets. That
is verbose, and it matches the house rule that every optional parameter is passed
explicitly at every call site rather than defaulted.

**3 — the negative test.** The widened allowlist must still refuse everything it refused
before, so three refusals were exercised and all three still fire:

- `.unsafeFlags(["-Onone"])` → `unsafe package compiler flags: .unsafeFlags` **and**
  `manifest outside approved declarative subset: unsafeFlags`
- `.define("ARBITRARY")` → `manifest outside approved declarative subset: define`
- a second `let` binding → `manifest outside approved declarative subset: extra`

The widening admitted two identifiers and nothing else.

**4 — `MetalBufferTransfer`'s governed exception.** Unchanged, and now stronger. Its three
`unsafe` markers were voluntary; the compiler now **requires** them. The file's SHA-256 pin
and its three `expected_findings` are untouched, and the safety scan passes.

## The positive control

A manifest change that is silently ignored looks exactly like one that works. So a
temporary probe was added to `VoxeliaSpatial` using `withUnsafeBufferPointer` with no
marker, and the build emitted:

```text
warning: expression uses unsafe constructs but is not marked with 'unsafe' [#StrictMemorySafety]
```

The probe was then removed and the build returned clean. **The mode is live**, not accepted
and ignored.

## Decision

1. **`StrictMemorySafety` is enabled on all 29 targets**, product and test alike.
2. **The declarative subset gains exactly `swiftSettings` and `strictMemorySafety`**, and
   the negative tests above are the evidence that nothing else came with them.
3. **The policy's stated model is now true.** "Compiler-classified memory boundary"
   describes what the compiler does rather than what the codebase habitually writes, and
   `check_swift_safety.py`'s word detection now backs a compiler requirement instead of
   standing in for one.
4. **No source changed.** `ADR-0287` did the only preparation needed by rewriting two test
   fixtures; the package was already clean.
5. **A clean rebuild was performed**, because a manifest change alters every target's
   compilation. Zero strict diagnostics across the rebuilt package and tests.

## A pre-existing failure found and not mine

`Tools/Tests/Python/test_repository_scripts.py` fails one of twelve tests: it asserts the
DocC wrapper passes `OTHER_DOCC_FLAGS='--warnings-as-errors'`, and the wrapper deliberately
does **not** — its own comment explains that `ADR-0233` removed the global flag because
`docbuild` documents the whole package graph and a global flag would fail the gate on a
transitive dependency's doc comments.

So the script was corrected and its self-test was not.

**Verified pre-existing rather than assumed**: the tree was stashed and the failure
reproduces on pristine `main`. That check is standing practice here after a whole-suite
failure was once misattributed to in-progress work. It is recorded for its own increment
rather than fixed inside a manifest change, and it is not in `validate-docs.sh`, which is
why it has gone unnoticed.

## Alternatives considered

### Single-source the setting through a shared `let`

Rejected because it is structurally impossible, not because it is undesirable — it is the
better shape. The manifest lexer permits one `let` and one `=`, and that constraint exists
so SwiftPM's pre-compilation execution stays trivially auditable. Repetition is the price.

### Enable it only on product targets

Rejected. The tests are where the pointer APIs actually appeared — `ADR-0287` found all
fourteen diagnostics in two test files — so excluding tests would exempt the code most
likely to reach for them.

### Widen the allowlist more broadly while it is open

Rejected. Two identifiers were needed and two were added. A safety control is not the place
to bank future convenience, and the negative tests exist precisely to prove nothing else
slipped in.

### Treat the stale self-test as in scope

Rejected. It is unrelated to memory safety, it reproduces on pristine `main`, and folding an
unrelated fix into a governed manifest change is how a diff stops being reviewable.

## Consequences

The Swift compiler now enforces what the policy always described. A future increment that
reaches for a pointer API gets a diagnostic at the call site rather than passing a scan that
was never looking for it.

The manifest's declarative subset is two identifiers wider, with three refusals re-verified.

A stale script self-test is on the record, with its pre-existence established rather than
assumed.

## Affected modules

None. `Package.swift` gains a setting on every target and
`Tools/Scripts/check_swift_safety.py` gains two allowlist entries. No Swift source changed.

## Compatibility impact

Consumers building this package now compile under strict memory safety. Since the package
is clean, nothing they see changes; a consumer adding memory-unsafe code to a fork would
now see diagnostics, which is the intent.

## Security impact

Positive, and this is the increment's whole point. The one approved memory boundary is now
compiler-classified rather than convention-marked, and any new unmarked unsafe construct is
diagnosed where it is written.

## Performance and memory impact

None. Strict memory safety is a diagnostic mode; it changes no generated code.

## Validation impact

```text
rm -rf .build && swift build --build-tests
swift test
python3 Tools/Scripts/check_swift_safety.py
python3 Tools/Scripts/check_package_graph.py
python3 Tools/Scripts/check_package_graph_static.py
python3 Tools/Scripts/check_licence_policy.py
python3 Tools/Scripts/check_prohibited_imports.py
swift format lint --strict Package.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1152 tests in 207 suites pass after a clean rebuild, with zero strict-memory-safety
diagnostics. The mode was positive-controlled and the allowlist widening negative-tested
three ways.

## Migration

1. This record, the manifest setting and the two allowlist entries.
2. **Next**: the stale DocC self-test, then a re-derived queue.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **completes `ADR-0287`'s proposal** and makes
`ADR-0186`'s governed boundary compiler-enforced rather than convention-marked.

## References

- [ADR-0186 - Governed Metal buffer transfer](ADR-0186-governed-metal-buffer-transfer.md)
- [ADR-0233 - DICOMKit adapter and dependency](ADR-0233-dicomkit-adapter-and-dependency.md)
- [ADR-0286 - Shading normal space correction](ADR-0286-shading-normal-space-correction.md)
- [ADR-0287 - Strict memory safety readiness](ADR-0287-strict-memory-safety-readiness.md)
