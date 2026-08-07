---
document_id: "ADR-0336"
title: "The spelling floor is exempt"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-003"
---

# ADR-0336 - The spelling floor is exempt

## Context

`ADR-0335` cut the spelling backlog from 121 to 15 and left the remainder as "frozen-identifier
cases", proposing a rename of `ADR-0040` as a possible future increment. **That proposal is
withdrawn, and the reason is the requirement's own wording.**

## The measurement, read one hit at a time

All 15 were printed with their surrounding text. Three were ordinary prose and are now
corrected:

- `ADR-0040:142` and `:426` — "exact `initialized` bytes" inside a table cell;
- `SWIFT_SAFETY_POLICY.md:141` — "`serialization`" in a list of concerns.

**My previous pass had skipped lines beginning with `|`**, to protect register rows. A table
*cell* can contain ordinary prose, so that rule was too broad — one refinement further along the
same path as `ADR-0335`'s link-target lesson: each exclusion protected something real and caught
something it should not have.

The remaining **12 are all one thing**: `ADR-0040`'s filename, the `title:` and heading that
mirror it, the register row that quotes both, and eight citations of the path from other records.

## The decision this turns on

`VOX-DOC-003` requires British English **"except where external standards or programming
identifiers require otherwise"**.

**A record's filename is an identifier.** It is what the register indexes, what
`check_adr_links.py` resolves, and what eight accepted records cite. The `title:` and heading
exist to mirror it. Spelling in an identifier is not prose spelling, and the row's own clause
says so.

So the 12 are **compliant, not deferred**. The floor is a compliance floor.

## Decision

1. **`VOX-DOC-003` is fully satisfied at 12 remaining spellings**, all within the exemption its
   own text grants.
2. **`ADR-0040` is not renamed, and the proposal is withdrawn.** It would change an accepted
   record's identity, rewrite eight citations and a register row, to satisfy a rule that
   exempts identifiers. `ADR-0335` floated it as an option; reading the clause closes it.
3. **The baseline stays at 12 rather than being deleted.** An empty file would say the property
   is clean; a file listing twelve exempt cases says the property is *understood*, which is more
   useful and is what a later reader needs.
4. **The over-broad table-row exclusion is recorded**, because it is the third protection in this
   sequence that was correct in intent and wrong in reach — after fenced blocks
   (`ADR-0309`) and link targets (`ADR-0335`).

## Alternatives considered

### Rename `ADR-0040`

Rejected; see decision 2. It is work in service of a rule that does not ask for it.

### Delete the baseline file

Rejected; see decision 3. The count is not zero and pretending otherwise would misreport the
state.

### Add the twelve to a permitted-word list instead

Rejected. `ADR-0321` decision 1 refused a blessed-word list on the grounds that it grows by
argument, and this would be the first entry establishing exactly that habit.

## Consequences

**`VOX-DOC-003` is satisfied**, the spelling ratchet sits at a floor that is understood rather
than owed, and a rename that would have touched an accepted record's identity is not done.

All three of this arc's ratchets are now resolved: test levels at zero, the temporary-file list
empty by achievement, and spelling at its exempt floor.

## Affected modules

None. Three prose corrections. No source file changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_british_english.py
python3 Tools/Scripts/check_adr_links.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

945 cross-references resolve across 315 records. 1238 tests in 219 suites pass, unchanged.

## Migration

1. This record and three corrections.
2. **Next**: nothing on this row. It is satisfied.
3. **Owner**: unchanged.

## Supersession

This record **withdraws `ADR-0335`'s proposed rename of `ADR-0040`** and records
`VOX-DOC-003` as satisfied. It supersedes no decision.

## References

- [ADR-0309 - Resolve decision cross references](ADR-0309-resolve-decision-cross-references.md)
- [ADR-0321 - British English ratchet](ADR-0321-british-english-ratchet.md)
- [ADR-0335 - Correct the documentation spelling](ADR-0335-correct-the-documentation-spelling.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
