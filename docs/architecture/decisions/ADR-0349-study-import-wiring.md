---
document_id: "ADR-0349"
title: "Study import wiring"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-VS1-010"
  - "VOX-MPR-011"
---

# ADR-0349 - Study import wiring

## Context

The release packet's one recorded engineering remainder: the reference
application demonstrates on a synthetic phantom, and the owner may want the
Demonstrations on a real study. Every piece exists — `DICOMFrameSource` was
built for exactly this composition, `CTImportSession` takes its closures, the
owner's real series is proven to import under the `exact` tolerance, and
`CTImportedVolume.image` publishes directly.

## Decision

1. **The application gains a study mode**: launched with a directory argument
   (`swift run VoxeliaCTReference /path/to/series`), it imports through
   `CTImportSession` with `DICOMFrameSource`'s closures under the **`exact`
   geometry tolerance** — the accepted conservative posture, and the one the
   owner's own series passed — publishes the imported volume, and views it
   through the multiplanar path at full quality with an adaptive slice range.
   Without the argument, the phantom mode is unchanged.

2. **Study mode is full-resolution viewing, and the bound is recorded**: the
   level and refinement demonstrations run on the phantom, because
   `LevelSelectOperation` admits the sampler's `uint8` domain and a CT study
   carries wider stored values. Widening the sampler's value domain is that
   operation family's own future decision (`ADR-0343` decision 7 precedent);
   wiring a workaround here would fork the domain question inside an example.

3. **The demonstration window is a fixed demo default** (centre 1024, width
   4096 over stored values), recorded as the application's choice; window
   controls are host UI the demonstrations do not require.

4. **This closes the engineering queue.** Every M0-M6 row is discharged,
   characterised or measured; the vehicle demonstrates on phantom and study;
   what remains is the owner's session from the release packet.

## Alternatives considered

### Widen the level path to serve the study interactively

Rejected here; see decision 2. A value-domain widening is a designed change to
a frozen operation family, not an example-app patch.

## Consequences

The loop's engineering queue is empty; per `ADR-0338` decision 10 the loop
stops and the release packet goes to the owner.

## Affected modules

The example application only; it gains a `VoxeliaDICOMKit` dependency.

## Compatibility impact

None.

## Security impact

The application reads the caller-supplied directory, skipping inadmissible
files through the source's own refusal path; nothing else external.

## Performance and memory impact

Import cost is the accepted session's; the measured 899-frame figure stands.

## Validation impact

```text
cd Examples/VoxeliaCTReference && swift build
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The app builds clean; the import path is the accepted session under its own
suite evidence. The full suite must show the literal pass line before push.

## Migration

1. This record with the wiring.
2. **Owner**: the release session, from `docs/releases/v0.2.0/README.md`.

## Supersession

This record supersedes nothing. It completes `ADR-0347`'s deferred wiring and
`ADR-0348`'s recorded remainder.

## References

- [ADR-0347 - The reference application](ADR-0347-the-reference-application.md)
- [ADR-0348 - Release readiness](ADR-0348-release-readiness.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
