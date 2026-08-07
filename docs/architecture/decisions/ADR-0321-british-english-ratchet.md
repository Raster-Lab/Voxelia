---
document_id: "ADR-0321"
title: "British English ratchet"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-003"
---

# ADR-0321 - British English ratchet

## Context

`VOX-DOC-003` requires that "project documentation shall use British English except where
external standards or programming identifiers require otherwise". P0, **`I,R`**, milestone M0 —
a baseline row, from `ADR-0319`'s rederived queue.

## The measurement

**Nothing enforced it.** `check_document_text.py` is thirty lines and checks other properties
entirely; no gate has ever looked at spelling.

Scanning documentation prose — with fenced blocks and inline code removed — found **121
American spellings across 34 files**.

Sampling them settles whether the row's exemption covers them. It does not:

```text
VOXELIA-ALG-0028…:249  resource-limit behavior.
VOXELIA-ALG-0030…:238  copy-on-write behavior, concurrency, cancellation machinery …
CCR-0003…:53           duplicate-input behavior, continuity, endpoint inclusion, …
```

These are ordinary prose, not external standards and not identifiers. **Tenth instance in this
arc of a rule asserted with nothing running it.**

## Decision

1. **The exemption is honoured structurally, not by a list of blessed words.** Fenced blocks
   and inline code are blanked before scanning, so an identifier, a DICOM keyword or a quoted
   API name is invisible to the check **as long as it is written as code** — which this
   project's style already does throughout. A word list of allowed Americanisms would need
   arguing about at every addition; a structural rule does not.
2. **Code is blanked rather than deleted, preserving newlines**, so reported line numbers stay
   true. That is the same fix `ADR-0309` needed when its link checker read an illustration as a
   citation, and it is applied here from the start rather than after a false positive.
3. **This is a ratchet, not a clean gate.** 121 spellings across 34 files is a backlog, and
   `ADR-0301` established what a gate that lands red produces: one nobody can keep. Counts are
   recorded per file in `docs/progress/american-spellings.txt`; a file's count may shrink but
   never grow, and a file absent from the baseline may introduce none.
4. **A record quoting a misspelling as evidence must put it in backticks** — as this record
   does above. The gate cannot distinguish a citation from a lapse, and the convention that
   resolves it is the one the project already uses for every other technical term.
5. **`VOX-DOC-003`'s `I` is discharged**; its **`R` is not claimed.**

## The gate is proven able to fail

A line reading `the color of the behavior is optimized` was appended to `VOXELIA-ALG-0001`, and
the check reported the file, the count and each spelling with its line, then the file was
restored:

```text
ERROR: docs/algorithms/VOXELIA-ALG-0001-….md introduces 3 American spelling(s)
  …:212: American spelling 'behavior'
  …:212: American spelling 'optimized'
```

## The gate caught this record

Its first live run rejected **`ADR-0321` itself**, and the ledger entry beside it. The failure
probe above was quoted in plain prose rather than in backticks — the very convention decision 4
states — so the checker counted three spellings in a file with no baseline.

That is the rule working, not a false positive, and it is worth recording that the record
introducing a convention broke it in the same commit. `ADR-0309` hit the mirror image: there the
checker was wrong about an illustration; here the author was.

## Alternatives considered

### Correct all 121 now and land a clean gate

Rejected. Rewording prose across 34 documents — several of them frozen algorithm
specifications and accepted decision records — is a large change bundled with the gate that
would check it, and this project forbids editing accepted records for anything but a genuine
correction. A spelling ratchet lets each document be fixed when it is next touched for its own
reasons.

### Maintain a list of permitted American spellings

Rejected; see decision 1. It would grow by argument, and every addition would be a small
negotiation rather than a rule.

### Scan source comments as well

Rejected as scope creep for this row, which says *documentation*. Source comments are worth a
later look and are not what `VOX-DOC-003` asks about.

## Consequences

`VOX-DOC-003`'s implementation obligation is discharged, and a 121-spelling backlog is visible
and bounded rather than invisible.

**11 rows remain unclaimed** under `ADR-0319`'s criterion, recomputed rather than decremented.

## Affected modules

None. One gate, one baseline, one `validate-docs.sh` step. No source file changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_british_english.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged — this increment adds no Swift.

## Migration

1. This record, the gate, the baseline and the `validate-docs.sh` step.
2. **Next**: the M1 rows from `ADR-0319`'s queue. The spelling backlog shrinks opportunistically.
3. **Owner**: unchanged — `VOX-DOC-003`'s Review remains outstanding.

## Supersession

This record supersedes nothing. It **enforces** a documentation rule that had never been
checked.

## References

- [ADR-0301 - Enforce the test level taxonomy](ADR-0301-enforce-the-test-level-taxonomy.md)
- [ADR-0309 - Resolve decision cross references](ADR-0309-resolve-decision-cross-references.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0320 - Repository baseline rows](ADR-0320-repository-baseline-rows.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
