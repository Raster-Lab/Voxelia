---
document_id: "ADR-0309"
title: "Resolve decision cross references"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-009"
---

# ADR-0309 - Resolve decision cross references

## Context

`VOX-DOC-009` requires that "architecture deviations shall be linked to approved ADRs". P0,
**`I,R`**, milestone M0 — a baseline row, from `ADR-0290`'s sweep.

## The measurement

The **shape** of the linkage was already enforced. Every one of the 288 decision records
carries a `## Supersession` section, and `check_adr_register.py` lists it among its required
sections, so a record cannot be accepted without saying what it supersedes or stating plainly
that it supersedes nothing.

The **targets** were not. Across 850 ADR-to-ADR cross-references, nothing resolved a single
one, and nothing checked that a cited record was approved rather than merely written.

Two links did not resolve, both in `ADR-0183`:

```text
[ADR-0059 - Provenance record aggregate](ADR-0059-provenance-record-aggregate.md)
[ADR-0064 - Image data aggregate](ADR-0064-image-data-aggregate.md)
```

**The link text was right and the numbers were wrong, by one in each case.** `ADR-0058` is
"Provenance record aggregate" and `ADR-0063` is "Image data aggregate"; the numbers cited
belong to "Complete graph admission" and "Exact region extraction operation". So `ADR-0183`
named the two records it meant and pointed at two others.

That is the seventh instance in this arc of a rule that existed with nothing running it, and
it is the one where the omission had already produced real damage rather than only risk.

## Decision

1. **`check_adr_links.py` resolves every cross-reference.** Two rules, both clean from day
   one: a link must resolve to a file that exists, and that file's `status` must be
   `Accepted` — because the requirement says *approved*, not *written*.
2. **The two dead links are repaired, and repairing them is not editing an accepted record's
   decisions.** The standing discipline forbids editing a frozen ADR; it exists so a decision
   cannot be rewritten after acceptance. A hyperlink that points at the wrong file contradicts
   the sentence beside it, and repairing it makes `ADR-0183` say what it always said. Leaving
   them dead would have meant either an unenforceable requirement or a gate landing red.
3. **Status is checked, not just existence.** Every ADR is `Accepted` today, so this rule
   catches nothing now — and it is the rule that matters when the first `Proposed` record
   appears, which is exactly when nobody will remember to look.
4. **`VOX-DOC-009`'s `I` is discharged**; its **`R` is not claimed**.

## The gate is proven able to fail

A link to `ADR-9999-nonexistent.md` was added to `ADR-0183`, reported by file and line, and
the file restored:

```text
Architecture decision link check failed:
- ADR-0183-geometry-arc.md:163: link to ADR-9999-nonexistent.md, which does not exist
```

## Alternatives considered

### Leave the two links and land the gate as a ratchet

Rejected. Two is not a backlog. A ratchet is for a debt too large to clear in the increment
that discovers it, and using one here would preserve a defect for no reason.

### Check only that links resolve, not that targets are approved

Rejected; see decision 3. The requirement's word is *approved*, and a check that ignores it
would satisfy the sentence's grammar and not its meaning.

### Resolve links inside fenced code blocks

Rejected, after the gate's first live run rejected **this record**. `ADR-0309` quotes the two
broken links verbatim as evidence, and a checker that cannot tell a citation from an
illustration would push authors to stop showing what they found. Fenced blocks are blanked
with their offsets preserved, so reported line numbers stay true.

### Extend the check to every markdown link in the repository

Rejected as scope creep. This row is about **architecture deviations** citing **ADRs**;
resolving every link in 418 markdown files is a different, larger job, and bundling it would
make the failure this gate exists to catch harder to see.

### Correct the numbers in `ADR-0183` by editing its decisions

Not done, and worth distinguishing from what was done. No decision, boundary or claim in
`ADR-0183` is altered — only two file paths and their numeric labels, which were internally
contradicted by their own link text.

## Consequences

`VOX-DOC-009`'s implementation obligation is discharged, 850 cross-references are now
resolved on every documentation run, and two references that pointed at the wrong records for
the life of `ADR-0183` are corrected.

**9 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. One gate, one `validate-docs.sh` step, two corrected links. No source file changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_adr_links.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1235 tests in 218 suites pass, unchanged — this increment adds no Swift.

## Migration

1. This record, the gate, the `validate-docs.sh` step and two corrected links.
2. **Next**: the derived queue's remaining 9 rows.
3. **Owner**: unchanged — `VOX-DOC-009`'s Review remains outstanding.

## Supersession

This record supersedes nothing. It **enforces** the target half of a linkage rule whose shape
was already enforced, and repairs the two references that omission had let through.

## References

- [ADR-0183 - Geometry arc](ADR-0183-geometry-arc.md)
- [ADR-0282 - Decision register enforcement](ADR-0282-decision-register-enforcement.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0301 - Enforce the test level taxonomy](ADR-0301-enforce-the-test-level-taxonomy.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
