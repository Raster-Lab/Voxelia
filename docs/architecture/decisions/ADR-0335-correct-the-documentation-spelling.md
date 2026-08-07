---
document_id: "ADR-0335"
title: "Correct the documentation spelling"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-003"
---

# ADR-0335 - Correct the documentation spelling

## Context

`ADR-0321` enforced British English as a ratchet over a 121-spelling backlog, deliberately not
correcting it in the increment that created the gate. This corrects it: **121 down to 15.**

## What could not be corrected, and why

The backlog is **not uniformly correctable**, which the ratchet's flat count concealed.

**`ADR-0040`'s filename contains `normalized`.** Its `title:` front matter, its `# ADR-0040 -`
heading and its register row all mirror that filename. Correcting the prose there is fine;
correcting the identity would rename an accepted record, break every link into it, and change
what the register says a record is called. So those, and the register rows that quote them, are
left: **the spelling is part of a frozen identifier, not prose.**

The 15 remaining are that case plus a handful in `README.md` register rows and the safety
policy's own quoted rule names.

## The defect this pass introduced, and the gate that caught it

**My correction rewrote link targets as though they were prose.** Three records cited
`ADR-0040-normalized-…md`; the pass turned each into `…normalised…`, pointing at a file that
does not exist.

`check_adr_links.py` — `ADR-0309`'s gate, built two increments earlier for an unrelated reason —
**reported all three by file and line**, and they were restored.

The bug is precise and worth naming: the pass protected fenced blocks, inline code and frozen
heading lines, and **did not protect markdown link targets**. A link target is an identifier
that happens not to be in backticks. `ADR-0321` had already learned that a *quoted* misspelling
needs backticks; this is the same lesson one level down, for a misspelling that is a **path**.

Without that gate this would have shipped as three dead links in accepted records, discovered
by whoever next followed one.

## Decision

1. **113 prose spellings are corrected** across 33 files, in two passes: a case-sensitive one,
   then a case-insensitive one that capitalises the replacement, so sentence-initial forms were
   not mangled by a blanket substitution.
2. **Correcting spelling in an accepted record is not editing its decisions**, the same
   distinction `ADR-0309` drew for a broken hyperlink. No decision, boundary, claim or numeric
   value changed anywhere in this pass.
3. **The 15 that remain are recorded as frozen-identifier cases**, not as residual debt to be
   cleared later. Clearing them means renaming `ADR-0040`, which is a deliberate act with its
   own record.
4. **The baseline is regenerated to 15**, so the ratchet still cannot grow.

## Alternatives considered

### Rename `ADR-0040` so its filename is British

Rejected here, and it is a legitimate future increment. It touches an accepted record's
identity, the register, and every citation of it, and doing that inside a spelling sweep is how
an identity change gets waved through.

### Correct link targets too, since the filename should change anyway

Rejected — that is the defect this pass made and the gate caught. A link must match the file
that exists today, not the file a future increment might create.

### Leave the backlog for opportunistic shrinking

Rejected, as in `ADR-0331`. These are stable specifications; "whenever touched" may be never.

## Consequences

The spelling backlog falls from **121 to 15**, and the 15 are one named, understood case rather
than an undifferentiated remainder.

**All three ratchets this arc created are now at or near zero** — `ADR-0301`'s test levels at
zero, `ADR-0302`'s temporary-file list empty by achievement, and this one at its frozen floor.

## Affected modules

None. Documentation prose in 33 files. No source file changed.

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

941 cross-references resolve. 1238 tests in 219 suites pass, unchanged — this increment adds no
Swift.

## Migration

1. This record and the corrections.
2. **Next**: renaming `ADR-0040`, if wanted, as its own increment.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **discharges** the backlog `ADR-0321` recorded.

## References

- [ADR-0309 - Resolve decision cross references](ADR-0309-resolve-decision-cross-references.md)
- [ADR-0321 - British English ratchet](ADR-0321-british-english-ratchet.md)
- [ADR-0331 - Shrink the untagged test backlog](ADR-0331-shrink-the-untagged-test-backlog.md)
- [ADR-0334 - The repository is format clean](ADR-0334-the-repository-is-format-clean.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
