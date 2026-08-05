---
document_id: "ADR-0157"
title: "Brick request abandonment"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-BRK-006"
  - "VOX-CON-009"
  - "VOX-PER-007"
---

# ADR-0157 - Brick request abandonment

## Context

Accepted `ADR-0149` fixed the version-one rule that a started brick
computation runs to completion for its followers and recorded
whole-computation abandonment as a future refinement rather than a
silent behaviour. This record delivers that refinement. It was
authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **The broker tracks the computation beside its waiters.** The
   in-flight entry holds the computation task; when the last awaiter
   cancels, the entry is removed immediately and the computation
   task is cancelled — abandoned work stops promptly instead of
   running for nobody. The compute contract documents cooperative
   cancellation: a computation that ignores cancellation still
   completes harmlessly into the no-waiter path.
2. **A completion with no waiters resumes nobody.** The orphaned
   task's completion finds no entry and clears nothing — the
   existing guard, now load-bearing. Because abandonment removes the
   entry, a fresh request for the same key after abandonment starts
   a new computation rather than joining a cancelled one.
3. **Partial cancellation is unchanged.** While any awaiter remains,
   the computation continues and followers receive the shared
   outcome — the accepted rule, re-proven by the existing storm.

## Alternatives considered

Keeping the abandoned entry until the task observed cancellation was
rejected: a newcomer would join a cancelled computation and receive
a cancellation it never asked for.

## Consequences

Abandoned bricks stop consuming work promptly; `VOX-BRK-006` holds at
the computation level, not only the awaiter level.

## Affected modules

`VoxeliaExecution`.

## Compatibility impact

Behavioural refinement recorded here; no signature changes.

## Security impact

None.

## Performance and memory impact

One task handle per in-flight entry.

## Validation impact

The broker suite gains the all-cancelled storm: sixty-four awaiters
cancel, the computation observes its own cancellation after the
gate, and a fresh request afterwards starts a new computation; the
partial-cancellation storm stays green unchanged.

## Migration

None.

## Supersession

Supersedes the version-one completion rule of `ADR-0149` decision 2;
its recorded refinement is now the behaviour.

## References

- [ADR-0149 - Brick request lifecycle design](ADR-0149-brick-request-lifecycle-design.md)
- [ADR-0150 - Brick request broker](ADR-0150-brick-request-broker.md)
