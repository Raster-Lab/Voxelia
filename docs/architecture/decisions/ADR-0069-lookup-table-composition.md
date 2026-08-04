---
document_id: "ADR-0069"
title: "Lookup-table composition"
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

# ADR-0069 - Lookup-table composition

## Context

Accepted `ADR-0066` composed the linear value transform with the
window model and left the `lookupTable` case a typed rejection pending
its own registered evaluation model. The table form is the
DICOM-derived alternative modality mapping, and its Core descriptor
has existed since `ADR-0023`. This record was authored and accepted on
2026-08-04 under the project owner's recorded overnight autonomous
delegation.

## Decision

1. **Registered mapping.** The stored-to-real step for the table case
   is `lookup-table-value-transform/binary64-v1` per
   `VOXELIA-ALG-0004`: a 64-bit clamped index from the stored integer
   value and the table's first mapped value, with the DICOM-derived
   out-of-range rule (below the table takes the first output, beyond
   it the last) and a frozen overflow-clamp rule. The window
   parameters are thereby expressed in the table's output domain; the
   descriptor's output unit is never converted.
2. **Admission.** The window-level composable set gains
   `lookupTable` with a non-empty table; an empty table defines no
   output and is its own typed rejection. The `composed` case remains
   rejected pending the chain decision.
3. **Version bump.** The operation and implementation versions
   advance to `1.3.0`; previously admitted inputs stay bit-identical.

## Alternatives considered

Interpolating between table entries was rejected: the DICOM-derived
table is a direct-lookup mapping, and interpolation is a different
registered model if ever needed. Treating an empty table as the
identity was rejected as silent substitution.

## Consequences

Table-mapped intensity images window end to end in the table's output
domain.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Previously rejected table inputs become admitted; everything else is
bit-identical under the advanced version tokens.

## Security impact

Table outputs are validated finite at construction; the clamped index
cannot read out of bounds by construction; existing budgets and typed
payload-free failures apply.

## Performance and memory impact

One integer subtraction, clamp and table read per sample.

## Validation impact

Tests must reproduce the `VOXELIA-ALG-0004` conformance fixture —
below-clamp, in-range including a fractional output, and above-clamp —
through the full operation, prove the advanced version tokens, reject
an empty table typed and keep every previously registered fixture
passing.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `ADR-0066` lookup-table deferral and
supersedes nothing.

## References

- [VOXELIA-ALG-0004 - Lookup-table stored-to-real value mapping binary64-v1](../../algorithms/VOXELIA-ALG-0004-lookup-table-value-transform.md)
- [ADR-0066 - Transform composition](ADR-0066-transform-composition.md)
