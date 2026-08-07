---
document_id: "ADR-0370"
title: "The registration metric architecture"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-007"
---

# ADR-0370 - The registration metric architecture

## Context

`VOX-REG-007` (P1, `I,T`, M7): the architecture shall support mean-square
and mutual-information-class metrics. The `ADR-0366` result record
already *identifies* metrics; this row makes them *exist* — an
abstraction plus both founding classes, so the intensity-driven
portfolio members and the optimiser have something real to drive.

## Decision

1. **`RegistrationMetric` is a small protocol over aligned sample
   pairs**: an instance carries its configuration and declares its
   `RegistrationMetricID`, version and **polarity** (lower-is-better
   versus higher-is-better) — recorded structurally so no optimiser ever
   guesses a metric's direction. Evaluation returns a
   `RegistrationMetricEvaluation`: an **optional** value plus
   contributing and excluded counts — the `VOX-SEG-009` honesty rule
   again: a shrunken denominator is visible, and an empty contribution
   publishes absence, never zero.

2. **Sampling is the caller's seam**: metrics see paired binary64
   samples, not images. How a transform produces aligned pairs
   (interpolation, masking) belongs to the intensity-registration
   increment — the metric contract stays pure and exactly testable.

3. **Both founding classes are frozen** (`VOXELIA-ALG-0072`): mean
   squares as the frozen fold of squared differences;
   histogram mutual information over a caller-declared bin count and
   explicit per-side ranges — defaultless, since an assumed range is a
   silent rescale — with out-of-range and non-finite pairs excluded and
   counted. The logarithm carries the same platform-libm determinism
   contract the `VOXELIA-ALG-0060` Gaussian's exponential set.

4. **Identifiers**: `org.voxelia.metric.mean-squares` and
   `org.voxelia.metric.mutual-information`, version `1.0.0`, matching
   the `ADR-0366` record vocabulary.

## Alternatives considered

### Metrics over `ImageData` with internal resampling

Rejected. It would fold the interpolation decision into every metric and
make exact fixtures impossible; the seam belongs to the caller.

### Parzen-window mutual information

Rejected for the founding class. The histogram estimator is exactly
testable; a Parzen kernel adds a bandwidth knob the row does not demand.
The class vocabulary does not preclude adding it later.

## Consequences

The optimiser and intensity-driven members can be built against a real
metric contract; the result record's metric identities now name
implementations.

## Affected modules

`VoxeliaCore` gains the protocol, both metrics and their error family.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(N)` per evaluation; the joint histogram is `O(B²)` memory.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0370-registration-metrics-oracle.py
swift test --filter RegistrationMetricTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0072`, the protocol, both metrics, the
   fixture suite and the register updates, in the same increment.
2. **Next**: the remaining registration rows per the `ADR-0351` order.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0072 - Registration metrics](../../algorithms/VOXELIA-ALG-0072-registration-metrics.md)
- [ADR-0366 - The registration result record](ADR-0366-the-registration-result-record.md)
- [ADR-0369 - Landmark rigid registration](ADR-0369-landmark-rigid-registration.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
