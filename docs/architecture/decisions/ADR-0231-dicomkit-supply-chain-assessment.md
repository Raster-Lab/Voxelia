---
document_id: "ADR-0231"
title: "DICOMKit supply-chain assessment"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CMP-001"
  - "VOX-DCM-001"
  - "VOX-DCM-002"
  - "VOX-VS1-001"
  - "VOX-LIC-004"
  - "VOX-LIC-007"
  - "VOX-LIC-008"
  - "VOX-LIC-009"
  - "VOX-REP-009"
---

# ADR-0231 - DICOMKit supply-chain assessment

## Context

This record opens increment (e) of the `ADR-0226` arc — the DICOMKit shim and
the manifest change that closes the arc. `ADR-0226` recorded increment (e) as
**unblocked**, sequenced last only so that the dependency would arrive when a
target actually needed it.

Design-first meant reading the dependency's manifest before changing ours. That
read found something `ADR-0226` did not know, and it changes the increment.

## The finding: DICOMKit is not a leaf dependency

`ADR-0226` verified three facts about DICOMKit — identity, version `v2.2.11`,
licence MIT — and treated it as a single package. Its manifest at that tag
declares **five external package dependencies of its own**:

| Transitive package | Pinned by DICOMKit | Licence | How established |
|---|---|---|---|
| `apple/swift-argument-parser` | from `1.8.2` | **Apache-2.0** | `LICENSE.txt` read |
| `Raster-Lab/J2KSwift` | from `11.0.2` | **MIT** | `LICENSE` read |
| `Raster-Lab/JLSwift` | from `0.9.0` | **none found** | see below |
| `Raster-Lab/JLISwift` | from `0.5.0` | **Apache-2.0** | `LICENSE` read |
| `Raster-Lab/JXLSwift` | from `1.4.0` | **MIT** | `LICENSE` read |

A sixth, `awslabs/aws-sdk-swift`, is present but commented out in DICOMKit's
manifest and so is not part of the graph.

Every licence above was read from the repository's own licence file, not from
GitHub's detected-licence field, which reported "none" for **all five** and was
wrong for four of them. The detector is not evidence.

**SwiftPM resolves a dependency's whole package graph.** There is no way to
depend on DICOMKit and not acquire these five. So this increment is not "add one
MIT package"; it is "add six packages, of which four are codec libraries".

## Blocker one: this crosses the standing codec gate

`J2KSwift`, `JLSwift`, `JLISwift` and `JXLSwift` are the **Raster-Lab codec
libraries**, which are the subject of the standing owner gate `VOX-CMP-001` —
recorded through this whole session as an owner decision not to be attempted
without engagement, and named alongside DICOMKit as one of the two supply-chain
questions awaiting an answer.

The owner released **one** of those two gates. "Yes proceed with DICOMKit" is an
answer about DICOMKit; the codec libraries are a separate question that has been
tracked separately since before this session. Adding them as a side effect of the
approved decision would answer the second question by implication, using
authority that was granted for the first.

**That is not a judgement this record may make**, and the fact that they are the
owner's own repositories does not change it: `ADR-0226` established that even for
an owner-owned dependency the facts get verified rather than assumed, and the
same discipline applies to which dependencies enter the build.

## Blocker two: one transitive dependency has no licence at all

`Raster-Lab/JLSwift` at `v0.9.0` has **no licence file** — no `LICENSE`,
`LICENSE.txt`, `COPYING` or `NOTICE` in its repository root — and **no licence
statement in its README**. Its licence is therefore undetermined.

This is not a paperwork detail. `VOX-LIC-007` forbids strong copyleft in core
distribution targets, `VOX-LIC-009` requires compatibility with static linking,
and `VOX-LIC-004` obliges a notice entry. **None of the three can be discharged
against an undetermined licence**, and an unlicensed package that is
redistributed is, by default, all rights reserved. `check_licence_policy.py`
exists to make exactly this failure loud.

It is also the cheapest of all these problems to fix: adding a licence file to a
repository the owner controls resolves it outright.

## Decision

1. **Increment (e) is split, and only its unblocked half proceeds.**
   - **(e1) The Voxelia-owned direct-write addressing contract** — `CTFrameRecord`
     and the volume sample layout that makes direct-write possible. Names no
     DICOMKit type, needs no dependency, and is the mechanism the plan's §16.1
     requires for transfer "without unnecessary intermediate copies". **Unblocked
     and proceeding.**
   - **(e2) The manifest dependency, the shim, the licence-gate update and the
     notices entry.** **Blocked** on the two decisions above.
2. **`Package.swift` is not touched, `check_licence_policy.py` is not relaxed,
   and `THIRD_PARTY_NOTICES.md` gains no entry.** The dependency gate stays green
   because it is still true: this repository declares no external dependency.
   Making it pass by editing it, in an increment that could not discharge the
   requirements it protects, is the precise failure `ADR-0226` decision 8
   forbids.
3. **Two owner decisions are recorded and surfaced, not resolved:**
   - whether the four Raster-Lab codec libraries may enter the build as
     transitive dependencies of DICOMKit — the `VOX-CMP-001` gate, now with the
     specific packages, versions and licences attached;
   - whether `Raster-Lab/JLSwift` will carry a licence, and which.
