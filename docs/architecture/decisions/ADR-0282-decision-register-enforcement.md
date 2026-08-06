---
document_id: "ADR-0282"
title: "Decision register enforcement"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-008"
---

# ADR-0282 - Decision register enforcement

## Context

Starting the affine design increment required the next unallocated `VOXELIA-ALG`
identifier, so `docs/architecture/decisions/README.md` was consulted for the equivalent
`ADR` line. It read:

> The next unallocated numeric identifier is `ADR-0227`.

The highest record on disk was `ADR-0281`.

## The defect, in two parts

**Ten accepted records had no register row.** `ADR-0272` through `ADR-0281` — every
record this session produced — exist as files, are referenced by other records, and appear
in the ledger, but the register's table stopped at `ADR-0271`. That omission is mine: the
per-increment recipe names updating the register and I did not, ten times.

**The allocation counter was forty-five identifiers stale, and that predates this
session.** The table was being maintained through `ADR-0271` while the counter said
`ADR-0227`, so the two halves of the register had already diverged: the prose allocation
convention lapsed around `ADR-0226` and only the table kept going.

## Why nothing caught it

`validate-docs.sh` runs `check_adr_register.py` on every increment, and it passed
throughout. The name is misleading. That script validates the **record files** — front
matter, required sections, duplicate identifiers — and never opens `README.md`. Its own
docstring says so: *"Validate all file-backed ADRs without interpreting body
references."*

So the register was a document the project treated as authoritative and no gate had ever
read.

This is the `ADR-0196` pattern exactly. That record found `check_prohibited_imports.py`
forbidding `ModelIO` in six modules but not in `VoxeliaGeometry` — the one module two
accepted records claimed was independent of it — and generalised: **when a record claims
something, check whether tooling actually enforces it.** Here the claim is structural
rather than architectural, and it failed the same way.

## Decision

1. **The ten missing rows are restored and the counter corrected** to `ADR-0283`, which
   accounts for this record. Rows were generated from each file's own front matter rather
   than typed, so the titles and statuses cannot drift from the records they index.
2. **`check_adr_register.py` gains `check_readme_index`**, which validates that every
   `ADR-NNNN` file has a register row **linking that exact filename**, and that the
   next-unallocated identifier equals the highest record plus one.
3. **A bare mention does not satisfy a row.** The check requires the markdown link
   `[ADR-NNNN](ADR-NNNN-....md)`, because prose cross-references to a record are common and
   would otherwise mask a missing index entry — which is precisely how ten records looked
   registered to a casual `grep`.
4. **Both branches are negative-tested**, and the messages are recorded because one of them
   is the repository's own recent history:
   - removing one row → `ADR-0275 has no register row linking ADR-0275-open-the-interactive-draw-loop-arc.md`
   - restoring the old counter → `the next unallocated identifier is ADR-0227 but the highest record on disk is ADR-0281, so it should be ADR-0282`

   The second message is verbatim what this repository would have emitted at any point in
   the last forty-five records, had anything been looking.
5. **The lapsed prose allocation convention is not revived.** Each record's own front
   matter and its table row carry its identity, and a third hand-maintained list of the
   same facts is what drifted. The counter stays because the check can verify it; the
   per-identifier prose does not come back.
6. **No algorithm specification and no oracle.** This is a register and a gate.

## What this cost, and the honest accounting

Ten increments passed every gate — build, tests, format, safety, imports, package graph,
licence, traceability, documentation, release integrity — while leaving the project's
index of decisions incomplete. None of those gates was wrong; the missing one simply did
not exist.

The lesson worth keeping is narrower than "be more careful". **A recipe step that no gate
enforces will be skipped**, and the fix is the gate rather than the resolution. The
per-increment recipe has other steps in the same position, and they deserve the same
treatment when one of them is next found lapsed.

## Alternatives considered

### Restore the rows and rely on the recipe

Rejected. The recipe already said to do it and ten increments did not. Repeating the
instruction changes nothing about the mechanism that let it lapse.

### Generate the register table from the files at build time

Rejected for now, and it is the tempting answer. It would make drift impossible, but the
register also carries allocation prose, a reconciliation note about `ADR-0024` and the
`ADR-0001` re-identification, and other content a generator would have to preserve or
destroy. A check that the index is complete gets the safety without taking ownership of a
document that holds more than the table.

### Also enforce the prose allocation sentences

Rejected; see decision 5. They lapsed at `ADR-0226` and duplicate what the table and the
records already state. Enforcing a third copy of the same facts would make the register
harder to maintain, not easier to trust.

### Treat the stale counter as harmless

Rejected. It is the line a reader consults to allocate the next identifier, and it was
wrong by forty-five. Two records claiming the same identifier is the failure it invites,
and `check_adr_register.py` already treats duplicate `document_id` values as an error —
so the project already considers that outcome serious.

## Consequences

The register lists every record, its counter is correct, and a gate keeps both true.

`validate-docs.sh` now fails on an unregistered record, so the next increment that forgets
the step is told immediately rather than forty-five records later.

A second instance of the `ADR-0196` pattern is on the record: an authoritative document
that no gate read.

## Affected modules

None. `Tools/Scripts/check_adr_register.py` gains a function; no Swift source changed.

## Compatibility impact

None to the package. `validate-docs.sh` becomes stricter, which is the intent.

## Security impact

None.

## Performance and memory impact

One extra read of `README.md` and one substring test per record.

## Validation impact

```text
python3 Tools/Scripts/check_adr_register.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1134 tests in 205 suites pass, unchanged — no Swift source changed. Both new failure
branches were exercised by temporarily breaking the register and restoring it.

## Migration

1. This record, the restored rows, the corrected counter and the new check.
2. **Next**: the affine design increment this increment interrupted — an ADR and a
   `VOXELIA-ALG` specification with an independent Python oracle for composition, vector
   transformation and normal transformation, under `ADR-0280` decision 3's constraint that
   no existing consumer's bits change. The next `VOXELIA-ALG` identifier is `0052`.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **repairs and then enforces** the decision register,
and records a second instance of `ADR-0196`'s pattern.

## References

- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0280 - Open the affine transform arc](ADR-0280-open-the-affine-transform-arc.md)
- [ADR-0281 - Singular transform typed errors](ADR-0281-singular-transform-typed-errors.md)
