---
document_id: "ADR-0068"
title: "Window-level uint16 extension"
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

# ADR-0068 - Window-level uint16 extension

## Context

Accepted `ADR-0065` admitted `uint8` and `int16` stored samples and
recorded every further scalar type as a registered per-type extension
with its own exact-conversion argument. Sixteen-bit unsigned intensity
is common in secondary-capture and ultrasound-derived data. This
record was authored and accepted on 2026-08-04 under the project
owner's recorded overnight autonomous delegation.

## Decision

1. **Extension.** The window-level operation admits `uint16` stored
   samples. Every `uint16` value (`0...65535`) converts to binary64
   exactly, so the `VOXELIA-ALG-0002` model applies without change;
   the two-byte assembly follows the specification's existing
   byte-order resolution rule. The specification advances to revision
   `1.1` recording the widened format set; its model, fixtures and
   rules are otherwise untouched.
2. **Version bump.** The operation and implementation versions
   advance to `1.2.0` — another compatible admission widening —
   keeping recipes and claims distinguishable; previously admitted
   inputs stay bit-identical.

## Alternatives considered

Admitting every remaining integer type at once was rejected: 32-bit
types exceed nothing in binary64 either, but each type deserves its
own fixture evidence, and no consumer asks for them yet. Deferring
until a consumer demanded it was rejected under the standing overnight
instruction to complete recorded extension work.

## Consequences

Unsigned sixteen-bit intensity images window end to end under the
frozen model.

## Affected modules

`VoxeliaExecution` and the `VOXELIA-ALG-0002` format registry; no
dependency change.

## Compatibility impact

Previously rejected `uint16` inputs become admitted; everything else
is bit-identical under the advanced version tokens.

## Security impact

No new failure modes: the conversion is exact and the existing
budgets, ceilings and typed payload-free failures apply.

## Performance and memory impact

Identical to the `int16` path.

## Validation impact

Tests must reproduce an independently computed `uint16` conformance
fixture through the full operation, prove the advanced version tokens
in the recipe and keep every previously registered fixture passing.

## Migration

Implemented in this increment.

## Supersession

This ADR extends accepted `ADR-0065` and supersedes nothing.

## References

- [ADR-0065 - Window-level operation](ADR-0065-window-level-operation.md)
- [VOXELIA-ALG-0002 - Window-level linear mapping binary64-v1](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
