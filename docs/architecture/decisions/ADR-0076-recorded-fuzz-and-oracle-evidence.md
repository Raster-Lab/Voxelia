---
document_id: "ADR-0076"
title: "Recorded fuzz and differential oracle evidence"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-007"
  - "VOX-ERR-001"
  - "VOX-SEC-001"
---

# ADR-0076 - Recorded fuzz and differential oracle evidence

## Context

Accepted `ADR-0035` recorded fuzz corpora and external differential
oracles as open evidence gaps for the canonical codecs, and the strict
`VCPJ-1` and `VCDJ-1` ingresses have since joined that surface. Part
of that evidence is honestly producible on this host today with
deterministic tooling; part is not. This record was authored and
accepted on 2026-08-05 under the project owner's recorded broadened
autonomous delegation, and it records exactly which part is which.

## Decision

1. **Deterministic mutation campaign.** A seeded linear congruential
   generator drives hundreds of byte mutations — flips, insertions and
   deletions at generated positions — over each registered golden
   corpus document (the `VCMJ-1` empty envelope, both `VCPJ-1`
   goldens and both `VCDJ-1` goldens). The asserted invariant for
   every mutant: the ingress either rejects by throwing, or accepts a
   record whose canonical re-emission equals the mutant byte for byte
   — no crash, no hang within budgets, and no acceptance of a
   non-canonical document, ever. The campaign is fully deterministic
   and re-runs identically in every suite execution.
2. **Independent parser oracle.** For 256 deterministically generated
   finite binary64 values, the canonical number tokens emitted by the
   `VCMJ-1` formatter are fed to the host `python3` interpreter, whose
   independent `strtod`-based parser must round-trip every token to
   the bit-identical value; the Swift-side parser must do the same.
   This is a real cross-implementation round-trip oracle; the test
   depends on the host `python3`, which the Apple-only development
   platform provides.
3. **Honest remainder.** This evidence does not close the `ADR-0035`
   gaps, and must not be reported as if it did. Still open: external
   Ryu and V8 formatter oracles compared token-for-token; sustained
   corpus-guided random fuzzing at scale; the supported-device matrix;
   the universal raw ceiling; and the `VOX-ERR-001` allocation
   disposition.

## Alternatives considered

Random (unseeded) fuzzing in the suite was rejected: flaky evidence
is worse than none. Skipping the oracle when `python3` is absent was
rejected: a silently skipped oracle reads as passing evidence.

## Consequences

Every canonical ingress carries repeatable mutation-robustness
evidence, and the number formatter carries a real independent
round-trip oracle, with the remaining gaps stated rather than
implied closed.

## Affected modules

Test targets only; no product source changes.

## Compatibility impact

None.

## Security impact

The campaign exercises hostile-input paths deterministically; the
invariant proves the byte-equality gates hold under mutation.

## Performance and memory impact

Roughly two thousand bounded decodes and one subprocess invocation
per suite run.

## Validation impact

The increment is itself validation; its suites must pass with the
invariants stated above.

## Migration

Implemented in this increment.

## Supersession

This ADR narrows the recorded `ADR-0035` evidence gaps and supersedes
nothing.

## References

- [ADR-0035 - Versioned canonical metadata JSON and raw ingress boundary](ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md)
- [ADR-0061 - Strict canonical provenance ingress](ADR-0061-strict-provenance-ingress.md)
- [ADR-0073 - Strict canonical derivation ingress](ADR-0073-strict-derivation-ingress.md)
