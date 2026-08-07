---
document_id: "ADR-0301"
title: "Enforce the test level taxonomy"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-001"
---

# ADR-0301 - Enforce the test level taxonomy

## Context

`VOX-VAL-001` requires that "Voxelia shall maintain automated unit, kernel, operation,
pipeline, integration and system-reference test levels". P0, **`I,T`**, milestone M0 — a
baseline row, and one of the rows `ADR-0290`'s sweep found untouched.

## The measurement

Before deciding anything, the 1,229 tests were scanned for their level tag:

| Tag | Tests |
|---|---|
| `Unit` | 959 |
| `Oracle` | 22 |
| `Integration` | 16 |
| `Concurrency` | 12 |
| `Boundary` | **1** |
| *(no tag)* | **219**, across 27 files |

Set against the six levels the requirement names:

- **unit** and **integration** existed.
- **kernel**, **operation**, **pipeline** and **system-reference** had **no tag at all**.
  Tests for each did exist — the Metal kernel suites, the execution operation suites, the
  renderer suites — but every one of them was labelled `Unit`, so nothing could tell whether
  a level had coverage.
- Three tags the requirement never names were in use, and one of them, `Boundary`, appeared
  **exactly once** in 1,229 tests.

That singleton is the finding in miniature. **This is the fifth time in this arc that a rule
was asserted and nothing enforced it** — after `ADR-0196`, `ADR-0282`, `ADR-0287` and
`ADR-0289`. An unenforced vocabulary does not stay a vocabulary.

## Decision

1. **The six names are frozen to tag spellings**: `Unit`, `Kernel`, `Operation`, `Pipeline`,
   `Integration`, `SystemReference`.
2. **`Concurrency` and `Oracle` are admitted, not rewritten.** Each marks a real and distinct
   kind of test that the requirement's six do not describe, and a gate that rejected them
   would delete information rather than enforce a taxonomy. `Boundary` was **not** admitted:
   one occurrence is a slip, not a level, and it was retagged `Kernel` where it belongs.
3. **`check_test_levels.py` enforces three rules.** Two are clean from day one — every tag
   must be in the vocabulary, and every one of the six required levels must have at least one
   test. The third, the untagged backlog, is a **ratchet**: `docs/progress/untagged-tests.txt`
   records the 219 as an explicit debt baseline, a file's count may shrink but never grow, and
   a file absent from the baseline may not introduce any.
4. **The ratchet follows `check_requirement_traceability.py`'s precedent deliberately.** That
   gate's own header explains why: a clean gate would have been red the day it landed and
   would have been switched off. Retagging 219 tests inside this increment would also have
   meant 219 classification judgements bundled with the gate that is supposed to check them.
5. **Four levels were established by retagging whole suites whose subject is unambiguous**,
   not by reclassifying tests one at a time:
   - `Kernel` — the three Metal kernel suites and the CPU reference-kernel suites.
   - `Operation` — the execution, CPU and Metal `*Operation` suites.
   - `Pipeline` — the slice, volume and multiplanar renderer suites.
   - `SystemReference` — the phantom-driven suites from `ADR-0297` and `ADR-0298`.
6. **`VOX-VAL-001` is discharged**: the `I` by the gate, the `T` by the gate's own failure
   proofs and by the suite continuing to pass.

## What "system-reference" was taken to mean, and why it was nearly empty

A system-reference test drives shipped product code end to end against a reference input
whose expected result is known **independently** of the code under test.

By that definition the level had **no members at all** until this week. `Tests/VoxeliaTests`
contains a single module-linkage assertion, not a system test. The suites that qualify are the
ones the phantom arc produced in the last two increments: a known phantom through
`WindowLevelOperation`, `CTSampleInspector` and `ObliqueSliceOperation`, and a known DICOM
dataset through the real ingest path into a phantom.

**Ten tests is thin, and this record says so rather than presenting the level as healthy.**
The gate now makes the thinness visible instead of hiding it inside 959 `Unit` tags.

## The gate is proven able to fail

Every rule was run against a deliberate violation before the gate was wired in:

```text
[Bogus] tag added        -> unknown test level [Bogus]                        (exit 1)
untagged test added      -> above its baseline of 1                           (exit 1)
required level removed   -> no test declares the required level [NoSuchLevel] (exit 1)
```

A gate that has never failed is a gate nobody has tested, which is exactly how the four
earlier omissions survived.

## Alternatives considered

### Retag all 1,229 tests now

Rejected; see decision 4. It bundles hundreds of classification judgements with the gate meant
to check them, and it is the change most likely to be waved through unread.

### Reject `Concurrency` and `Oracle`

Rejected. They are real distinctions the requirement's list does not cover, and forcing them
into `Unit` would lose information to satisfy a word count.

### Treat the row as already satisfied because tests exist at every level

Rejected. "Maintain ... test levels" is a claim about being able to tell, and before this
increment nobody could: four of the six levels were indistinguishable from unit tests.

### Add the gate without establishing the missing levels

Rejected. The required-level rule would have failed immediately on four levels, and a gate
that cannot pass on the day it lands gets disabled.

## Consequences

`VOX-VAL-001` is discharged, and the fifth instance of "something exists and nothing runs it"
is closed with a gate rather than a note.

The untagged backlog is now **visible and bounded**: 219 tests across 27 files, mostly the
DICOM ingest suites, which may shrink but cannot grow.

**14 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. One new gate, one baseline file, one `validate-docs.sh` step, and level tags on 125
existing tests. No source file changed and no test's behaviour changed — only its display
name.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None. The gate scans the test tree once.

## Validation impact

```text
swift build && swift test
swift format lint --strict --recursive Tests/
python3 Tools/Scripts/check_test_levels.py
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1229 tests in 217 suites pass, unchanged — this increment retags tests and adds a gate, and
changes no behaviour.

## Migration

1. This record, the gate, the baseline, the `validate-docs.sh` step and the retagging.
2. **Next**: the derived queue's remaining 14 rows. The untagged backlog shrinks
   opportunistically, whenever one of those 27 files is touched for another reason.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **enforces** a requirement that was asserted and unchecked.

## References

- [ADR-0282 - Decision register enforcement](ADR-0282-decision-register-enforcement.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0297 - Phantoms through the shipped pipelines](ADR-0297-phantoms-through-the-shipped-pipelines.md)
- [ADR-0298 - DICOM geometry validated with phantoms](ADR-0298-dicom-geometry-validated-with-phantoms.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
