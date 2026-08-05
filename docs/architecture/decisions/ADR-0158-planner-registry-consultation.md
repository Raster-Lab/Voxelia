---
document_id: "ADR-0158"
title: "Planner registry consultation"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-CCH-002"
  - "VOX-CCH-003"
  - "VOX-ARC-010"
---

# ADR-0158 - Planner registry consultation

## Context

The implementation-registration record reserved a revision path:
planning surfaces may consult the registry through their own future
revisions. The version-one planner proved device availability by
acquiring the context and kernels but never asked whether the device
implementations were actually registered with evidence. This record
closes that gap. It was authored and accepted on 2026-08-05 under
the project owner's recorded broadened autonomous delegation.

## Decision

1. **The planner takes the registry explicitly** — no permissive
   default — and a device plan is returned only when the registry
   lists a metal-backend implementation for each of the three
   operations the device path runs, in addition to the existing
   context and kernel acquisitions. A registry without those entries
   reports the exact CPU selection through the plan, per the
   plan-is-the-report rule: preference is not requirement and the
   fallback stays visible.
2. **The reference selection needs no registry proof.** The exact
   CPU pipeline is the registered validation baseline the fail-closed
   rule falls back to; requiring registry proof for the fallback
   would invert the fail-closed direction and leave no plan at all
   when proof is absent. That asymmetry is deliberate and recorded:
   the registry gates the preferred path, never the baseline.

## Alternatives considered

Consulting contract versions as well as backends was deferred: the
planner constructs the kernels whose own claims carry versions, and
version negotiation belongs to a future revision with a consumer
that needs it. Building the registry inside the planner was
rejected: the metal module cannot see the CPU registrations, and the
combined registry is the host's composition.

## Consequences

A device plan now implies registered, evidence-carrying device
implementations; hosts pass the registry they compose.

## Affected modules

`VoxeliaMetal`.

## Compatibility impact

The planner signature gains the explicit registry parameter.

## Security impact

None.

## Performance and memory impact

Three registry lookups per plan.

## Validation impact

The planner suite passes the metal registrations for the
device-bearing expectations and adds the empty-registry case
reporting the exact CPU selection under a device-preferring policy.

## Migration

Call sites pass the registry they compose.

## Supersession

Exercises the revision path reserved by `ADR-0134`; no record is
superseded.

## References

- [ADR-0134 - Implementation registration](ADR-0134-implementation-registration.md)
- [ADR-0104 - Backend policy planning](ADR-0104-backend-policy-planning.md)
