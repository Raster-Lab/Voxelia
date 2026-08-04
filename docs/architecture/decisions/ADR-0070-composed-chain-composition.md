---
document_id: "ADR-0070"
title: "Composed chain composition"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-IMG-001"
  - "VOX-ERR-001"
---

# ADR-0070 - Composed chain composition

## Context

Accepted `ADR-0066` and `ADR-0069` composed the linear and
lookup-table transforms with the window model and left the `composed`
case a typed rejection pending a chain decision. With both stage
models registered, sequential chain evaluation needs no new
arithmetic — only frozen ordering, stage-position and bound rules.
This record was authored and accepted on 2026-08-04 under the project
owner's recorded overnight autonomous delegation.

## Decision

1. **Registered chain model.** The stored-to-real step for the
   composed case is `composed-value-transform-chain/binary64-v1` per
   `VOXELIA-ALG-0005`: stages evaluate sequentially in declared order,
   identity stages are exact no-ops, linear stages apply the
   registered `VOXELIA-ALG-0003` arithmetic to their input, and a
   lookup-table stage is admissible only while every earlier stage is
   an identity, because its clamped index is defined on the exact
   stored integer and no registered model supplies an input-rounding
   rule for tables over arithmetic outputs.
2. **Admission bounds.** At most 8 declared stages; nested composed
   stages are rejected — flattening changes rounding behaviour and
   needs its own model — and empty table stages reject as before. An
   all-identity chain is exactly the identity mapping.
3. **Version bump.** The operation and implementation versions
   advance to `1.4.0`; previously admitted inputs stay bit-identical.

## Alternatives considered

Algebraically flattening adjacent linear stages was rejected: it
changes the number of roundings and therefore the result. Rounding
arithmetic outputs to feed mid-chain tables was rejected as an
unregistered model. An unbounded stage count was rejected under the
no-permissive-defaults rule.

## Consequences

Multi-stage modality mappings window end to end, and the composable
set now covers every `ValueTransform` case within registered bounds.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Previously rejected composed inputs become admitted within the
bounds; everything else is bit-identical under the advanced version
tokens.

## Security impact

Stage evaluation reuses already-registered validated models; the
stage ceiling bounds work per sample; existing budgets and typed
payload-free failures apply.

## Performance and memory impact

At most 8 stage evaluations per sample.

## Validation impact

Tests must reproduce both `VOXELIA-ALG-0005` conformance fixtures —
a two-stage linear chain and an identity-table-linear chain — through
the full operation, prove the advanced version tokens, and reject a
nested composed stage, a table after an arithmetic stage and an
over-ceiling chain, all typed.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the remaining `ADR-0066` deferral and supersedes
nothing.

## References

- [VOXELIA-ALG-0005 - Composed value-transform chain binary64-v1](../../algorithms/VOXELIA-ALG-0005-composed-value-transform-chain.md)
- [ADR-0069 - Lookup-table composition](ADR-0069-lookup-table-composition.md)
