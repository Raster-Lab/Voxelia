---
document_id: "ADR-0380"
title: "The registration declaration contract"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-EXT-003"
---

# ADR-0380 - The registration declaration contract

## Context

`VOX-EXT-003` (P0, `I,T`, M7): implementation registration shall declare
operation ID, implementation ID, versions, supported ranks, formats,
geometry, quality profiles and capability requirements. The `ADR-0134`
registration already declares identities, versions, backend, precision
and evidence; the envelope fields are absent. Surveying all thirty-two
built-in registrations exposed the design's real constraint: **the
entries are heterogeneous** — mesh operations have no image rank or
format at all, several axis operations accept any rank, and only the
volume operations require calibrated geometry.

## Decision

1. **`DeclaredImplementationContract` is the envelope declaration**,
   required on every `RegisteredImplementation` — defaultless, so every
   registration states its envelope or does not register. It carries a
   sample domain, quality profiles and capability requirements.

2. **The domain is a closed two-case vocabulary**:
   `image(ranks:scalars:geometry:)` and `triangleMesh`. Forcing mesh
   operations to fake image envelopes was the alternative, and it is
   exactly the kind of lie the registry exists to prevent. Image
   envelopes use small closed vocabularies with an honest `any`:
   `DeclaredRankSupport` (`any` / validated `range`),
   `DeclaredScalarSupport` (`any` / non-empty unique `scalars`),
   `DeclaredGeometrySupport` (`any` / `requiresAffine`).

3. **The declaration is selection metadata; the operation's own
   admission stays authoritative.** A declaration wider than the
   admission cannot admit anything the operation would refuse — every
   execution still passes the typed admission. The built-in envelopes
   below were derived by reading each operation's admission, not by
   guessing.

4. **Quality profiles are non-empty token lists** (the built-ins all
   declare `org.voxelia.quality.full`); **capability requirements may
   be empty** — most implementations require none — but must be unique
   when present.

5. **All thirty-two built-in entries migrate in this increment**, each
   with the envelope its admission enforces: the `ADR-0352`-domain
   operations declare rank `2...3` over the four stored scalars; the
   mask/label family declares its narrower scalars; the volume
   operations declare rank `3...3`, `uint8` and `requiresAffine`; the
   axis and region operations declare honest `any`; the surface
   extractions declare their nine scalars and affine requirement; the
   three mesh operations declare `triangleMesh`.

## Alternatives considered

### Optional envelope fields

Rejected. An optional declaration is a declaration nobody makes; the
row says "shall declare".

### A single image-shaped contract with sentinel values for mesh ops

Rejected — decision 2.

### Deriving envelopes from operations at runtime

Rejected. The registration is data a host can inspect without loading
operation code; a derived declaration would also invert the authority
order of decision 3.

## Consequences

Hosts and planners can inspect an implementation's envelope before
selection; third-party registrations must state theirs.

## Affected modules

`VoxeliaExecution` gains the contract vocabulary;
`VoxeliaCPU`/`VoxeliaMetal` registrations migrate; the extension
witness updates.

## Compatibility impact

Source-breaking for `RegisteredImplementation` constructors — the new
field is required by design. All in-tree constructors migrate here.

## Security impact

None beyond typed admission.

## Performance and memory impact

Negligible.

## Validation impact

```text
swift test --filter ImplementationContractTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the vocabulary, the thirty-two migrations, the witness
   update, the fixture suite and the register updates, in the same
   increment.
2. **Next**: the third-party provenance row, then the diagnostic guard.

## Supersession

This record extends `ADR-0134`'s registration value; the registry's
collision rule is unchanged.

## References

- [ADR-0134 - Implementation registration](ADR-0134-implementation-registration.md)
- [ADR-0379 - The source-package extension mechanism](ADR-0379-the-source-package-extension-mechanism.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
