---
document_id: "ADR-0310"
title: "Documented example safety"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-011"
---

# ADR-0310 - Documented example safety

## Context

`VOX-DOC-011` requires that "examples shall not bypass canonical validation or safety
semantics for convenience". P0, **`I,R`**, milestone M4, from `ADR-0290`'s sweep.

## The measurement

**Where the examples are was the first question, and the answer was not where it looked.**
The DocC catalogues contain **no Swift code blocks at all**, and there is no `Examples/` or
`Snippets/` directory. The project's examples are the **224 fenced Swift blocks in `docs/`** —
in the algorithm specifications, the RFCs and the project specifications.

`check_swift_safety.py` enforces the safety semantics over `.swift` files. **A fenced example
in a Markdown specification is not a `.swift` file**, so not one of those 224 blocks had ever
been scanned.

Scanning them found **one** hit, and it is not a violation:
`UnsafeMutableRawBufferPointer`, in a write-destination protocol in the core data model
specification. `ADR-0287` corrected an earlier over-strict reading of this exact rule: the
policy reserves the **bare word** `unsafe`, and an identifier that merely contains it is not
reserved. So the examples are clean.

## Decision

1. **`check_example_safety.py` scans every fenced Swift block under `docs/`** for the forms a
   writer reaches for to keep an example short: `try!`, `as!`, `fatalError`, and the bare word
   `unsafe`.
2. **It is a clean gate, not a ratchet**, because the measurement found nothing to absorb —
   the same reasoning as `ADR-0302`, and the opposite of `ADR-0301` where 219 tests had to be
   carried.
3. **An identifier containing "unsafe" is deliberately not matched**, and the gate's own
   documentation says why and cites `ADR-0287`. Re-making the over-strict mistake inside the
   gate that enforces the rule would have been a poor way to enforce it.
4. **`try!` and `as!` are the substantive rules.** They turn a typed refusal into a crash,
   which is precisely "bypassing canonical validation for convenience" — an example doing it
   teaches a reader to do it.
5. **`VOX-DOC-011`'s `I` is discharged**; its **`R` is not claimed**.

## The gate is proven able to fail

A `try!` example was appended to `VOXELIA-ALG-0001`, reported by file and line, and the file
restored:

```text
Example safety check failed:
- docs/algorithms/VOXELIA-ALG-0001-...md:213: example uses try!, which bypasses the safety
  semantics `VOX-DOC-011` requires it to keep
```

## Alternatives considered

### Scan only the DocC catalogues

Rejected, and it was the obvious first guess. They contain no Swift examples at all, so a gate
scoped there would have passed on an empty set while 224 real examples went unchecked.

### Reuse `check_swift_safety.py` by extracting blocks to temporary files

Rejected twice over. It would duplicate that gate's full rule set onto prose examples that
legitimately elide detail, and `ADR-0302` forbids product code creating temporary files —
adding a script that did so to enforce a documentation rule would be a poor precedent.

### Match every identifier containing "unsafe"

Rejected; see decision 3. It is the mistake `ADR-0287` had to withdraw, and it would fail on a
legitimate protocol signature the specification needs.

## Consequences

`VOX-DOC-011`'s implementation obligation is discharged, and 224 examples that no gate had
ever read are now checked on every documentation run.

**8 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. One gate and one `validate-docs.sh` step. No source file changed.

## Compatibility impact

None.

## Security impact

None directly. An example teaching a reader to force-unwrap a typed refusal is a defect that
reaches production through readers rather than through the compiler.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_example_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1235 tests in 218 suites pass, unchanged — this increment adds no Swift.

## Migration

1. This record, the gate and the `validate-docs.sh` step.
2. **Next**: the derived queue's remaining 8 rows.
3. **Owner**: unchanged — `VOX-DOC-011`'s Review remains outstanding.

## Supersession

This record supersedes nothing. It **extends** safety enforcement to examples, which were
outside every existing gate's reach.

## References

- [ADR-0287 - Strict memory safety readiness](ADR-0287-strict-memory-safety-readiness.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0301 - Enforce the test level taxonomy](ADR-0301-enforce-the-test-level-taxonomy.md)
- [ADR-0302 - Declared temporary file sites](ADR-0302-declared-temporary-file-sites.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
