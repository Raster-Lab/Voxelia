---
document_id: "ADR-0135"
title: "Metal backend registrations"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-011"
  - "VOX-CCH-001"
  - "VOX-ERR-001"
---

# ADR-0135 - Metal backend registrations

## Context

`ADR-0134` made registration a backend-neutral vocabulary and
registered the CPU implementations; the three device implementations
remained unregistered, so a future planner consulting the registry
would see one backend only. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

`MetalBackendRegistrations.standard` registers the three device
implementations with their honest split versions — the contract each
implements and the implementation's own version, which the registry
type carries separately by design: window-level at contract 1.4.0
with implementation 1.1.0 and the `binary32-device` approximate
claim, composite-layers at contract 1.2.0 with implementation 1.1.0
and the same approximate claim, and invert-display at contract 1.0.0
with implementation 1.0.0 and the `exact` claim — the registry now
states, in one queryable vocabulary, exactly the contract gaps the
decision records narrate, such as the device window implementing 1.4
while the CPU implements 1.5.

## Alternatives considered

Registering device entries from `VoxeliaCPU` was rejected: each
backend registers its own implementations in its own module, per the
`VOX-ARC-011` ownership row.

## Consequences

Both backends' implementations are registered data; a combined
registry composes from both standard sets, and planner consultation
has its complete input.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Registrations carry tokens, versions and evidence identifiers only.

## Performance and memory impact

Negligible.

## Validation impact

Tests must verify the three device registrations with their split
contract and implementation versions, their claims, and the combined
CPU-plus-metal registry constructing without collision.

## Migration

Implemented in this increment.

## Supersession

Extends `ADR-0134` to the metal backend; no record is superseded.

## References

- [ADR-0134 - Implementation registration](ADR-0134-implementation-registration.md)
- [ADR-0133 - Device invert operation](ADR-0133-device-invert-operation.md)
