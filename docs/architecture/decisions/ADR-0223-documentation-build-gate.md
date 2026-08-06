---
document_id: "ADR-0223"
title: "Documentation build gate"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-002"
  - "VOX-DOC-005"
---

# ADR-0223 - Documentation build gate

## Context

`ADR-0222`'s third consumer completed the progress work, and the ledger's next
action was explicit: **stop extending and reassess**, and if nothing is both
unblocked and consumer-backed, say so plainly rather than manufacture an
increment.

The reassessment began by running every check the repository defines that had
not been exercised recently. Six passed. The seventh could not be run at all
without a products directory, which led to `build-docc.sh` — and that **failed**.

## Findings

1. **The documentation build was broken, and had been since at least
   2026-08-04.** `xcodebuild docbuild` failed outright on unresolved symbol
   links. No documentation archive could be produced for any module.
2. **Ten public-surface doc comments linked to symbols outside their own
   module.** DocC resolves symbol links within a module's own documentation
   archive; a link to a type declared in a dependency cannot resolve, and
   module-qualifying it does not help when the dependency's archive is built
   separately. The offenders were `StorageContractError`,
   `MetadataJSONEmissionError`, `UnitDimension`, `MeasurementUnit`,
   `DataModelError`, `CoordinateSpaceDescriptor`, five CPU operation error
   types, and three `VoxeliaExecution/`-prefixed links in `VoxeliaMetal`.
   One further link, `AxisAlignedBounds3D/intersection(with:)`, was **ambiguous**
   between two overloads rather than unresolved.
3. **Nothing in the repository ran `build-docc.sh`.** Not `validate-docs.sh`,
   not `test.sh`, not `prepare-release.sh`. The script existed, was correct, and
   was invoked by no pipeline — which is exactly why a broken build survived.

Finding 3 is the fifth instance of the pattern `ADR-0196` first recorded: a
capability the project depends on, asserted in accepted places, enforced
nowhere. `VOX-DOC-002` names DocC a primary documentation format and
`VOX-DOC-005` requires every public API to carry documentation sufficient for
safe integration; neither can hold if the documentation cannot be built.

## Decision

1. **The ten cross-module links become plain code formatting**, not symbol
   links. A single-backtick `StorageContractError.contractViolation` names the
   type accurately and renders as code; a symbol link that cannot resolve is
   worse than no link, because it fails the build rather than degrading.
2. **The ambiguous link is disambiguated by return type**, using DocC's own
   suggested form,
   ``AxisAlignedBounds3D/intersection(with:)->RayAxisAlignedBoundsIntersection3D?``.
   Ambiguity between overloads is a genuine reader problem, so it is resolved
   rather than downgraded to code formatting.
3. **`build-docc.sh` joins `prepare-release.sh`, not `validate-docs.sh`**, and
   the placement is deliberate. It drives `xcodebuild` and takes minutes; a
   per-edit gate that slow would be bypassed within a week. A release gate that
   actually runs beats a per-increment gate that gets switched off.
4. **The reassessment is recorded as having found real work rather than
   manufacturing it.** The previous increment committed to saying plainly if
   nothing was unblocked. What it found instead was a broken build that four
   sessions of green checks had not surfaced, which is the argument for running
   the checks nobody runs.

## Alternatives considered

### Add `build-docc.sh` to `validate-docs.sh`

Rejected; see decision 3. Minutes of `xcodebuild` on every documentation edit
would make the routine check intolerable, and a check people avoid is worse
than one placed where it will run.

### Module-qualify the cross-module links instead of downgrading them

Rejected on evidence, not preference: it was tried first and DocC rejected
`VoxeliaCore/StorageContractError/incompatibleBinding` as well, because the
dependency's archive is separate.

### Build one combined documentation archive so cross-module links resolve

Rejected for now. It would change how twelve archives are produced and
distributed for a cosmetic linking benefit, and `ADR-0223` is a repair, not a
documentation-architecture change. A future record may revisit it if
cross-module linking becomes valuable.

### Leave the documentation build broken and record it as a known gap

Rejected. It is a working repair of about a dozen lines, and two accepted
requirements depend on the build succeeding.

## Consequences

`xcodebuild docbuild` succeeds and **twelve expected archives are generated**,
verified by the existing `check_docc_archives.py`. The build is now gated at
release time, so the next regression fails a script rather than waiting for
someone to notice.

The deliberate limitation is that cross-module symbol links remain unavailable;
they render as code instead.

## Affected modules

Doc comments only in `VoxeliaSpatial`, `VoxeliaStorage`, `VoxeliaCore`'s
dependents `VoxeliaGeometry`, `VoxeliaExecution`, `VoxeliaCPU` and
`VoxeliaMetal`; plus one line in `prepare-release.sh`. **No executable code
changed.**

## Compatibility impact

None; comments and one script line.

## Security impact

None.

## Performance and memory impact

None at runtime. `prepare-release.sh` gains the documentation build's minutes.

## Validation impact

`Tools/Scripts/build-docc.sh` passes and reports twelve expected archives. The
full test suite is unaffected, which is itself the check that only comments
changed.

## Migration

None; the repair is complete in this increment.

## Supersession

This record supersedes nothing. It repairs a broken build and closes the gap
that hid it.

## References

- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0219 - Governance and licence traceability](ADR-0219-governance-and-licence-traceability.md)
- [ADR-0222 - Progress reporting design](ADR-0222-progress-reporting-design.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
