---
document_id: "ADR-0333"
title: "Tests are format clean"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
---

# ADR-0333 - Tests are format clean

## Context

`ADR-0332` recorded thirteen `swift format lint --strict` findings across `Tests/` as
pre-existing and deliberately untouched, so a retagging commit would not hide unrelated edits.
This clears them as their own increment.

## The finding that changed the approach

**`swift format --in-place` does not fix what `swift format lint --strict` reports for these
rules.** The formatter was run over all thirteen files and **changed nothing**; the lint count
stayed at thirteen.

So `OrderedImports` and `Indentation` are, for these shapes, lint-only: they are reported and
not corrected. That is worth knowing before anyone assumes a formatter pass will clear a lint
backlog, and it is why this increment edits rather than formats.

## What was done

- **Eleven module-linkage test files**: `@testable import` moved after the plain imports, with
  a blank line between the groups. A scripted, well-defined transformation over a three-line
  import block, not a judgement.
- **`Tests/Support/ApplePlatformGate.swift`**: the two `#error(...)` bodies inside their `#if`
  blocks indented four spaces.

`Tests/` now reports **zero** findings, and the suite is unchanged at 1238 in 219.

## The backlog this uncovered

Checking `Sources/` — which no increment in this arc had — reports **29 findings**:

| Rule | Count |
|---|---|
| `Indentation` | 24 |
| `OrderedImports` | 4 |
| `RemoveLine` | 1 |

**This is not fixed here, and the reason is not effort.** `Sources/` is product code under
`swiftLanguageModes: [.v6]` with `StrictMemorySafety`, and 24 indentation edits across it is a
diff that must be read against the compiler rather than waved through at the end of a session
that has already touched 219 test display strings.

It is also newly visible: the arc's format checks have been per-file on changed sources, so a
whole-tree `Sources/` lint had not been run. Recording the number is the point of noticing it.

## Decision

1. **`Tests/` is format-clean**, and the two mechanical shapes are fixed by hand because the
   formatter does not fix them.
2. **The `Sources/` backlog of 29 is recorded, not fixed.** It is the next increment, and it
   should be taken with the suite green before and after each rule class rather than in one
   sweep.
3. **No gate is added.** `swift format lint` is already run per file in every increment's
   validation block; what was missing was a whole-tree run, which is a habit rather than a
   mechanism.

## Alternatives considered

### Run the formatter and trust it

Rejected on measurement — it changed nothing. Assuming a formatter clears its own linter's
findings is the mistake this record exists to document.

### Fix `Sources/` in the same commit

Rejected; see the backlog section. It is product code, and 24 indentation edits deserve their
own reading.

### Leave `Tests/` as `ADR-0332` left it

Rejected. `ADR-0332` deferred them explicitly so they would be done separately, not so they
would be forgotten.

## Consequences

`Tests/` is clean under the project's own strict lint, and a 29-finding `Sources/` backlog is
visible for the first time in this arc.

## Affected modules

None. Twelve test files. No source file changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test
swift format lint --strict --recursive Tests/
swift format lint --strict --recursive Sources/
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged. `Tests/` reports zero findings; `Sources/` reports 29.

## Migration

1. This record and twelve formatting fixes.
2. **Next**: the `Sources/` backlog, one rule class at a time.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **completes** what `ADR-0332` deferred.

## References

- [ADR-0331 - Shrink the untagged test backlog](ADR-0331-shrink-the-untagged-test-backlog.md)
- [ADR-0332 - The test level ratchet is clean](ADR-0332-the-test-level-ratchet-is-clean.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
