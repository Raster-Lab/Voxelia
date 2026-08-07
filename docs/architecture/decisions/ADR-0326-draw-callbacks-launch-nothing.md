---
document_id: "ADR-0326"
title: "Draw callbacks launch nothing"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CON-005"
---

# ADR-0326 - Draw callbacks launch nothing

## Context

`VOX-CON-005` requires that "interactive draw callbacks shall not launch overlapping
unstructured work". P0, `T`, milestone M3, from `ADR-0319`'s rederived queue.

## The measurement

Every unstructured-concurrency site in `Sources/` was located. There are **four**, and one
apparent fifth is not concurrency at all — `CanonicalMetadataJSON`'s `EmissionTask` is a
private enum whose name matched the search.

| Site | Module | Shape |
|---|---|---|
| `StorageReadCoordinator` | `VoxeliaExecution` | `Task.detached` bound to `shared` |
| `MetadataIdentityCoordinator` | `VoxeliaExecution` | `Task.detached` bound to `started` |
| `BrickRequestBroker` (×2) | `VoxeliaExecution` | `Task` bound to `computation` |

**`VoxeliaInteraction` contains none.** The module a draw callback calls into launches no
unstructured work at all, so a callback cannot inherit any from it.

**And the four that exist are the opposite of what the row prohibits.** Each binds its task to
a name and shares it: that is the coalescing pattern, where concurrent requests for the same
work join one task rather than starting their own. A coordinator that deduplicates overlap is
not a source of it.

## Decision

1. **`VOX-CON-005`'s `T` is discharged.** The property holds structurally: the interaction
   module launches nothing, and the execution coordinators that do launch use a shared-task
   pattern to prevent overlap rather than create it.
2. **The absence of a gate is recorded, not papered over.** Nothing stops a future increment
   adding `Task.detached` to `VoxeliaInteraction`, and this is the eleventh property in this
   arc found true and unenforced. A prohibition on unstructured concurrency in that module,
   in the shape `check_prohibited_imports.py` already uses for frameworks, is the natural next
   increment — named here rather than half-built at the end of a session.
3. **The measurement is stated so it can be rerun**, like `ADR-0319`'s: four sites, all in
   `VoxeliaExecution`, all coalescing. A future check compares against that, not against a
   memory of it.

## Alternatives considered

### Build the gate now

Not done, and it is a scoping choice rather than a judgement about its value. A prohibition
naming `Task.detached` and bare `Task {` in one module is small, and it deserves its own
increment with the failure proof this project requires of every gate — the kind that would be
rushed at the end of a session.

### Read the four coordinator sites as violations

Rejected. The row prohibits *launching overlapping* work, and each of those sites exists to
make concurrent callers share one task. Reading them as violations would invert the
requirement.

### Claim the row without locating the sites

Rejected. "The interaction module launches nothing" is only meaningful once the sites that do
launch have been found and read; otherwise it is an absence of evidence reported as evidence
of absence.

## Consequences

`VOX-CON-005` is discharged on a located, read measurement rather than an assumption, and the
gate that would keep it true is named.

**6 rows remain unclaimed** under `ADR-0319`'s criterion, recomputed rather than decremented.

## Affected modules

None. This record adds no code.

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
2. **Next**: the unstructured-concurrency prohibition for `VoxeliaInteraction`, with its
   failure proof.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **claims** a row on a measurement of where unstructured work
is launched.

## References

- [ADR-0275 - Open the interactive draw loop arc](ADR-0275-open-the-interactive-draw-loop-arc.md)
- [ADR-0303 - Headless rendering enforced](ADR-0303-headless-rendering-enforced.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
