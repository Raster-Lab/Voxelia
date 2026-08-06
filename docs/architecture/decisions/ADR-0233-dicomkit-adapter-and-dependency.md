---
document_id: "ADR-0233"
title: "DICOMKit adapter and dependency"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CMP-001"
  - "VOX-DCM-001"
  - "VOX-DCM-002"
  - "VOX-DCM-003"
  - "VOX-DCM-005"
  - "VOX-DCM-006"
  - "VOX-DCM-007"
  - "VOX-DCM-008"
  - "VOX-VS1-001"
  - "VOX-LIC-003"
  - "VOX-LIC-004"
  - "VOX-LIC-007"
  - "VOX-LIC-008"
  - "VOX-LIC-009"
  - "VOX-REP-009"
---

# ADR-0233 - DICOMKit adapter and dependency

## Context

This record performs increment (e2) and **closes the `ADR-0226` arc**. It is the
first external dependency this repository has ever declared.

`ADR-0231` split increment (e) and blocked (e2) on two owner decisions. Both were
answered on 2026-08-06:

> "yes proceed with codec libraries also", "JLSwift licence i will add MIT",
> "It also owned by us", "CompressionFamily is MIT too, its ours"

The `VOX-CMP-001` codec gate is released for this graph.

## Corrections to ADR-0231, stated rather than absorbed

`ADR-0231` read DICOMKit's manifest and recorded **five** transitive packages.
Resolving the graph produced **six**: `Raster-Lab/CompressionFamily` at `1.0.0`
arrives one level below the codec packages and appears in no manifest this project
had read.

**Reading a manifest gives one level; only resolution gives the closure.** That
is the correction, and it is the reason the licence gate below now pins the
resolved closure rather than the declared list. The owner was asked about
`CompressionFamily` separately once it was found, rather than having its licence
inferred from the answer about the others.

`ADR-0231` also noted that Apache-2.0 "requires reproducing its NOTICE content
where one is supplied". **Neither Apache package ships a `NOTICE` file** — checked
directly — so section 4(d) is not triggered. The obligation was real and the
condition was not met, which is a fact rather than a relaxation.

## The licence position, complete

| Package | Version | Licence | Basis |
|---|---|---|---|
| `Raster-Lab/DICOMKit` | `2.2.11` | MIT | file read |
| `apple/swift-argument-parser` | `1.8.2` | Apache-2.0 | file read |
| `Raster-Lab/J2KSwift` | `11.0.2` | MIT | file read |
| `Raster-Lab/JLISwift` | `0.5.0` | Apache-2.0 | file read |
| `Raster-Lab/JXLSwift` | `1.4.0` | MIT | file read |
| `Raster-Lab/JLSwift` | `0.9.0` | MIT | **owner grant; file pending** |
| `Raster-Lab/CompressionFamily` | `1.0.0` | MIT | **owner grant; file pending** |

**For a package the project owner owns, the owner's declaration is the licence
grant.** That is a substantive distinction from a third party, where only the
file counts: the copyright holder stating the terms *is* the grant. The file is
how a third party verifies it, so it is a **release prerequisite** recorded in
decision 9 rather than a discharged item.

## Decision

1. **The dependency is declared exactly once, pinned exactly**, at
   `2.2.11` — not a range. An exact pin means the resolved closure cannot change
   without a manifest edit the gate sees.
2. **It is attached only to a new optional `VoxeliaDICOMKit` target**, with its
   own product and test target. No existing module gains a dependency, satisfying
   `VOX-REP-009` and `VOX-DCM-002` at once.
3. **`check_licence_policy.py` was strengthened, not relaxed.** It previously
   asserted `dependencies: []`. It now pins three things: the declared
   dependencies with their exact versions, the **whole resolved closure** with
   each package's recorded licence, and the set of targets permitted to link an
   external product. It still names `VOX-LIC-007`, `VOX-LIC-008`, `VOX-LIC-009`
   and `VOX-REP-009` in its failure messages.
