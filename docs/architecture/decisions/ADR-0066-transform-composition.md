---
document_id: "ADR-0066"
title: "Transform composition"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-IMG-001"
  - "VOX-DAT-014"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0066 - Transform composition

## Context

Accepted `ADR-0065` deliberately rejected inputs carrying a value
transform: windowing over transformed real values composes two numeric
models and was deferred to this decision. The clinically essential
case is the DICOM-derived modality rescale — CT stored values map
linearly to Hounsfield units, and the window is expressed in that real
domain. This record was authored and accepted on 2026-08-04 under the
project owner's recorded autonomous delegation, following the owner's
explicit instruction to build the transform-composition decision.

## Decision

1. **Composition rule.** A value-domain operation model composes with
   the input descriptor's value transform by evaluating the stored
   sample to its real value first and feeding the real value to the
   downstream model unchanged; the operation's value parameters are
   thereby expressed in the input's real value domain. An absent
   transform and the identity transform make the real domain equal to
   the stored domain, so the previously accepted stored-domain
   behaviour is the degenerate case, bit-identical.
2. **Registered mapping.** The stored-to-real step for the linear
   case is `linear-value-transform/binary64-v1` per
   `VOXELIA-ALG-0003`: one correctly rounded binary64 multiplication
   followed by one correctly rounded addition in frozen association,
   with fused multiply-add explicitly forbidden because it changes
   the rounding count.
3. **Version-one composable set.** The window-level operation admits
   exactly the absent, `identity` and `linear` transforms. The
   `lookupTable` and `composed` cases stay typed rejections: table
   evaluation semantics and multi-stage composition chains each need
   their own registered model before any source.
4. **Version bump.** Admitting a wider input domain with a defined
   real-domain parameter semantic is a compatible semantic extension:
   the operation and implementation versions both advance to `1.1.0`,
   so derivation recipes and provenance claims distinguish executions
   under the extended contract; outputs for previously admitted
   inputs are bit-identical.
5. **Output invariants unchanged.** The output remains dimensionless
   eight-bit display intensity with no transform and no units, and
   the frozen parameter schema, identity, recipe and provenance
   assembly are untouched.

## Alternatives considered

Windowing stored values while ignoring a present transform was
rejected as silently wrong in the unit domain clinicians reason in.
Baking the rescale into adjusted window parameters was rejected: it is
algebraically equivalent only for the linear case, changes the
recorded parameters away from the clinical values, and breaks down for
future table transforms. Admitting `composed` chains of linear stages
by algebraic flattening was rejected for version one: flattening
changes rounding behaviour and needs its own model.

## Consequences

True Hounsfield-domain windowing works end to end over rescaled CT
stored values; the composition rule generalises to future value-domain
operations without re-deciding the layering.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Previously rejected inputs become admitted with defined semantics;
previously admitted inputs produce bit-identical outputs under the
advanced version tokens.

## Security impact

The transform coefficients are already finite validated values; the
admitted 8- and 16-bit stored domains cannot overflow binary64 under
finite coefficients; all existing budgets and typed payload-free
failures apply.

## Performance and memory impact

One additional multiply and add per sample in the transformed case;
nothing else changes.

## Validation impact

Tests must reproduce both `VOXELIA-ALG-0003` conformance fixtures —
the CT rescale reproducing the exact real-domain window fixture and a
fractional-scale mapping — through the full operation, prove the
identity transform bit-identical to the absent transform, prove the
advanced version tokens in the recipe and claims, and reject the
`lookupTable` and `composed` cases typed.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `ADR-0065` transform-composition deferral and
supersedes nothing.

## References

- [VOXELIA-ALG-0003 - Linear stored-to-real value mapping binary64-v1](../../algorithms/VOXELIA-ALG-0003-linear-value-transform.md)
- [ADR-0065 - Window-level operation](ADR-0065-window-level-operation.md)
- [ADR-0023 - Value transform shape](ADR-0023-value-transform-shape.md)
