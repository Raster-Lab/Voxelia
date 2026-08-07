---
document_id: "ADR-0320"
title: "Repository baseline rows"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-REP-001"
  - "VOX-REP-002"
  - "VOX-REP-003"
  - "VOX-LIC-002"
---

# ADR-0320 - Repository baseline rows

## Context

`ADR-0319` rederived the unclaimed queue and found sixteen rows, five of them M0 baseline rows
about the repository itself. This claims four of them; `VOX-DOC-003` (British English) is left
for its own increment because it carries an `R` and a linguistic judgement the others do not.

The expectation going in was that these were trivially satisfied. **Two were satisfied and
unenforced**, which is the ninth instance of that pattern in this arc — and this time the
enforcement was *partial*, which is harder to see than absent.

## The measurement

`check_required_files.py` holds a `REQUIRED` list of forty-odd paths. Comparing it against what
the rows actually name:

| Row | Names | In the gate |
|---|---|---|
| `VOX-REP-002` | `README.md`, `LICENSE`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CODEOWNERS`, `THIRD_PARTY_NOTICES.md` | all but **`CODEOWNERS`** |
| `VOX-REP-003` | `Sources`, `Tests`, `Benchmarks`, `Validation`, `Examples`, `Tools`, `docs` | all but **`Examples`** |

Both omissions were **present on disk and unchecked**. A list that covers seven of eight entries
reads as complete at a glance, which is exactly why a partial omission survives longer than a
missing gate.

`VOX-REP-001` and `VOX-LIC-002` needed no change: this is one repository containing every
category the row names, and `LICENSE` is a twenty-one-line MIT text at the root.

## The discrepancy worth recording rather than resolving

`VOX-REP-002` says the **root** repository shall contain `CODEOWNERS`. The file is at
**`.github/CODEOWNERS`**, which is one of the three locations GitHub resolves and the
conventional one.

The gate now requires the file **where it actually is**. Moving it to the root to match the
row's wording, or amending the row to match the file, is a one-line change either way and it is
**not mine to pick**: the row is frozen text and the file is in the location its tooling
expects. Recorded as an owner item rather than decided silently in a gate.

## Decision

1. **`CODEOWNERS` and `Examples` are added to the required list**, so both rows are enforced in
   full rather than in part.
2. **`CODEOWNERS` is required at `.github/CODEOWNERS`**, the path that exists and functions,
   with the wording discrepancy recorded above.
3. **`VOX-REP-001`, `VOX-REP-002`, `VOX-REP-003` and `VOX-LIC-002` are claimed and their `I`
   discharged.**
4. **`VOX-DOC-003` is not claimed here.** It declares `I,R` and asks a question about language
   that the other four do not; bundling it would be four verifications and one assertion.

## The gate is proven able to fail

Each new entry was removed and restored:

```text
Examples moved away            -> Required-file check failed: - Examples            (exit 1)
.github/CODEOWNERS moved away  -> Required-file check failed: - .github/CODEOWNERS  (exit 1)
```

Before this change both moves passed.

## Alternatives considered

### Move `CODEOWNERS` to the root to match the row

Rejected as a unilateral change to a working configuration. It is a reasonable outcome and it
is an owner's call.

### Claim the rows without touching the gate

Rejected. Two of the four would have been claimed on a check that did not check them, which is
the defect this arc keeps finding.

### Also claim `VOX-DOC-003`

Rejected; see decision 4.

## Consequences

Four M0 rows are claimed, and a partially complete required-file list is completed.

**12 rows remain unclaimed** under `ADR-0319`'s criterion, which is recomputed rather than
decremented.

## Affected modules

None. One gate list. No source file changed.

## Compatibility impact

None.

## Security impact

None. `CODEOWNERS` is now required to exist rather than merely happening to.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_required_files.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged — this increment adds no Swift.

## Migration

1. This record and two required-list entries.
2. **Next**: `VOX-DOC-003`, then the M1 and M2 rows.
3. **Owner**: **one new item** — whether `CODEOWNERS` moves to the root to match
   `VOX-REP-002`'s wording, or the row is amended to `.github/CODEOWNERS`.

## Supersession

This record supersedes nothing. It **completes** a required-file list that enforced seven of
eight entries in one row and six of seven in another.

## References

- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0301 - Enforce the test level taxonomy](ADR-0301-enforce-the-test-level-taxonomy.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
