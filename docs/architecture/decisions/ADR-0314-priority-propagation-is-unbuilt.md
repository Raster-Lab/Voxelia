---
document_id: "ADR-0314"
title: "Priority propagation is unbuilt"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CON-008"
---

# ADR-0314 - Priority propagation is unbuilt

## Context

`VOX-CON-008` requires that "priority shall be propagated so interactive work can pre-empt or
outrank background cache generation". P1, **`T,D`**, milestone M3, from `ADR-0290`'s sweep.

## The measurement

**The words `priority` and `Priority` do not appear in `Sources/` at all** — not once, in any
spelling, across every module. There is no `TaskPriority`, no priority parameter, and no
scheduling vocabulary that could carry one.

So there is nothing to propagate. The row is **unbuilt**, in the same sense `ADR-0307` recorded
`VOX-PER-006` as unbuilt rather than untested.

## The finding that matters more than this row

**`VOX-CON-008` and `VOX-PER-006` are blocked on the same missing artefact.**

`ADR-0307` found there is no study cache: the only caches are `CachePreservationRule`,
`BrickResultCache` and `ContentResultCache`, none of which is a study-level generation stage.

- `VOX-PER-006` needs that stage to **have a completion**, so a first image can precede it.
- `VOX-CON-008` needs it to **be something interactive work can outrank**.

Neither row can be built until the same owner decision is made, and that decision — *what a
study cache is* — was already recorded by `ADR-0307`. **It gates two rows, not one**, and that
is worth knowing before anyone sizes it.

## Decision

1. **`VOX-CON-008` is not discharged, and no test is written.** A test asserting that
   interactive work outranks background generation, where neither a priority nor a background
   generation stage exists, would assert nothing.
2. **The row is recorded as unbuilt**, not untested, so its cost is not mistaken for a tagging
   exercise.
3. **No priority vocabulary is invented here.** Introducing a `TaskPriority` parameter across
   the operation surface before the thing it would order exists would fix a design against a
   consumer nobody has specified, and the parameter would then be argued about rather than
   used.
4. **The two rows are linked in the ledger**, so the owner's single decision is visible as
   unblocking both.
5. **The `D` remains an owner item**, as with `VOX-HLS-001`, `VOX-MTL-009`, `VOX-API-008` and
   `VOX-MPR-002`.

## Alternatives considered

### Add `TaskPriority` parameters now and discharge the propagation half

Rejected; see decision 3. "Propagated" means carried from an interactive caller through to the
work that competes with it, and with no competing work the parameter would be carried from
nowhere to nowhere while looking like progress.

### Treat Swift's cooperative pool priority as satisfying the row

Rejected. Structured concurrency does propagate priority through child tasks, and that is a
property of the language rather than of Voxelia. The row asks Voxelia to propagate it *so that*
interactive work outranks background cache generation, and no code here creates that
background work or expresses that relationship.

### Open an arc

Rejected as premature, for the same reason `ADR-0307` declined: the blocking definition is the
owner's, and an arc opened before it would freeze a guess.

## Consequences

`VOX-CON-008` is recorded as unbuilt, and the study-cache decision is now known to gate **two**
rows rather than one.

**5 entered-milestone rows remain** from `ADR-0290`'s sweep — unchanged, because this record
discharges nothing.

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

1235 tests in 218 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: the derived queue's remaining 5 rows. `VOX-CON-008` resumes when the study-cache
   definition exists.
3. **Owner**: no new item. The study-cache definition `ADR-0307` already listed now gates this
   row too.

## Supersession

This record supersedes nothing. It **records a row as unbuilt** and links it to the decision
that blocks it.

## References

- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0305 - Open the residency duplication row](ADR-0305-open-the-residency-duplication-row.md)
- [ADR-0307 - First useful image is unbuilt](ADR-0307-first-useful-image-is-unbuilt.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
