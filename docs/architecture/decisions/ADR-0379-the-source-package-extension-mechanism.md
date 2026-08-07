---
document_id: "ADR-0379"
title: "The source-package extension mechanism"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-EXT-001"
  - "VOX-EXT-002"
  - "VOX-EXT-004"
---

# ADR-0379 - The source-package extension mechanism

## Context

The extension-mechanism arc opens — the M7 queue's fifth arc. Its M7
rows in baseline order: the primary mechanism (`I,D`), third-party
operations without core modification (`I,T,D`), the registration
declaration contract (`I,T`), duplicate rejection (`T`), third-party
provenance (`T`) and the diagnostic-selection guard (`T,R`). Much of
the substance already exists in `ADR-0134`'s `ImplementationRegistry`;
this record opens the arc and discharges the three rows the existing
substance already serves.

## Decision

1. **The primary mechanism is source-level Swift packages depending on
   public Voxelia modules** (`VOX-EXT-001`). No plug-in loader, no
   dynamic discovery, no binary boundary in M7. The documentation
   deliverable is `docs/architecture/extension-mechanism.md`, which
   states what an extension can and cannot do; the runtime plug-in
   questions stay with their M9 rows, unpresumed.

2. **Third-party operations register as data, never as patches**
   (`VOX-EXT-002`): the host composes one `ImplementationRegistry` from
   the built-in registrations plus extension entries. The witness
   defines a third-party implementation entirely inside the validation
   suite — its own reverse-DNS tokens, never `org.voxelia.*` — and
   registers it beside the standard CPU entries **without one line of
   any core module changing**. The inspection half is the composition
   itself: registries are values constructed by the host, not global
   state a module must be edited to join.

3. **Duplicate identity pairs refuse typed** (`VOX-EXT-004`): the
   registry's existing admission rejects a repeated
   operation/implementation pair with `duplicateImplementation` — it
   rejects *every* duplicate, which is strictly stronger than the
   row's "duplicate incompatible" and deliberately so: two
   registrations claiming one identity are a conflict even when their
   contracts agree, because identity is the selection key. Witnessed
   against a third-party entry colliding with itself.

4. **The remaining arc rows are queued, not presumed**: the declaration
   contract row needs a design decision (widening
   `RegisteredImplementation` with ranks, formats, geometry, quality
   profiles and capability requirements touches every backend
   registration); the provenance and diagnostic-guard rows follow it.

## Alternatives considered

### A dynamic plug-in registry in M7

Rejected. The baseline places runtime plug-ins in M9 behind explicit
boundary and negotiation rows; presuming them now would build the
mechanism those rows exist to gate.

### Idempotent duplicate registration

Rejected — decision 3. Identity is the selection key; silent
re-registration would make selection order-dependent.

## Consequences

The arc is open with three rows discharged; the declaration-contract
row is next and carries the arc's one real design decision.

## Affected modules

Documentation and the validation suite only; no source module changes.

## Compatibility impact

None.

## Security impact

None; the diagnostic-selection guard row follows separately.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter ExtensionMechanismTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the guide, the witness suite and the register updates,
   in the same increment.
2. **Next**: the registration declaration contract row.

## Supersession

This record supersedes nothing; it composes `ADR-0134` unchanged.

## References

- [ADR-0134 - Implementation registration](ADR-0134-implementation-registration.md)
- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [The extension mechanism](../extension-mechanism.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
