# Third-Party Notices

Voxelia declares **one** external package dependency,
`https://github.com/Raster-Lab/DICOMKit.git` pinned exactly at `2.2.11`, attached
solely to the optional `VoxeliaDICOMKit` target per `VOX-REP-009`. No core
distribution target links it.

Depending on DICOMKit acquires its whole resolved graph, so **all seven packages
in the closure are inventoried below**, not only the one Voxelia names.
`ADR-0231` found that reading DICOMKit's manifest listed five transitive
packages while resolving the graph produced six: `CompressionFamily` arrives a
level further down. Reading a manifest gives one level; only resolution gives the
closure. `Tools/Scripts/check_licence_policy.py` now pins the closure so a
version bump that adds a package fails a gate instead of passing unnoticed.

## Licence summary

| Package | Version | Licence | Basis |
|---|---|---|---|
| DICOMKit | `2.2.11` | MIT | Licence file read from the repository |
| swift-argument-parser | `1.8.2` | Apache-2.0 | Licence file read from the repository |
| J2KSwift | `11.0.2` | MIT | Licence file read from the repository |
| JLISwift | `0.5.0` | Apache-2.0 | Licence file read from the repository |
| JXLSwift | `1.4.0` | MIT | Licence file read from the repository |
| JLSwift | `0.9.0` | MIT | **Owner grant, 2026-08-06; licence file pending** |
| CompressionFamily | `1.0.0` | MIT | **Owner grant, 2026-08-06; licence file pending** |

**Two packages carry a licence by owner grant rather than by a file.** Both are
Raster-Lab repositories, and for a package the project owner owns, the owner's
declaration **is** the licence grant. The file is how a third party verifies it,
so adding `LICENSE` to `Raster-Lab/JLSwift` and `Raster-Lab/CompressionFamily`
is a **release prerequisite** and is recorded as such in `ADR-0233` rather than
treated as done.

Every licence in the closure is permissive. None is strong copyleft, so
`VOX-LIC-007` is satisfied; all permit static linking, so `VOX-LIC-009` is
satisfied; and none is restrictive, so `VOX-LIC-008`'s isolation requirement is
not triggered — the optional-module isolation happens anyway, because
`VOX-DCM-002` requires it independently.

### Apache-2.0 notice obligations

`swift-argument-parser` and `JLISwift` are Apache-2.0. Its section 4(d) requires
reproducing the attribution notices of a `NOTICE` file **when the work includes
one**. **Neither repository ships a `NOTICE` file**, checked directly rather than
assumed, so no notice text is reproduced here. Sections 4(a) to 4(c) are met by
this inventory, by retaining the licence text and copyright notices in the
resolved source, and by Voxelia making no modifications to either package.

## Entries

| Field | Value |
|---|---|
| Name | DICOMKit |
| Repository | `https://github.com/Raster-Lab/DICOMKit.git` |
| Version or revision | `2.2.11` (exact pin) |
| Licence | MIT |
| Usage | `VoxeliaDICOMKit` (optional module) |
| Distribution | Optional, linked only when the module is used |
| Notice requirements | MIT: retain copyright and permission notice |
| Review | Voxelia Project, 2026-08-06; licence file read from the repository |

| Field | Value |
|---|---|
| Name | swift-argument-parser |
| Repository | `https://github.com/apple/swift-argument-parser.git` |
| Version or revision | `1.8.2` |
| Licence | Apache-2.0 |
| Usage | Transitive, via DICOMKit's executable targets |
| Distribution | Build-only in Voxelia's use; no Voxelia distribution target links it |
| Notice requirements | Apache-2.0 sections 4(a)-(c); no `NOTICE` file is shipped, so 4(d) does not apply |
| Review | Voxelia Project, 2026-08-06; `LICENSE.txt` read from the repository |

| Field | Value |
|---|---|
| Name | J2KSwift |
| Repository | `https://github.com/Raster-Lab/J2KSwift.git` |
| Version or revision | `11.0.2` |
| Licence | MIT |
| Usage | Transitive, via DICOMKit's JPEG 2000 codec support |
| Distribution | Optional, with DICOMKit |
| Notice requirements | MIT: retain copyright and permission notice |
| Review | Voxelia Project, 2026-08-06; `LICENSE` read from the repository |

| Field | Value |
|---|---|
| Name | JLISwift |
| Repository | `https://github.com/Raster-Lab/JLISwift.git` |
| Version or revision | `0.5.0` |
| Licence | Apache-2.0 |
| Usage | Transitive, via DICOMKit's JPEG codec support |
| Distribution | Optional, with DICOMKit |
| Notice requirements | Apache-2.0 sections 4(a)-(c); no `NOTICE` file is shipped, so 4(d) does not apply |
| Review | Voxelia Project, 2026-08-06; `LICENSE` read from the repository |

| Field | Value |
|---|---|
| Name | JXLSwift |
| Repository | `https://github.com/Raster-Lab/JXLSwift.git` |
| Version or revision | `1.4.0` |
| Licence | MIT |
| Usage | Transitive, via DICOMKit's JPEG XL codec support |
| Distribution | Optional, with DICOMKit |
| Notice requirements | MIT: retain copyright and permission notice |
| Review | Voxelia Project, 2026-08-06; `LICENSE` read from the repository |

| Field | Value |
|---|---|
| Name | JLSwift |
| Repository | `https://github.com/Raster-Lab/JLSwift.git` |
| Version or revision | `0.9.0` |
| Licence | MIT **by owner grant of 2026-08-06; no licence file in the repository yet** |
| Usage | Transitive, via DICOMKit's JPEG-LS codec support |
| Distribution | Optional, with DICOMKit |
| Notice requirements | MIT: retain copyright and permission notice, once the file exists |
| Review | Voxelia Project, 2026-08-06. **Release prerequisite: add `LICENSE` to the repository so third parties can verify the grant.** |

| Field | Value |
|---|---|
| Name | CompressionFamily |
| Repository | `https://github.com/Raster-Lab/CompressionFamily.git` |
| Version or revision | `1.0.0` |
| Licence | MIT **by owner grant of 2026-08-06; no licence file in the repository yet** |
| Usage | Transitive, one level below the codec packages |
| Distribution | Optional, with DICOMKit |
| Notice requirements | MIT: retain copyright and permission notice, once the file exists |
| Review | Voxelia Project, 2026-08-06. Found only by resolving the graph, not from DICOMKit's manifest. **Release prerequisite: add `LICENSE` to the repository.** |

## Tools

GitHub workflow actions and development tools are inventoried here when required
by their licences or release process. None currently requires an entry.
