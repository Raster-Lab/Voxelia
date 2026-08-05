---
document_id: "ADR-0108"
title: "Shader fingerprint evidence"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-010"
  - "VOX-DOC-007"
---

# ADR-0108 - Shader fingerprint evidence

## Context

`VOX-VAL-010` requires validation reports to identify source and
compiled shader fingerprints for GPU-tested behaviour, while the
`ADR-0036` sensitivity rule rejects treating digests as safe to log.
The two must be reconciled before evidence lines may carry
fingerprints. This record was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **The sensitivity boundary.** The `ADR-0036` rule protects
   content-derived digests — its recorded rationale is equality and
   dictionary attacks against potentially sensitive canonical
   content. A shader-source fingerprint is the digest of Voxelia's
   own public repository text, already committed in the shader
   manifest, the pinned-digest suite and the decision record; no
   sensitive content exists behind it, so the rule does not cover it.
   This boundary interpretation extends `ADR-0036` without weakening
   it: content-derived digests stay out of names, logs and URLs.
2. **Source fingerprints in evidence.** The GPU differential
   harnesses identify the exercised source fingerprint in their
   printed evidence lines, so a recorded measurement binds to the
   exact shader text it measured.
3. **Compiled fingerprints honestly open.** Runtime source
   compilation produces no stable compiled artefact — the pipeline
   state is in-memory and device-and-driver dependent — so a
   compiled-shader fingerprint does not exist to report; it arrives
   with the already-gated `metallib` distribution work, and claiming
   one today would be fabricated evidence.

## Alternatives considered

Abbreviating fingerprints in evidence was rejected: an abbreviated
fingerprint identifies nothing exactly. Extending the sensitivity
rule to build fingerprints was rejected: it would forbid what the
manifest already publishes.

## Consequences

`VOX-VAL-010` is discharged for the source fingerprint with the
compiled fingerprint recorded open; GPU evidence lines are now
self-identifying.

## Affected modules

Test evidence only; no source change.

## Compatibility impact

None.

## Security impact

Content-derived digests remain protected; only public-source build
fingerprints appear in evidence.

## Performance and memory impact

None.

## Validation impact

The GPU differential evidence lines must carry the pinned source
fingerprint of the measured kernel family.

## Migration

Implemented in this increment.

## Supersession

Interprets the `ADR-0036` boundary for build fingerprints; no record
is superseded.

## References

- [ADR-0036 - Domain-separated complete canonical metadata record identity](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [ADR-0080 - Window-level Metal kernel](ADR-0080-window-level-metal-kernel.md)
