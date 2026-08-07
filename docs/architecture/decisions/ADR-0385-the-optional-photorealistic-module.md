---
document_id: "ADR-0385"
title: "The optional photorealistic module"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PRR-001"
  - "VOX-PRR-002"
  - "VOX-PRR-003"
---

# ADR-0385 - The optional photorealistic module

## Context

The `ADR-0384` queue's first arc: photorealistic rendering shall be an
optional module (`I,T`), disableable without disabling conventional
diagnostic rendering (`T,D`), with interactive, progressive and
reference quality modes (`I,T`). Everything later in M8 registers into
this module, so its boundary decisions come first.

## Decision

1. **`VoxeliaPhotorealistic` is its own library product**, depending on
   `VoxeliaCore` only for now — the physics arc will add what it
   actually needs when it needs it. **The umbrella `Voxelia` product
   does not re-export it**: optionality is structural (a host that does
   not link the product has no photorealistic code at all), which also
   honours the M10 umbrella row's direction early rather than
   contradicting it now.

2. **Disable-independence is a typed runtime seam on top of the
   structural one**: `PhotorealisticActivation` is a closed two-case
   vocabulary (`enabled` / `disabledByHost`), and
   `PhotorealisticGate.requireEnabled` refuses typed when the host has
   disabled the module. Conventional rendering lives in
   `VoxeliaRendering`, which this module does not touch and which does
   not know this module exists — disabling photorealistic rendering
   cannot reach it, by construction, and the witness demonstrates the
   refusal while the conventional path's own tests keep passing
   unchanged.

3. **The quality modes are a closed defaultless vocabulary**:
   `interactive`, `progressive`, `reference` — the `VOX-PRR-003` triad
   verbatim, no default case, no "auto" mode inventing a fourth
   semantics. Each mode's numeric behaviour (seeds, convergence,
   accumulation) belongs to the arcs that build it; the vocabulary
   deliberately carries no knobs yet.

## Alternatives considered

### Photorealistic features inside `VoxeliaRendering` behind a flag

Rejected. A flag is optionality by promise; a separate product is
optionality by construction, and the disable row's `T` becomes trivial
to witness honestly.

### An `automatic` quality mode

Rejected. A library guess about quality is a hidden clinical decision;
hosts select modes explicitly.

## Consequences

The physics arc has a module to build into; the M9 headless and
distributed rows will find the module boundary already drawn.

## Affected modules

New target `VoxeliaPhotorealistic` (+ its test target); `Package.swift`
gains the product; the umbrella is unchanged by design.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

None; vocabulary only.

## Validation impact

```text
swift test --filter PhotorealisticFoundationTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the target, the vocabulary, the witness suite, the
   module note and the register updates, in the same increment.
2. **Next**: the physics core arc, first optical model design-first.

## Supersession

This record supersedes nothing.

## References

- [ADR-0384 - The M8 queue](ADR-0384-the-m8-queue.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
