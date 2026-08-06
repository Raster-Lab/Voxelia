---
document_id: "ADR-0216"
title: "Requirement traceability sweep"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-008"
---

# ADR-0216 - Requirement traceability sweep

## Context

Three times now, re-reading the requirements baseline's own table has surfaced a
row that a decomposition list silently skipped. The most recent, `VOX-MPR-011`,
reached no accepted record and not one ledger entry until `ADR-0208` went
looking; `ADR-0215` then assessed it. Each catch depended on someone choosing to
re-read the table.

`VOX-DOC-008` requires that "requirements shall be traceable to architecture,
implementation, tests, validation". Nothing enforced that. This is precisely the
shape of finding `ADR-0196` recorded for Model I/O: a claim asserted in two
accepted places and enforced in none.

`ADR-0215` closed M6's actionable queue, so this is the right moment to sweep
rather than to open the next arc.

## The sweep

Every row of the baseline table was matched against a corpus of the autonomy
ledger, every decision record, every algorithm specification, and all source,
test, tooling and benchmark files. The baseline itself and its generated
traceability mirror were excluded, because they list every identifier by
construction and counting them would make the exercise vacuous.

Of **486** baseline rows, **356** belong to milestones the project has entered
(M0 through M6). Of those, **83 are named nowhere at all**.

## Findings

1. **The gap is overwhelmingly traceability, not capability.** Spot-checking
   the list against the repository shows most rows are already satisfied by
   artefacts or operations that simply never cited their requirement
   identifier. `VOX-LIC-002` (root licence text), `VOX-REP-002` and
   `VOX-REP-003` (required files and directories) are satisfied *and
   mechanically enforced* by `check_required_files.py`, which passes.
   `VOX-DOC-002` and `VOX-DOC-003` (Markdown, DocC, British English) are
   enforced by `check_document_text.py`. `VOX-IMG-003`, `VOX-IMG-004` and
   `VOX-IMG-008` (nearest, linear and resampling) are satisfied by accepted
   operations with registered algorithms `ALG-0008`, `ALG-0015` and `ALG-0021`.
   Those rows are not unbuilt; they are unlabelled.
2. **Eighteen of the 83 are owner-gated, not merely untraced.** The whole
   `VOX-CMP` block (thirteen rows) waits on the Raster-Lab codec libraries and
   the `VOX-DCM` rows (five) wait on the DICOMKit dependency. Both are standing
   owner questions. They will remain untraced until the owner answers, and that
   is correct.
3. **Some rows are genuinely unassessed and are not obviously satisfied.** The
   `VOX-VS1` rows in the list (`002`, `003`, `004`, `007`, `010`, `011`, `012`,
   `013`, `015`) describe first-vertical-slice behaviour that the project has
   partly built, but no record cites them and no test names them. Whether each
   is discharged needs a per-row inspection this record does not perform and
   does not pretend to.
4. **This record discharges nothing.** Establishing that a row is *probably*
   satisfied is not evidence that it is. Claiming 83 discharges from a
   spot-check would be exactly the overstatement these records exist to prevent.

## Decision

1. **The sweep's result is recorded as an explicit debt baseline**, in
   `docs/progress/untraced-requirements.txt`, listing all 83 identifiers.
2. **A new check enforces the ratchet.**
   `Tools/Scripts/check_requirement_traceability.py` fails when a row in an
   entered milestone becomes untraced and is not on that list, and also fails
   when an allowlisted row becomes traced without being removed from the list.
   The debt can shrink but never grow, and shrinking it is a visible diff.
3. **A ratchet, not a clean gate, and the reason is recorded.** A gate demanding
   zero untraced rows would have been red the day it landed and would have been
   switched off or ignored. Freezing the known debt and refusing new debt is the
   change that actually holds.
4. **The check knows which milestones are due.** A row in a milestone the
   project has not entered is not a gap, so the check bounds itself to M0
   through M6 and the constant is raised as milestones open.
5. **The allowlist is excluded from the searched corpus.** The first run of the
   check caught this itself: writing the list into a searched directory made
   every allowlisted row appear traced, and the check reported all 83 as newly
   resolved. That is recorded here rather than quietly fixed, because a
   self-referential corpus is the obvious way for this check to become vacuous
   later.
6. **Discharging the debt is future work, per row, with real evidence.** Each
   row leaves the list when a record, a source comment or a test genuinely cites
   it — never by being added to a document for the sake of the count.
7. **The owner-gated rows stay on the list** and are not to be traced by
   fabricating an assessment of work that cannot start.

## Alternatives considered

### Trace all 83 rows now by citing them in a single index document

Rejected. It would satisfy the check without satisfying `VOX-DOC-008`: a
requirement listed in a file that mentions every requirement is exactly as
untraceable as before, which is why the baseline and its mirror are excluded
from the corpus in the first place.

### Make the check a clean gate demanding zero untraced rows

Rejected; see decision 3.

### Assess all 83 rows in this record

Rejected; see finding 4. A record that discharged 83 requirements from a
spot-check would be the largest unevidenced claim in the project.

### Leave the sweep as a one-off ledger note

Rejected. That is the status quo that failed three times. The lesson from
`ADR-0196` is that a claim nothing enforces is a claim waiting to drift.

## Consequences

The class of defect that hid `VOX-MPR-011` now fails a check rather than
depending on someone choosing to re-read the table. The project gains a measured
figure for its traceability debt — 83 rows — and a mechanism that makes paying
it down visible.

M6's actionable *capability* queue remains empty; this record adds a documented
traceability queue that is separate from it.

## Affected modules

Tooling and documentation only. No product source changes.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

The check reads the repository's text files once; it runs in well under a
second.

## Validation impact

The new check passes with all 83 rows recorded as known debt, and its ratchet
was verified by removing one identifier from the allowlist and confirming the
check fails naming exactly that row.

## Migration

1. Add the check and the debt baseline.
2. Reduce the list per row, with evidence, as future increments touch each area.
   The `VOX-VS1` rows are the most likely first candidates, being behaviour the
   project has largely built but never labelled.

## Supersession

This record supersedes nothing. It makes mechanical a rule the project has been
applying by hand.

## References

- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0208 - Colour and overlay arc](ADR-0208-colour-and-overlay-arc.md)
- [ADR-0215 - Multi-volume fusion assessment](ADR-0215-multi-volume-fusion-assessment.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