4. **The licence facts are recorded here so the decision is informed rather than
   re-derived.** Four of six licences are permissive and verified; one is
   Apache-2.0, which is permissive but carries notice obligations
   `THIRD_PARTY_NOTICES.md` must reflect; one is unknown.
5. **Apache-2.0 is noted as a new obligation shape, not a problem.** It satisfies
   `VOX-LIC-007` and `VOX-LIC-009`, and unlike MIT it requires reproducing its
   NOTICE content where one is supplied. `VOX-LIC-004`'s entry for
   `swift-argument-parser` and `JLISwift` must therefore be more than a licence
   name.
6. **`swift-argument-parser` deserves a separate remark.** It is a
   command-line-interface library, pulled in for DICOMKit's executable targets. A
   library consumer has no use for it, and it will still enter the resolved graph.
   That is not a blocker, but it is the kind of dependency `VOX-REP-009` exists to
   keep out of distribution targets, and (e2) must confirm no Voxelia
   distribution target links it.
7. **No attempt is made to work around the graph.** Vendoring DICOMKit's source,
   forking it to drop dependencies, or pinning around the codecs would each
   trade a recorded supply-chain question for an unrecorded one.

## Alternatives considered

### Add DICOMKit now, on the strength of the DICOMKit approval

Rejected; see blocker one. The approval names one package and the change acquires
six, four of which are the subject of a separate standing gate. Treating "yes to
DICOMKit" as "yes to its whole graph" would be the most consequential unstated
assumption of this arc.

### Add DICOMKit and record the codec libraries as a follow-up

Rejected. The dependency would already be in the build by the time the follow-up
was read, which makes the record a notification rather than a decision.

### Treat the missing JLSwift licence as satisfied because Raster-Lab owns it

Rejected. `ADR-0226` set the precedent in the opposite direction: the owner
supplied DICOMKit's identity and the licence was still **read** rather than
assumed. Ownership tells you who may set a licence, not what it is.

### Relax `check_licence_policy.py` to admit the graph and revisit later

Rejected outright, and it is worth naming why. The check is the only reason four
accepted requirements hold today. Editing it in the same increment that cannot
discharge those requirements would delete the evidence rather than satisfy it.

### Vendor or fork DICOMKit to remove its dependencies

Rejected; see decision 7. It also forfeits upstream fixes and makes the licence
position harder to state, not easier.

### Stop increment (e) entirely until the owner answers

Rejected. The addressing contract in (e1) is Voxelia-owned, needs no dependency,
and is the same "most of this work never needed the dependency" shape that
`ADR-0226` found for the whole arc. Idling the unblocked majority behind the
blocked minority is the error that record already declined to make.

## Consequences

The arc reaches its final increment with four of five parts complete and the
fifth split: its Voxelia-owned half proceeds, its supply-chain half stops at a
gate with the facts assembled.

**The project's gate count is unchanged at three, but one of them is now
concrete.** `VOX-CMP-001` was an abstract question about codec libraries; it is
now a specific list of four packages at four versions with three known licences
and one unknown.

`VOX-VS1-001` — ingest a CT series through DICOMKit — remains undischargeable
until (e2), and this record states that plainly rather than counting the arc as
finished.

## Affected modules

Documentation only in this record. Increment (e1) adds Voxelia-owned types to
`VoxeliaImaging`. **No module gains a dependency, and `Package.swift` is
unchanged.**

## Compatibility impact

None.

## Security impact

Positive, in the sense that matters most for a supply chain: an unlicensed
transitive dependency and four gated ones were identified **before** entering the
build graph rather than after. The repository still declares no external
dependency.

## Performance and memory impact

None in this record.

## Validation impact

```text
gh api repos/Raster-Lab/DICOMKit/contents/Package.swift?ref=v2.2.11   # graph read
gh api repos/<each>/contents/<licence file>                           # licences read
python3 Tools/Scripts/check_licence_policy.py    # still passes, unmodified
Tools/Scripts/validate-docs.sh
```

## Migration

1. This record, and increment (e1)'s design and implementation.
2. **Owner decisions** on the codec-library graph and the JLSwift licence.
3. (e2) once both are answered: the manifest dependency attached only to an
   optional `VoxeliaDICOMKit` target, the licence-gate update admitting exactly
   the resolved graph while still naming the four requirements it protects, the
   `THIRD_PARTY_NOTICES.md` entries including Apache-2.0 notice content, a
   confirmation that no distribution target links `swift-argument-parser`, and an
   SBOM regeneration.

## Supersession

This record supersedes nothing. It **corrects a factual premise** of `ADR-0226`
without editing it: that record called increment (e) unblocked, on the
understanding that DICOMKit was a single MIT package. Its reasoning was sound on
the facts it had; this record supplies the facts it lacked.

## References

- [ADR-0219 - Governance and licence traceability](ADR-0219-governance-and-licence-traceability.md)
- [ADR-0226 - DICOM ingest arc](ADR-0226-dicom-ingest-arc.md)
- [ADR-0230 - CT affine volume construction](ADR-0230-ct-affine-volume-construction.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
