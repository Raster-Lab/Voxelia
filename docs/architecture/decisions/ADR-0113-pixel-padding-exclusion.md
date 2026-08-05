---
document_id: "ADR-0113"
title: "Pixel padding exclusion"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-R2D-009"
  - "VOX-EXE-002"
  - "VOX-ERR-001"
---

# ADR-0113 - Pixel padding exclusion

## Context

`VOX-R2D-009` requires pixel-padding exclusion where supplied by the
source adapter — the DICOM pixel-padding convention marks samples
outside the reconstructed region with a stored sentinel that must not
window as data. The window model had no exclusion rule. This record
was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **The registered rule.** `VOXELIA-ALG-0002` revision 1.2 adds the
   optional stored-domain padding sentinel: a stored integer sample
   exactly equal to the declared value is excluded before every
   stored-to-real step and displays exactly zero; an absent padding
   value leaves revision 1.1 byte-identical.
2. **An explicit optional parameter.** `WindowLevelOperation` takes
   the optional padding value with absence stated explicitly, rejects
   a sentinel not representable in the admitted integer scalar type
   as the typed `invalidPaddingValue`, and advances to 1.5.0 under
   the established widening rule. The frozen parameter schema gains
   the `padding` entry exactly when a value is declared, so every
   unpadded parameter document and digest is unchanged.
3. **The device implementation stays at its contract.** The device
   window implementation does not admit padding and continues to
   claim operation contract 1.4.0 — the revision it implements —
   because claiming a contract whose rule it lacks would be false;
   a padded device path is its own future increment with its own
   measured evidence.
4. **Renderer wiring deferred.** The renderer passes no padding
   today; surfacing padding through the presentation vocabulary
   arrives with the adapter that supplies it, per the row's own
   wording.

## Alternatives considered

Mapping padded samples through the window was rejected: a sentinel is
not data. A mandatory padding parameter was rejected: most sources
declare none. Excluding after the stored-to-real transform was
rejected: the sentinel is a stored-domain convention.

## Consequences

`VOX-R2D-009` is discharged at the operation level, ready for the
gated adapter to supply values.

## Affected modules

`VoxeliaExecution` and call-site signatures in `VoxeliaMetal`; no
dependency change.

## Compatibility impact

Pre-release explicit-parameter addition; unpadded digests unchanged;
operation version advanced to 1.5.0.

## Security impact

Unchanged budgets; typed payload-free rejections.

## Performance and memory impact

One integer comparison per sample when padding is declared.

## Validation impact

Tests must reproduce both padding fixtures through the full
operation, prove an absent padding value byte-identical to the
accepted results, verify the padded parameter digest differs from the
unpadded digest while unpadded digests are unchanged, and reject an
unrepresentable sentinel typed.

## Migration

Implemented in this increment.

## Supersession

Revises the `VOXELIA-ALG-0002` model to 1.2; no record is superseded.

## References

- [VOXELIA-ALG-0002 - Window-level linear binary64-v1](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
- [ADR-0065 - Window-level operation](ADR-0065-window-level-operation.md)