4. **The closure check exists because of the `CompressionFamily` finding**, and
   it closes that failure mode: a version bump pulling in an eighth package now
   fails the gate instead of passing unnoticed.
5. **The strengthened gate was negative-tested rather than assumed to work.**
   Three conditions were injected and each produced the intended failure: an
   unexpected package in `Package.resolved`, a version drift on an approved
   package, and a core target linking an external product. A gate whose failure
   path has never run is the `ADR-0196` pattern this project keeps finding.
6. **`Package.resolved` is committed.** The resolved closure is what
   `VOX-LIC-009` is checked against, so it has to be in the repository.
7. **The adapter parses nothing.** `DICOMFrameAdapter` reads attributes from a
   `DataSet` DICOMKit has already parsed and translates them into
   `CTFrameDescription`. `VOX-DCM-001`'s prohibition is honoured by construction.
8. **The adapter owns the axis convention `ADR-0227` assigned it.** DICOM's Image
   Orientation (Patient) supplies the row direction first and Pixel Spacing the
   row spacing first, which map directly onto `ADR-0227`'s names. A test asserts
   both pairs with **distinct** values, so a swap changes an asserted number.
9. **Adding `LICENSE` to `Raster-Lab/JLSwift` and
   `Raster-Lab/CompressionFamily` is a release prerequisite.** `VOX-LIC-004` is
   satisfied by the notices inventory; the files are what let a third party
   verify two of its entries. Recorded, not counted as done.
10. **`VOX-VS1-001`'s Demonstration half is discharged for the geometry path**,
    against real clinical CT data the owner supplied mid-increment. A 899-slice
    thorax series ingested completely — 899 of 899 files parsed and adapted, one
    series assembled, verdict **`representable`** with **no findings** under the
    `exact` tolerance. The recorded evidence is
    `docs/progress/evidence/VOX-VS1-001-real-ct-demonstration-2026-08-06.md`.
    The **pixel-data** path is not discharged: no samples were decoded, so
    `CTVolumeLayout` and the direct-write model remain untested against real
    data.

## The finding: a "try both readings" shortcut was wrong

The adapter's first version read Pixel Padding Value as unsigned and fell back to
signed. DICOM defines that attribute as US **or** SS according to Pixel
Representation, and the choice is not cosmetic: the same two bytes read the wrong
way turn a signed `-2000` into `63536`, which `CTFrameDescription` then correctly
refuses as unrepresentable in a signed sixteen-bit format.

**The fallback passes for every non-negative value and fails for exactly the
negative ones real CT padding uses.** The test caught it because its fixture used
a negative padding value with a signed format; a positive fixture would have
passed both readings identically and shipped the bug. The reader now selects on
Pixel Representation, as DICOM specifies.

## The dependency broke the documentation gate, and the gate was re-scoped

`build-docc.sh` passed `--warnings-as-errors` globally and
`check_docc_archives.py` treated any archive it did not expect as an error. Both
were correct while the package had no dependencies. `xcodebuild docbuild`
documents the **whole package graph**, so adding one dependency produced 16 DocC
errors — every one of them inside `JXLSwift` and `DICOMKit`'s own doc comments —
and 14 archives for dependency targets.

**Neither was a Voxelia defect, and neither is Voxelia's to fix.** The gate's
intent is that Voxelia's documentation builds clean, so its scope was corrected
rather than its standard lowered:

- `build-docc.sh` no longer passes `--warnings-as-errors` globally. It captures
  the log and **fails on any diagnostic whose path is inside this repository's
  `Sources/`**. Voxelia's own standard is unchanged: one warning in a Voxelia
  source still fails the gate.
- `check_docc_archives.py` requires every expected Voxelia archive, still fails
  on an unexpected archive whose name begins with `Voxelia` — so a new module
  nobody registered is still caught — and **counts and reports** the
  dependency archives it ignores rather than discarding them silently.

