---
document_id: "VOXELIA-ALG-0079"
title: "Deterministic sample sequence v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Project"
---

# Deterministic sample sequence v1

## Purpose

`VOX-PRR-010` — deterministic random seeds for the reference mode: the
same declared seed produces the same sample sequence on every run and
every platform. The model is `deterministic-sequence/v1`; `ADR-0390`
records the design.

## The rule

The generator is **SplitMix64** over exact wrapping 64-bit integer
arithmetic:

- The state advances by the constant `0x9E3779B97F4A7C15`; the output
  word mixes the state with the standard shift-xor-multiply constants
  `0xBF58476D1CE4E5B9` and `0x94D049BB133111EB` and the shifts
  `30, 27, 31`.
- **A unit sample** is the word's top 53 bits scaled by `2⁻⁵³` — exact
  binary64 by construction, in `[0, 1)`.
- The seed is caller-declared and defaultless; sequences with the same
  seed are identical, word for word.

## Determinism and failure classification

Integer arithmetic is exact; there is no rounding anywhere in the
generator and no failure case — every 64-bit seed is valid.

## Conformance fixtures

Computed by
`docs/progress/evidence/ADR-0390-deterministic-sequence-oracle.py`.

- Seed `0`: words `0xE220A8397B1DCDAF, 0x6E789E6AA1B965F4,
  0x06C45D188009454F, 0xF88BB8A8724C81EC`.
- Seed `0xDEADBEEF`: words `0x4ADFB90F68C9EB9B, 0xDE586A3141A10922,
  0x021FBC2F8E1CFC1D, 0x7466CE737BE16790`.
- Seed `42` units: `0x1.7bae644c5fd6dp-1, 0x1.477f199d93378p-3,
  0x1.1d499d5c4c3e6p-2`.

## Validation obligations

The implementing increment must reproduce every fixture exactly and
verify that equal seeds give equal sequences.

## References

- [ADR-0390 - Deterministic reference seeds](../architecture/decisions/ADR-0390-deterministic-reference-seeds.md)
