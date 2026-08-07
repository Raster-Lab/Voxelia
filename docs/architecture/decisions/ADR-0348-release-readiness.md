---
document_id: "ADR-0348"
title: "Release readiness"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-002"
  - "VOX-REP-005"
---

# ADR-0348 - Release readiness

## Context

Every M0-M6 engineering row is discharged, characterised or measured, the
demonstration vehicle exists, and `ADR-0338` decision 11 defines what
"complete" means for this series: the owner's witnessed Demonstrations and
approved Reviews at release, and a tagged release from the existing tooling.
What remains is assembly: the changelog has said "None" through five hundred
commits, no release-candidate structure exists for this series, and the
owner's session has no consolidated packet to run from.

## Decision

1. **The release is `v0.2.0`, cut by the owner, after the session.** No tag
   exists in the repository; `v0.1.1` was a documentation release. `VERSION`
   stays `0.1.1` until the owner's session concludes — a bumped version before
   the witnessing would claim a release that has not happened.

2. **The changelog's `Unreleased` section is compiled now**, by area, from the
   decision register and ledger — the release's content summary is engineering
   work, not ceremony, and doing it at tag time would compress five hundred
   commits into haste.

3. **`docs/releases/v0.2.0/README.md` is the owner's release packet**: the
   eight Demonstrations with run instructions and what to observe, the pending
   Reviews with their document paths, the `VOX-PER-004` target standing
   surfaced as its own acceptance item, the two Raster-Lab licence actions,
   and the tag steps (`prepare-release.sh`, `VERSION`, tag) in order. One
   document, so the session is turnkey.

4. **One engineering item remains and is recorded, not hidden**: wiring
   `CTImportSession` directory import into the reference application, so the
   Demonstrations can run on a real study as well as the phantom. It is the
   next increment; nothing in the packet depends on it except the owner's
   choice of demonstration data.

## Alternatives considered

### Bump the version and tag now

Rejected; see decision 1. The Demonstrations and Reviews are constitutive of
this release's definition of complete, not decorations after it.

### Fold the packet into the validation report

Rejected. The reports are evidence; the packet is an agenda. Mixing them
would put session logistics inside documents the owner is meant to review as
evidence.

## Consequences

The owner can run the release session from one document, and the tag steps
are mechanical once it concludes.

## Affected modules

None. Documentation and release structure only.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
swift test
```

1289 tests in 225 suites pass, unchanged — this record adds no code.

## Migration

1. This record, the changelog compilation and the release packet.
2. **Next**: DICOM import wiring in the reference application — the final
   engineering increment.
3. **Owner**: the release session, from the packet.

## Supersession

This record supersedes nothing. It executes `ADR-0338` decision 11's release
definition.

## References

- [ADR-0338 - The owner decision batch](ADR-0338-the-owner-decision-batch.md)
- [ADR-0346 - Frame rate measured](ADR-0346-frame-rate-measured.md)
- [ADR-0347 - The reference application](ADR-0347-the-reference-application.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
