---
document_id: "ADR-0226"
title: "DICOM ingest arc"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-001"
  - "VOX-DCM-002"
  - "VOX-DCM-004"
  - "VOX-DCM-007"
  - "VOX-DCM-009"
  - "VOX-VS1-001"
  - "VOX-VS1-002"
  - "VOX-VS1-003"
  - "VOX-VS1-004"
  - "VOX-LIC-004"
  - "VOX-LIC-007"
  - "VOX-LIC-008"
  - "VOX-LIC-009"
  - "VOX-REP-009"
---

# ADR-0226 - DICOM ingest arc

## Context

`ADR-0225` closed the pipeline sweep by recording that the autonomous queue was
drained to its gates, and named three owner decisions as the only things that
could unblock substantive work. The project owner has now given one:

> "yes proceed with DICOMKit"

That releases the standing gate on the DICOMKit dependency, which has blocked
`VOX-DCM-001` through `VOX-DCM-012` and the ingest half of the first vertical
slice since the beginning.

This record opens the arc. It decides the decomposition and the binding rules
only, in the shape `ADR-0183`, `ADR-0197` and `ADR-0208` used.

## The finding that shapes the whole arc

**Most of this work does not need the dependency.**

The First Vertical Slice Plan already divides ownership precisely. DICOMKit owns
parsing, dataset access, transfer-syntax interpretation, frame extraction,
encapsulated pixel-data access, metadata value decoding and DICOM-specific
errors. **Voxelia owns** conversion into neutral frame records, series grouping,
geometry validation and volume construction.

The plan's proposed `CTFrameRecord` is deliberately **neutral**: it names no
DICOMKit type. Everything downstream of it — series assembly, irregular-geometry
rejection, affine volume construction — is Voxelia's own code, testable against
synthetic frame records, and needs no dependency at all.

So the arc's substance is Voxelia's own code, and the DICOMKit-facing part is a
thin shim at one end of it. That shape held even while the dependency was still
gated, and it is why four of the five increments could have proceeded either
way.

## The dependency's three facts, verified from the source

`ADR-0219` established that four accepted requirements — `VOX-LIC-007`,
`VOX-LIC-008`, `VOX-LIC-009` and `VOX-REP-009` — hold today for exactly one
reason: `Package.swift` declares `dependencies: []`. It also added
`check_licence_policy.py`, whose dependency gate **fails** when that changes,
with a message naming those four requirements.

Adding the dependency needs three facts, and this project recorded **none** of
them. The owner supplied the identity — "DICOMKit belongs to me, see the
repository, it's the same as ours" — and the remaining two were then **read from
the repository rather than assumed**:

| Fact | Value | How established |
|---|---|---|
| Identity | `https://github.com/Raster-Lab/DICOMKit` | Owner statement, confirmed public |
| Version | `v2.2.11`, published 2026-07-20 | Latest release on that repository |
| Licence | **MIT** | The repository's own licence metadata |

Its products are `DICOMKit`, `DICOMCore` and `DICOMDictionary`.

**MIT settles the licence requirements rather than merely permitting them to be
argued.** It is permissive, so `VOX-LIC-007` (no strong copyleft in core
distribution targets) is satisfied outright; `VOX-LIC-009` (compatibility with
static linking) is satisfied for the same reason; and `VOX-LIC-008`'s isolation
requirement, which exists for *restrictive* licences, is not triggered — though
the optional-module isolation still happens, because `VOX-DCM-002` requires it
independently. `VOX-LIC-004` obliges a `THIRD_PARTY_NOTICES.md` entry, which
increment (e) adds.

**None of this was guessed.** Had the licence come back copyleft, the arc's
shape would have changed, which is precisely why it was checked before being
relied upon.

## Decision

1. **This record opens the arc and decides its decomposition and binding rules
   only.** It adds no dependency, changes no manifest, and freezes no numeric
   boundary. Each increment below carries its own accepted record, and any that
   fixes a numeric boundary carries an algorithm specification with an
   independent Python oracle before implementation.
2. **The decomposition, unblocked work first:**
   - **(a) The neutral frame-record vocabulary.** Voxelia-owned, naming no
     DICOMKit type. Unblocked.
   - **(b) Series grouping** (`VOX-VS1-002`, `VOX-DCM-004`). Unblocked.
   - **(c) Irregular-geometry rejection** (`VOX-VS1-003`, `VOX-DCM-009`).
     Unblocked, and the arc's hardest numeric boundary.
   - **(d) Affine volume construction in patient space** (`VOX-VS1-004`,
     `VOX-DCM-007`). Unblocked.
   - **(e) The DICOMKit-facing shim and the manifest change**
     (`VOX-DCM-001`, `VOX-DCM-002`, `VOX-VS1-001`). **Unblocked**, and
     deliberately **last** — see decision 9.
3. **The neutral record uses the accepted spatial vocabulary, not bare
   vectors.** The plan sketches `SIMD3<Double>` for directions and positions;
   this arc uses `Point3D` and `Vector3D`, because those carry a
   `CoordinateSpaceID` and the entire purpose of increment (c) is deciding
   whether frames share a frame of reference. A bare triple cannot express the
   thing being validated. The plan says of its own sketch that it is "a planning
   contract, not a final public API", so this is a permitted refinement rather
   than a contradiction.
