---
document_id: "ADR-0410"
title: "Registration Metal acceptance resolution"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-010"
---

# ADR-0410 - Registration Metal acceptance resolution

## Context

The owner batch's Metal-acceptance item (`ADR-0374`'s `R` half): the
baseline requires reference registration implementations before Metal
acceleration is accepted into a diagnostic profile. **The owner has
taken up this item (2026-08-07).** The factual ground: the CPU
reference chain exists end-to-end with bit-pinned evidence, **no Metal
registration implementation exists in the tree**, and the registry
tripwire fails the suite if one ever registers before this ordering is
re-confirmed.

## Decision

1. **The diagnostic implementations for registration are the CPU
   references, and no Metal registration acceleration is accepted** —
   there is nothing to accept: no Metal registration path exists, and
   acceptance of an implementation that does not exist would be the
   fabricated-validation shape this project refuses.

2. **The ordering constraint is closed as satisfied and stays
   guarded**: the references demanded by the row are available and
   witnessed (`ADR-0374`), and the tripwire remains in force — if a
   Metal registration implementation is ever built, its acceptance
   into a diagnostic profile is a **new owner session** with
   CPU/Metal differential evidence in the standing harness pattern,
   plus the `ADR-0382` diagnostic-selection approval.

3. **Recorded interpretation**: this resolution reads the owner's
   direction as accepting the current posture — reference-first,
   CPU-only diagnostic registration. If the owner instead intends a
   Metal registration implementation to be built and accepted, that is
   new scope entering through the ledger, and this record's guard
   defines exactly what its acceptance requires.

## Alternatives considered

### Pre-approving future Metal registration acceleration

Rejected. Approval keyed to identifier and exact version
(`ADR-0382`) cannot pre-approve unbuilt code, by design.

## Consequences

`VOX-REG-010` is fully discharged — both halves. The owner batch
shrinks to nine items.

## Affected modules

None; documentation only.

## Compatibility impact

None.

## Security impact

Unchanged: the tripwire and the diagnostic-selection guard stand.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record and the ledger entry, in the same increment.
2. The loop remains stopped; nine owner-batch items remain open.

## Supersession

This record closes `ADR-0374`'s owner half.

## References

- [ADR-0374 - Registration references before Metal](ADR-0374-registration-references-before-metal.md)
- [ADR-0382 - The diagnostic selection guard](ADR-0382-the-diagnostic-selection-guard.md)
