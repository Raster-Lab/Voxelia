---
document_id: "ADR-0412"
title: "Five batch resolutions"
status: "Accepted"
date: "2026-08-08"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-SEG-010"
  - "VOX-EXT-006"
  - "VOX-PRR-014"
  - "VOX-EXT-007"
  - "VOX-VAL-015"
  - "VOX-PRR-017"
---

# ADR-0412 - Five batch resolutions

## Context

The owner directed (2026-08-08): "Answer 1-5 with your
recommendations" — adopting the loop's recommendations as the
decisions for five open batch items. Each is recorded with its
rationale; each was the conservative branch.

## Decision

1. **Segmentation reference AI adapter: boundary-only for 1.0**
   (closing the segmentation row's `R` half). No inference runtime
   enters the tree: the `ADR-0364` boundary is proven implementable by
   conformance, `CoreML`/`CreateML` stay gate-prohibited in every
   module, and a reference adapter is post-1.0 scope for when a real,
   clinically validated model exists. An adapter without a model would
   validate nothing.

2. **Validated-distribution semantics: this distribution only**
   (closing the diagnostic-selection row's `R` half). For 1.0, the
   built-in backend registrations are the one validated distribution;
   host approval remains the only other admission path. Broader
   semantics wait until a second distribution actually exists to
   define them against.

3. **Generative output: never in diagnostic presentation** (closing
   the generative-acceptance policy). Declared generative
   reconstruction is excluded from diagnostic presentation at 1.0;
   it is permissible only in explicitly non-diagnostic contexts with
   visible labelling. The declaration vocabulary (`ADR-0393`) makes
   the exclusion checkable.

4. **Runtime binary plug-ins: revisit post-1.0** (closing the
   introduction question without foreclosing it). `ADR-0403` stands
   as recorded — not introduced, future-bound to a versioned stable
   boundary — and nothing is permanently ruled out.

5. **Photorealistic validation and presets: accepted for 1.0 within
   the module's non-diagnostic status** (closing both `R` halves).
   The deterministic witnesses — seed-determined convergence,
   bit-equal reproducibility, pinned thin-structure contrast — are
   accepted as the 1.0 evidence; they re-run green on every suite
   execution. The preset under review is the recorded
   single-scattering preset with its omissions analysed
   (`ADR-0389`), and its acceptance is **bounded by decision 3 and
   the module's explicitly non-diagnostic status**: photorealistic
   output is presentation, never measurement.

## Alternatives considered

Each item's aggressive branch (build the adapter, widen distributions,
permit labelled generative output diagnostically, introduce plug-ins,
defer validation) was declined for the reasons above; any can be
reopened by the owner as new scope.

## Consequences

The owner batch shrinks to two items: the measurement campaigns (now
directed to run) and the 1.0 release session.

## Affected modules

None; documentation only.

## Compatibility impact

None.

## Security impact

Strengthened posture at every branch.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record and the ledger entry, then the benchmark campaign in
   the same session.

## Supersession

This record closes the batch halves of the records it cites.

## References

- [ADR-0364 - The AI adapter boundary](ADR-0364-the-ai-adapter-boundary.md)
- [ADR-0382 - The diagnostic selection guard](ADR-0382-the-diagnostic-selection-guard.md)
- [ADR-0393 - Declared post-processing](ADR-0393-declared-post-processing.md)
- [ADR-0403 - Runtime plug-ins not introduced](ADR-0403-runtime-plug-ins-not-introduced.md)
- [ADR-0396 - Photorealistic validation witnesses](ADR-0396-photorealistic-validation-witnesses.md)
