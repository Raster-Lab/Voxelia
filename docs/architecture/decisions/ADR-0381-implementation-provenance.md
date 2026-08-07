---
document_id: "ADR-0381"
title: "Implementation provenance"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-EXT-005"
---

# ADR-0381 - Implementation provenance

## Context

`VOX-EXT-005` (P0, `T`, M7): third-party implementations shall provide
provenance metadata. A registration already declares identities,
versions, envelope and evidence — but nothing says **who built the
implementation**. For a first-party entry the answer is implicit; for a
third-party entry it is exactly the metadata a host must have before
any trust decision, and the diagnostic-guard row next door consumes it.

## Decision

1. **`RegisteredImplementation` gains a required `provider`**: a
   `SoftwareIdentity` — the accepted provenance vocabulary every
   `ProvenanceRecord` already uses, not a new type — naming the
   implementation's producer with name, version and optional commit and
   build identifier. Defaultless, like the envelope: an anonymous
   registration does not register.

2. **Built-in entries carry the project's own identity** (`Voxelia`,
   the release version), stated once per backend helper — first-party
   is a provider like any other, not an exemption.

3. **The witness extends the third-party entry**: the `com.example`
   registration declares its own provider, and the test reads it back
   from the registry — the metadata is host-inspectable data, not a
   comment.

4. **Trust is not decided here.** The provider identity is provenance,
   not approval; the diagnostic-selection guard row consumes it in its
   own increment.

## Alternatives considered

### A new dedicated provenance struct

Rejected. `SoftwareIdentity` is the accepted vocabulary for exactly
this fact; a parallel type would fork it.

### Optional provider for first-party entries

Rejected — decision 2. Implicit first-party identity is the same
anonymous registration the row prohibits, spelled politely.

## Consequences

Every registration names its producer; the diagnostic guard has the
fact it needs.

## Affected modules

`VoxeliaExecution` (the field), `VoxeliaCPU`/`VoxeliaMetal` (the
migrations), the extension witness.

## Compatibility impact

Source-breaking for `RegisteredImplementation` constructors, migrated
in-tree here. The layout change requires a clean build (the standing
stale-witness rule).

## Security impact

Strengthened: trust decisions gain an inspectable producer identity.

## Performance and memory impact

Negligible.

## Validation impact

```text
swift test --filter ExtensionMechanismTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the field, the migrations and the witness, in the same
   increment.
2. **Next**: the diagnostic-selection guard row closes the arc's
   engineering.

## Supersession

This record extends `ADR-0380`'s registration value.

## References

- [ADR-0380 - The registration declaration contract](ADR-0380-the-registration-declaration-contract.md)
- [ADR-0379 - The source-package extension mechanism](ADR-0379-the-source-package-extension-mechanism.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
