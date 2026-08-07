---
document_id: "ADR-0334"
title: "The repository is format clean"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
---

# ADR-0334 - The repository is format clean

## Context

`ADR-0333` made `Tests/` clean and recorded a newly-visible `Sources/` backlog of 29 findings,
to be taken one rule class at a time. This clears it. **Both trees now report zero.**

## What the 29 turned out to be

The number looked like product-code churn and was not. Read by file:

- **Five `Module.swift` marker files** — four `OrderedImports`, one `RemoveLine`. These are
  module-identity stubs, not logic.
- **Twenty-four in twelve `ApplePlatformGate.swift` files** — two each, every one the **same
  shape**: an `#error(…)` directive inside an `#if` block, unindented. It is the identical
  finding already fixed and verified in `Tests/Support/ApplePlatformGate.swift` by `ADR-0333`.

**Not one finding was in a file containing algorithm or operation logic.** The estimate in
`ADR-0333` — that 24 indentation edits across product code needed reading against the
compiler — was the right caution on the information available and turned out not to apply,
because the edits were all in platform-gate stubs.

## A refinement to `ADR-0333`'s finding

That record concluded, on measurement, that `swift format --in-place` does not fix what
`swift format lint --strict` reports. **That is true of some rules and not all.** Run over the
five `Module.swift` files it fixed every one, taking the count from 29 to 24 — lexicographic
import sorting is something the formatter performs. What it did **not** do, in `ADR-0333`'s
case, was regroup `@testable import` after plain imports, nor indent a preprocessor directive.

So the accurate statement is: **the formatter fixes a subset, and which subset must be measured
rather than assumed in either direction.** `ADR-0333`'s conclusion is corrected here rather than
edited there.

## Decision

1. **The five marker files were formatted**, and the twenty-four directives indented by the same
   scripted transformation `ADR-0333` verified.
2. **Verified three ways, not one.** `swift format lint --strict --recursive` reports zero over
   `Sources/` and zero over `Tests/`; `swift build` completes; the suite passes at 1238 in 219.
   A whitespace change to a file containing `#error` directives could plausibly have altered
   which branch compiled, so the build is part of the evidence rather than an afterthought.
3. **No gate is added.** A whole-tree lint is one command and belongs in the validation block of
   every increment, which is where `ADR-0333` put it. What was missing was the habit, and the
   habit is now recorded twice.

## Alternatives considered

### Take the two rule classes as separate increments, as `ADR-0333` proposed

Rejected once the files were read. That plan assumed the indentation findings were spread
through product logic; they are twenty-four instances of one pattern in twelve stub files, and
splitting them would produce two commits with the same one-line diff repeated.

### Trust the formatter for the directives too

Rejected on `ADR-0333`'s measurement — it left them alone there. The scripted indent is what was
verified, so it is what was used.

## Consequences

**The repository is format-clean under its own strict lint for the first time in this arc**, and
`ADR-0333`'s conclusion about the formatter is refined from *does not fix* to *fixes a measured
subset*.

## Affected modules

Seventeen files: five `Module.swift` markers and twelve `ApplePlatformGate.swift` stubs. No
algorithm, operation or kernel source changed.

## Compatibility impact

None. The changes are whitespace and import order in files that declare no API.

## Security impact

None. The platform gates still refuse the same platforms; the build confirms it.

## Performance and memory impact

None.

## Validation impact

```text
swift build
swift test
swift format lint --strict --recursive Sources/
swift format lint --strict --recursive Tests/
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged. Both trees report zero findings.

## Migration

1. This record and seventeen formatting fixes.
2. **Next**: `ADR-0321`'s 121-spelling ratchet, the last backlog this arc created.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **completes** `ADR-0333`'s backlog and **corrects** its
conclusion about the formatter's reach.

## References

- [ADR-0332 - The test level ratchet is clean](ADR-0332-the-test-level-ratchet-is-clean.md)
- [ADR-0333 - Tests are format clean](ADR-0333-tests-are-format-clean.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