4. **`VoxeliaDICOMKit` is an optional module and never a core dependency.**
   `VOX-DCM-002` requires it directly. `VOX-LIC-008`'s isolation rule is not
   triggered, because MIT is not restrictive — the isolation happens anyway, and
   it keeps a third-party package out of every core build. No existing module
   gains a dependency on it.
5. **`VOX-DCM-001`'s substance is a prohibition and is honoured by
   construction**: Voxelia implements no second general DICOM parser. Increments
   (a) through (d) parse nothing — they consume frame records that something
   else produced.
6. **Irregular geometry is rejected, and the tolerance question is the
   increment's whole content, not a footnote.** `ADR-0215` established exact
   equality for registration; real scanner geometry does not arrive exact. Which
   of position, orientation and spacing admits a tolerance, what that tolerance
   is, and where it comes from, are decided in increment (c) with an oracle —
   **not assumed here**.
7. **Warning versus rejection is decided per case, on evidence.**
   `VOX-VS1-003` says "reject or clearly warn"; the accepted provenance model
   already carries a warning schema (`ADR-0052`). Which irregularities are
   representable-with-a-warning and which are not is increment (c)'s finding.
8. **The gate is updated in the same increment that adds the dependency**, with
   the licence recorded and `THIRD_PARTY_NOTICES.md` updated — never before, and
   never by relaxing the check. `check_licence_policy.py` will need to admit
   exactly one declared dependency instead of none, and its failure message
   must keep naming the four requirements it protects.
9. **Increment (e) stays last even though it is unblocked.** `VOX-REP-009`
   requires external dependencies to be attached only to the targets that need
   them, and until increments (a) through (d) exist, **no target needs
   DICOMKit**. Adding it first would introduce an unused dependency and put a
   third-party package in the build before anything consumed it.

## Alternatives considered

### Add the dependency on the owner's word without checking the licence

Rejected, and then made moot by checking. "Proceed with DICOMKit" authorises the
direction; it does not state a licence, and the four licence requirements cannot
be discharged against an unknown one. The repository was read instead of
assumed. It happens to be MIT, which is the easy outcome — but the check was
what made it a finding rather than a hope.

### Add the dependency now, before anything needs it

Rejected; see decision 9.

### Wait for the three facts before doing anything

Rejected. It would idle the arc's large unblocked majority behind its small
blocked minority, and the owner's decision was to proceed.

### Use the plan's `SIMD3<Double>` sketch verbatim

Rejected; see decision 3.

### Let `VoxeliaCore` or `VoxeliaImaging` depend on `VoxeliaDICOMKit`

Rejected; see decision 4. It would make an optional adapter a core dependency
and put a third-party licence in the path of every build.

### Decide the geometry tolerance here

Rejected; see decision 6. It is the arc's hardest numeric question and deserves
its own record, oracle and fixtures.

## Consequences

All five increments are unblocked. The fifth is sequenced last so that the
dependency arrives when a target actually needs it, rather than sitting unused
in the manifest.

`VOX-VS1-002`, `003` and `004` — recorded as dependency-blocked by `ADR-0217` —
turn out to be blocked only in their ingest framing; their substance is
unblocked and is this arc's first work.

## Affected modules

Documentation only in this increment. Later increments add `VoxeliaDICOMKit` as
an optional module; no existing module's dependencies change.

## Compatibility impact

None in this arc-opening increment.

## Security impact

None here. Increment (e) crosses the supply-chain boundary and carries its own
licence, provenance and notice obligations.

## Performance and memory impact

None in this arc-opening increment.

## Validation impact

Documentation, register, index, link, manifest and release-integrity checks
only. No oracle, because this record freezes no numeric boundary.

## Migration

1. Increment (a): the neutral frame-record vocabulary.
2. Increments (b) through (d) in the recorded order.
3. Increment (e): the optional `VoxeliaDICOMKit` module, the manifest
   dependency on `https://github.com/Raster-Lab/DICOMKit` at `v2.2.11`, the
   `THIRD_PARTY_NOTICES.md` entry recording its MIT licence, and the
   corresponding update to `check_licence_policy.py`.

## Supersession

This record opens a new arc and supersedes no accepted record. It composes the
First Vertical Slice Plan's ownership split rather than restating it.

## References

- [ADR-0052 - Provenance warning schema](ADR-0052-provenance-warning-schema.md)
- [ADR-0183 - Geometry arc](ADR-0183-geometry-arc.md)
- [ADR-0215 - Multi-volume fusion assessment](ADR-0215-multi-volume-fusion-assessment.md)
- [ADR-0217 - Vertical slice traceability](ADR-0217-vertical-slice-traceability.md)
- [ADR-0219 - Governance and licence traceability](ADR-0219-governance-and-licence-traceability.md)
- [ADR-0225 - Unrun pipeline sweep conclusion](ADR-0225-unrun-pipeline-sweep-conclusion.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
