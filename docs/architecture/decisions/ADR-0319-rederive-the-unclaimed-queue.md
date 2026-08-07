---
document_id: "ADR-0319"
title: "Rederive the unclaimed queue"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
---

# ADR-0319 - Rederive the unclaimed queue

## Context

`ADR-0290` swept for requirement rows in entered milestones that no record had claimed, and
listed what it found. Every row on that list has now been recorded, so the queue was rederived
rather than declared finished.

## The correction

**The count I have been reporting was wrong.** Successive records in this arc counted down from
that list — "20 rows remain", then 18, 17, and so on to 5 — and the number was a decrement of a
copied snapshot rather than a measurement.

Rederiving mechanically gives a different answer:

```text
entered-milestone rows (M0…M6):        356
claimed in some ADR's front matter:    340
UNCLAIMED:                              16
```

Sixteen, not five. The list `ADR-0290` produced was a correct snapshot of its moment and became
a stale copy the instant it was written down; every increment that decremented it inherited
that staleness. **This is the same defect this arc has found eight times in code — a value
asserted once and never recomputed — occurring in my own reporting.**

## The criterion, stated so it can be recomputed

A row is **claimed** when some `ADR-*.md` names it in its `affected_requirements` front matter.
That is deliberately narrower than the traceability gate, which passes when a row is *mentioned*
anywhere — a ledger line or a test name counts there. Front-matter claiming is what makes a row
findable from the decision register, and it is the property this queue is about.

**Claimed is still not discharged**, exactly as `check_requirement_traceability.py`'s own header
says of tracing. A row can be claimed by a record that declines to discharge it — `VOX-PER-006`
and `VOX-CON-008` are both claimed and both recorded as unbuilt.

## The sixteen

| Row | Pri | Methods | M | Subject |
|---|---|---|---|---|
| `VOX-REP-001` | P0 | I | M0 | single public monorepo |
| `VOX-REP-002` | P0 | I | M0 | root files present |
| `VOX-REP-003` | P0 | I | M0 | dedicated source directories |
| `VOX-LIC-002` | P0 | I | M0 | complete MIT licence text |
| `VOX-DOC-003` | P0 | I,R | M0 | British English |
| `VOX-DAT-002` | P0 | I,T | M1 | variable-rank extents |
| `VOX-DAT-003` | P0 | T | M1 | reject zero and negative extents |
| `VOX-SPA-010` | P0 | T | M1 | bounds in index and physical coordinates |
| `VOX-IMG-003` | P0 | T | M2 | nearest-neighbour interpolation |
| `VOX-IMG-004` | P0 | T | M2 | linear interpolation |
| `VOX-IMG-008` | P0 | T | M2 | resampling between explicit grids |
| `VOX-CON-005` | P0 | T | M3 | no overlapping unstructured draw callbacks |
| `VOX-ADP-003` | P0 | I,T | M6 | optional Model I/O integration |
| `VOX-BRK-009` | P0 | T,D | M6 | lower-resolution interactive rendering |
| `VOX-DVR-013` | P0 | T,D | M6 | refinement towards diagnostic quality |
| `VOX-PER-004` | P1 | T,D | M6 | 512³ at 30–60 frames per second |

**Most of these are almost certainly implemented.** The repository has its directories, its
licence text and its interpolation operations; several are M0 and M1 rows the project could not
have got this far without. The gap is that no record names them, which is the same shape as
`VOX-R2D-001`, `VOX-VAL-006` and `VOX-ARC-009` — three rows this arc found delivered and
unclaimed.

## Decision

1. **The queue is 16 rows, derived by the criterion above**, and the earlier countdown is
   superseded by this measurement rather than quietly adjusted.
2. **The derivation is written into this record so it can be rerun**, not saved as another
   list to decrement. A future increment recomputes; it does not read the table above as
   authoritative.
3. **No gate is added.** A check requiring every entered row to be front-matter-claimed would be
   red on sixteen rows today, and `ADR-0301` already established what that produces: a gate
   nobody can land. If one is wanted later, the ratchet pattern is available.
4. **Order of work: M0 and M1 first.** Five of the sixteen are M0 baseline rows about the
   repository itself, and they are the cheapest to check and the most embarrassing to leave
   unclaimed.

## Alternatives considered

### Keep decrementing `ADR-0290`'s list

Rejected — it is what produced the wrong number. A list is a cache, and this one was never
invalidated.

### Claim all sixteen in one sweeping record

Rejected. Each needs its evidence read for *that* row; a record claiming sixteen would be
sixteen unexamined assertions, which is what `ADR-0300` had to untangle in the other direction.

### Treat traceability-gate passing as sufficient

Rejected; see the criterion. That gate measures mention, deliberately, and its own header says
traced is not discharged.

## Consequences

The queue is a measurement again. **16 rows are unclaimed**, five of them M0.

## Affected modules

None.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: the five M0 rows, each claimed on evidence read for it.
3. **Owner**: unchanged.

## Supersession

This record supersedes **`ADR-0290`'s remaining-row count** and the running total quoted in the
records after it. It does not supersede that record's findings, which stand.

## References

- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0300 - CPU Metal differential references](ADR-0300-cpu-metal-differential-references.md)
- [ADR-0301 - Enforce the test level taxonomy](ADR-0301-enforce-the-test-level-taxonomy.md)
- [ADR-0312 - Canonical two dimensional pipeline](ADR-0312-canonical-two-dimensional-pipeline.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
