---
document_id: "ADR-0411"
title: "DICOMKit fix-what-surfaces confirmed"
status: "Accepted"
date: "2026-08-08"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DCM-012"
---

# ADR-0411 - DICOMKit fix-what-surfaces confirmed

## Context

The `ADR-0351` owner batch's third question asked the owner to confirm
that the fix-what-surfaces posture covers DICOMKit's segmentation and
parametric-map reading surfaces. **The owner has confirmed
(2026-08-08).** The `ADR-0378` capability seams were built without
readers precisely pending this answer.

## Decision

1. **Fix-what-surfaces is the confirmed posture for DICOMKit surface
   work**: segmentation, parametric map, surface and spatial
   registration reading in the external `DICOMKit` package is
   addressed **as real usage surfaces the need**, not by proactive
   reader construction against unexercised object types. The approved
   dependency identity and exact version pin are unchanged; DICOMKit
   changes arrive as ordinary pinned upgrades through the supply-chain
   gate.

2. **The `ADR-0378` capability protocols remain the integration
   points**: when usage surfaces a need, the conforming reader is
   built behind the existing seam — mapping into canonical models
   through their own admissions — and enters as an ordinary ledger
   increment, not as a standing obligation created here.

3. **No reader is scheduled by this record.** Confirmation of a
   maintenance posture is not a work order; the adapter-capabilities
   row stays discharged exactly as `ADR-0378` recorded it.

## Alternatives considered

### Proactively building a SEG reader now that the posture is confirmed

Rejected. The confirmed posture says the opposite: build when usage
surfaces the need, so the first real SEG consumer defines the reader's
requirements instead of a guess defining them.

## Consequences

The owner batch shrinks to eight items. The separate batch question of
a reference AI adapter for the segmentation row remains open.

## Affected modules

None; documentation only.

## Compatibility impact

None.

## Security impact

None; the supply-chain posture is unchanged.

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
2. The loop remains stopped; eight owner-batch items remain open.

## Supersession

This record closes the `ADR-0351` batch's third question.

## References

- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [ADR-0378 - DICOM adapter capabilities](ADR-0378-dicom-adapter-capabilities.md)
