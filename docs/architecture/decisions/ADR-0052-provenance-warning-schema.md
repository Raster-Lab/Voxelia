---
document_id: "ADR-0052"
title: "Provenance warning schema"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ERR-001"
  - "VOX-ERR-002"
  - "VOX-SEC-006"
  - "VOX-SEC-011"
---

# ADR-0052 - Provenance warning schema

## Context

Accepted `ADR-0038` rejects arbitrary warning text in the provenance
record because free strings can carry patient, path or host data, and
its record target names an undeclared `ProvenanceWarning` shape and
severity. The warning claim must be serialisable, bounded and
aggregatable without ever holding free text. This record was authored
and accepted on 2026-08-04 under the project owner's recorded
autonomous delegation.

## Decision

`VoxeliaCore` gains the closed provenance warning value shapes:

1. **`ProvenanceWarningCode`.** One bounded nominal code token with the
   lowercase ASCII reverse-domain grammar and byte-limit-before-grammar
   precedence (inclusive 255-byte total and 63-byte label ceilings, at
   least two labels), exact-byte identity. The code names a condition
   in a governed vocabulary; it is descriptive, never free text and
   never executable.
2. **`ProvenanceWarningSchemaVersion`.** The exact major/minor version
   of the vocabulary that defines the code, so a code's meaning is
   pinned to one published revision.
3. **`ProvenanceWarningSeverity`.** A closed frozen enum with exactly
   three cases: `informational` (asserts no output effect),
   `qualityAffecting` (asserts output quality was affected) and
   `integrityAffecting` (asserts the result may be unusable for its
   stated purpose). Any extension requires its own decision record.
4. **`ProvenanceWarning`.** The immutable aggregated claim binding one
   code, one schema version, one severity and a checked occurrence
   count of at least one, so repetition is counted, never repeated as
   entries. There is no message, reason, path or parameter field: free
   text is structurally impossible in the Core identity, and richer
   diagnostics belong to host-side rendering of the governed
   vocabulary.
5. **No wire.** The stable coding is owned by the future canonical
   provenance-record projection decision; no `Codable` is declared.

## Alternatives considered

An optional bounded free-text detail field was rejected: any free text
in an identity-bearing claim is a disclosure channel. Reusing
`MetadataSchemaReference` was rejected because its authority is the
metadata document schema. Per-occurrence warning entries were rejected
as unbounded repetition; the count aggregates exactly.

## Consequences

The `ADR-0038` record target gains its warning leg: bounded, private,
aggregated and pinned to governed vocabularies.

## Affected modules

`VoxeliaCore` only; no dependency change.

## Compatibility impact

Purely additive public surface; no wire exists yet.

## Security impact

No free text can enter a warning; codes are bounded validated ASCII
with payload-free typed rejection; diagnostics never disclose rejected
code text.

## Performance and memory impact

One bounded byte scan per code; warnings are small immutable values
whose aggregation bounds record growth.

## Validation impact

Tests must prove the code ceilings precede grammar, valid and invalid
codes classify exactly, a zero occurrence count is rejected typed,
every field participates in warning identity and errors stay
payload-free.

## Migration

Implemented in this increment.

## Supersession

This ADR implements the warning prerequisite of accepted `ADR-0038`
and supersedes nothing.

## References

- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0051 - Execution claim value shapes](ADR-0051-execution-claim-value-shapes.md)
