---
document_id: "ADR-0382"
title: "The diagnostic selection guard"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-EXT-006"
---

# ADR-0382 - The diagnostic selection guard

## Context

`VOX-EXT-006` (P0, `T,R`, M7): third-party implementations shall not be
selected for diagnostic policy unless explicitly approved by the host
or validated distribution. The registry now declares envelopes
(`ADR-0380`) and providers (`ADR-0381`); what is missing is the seam
where "registered" and "allowed for diagnosis" stop being the same
thing.

## Decision

1. **Approval is an explicit set, never an inference.**
   `DiagnosticApprovalSet` is built from two sources and nothing else:
   a **distribution-approved registry** (the validated distribution's
   own entries — for this distribution, the built-in backend
   registrations) and **host-approved references** the host adds
   deliberately. The key is the `DerivationImplementationReference` —
   identifier plus exact version — so approval never survives a version
   change silently.

2. **Provider names are not trust.** An entry claiming
   `provider: "Voxelia"` gains nothing: approval keys on the
   distribution's actual registry contents, not on a spoofable string.
   `ADR-0381`'s provider identity is provenance for the host's
   decision, not the decision.

3. **The seam is typed and total**: `DiagnosticSelection.
   requireDiagnostic(_:approvals:)` refuses an unapproved entry with
   `unapprovedThirdPartyImplementation`, and
   `implementationsForDiagnosticUse(in:approvals:)` filters a registry
   to the approved subset — the default posture is refusal, and an
   entry outside the set never appears in a diagnostic candidate list
   at all.

4. **The `R` half joins the owner batch**: what counts as a "validated
   distribution" beyond this project's own registrations, and the
   acceptance of this guard into the diagnostic execution policy, are
   owner decisions. Nothing here pre-empts them; the seam makes them
   enforceable when taken.

## Alternatives considered

### Trusting the provider identity

Rejected — decision 2. A string is not a chain of custody.

### An approval flag on the registration itself

Rejected. Self-declared approval is the prohibited shape; approval must
come from the host or distribution, outside the registrant's reach.

## Consequences

The extension arc's engineering closes: mechanism, contract, provenance
and guard all exist; the owner batch holds the arc's two `R` halves.

## Affected modules

`VoxeliaExecution` gains `DiagnosticSelection` and
`DiagnosticApprovalSet`.

## Compatibility impact

Additive only.

## Security impact

Strengthened: diagnostic selection defaults to refusal for anything
outside the explicit approval set.

## Performance and memory impact

`O(entries)` set construction, `O(1)` per check.

## Validation impact

```text
swift test --filter DiagnosticSelectionTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the seam, the witness suite and the register updates,
   in the same increment.
2. **Next**: the M7 queue's remaining open items are owner-reserved or
   awaiting the optimiser design; take the next unblocked row from the
   ledger.
3. **Owner**: validated-distribution semantics and diagnostic-policy
   acceptance, batched.

## Supersession

This record supersedes nothing.

## References

- [ADR-0380 - The registration declaration contract](ADR-0380-the-registration-declaration-contract.md)
- [ADR-0381 - Implementation provenance](ADR-0381-implementation-provenance.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
