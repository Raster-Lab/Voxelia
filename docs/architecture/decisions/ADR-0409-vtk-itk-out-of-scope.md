---
document_id: "ADR-0409"
title: "VTK/ITK interop out of scope"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-ADP-007"
  - "VOX-ADP-008"
  - "VOX-ADP-009"
  - "VOX-ADP-010"
---

# ADR-0409 - VTK/ITK interop out of scope

## Context

The `ADR-0351` owner batch's first question — VTK/ITK interop package
scope or post-1.0 deferral — blocked the M7 queue's interoperability
arc, the only arc never opened. **The owner has answered
(2026-08-07): VTK/ITK interop is out of scope; a replacement is
planned.** This record dispositions the four rows the answer touches.

## Decision

1. **No VTK/ITK interoperability is built** (`VOX-ADP-008`,
   `VOX-ADP-009` — both "should" rows): out of scope by owner
   decision. The planned replacement is a future owner-defined
   direction, not this baseline's debt; when it is specified, it
   enters through a baseline revision, not through this record.

2. **The optionality row is satisfied structurally and stays
   enforced** (`VOX-ADP-007`): no VTK or ITK dependency exists in the
   package graph, the supply-chain gate admits only the approved
   external identities, and the canonical-API prohibition on VTK/ITK
   types is a standing M1 row. Nothing can become a core runtime
   dependency by accident.

3. **The conversion-convention row is discharged by the conversions
   that exist** (`VOX-ADP-010`): every interoperability seam actually
   shipped — the DICOM adapter capabilities, the media and spatial
   adapter seams — exchanges values that carry their
   `CoordinateSpaceDescriptor`, and convention disagreement is a typed
   refusal at the seams that compose spaces (witnessed in the
   transform-composition suite). No conversion in the tree can change
   a spatial convention silently, and any future replacement interop
   inherits the same vocabulary.

## Alternatives considered

### Holding the rows open for the replacement

Rejected. The replacement is unspecified; open rows against an
unspecified target are unpayable debt, and the owner's decision closes
this baseline's question cleanly.

## Consequences

The M7 queue's last blocked arc is resolved without construction. The
owner batch shrinks to ten items.

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
2. The loop remains stopped; ten owner-batch items remain open.

## Supersession

This record closes the `ADR-0351` batch's first question.

## References

- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [ADR-0367 - Registration transform composition](ADR-0367-registration-transform-composition.md)
- [ADR-0378 - DICOM adapter capabilities](ADR-0378-dicom-adapter-capabilities.md)