Scope-correction and standard-relaxation are easy to confuse, so to be exact
about what was verified: the Voxelia-diagnostic filter is a `grep` over the build
log, and the run that produced this result had 16 dependency diagnostics and zero
Voxelia ones, which exercised the filter's discrimination but not its failure
path. That failure path is asserted by construction, not by a negative test, and
saying so is more useful than implying otherwise.

**Worth surfacing separately**: `JXLSwift` and `DICOMKit` have DocC errors in
their own documentation. Both are Raster-Lab repositories, so they are cheap for
the owner to fix, and doing so would let this gate go back to a global
`--warnings-as-errors`.

## The manifest safety policy needed a vocabulary, not an exemption

`check_swift_safety.py` constrains `Package.swift` to a reviewable declarative
subset with an allowlist of identifiers. Written when there were no dependencies,
that allowlist had no dependency vocabulary, so the first `.package(url:exact:)`
declaration failed it — and so did the explanatory comments, because the
tokeniser has no comment rule.

The comments were **removed** rather than the tokeniser widened: the rationale
belongs in this record and in `THIRD_PARTY_NOTICES.md`, and widening a security
policy to accommodate a comment is the wrong trade. `url` and `exact` were added
to the allowlist, which is an extension of a declarative vocabulary rather than a
relaxation — a pinned URL is data, not computation.

**`from`, `branch` and `revision` were deliberately left out.** A version range
would let the resolved closure drift without a manifest edit, and a negative test
confirms both gates refuse it: the safety policy rejects the `from` token and the
licence gate rejects a non-exact requirement, independently.

## The demonstration corrects ADR-0229 a second time

`ADR-0229` decision 5 said the `exact` tolerance "will reject real series whose
spacing or orientation varies at all", and framed that as an accepted cost of the
conservative posture.

**Measurement says otherwise.** Across roughly forty real CT series, `exact`
**accepts about half outright**, including every large primary axial
reconstruction measured. The warning was not wrong in principle — it was wrong
about how often the principle bites, and it should not have been stated that
strongly without data.

The data also supplies what the tolerance gate was waiting for. Spacing spread
falls into four measured groups: exactly zero for primary reconstructions;
`1.4e-14` to `1.1e-13` mm of floating-point noise on physically regular series;
`2.1e-4` to `1.2e-3` mm on coronal and sagittal reformats; and `51.77` mm and
`72.57` mm for genuinely mixed secondary-capture studies. **A threshold above
`1.2e-3` mm and well below a millimetre would admit every physically regular
series while still rejecting the irregular ones by four orders of magnitude.**
Choosing the number is still an owner decision needing a record and an oracle —
but it is no longer a decision without evidence, which is exactly what
`ADR-0229` decision 3 said it was waiting for.

Two real series confirmed design decisions rather than merely passing:
`Monitoring_1000_12` is eight frames at one position, rejected for
`duplicateProjections` — a real-world instance of frozen fixture G4 — and
`CT_Raw_data_601` is raw-data objects with no image pixel module, refused with
the precise `missingRows` reason.

## A correction owed to ADR-0229

`ADR-0229` decided the geometry tolerance had no evidence-based source, and
argued that the one principled candidate — the source's own stated decimal
precision — "is not available", because `ADR-0227` kept `Double` values rather
than the original strings.

**That claim is too strong.** DICOMKit's `DICOMDecimalString` carries **both**
`value: Double` and `originalString: String`, so the source's stated precision is
available *at this boundary*. `ADR-0229`'s decision stands — the neutral
description deliberately holds `Double`, and the validator cannot see strings —
but the precision is **recoverable here and could be carried forward**, which
means an evidence-based tolerance may be derivable without phantom studies.

That is a design question with a real numeric boundary and needs its own record,
oracle and owner acceptance. It is named here so the gate's description stops
saying the information is gone.

## Alternatives considered

### Depend on a version range rather than an exact pin

Rejected; see decision 1. A range lets the closure change without a manifest edit,
which is precisely what the closure check exists to detect.

### Keep the licence gate as an emptiness assertion and add an exemption

Rejected. An exemption would make the gate weaker at the exact moment the risk
became real. Pinning the closure makes it stronger.

