---
document_id: "ADR-0332"
title: "The test level ratchet is clean"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-001"
---

# ADR-0332 - The test level ratchet is clean

## Context

`ADR-0301` created the test-level taxonomy as a ratchet over a 219-test backlog, because a
clean gate would have landed red. `ADR-0331` cut that to 21. This clears the rest, and the
ratchet becomes a clean gate — not by changing the rule, but by the backlog reaching zero.

## The two judgements, made by reading

**`CTVolumeBridgeCompositionTests` is `[Integration]`**, and this time the level was read rather
than inferred. `ADR-0331` skipped it because its *name* suggested integration and a
disambiguating pass should not guess. Its own documentation settles it:

> an ingested CT volume is published through `PublicationCoordinator` and reconstructed in all
> three planes through `MPRSliceCoordinator` … the first time the ingest arc's output meets code
> written in earlier milestones … the proof that the two halves compose

Two subsystems composing is what `Integration` describes. The filename was a correct hint and a
bad reason; the doc comment is the reason.

**The remaining 14 are `[Unit]`**, matching their siblings in the same suites. They were missed
by `ADR-0331` only because they use the multi-line attribute form, where the display string sits
on the line after `@Test(`.

## Decision

1. **All 1,238 tests now carry a level.** `Unit` 1055, `Integration` 23, `Operation` 58,
   `Kernel` 37, `Oracle` 22, `Pipeline` 21, `Concurrency` 12, `SystemReference` 10.
2. **The baseline is regenerated empty, and the gate is therefore clean without a rule change.**
   `check_test_levels.py` already fails when a file absent from the baseline introduces an
   untagged test; with an empty baseline that is every file. The ratchet did its job and
   dissolved.
3. **The cleanliness is proven, not assumed.** An untagged probe was added to
   `VoxeliaCoreTests` and the gate rejected it, then the file was restored. A ratchet that
   silently stopped ratcheting would look identical to this from the outside.
4. **The thirteen remaining `swift format` findings are pre-existing** — `OrderedImports` in the
   twelve module-linkage files and one `Indentation` in `Tests/Support`. **None is a
   `LineLength`**, so this pass introduced none, and they are recorded here as untouched rather
   than quietly fixed in a retagging commit.

## Alternatives considered

### Tag the bridge suite `[Unit]` with its siblings

Rejected. It is the one file in the backlog whose subject is two subsystems rather than one
type, and mislabelling it would put nine of the ten levels' counts slightly wrong in the
direction that flatters `Unit`.

### Leave the ratchet in place with an empty baseline

Rejected as misleading. A baseline file implies a debt; an empty one implies a debt of nothing,
which is a clean gate wearing a ratchet's clothes. The file stays as the mechanism, and this
record states that it is currently empty by achievement rather than by omission.

### Fix the thirteen pre-existing findings here

Rejected as unrelated. `OrderedImports` in twelve linkage files is its own small increment, and
bundling it with 219 retagged display strings would make both harder to review.

## Consequences

`VOX-VAL-001`'s taxonomy is now complete: every test declares a level, from a closed
vocabulary, with every required level non-empty and the whole set measured rather than
estimated.

**`ADR-0301`'s ratchet is the first in this arc to reach zero.** The other two —
`ADR-0321`'s 121 American spellings and `ADR-0302`'s empty temporary-file list — remain as they
were.

## Affected modules

None. Level tags on 21 existing tests and an emptied baseline. No source file changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test
swift format lint --strict --recursive Tests/
python3 Tools/Scripts/check_test_levels.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged. The gate reports zero untagged.

## Migration

1. This record and the last 21 tags.
2. **Next**: `ADR-0321`'s spelling backlog, and the twelve `OrderedImports` findings as their own
   increment.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **completes** the backlog `ADR-0301` recorded and `ADR-0331`
reduced.

## References

- [ADR-0301 - Enforce the test level taxonomy](ADR-0301-enforce-the-test-level-taxonomy.md)
- [ADR-0321 - British English ratchet](ADR-0321-british-english-ratchet.md)
- [ADR-0331 - Shrink the untagged test backlog](ADR-0331-shrink-the-untagged-test-backlog.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
