---
document_id: "ADR-0327"
title: "Interaction launches nothing"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CON-005"
---

# ADR-0327 - Interaction launches nothing

## Context

`ADR-0326` discharged `VOX-CON-005` on a located measurement — four unstructured sites in
`Sources/`, all in `VoxeliaExecution`, all coalescing — and named the missing gate as its next
increment rather than half-building it at the end of a session. This builds it.

## Decision

1. **`Task.detached`, a bare `Task {` and `Task.init` are forbidden in `VoxeliaInteraction`.**
2. **This is a boundary, not a ban**, in the shape `ADR-0311` used for Metal Performance
   Shaders. The four coordinator sites are legitimate: each binds a task to a name and shares
   it, so concurrent callers join one task instead of starting their own. Forbidding them would
   enforce a rule the requirement does not state and would remove the mechanism that *prevents*
   overlap.
3. **The forbidden module is the one a draw callback calls into.** A task launched in
   `VoxeliaInteraction` is launched **per draw**, which is precisely the overlap `VOX-CON-005`
   names. A task launched in a coordinator is launched per distinct unit of work.
4. **The pattern is written so it cannot repeat a known false positive.** `ADR-0326` found by
   hand that `CanonicalMetadataJSON`'s private `EmissionTask` enum matched a naive search. The
   patterns here require a **word boundary before `Task`**, so an identifier merely ending in
   it is invisible — and that immunity is asserted, not assumed.

## The gate is proven in three directions

```text
Task.detached added to FramePresenter.swift  -> failed, named by file and line   (exit 1)
the four VoxeliaExecution coordinators       -> passed                           (exit 0)
CanonicalMetadataJSON's EmissionTask         -> not matched by the pattern
```

The second matters as much as the first: a gate failing on both would have turned a boundary
into a ban. The third is the one a hurried version would have skipped, and it is the exact
mistake the previous increment made manually.

## Alternatives considered

### Forbid unstructured concurrency everywhere

Rejected; see decision 2. It would break the coalescing coordinators, which exist to stop
duplicate work, and would answer a requirement nobody wrote.

### Fold this into `check_swift_safety.py`

Rejected. That gate's subject is memory and escape-hatch syntax; concurrency structure is a
different property, and a gate that checks two unrelated things is one whose failures are
harder to read.

### Match `Task` without a word boundary

Rejected, with evidence. It produces the `EmissionTask` false positive `ADR-0326` hit, and a
gate that cries wolf on a private enum is one that gets disabled.

## Consequences

`VOX-CON-005`'s property is enforced rather than merely true, and the eleventh unenforced
property this arc found is closed.

**6 rows remain unclaimed** under `ADR-0319`'s criterion — unchanged, since `ADR-0326` already
claimed this row.

## Affected modules

None. One gate and one `validate-docs.sh` step. No source file changed.

## Compatibility impact

None. No existing code is affected, because `VoxeliaInteraction` launches nothing today.

## Security impact

None directly.

## Performance and memory impact

None. The gate scans seven sources.

## Validation impact

```text
python3 Tools/Scripts/check_unstructured_concurrency.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged — this increment adds no Swift.

## Migration

1. This record, the gate and the `validate-docs.sh` step.
2. **Next**: the remaining unclaimed rows.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **enforces** what `ADR-0326` measured.

## References

- [ADR-0311 - Metal performance shaders boundary](ADR-0311-metal-performance-shaders-boundary.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0326 - Draw callbacks launch nothing](ADR-0326-draw-callbacks-launch-nothing.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