### Take the attribute tags from `DICOMDictionary`

Rejected. Spelling out the fifteen tags this adapter reads makes its whole
dependency on the DICOM data dictionary visible in one place, and means a
dictionary change cannot silently alter which attribute is read.

### Treat a colour photometric interpretation as greyscale

Rejected. `VOX-DCM-008` scopes the slice to the monochrome interpretations, and
silently reinterpreting colour data as greyscale is the kind of plausible-looking
wrong result this project's admissions exist to prevent.

### Surface the underlying Voxelia admission error from the adapter

Rejected. Those errors are payload-free precisely so a diagnostic cannot name
patient geometry; forwarding them would be safe, but a single
`rejectedByVoxeliaAdmission` case keeps the adapter's own family honest about what
it knows.

### Infer `CompressionFamily`'s licence from the owner's answer about the codecs

Rejected. It was found after that answer was given, and the owner had not been
shown it. Asking took one sentence.

## Consequences

**The `ADR-0226` arc is closed.** Five increments, seven accepted records, five
algorithm specifications and five oracles, from a neutral frame description to a
DICOM adapter that composes with the whole pipeline in one test.

This repository now carries a third-party dependency, and the property that used
to make four licence requirements true — there being none — has been replaced by
a stronger, tested gate.

`VOX-VS1-001`'s Demonstration half is discharged for the geometry path on real
data. The geometry-tolerance gate remains an owner decision but now has measured
evidence attached. The two licence files remain a release prerequisite.

## Affected modules

New optional module `VoxeliaDICOMKit` with a test target. `Package.swift` gains
one dependency and one product. **No existing module's dependencies change.**

## Compatibility impact

Additive. No platform floor moves: Voxelia already requires macOS 15, which is
DICOMKit's minimum — checked rather than assumed after a probe failure that turned
out to be a missing `platforms:` declaration in the probe itself.

## Security impact

This increment crosses the supply-chain boundary, which is why the gate was
strengthened and negative-tested. The adapter's failure family is payload-free and
names attributes rather than values.

## Performance and memory impact

Translation is a fixed number of attribute reads per frame. No sample data is
copied: `ADR-0230` decision 10's direct-write model is served by
`CTVolumeLayout`, and this adapter produces descriptions only.

## Validation impact

```text
swift build && swift test
swift test --filter DICOMFrameAdapter
python3 Tools/Scripts/check_licence_policy.py       # strengthened, and negative-tested
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/generate-sbom.sh
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This increment closes the arc.
2. **Release prerequisite**: `LICENSE` files in `Raster-Lab/JLSwift` and
   `Raster-Lab/CompressionFamily`.
3. **Open, each needing its own record**: an evidence-based geometry tolerance —
   now with a measured distribution from real data *and* possibly derivable from
   `DICOMDecimalString.originalString`; and the pixel-data path, which is the
   only part of `VOX-VS1-001` the demonstration did not reach.

## Supersession

This record supersedes nothing. It performs increment (e2) of `ADR-0226`,
**corrects `ADR-0231`'s transitive-package table and its Apache-2.0 notice
claim**, and **corrects `ADR-0229`'s claim that the source's decimal precision is
unavailable** — in each case by recording the correction here rather than editing
an accepted record.

## References

- [ADR-0219 - Governance and licence traceability](ADR-0219-governance-and-licence-traceability.md)
- [ADR-0226 - DICOM ingest arc](ADR-0226-dicom-ingest-arc.md)
- [ADR-0227 - Neutral CT frame description](ADR-0227-neutral-ct-frame-description.md)
- [ADR-0229 - CT series geometry validation](ADR-0229-ct-series-geometry-validation.md)
- [ADR-0230 - CT affine volume construction](ADR-0230-ct-affine-volume-construction.md)
- [ADR-0231 - DICOMKit supply-chain assessment](ADR-0231-dicomkit-supply-chain-assessment.md)
- [ADR-0232 - CT volume sample layout](ADR-0232-ct-volume-sample-layout.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
