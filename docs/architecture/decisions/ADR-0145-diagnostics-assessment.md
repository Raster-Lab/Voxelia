---
document_id: "ADR-0145"
title: "Diagnostics and logging assessment"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-ERR-007"
  - "VOX-SEC-006"
  - "VOX-DCM-013"
  - "VOX-META-011"
---

# ADR-0145 - Diagnostics and logging assessment

## Context

The M4 sweep queued a diagnostics-and-logging decision for
`VOX-ERR-007`, `VOX-SEC-006` and the non-adapter half of
`VOX-DCM-013` — a decided position rather than incidental absence.
This record is a documentation-only assessment under the `ADR-0114`
and `ADR-0121` precedent. It was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **No logging framework is built now.** Voxelia today emits no
   logs: there is no logging subsystem, no print path and no
   free-text diagnostic channel anywhere in the package. A framework
   without a consumer would be speculative surface; the arcs that
   will produce real diagnostic consumers — the interactive draw
   loop and the DICOM adapter — are both gated, and the component
   should be designed against their actual needs.
2. **The existing diagnostic surfaces are compliant by
   construction**, and this record inventories them as the
   `VOX-SEC-006` evidence:
   - *Structured provenance warnings* (`VOX-ERR-005`) are coded
     values with schema versions, not free text.
   - *Dispatch telemetry* carries kernel tokens, entry points,
     sample counts and timings only; no image bytes, no metadata, no
     identifiers beyond registered token spellings, and no
     content-derived digests per the `ADR-0108` sensitivity
     boundary.
   - *Typed errors* are payload-free cases; decode failures in the
     metadata path deliberately redact incoming values and coding
     paths — the practiced value-redaction rule — so source text
     that may identify a patient never rides an error.
   - *Metadata privacy classes* exist precisely to support logging
     and export policy, with `potentiallyIdentifying` and
     `sensitive` distinguished from `technical`.
3. **Binding rules for any future logging component** — these bind
   the implementing increment whenever a consumer arc opens:
   - Emission is configurable and off by default; enabling it is a
     host decision, never a library default.
   - Log records are structured values with coded events, never
     interpolated free text.
   - Image bytes, metadata values classified `potentiallyIdentifying`,
     `sensitive` or `hostDefined`, and content-derived digests are
     excluded by default; inclusion requires the host to supply and
     permit it explicitly, mirroring `VOX-META-011`.
   - Source-object context travels as object identifiers and
     registered token spellings, never as source metadata text —
     the non-adapter half of `VOX-DCM-013`.
   - The component records its own decision record before first
     emission; no diagnostic channel appears incidentally inside
     another increment.

## Alternatives considered

A minimal typed diagnostic vocabulary now was rejected: without a
consumer its shape would be guessed, and a guessed vocabulary
becomes compatibility debt the moment the draw loop or adapter
arrives with real requirements. Treating absence alone as
satisfaction was rejected: absence is an accident until a record
states the rules that keep it true.

## Consequences

`VOX-SEC-006` holds by inventory, `VOX-ERR-007` and the non-adapter
half of `VOX-DCM-013` hold structurally with their future component
bound by recorded rules; the sweep's actionable queue is drained.

## Affected modules

Documentation only.

## Compatibility impact

None.

## Security impact

The default-exclusion rules any future logging component must obey
are now recorded rather than implicit.

## Performance and memory impact

None.

## Validation impact

None in this increment; the binding rules impose validation
obligations on the future component.

## Migration

None.

## Supersession

No record is superseded.

## References

- [ADR-0114 - Clinical pipeline assessments](ADR-0114-clinical-pipeline-assessments.md)
- [ADR-0121 - Window edge-case assessment](ADR-0121-window-edge-case-assessment.md)
- [ADR-0108 - Shader fingerprint evidence](ADR-0108-shader-fingerprint-evidence.md)
