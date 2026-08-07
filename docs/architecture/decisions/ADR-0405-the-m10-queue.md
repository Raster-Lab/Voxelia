---
document_id: "ADR-0405"
title: "The M10 queue"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-API-012"
  - "VOX-DOC-004"
  - "VOX-DOC-012"
  - "VOX-ERR-008"
  - "VOX-ERR-009"
  - "VOX-PER-010"
  - "VOX-PER-011"
  - "VOX-PER-012"
  - "VOX-REL-003"
  - "VOX-REL-004"
  - "VOX-REL-006"
  - "VOX-REL-007"
  - "VOX-REL-008"
  - "VOX-REL-009"
  - "VOX-REL-010"
  - "VOX-REP-007"
  - "VOX-SEC-008"
  - "VOX-SEC-009"
---

# ADR-0405 - The M10 queue

## Context

M7 through M9 are engineering-complete. M10 is the publication
baseline — the final eighteen rows, and with this record they all
become traced: **the debt baseline empties**, and what remains is
discharge tracked by the ledger. The rows are largely `I,R`: records
and policies whose acceptance halves land in the owner's release
session. The queue is derived once, in the standing pattern.

## Decision

The M10 rows order into three arcs:

1. **Umbrella and module documentation** — the umbrella re-export row
   (witnessable structurally: the `Voxelia` product already re-exports
   exactly the eight stable modules and none of the optional
   integrations, which `ADR-0385` deliberately preserved) and the
   module-overview row (audit and complete
   `docs/architecture/modules/` so every public module states purpose,
   dependencies, supported platforms and diagnostic status).

2. **Instrumentation and benchmark reporting** — the instrumentation
   overhead row (analysis plus witness over the existing telemetry
   seams), the benchmark report-content rows (a validated, `Codable`
   benchmark record carrying the baseline's required fields — the
   report *schema* is the engineering half; the multi-mode measurement
   campaign is release evidence for the owner's session), and the
   regression-threshold row (the check seam; approval thresholds are
   the owner's).

3. **Release policy records** — the thirteen `I,R` rows: semantic
   versioning after 1.0, deprecation before removal, diagnostic-change
   release-note and validation-evidence requirements, the
   supported-platform matrix, published test/benchmark/validation
   status, known limitations by operation/format/platform, dependency
   inventory and vulnerability monitoring, reproducibility and
   toolchain recording, and source-package compatibility before any
   binary ABI commitment. Much substance exists (`prepare-release.sh`,
   the SBOM, `RELEASE.json`, the security docs); the arc consolidates
   the policies into release documentation the owner's session
   accepts. **The `R` halves are the release session itself** — when
   the arcs' engineering halves are done, the queue is exhausted and
   the loop stops with the full owner batch surfaced.

## Alternatives considered

### Deferring the policy records to the owner entirely

Rejected. Writing the policy is the loop's work; accepting it is the
owner's. Empty-handed sessions waste the owner's time.

## Consequences

The loop takes arc 1 first. The traceability baseline is empty from
this record forward — every remaining fact is in the ledger.

## Affected modules

Planning only.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

Each arc's increments carry their own verification.

## Migration

1. This record, then arc 1.

## Supersession

This record completes the `ADR-0351`/`ADR-0384`/`ADR-0397` queue
series.

## References

- [ADR-0397 - The M9 queue](ADR-0397-the-m9-queue.md)
- [ADR-0404 - Apple adapter seams and energy](ADR-0404-apple-adapter-seams-and-energy.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
