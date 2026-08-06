---
document_id: "ADR-0225"
title: "Unrun pipeline sweep conclusion"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-LIC-005"
---

# ADR-0225 - Unrun pipeline sweep conclusion

## Context

`ADR-0223` began a sweep of the pipelines nothing routinely runs, after a
reassessment that was supposed to find nothing. `ADR-0224` continued it. This
record runs the last two — `generate-sbom.sh` and its `--validate` companion —
and closes the sweep with an honest summary.

## Findings

### The SBOM pipeline works; its committed artefact had drifted

Both stages **pass**. But regenerating changed the committed artefact in three
ways, all of which were stale rather than wrong-by-design:

1. **Two target dependency lists were out of date with `Package.swift`.**
   `VoxeliaCPU` gained `VoxeliaExecution` in commit `670611e` and
   `VoxeliaGeometry` gained `VoxeliaSpatial` in `ddf6e8c`; the SBOM recorded
   neither. A bill of materials that under-reports a module's dependencies is
   the one kind of error this artefact exists to prevent.
2. **The `Package.swift` and `ShaderManifest.yaml` checksums were stale**,
   naming content that no longer exists.
3. **The artefact recorded `"workingTreeDirty": true` at commit `d088b0b`** —
   it had been generated from an unclean working tree, and said so. That is the
   most serious of the three, because it is a claim about provenance: the
   committed bill of materials describes a state that was never a commit.

### This pipeline was gated, unlike the others

`prepare-release.sh` **does** invoke `generate-sbom.sh` and the validator. So
unlike the documentation build, which nothing invoked at all, the SBOM was
correctly gated and simply never exercised, because no release has been
prepared since the drift began. The distinction matters: this is a stale
artefact, not a missing gate.

## Decision

1. **The regenerated SBOM is committed.** It is strictly more accurate: correct
   dependency lists, current checksums, and an honest
   `"workingTreeDirty": false` observation at a real commit.
2. **The SBOM is not added to any per-increment check.** It is a release
   artefact, and drift between releases is expected and harmless **provided**
   the release gate regenerates it — which `prepare-release.sh` does. Adding it
   to `validate-docs.sh` would produce a diff on every increment and train
   everyone to ignore it.
3. **The dirty-tree provenance is the part worth remembering**, not the
   checksum drift. An artefact generated from an unclean tree records a state
   no commit can reproduce, and the generator was right to say so rather than
   hide it.

## The sweep's honest summary

Four heavyweight pipelines existed that nothing routinely ran. **Three were
broken:**

- **`build-docc.sh`** — the documentation build failed outright and was invoked
  by **no pipeline at all**. Repaired and gated by `ADR-0223`.
- **`validate-scaffold.sh`** — four Swift-safety and warnings-as-errors
  diagnostics, one of them introduced two increments earlier by `ADR-0221`.
  Repaired by `ADR-0224`; the script **still fails** on a pre-existing Apple
  Swift 6.3.3 compiler crash, which was attributed by worktree comparison rather
  than assumed, and which no flag was relaxed to hide.
- **`test-repository-scripts.sh`** — failed through the same `@unchecked
  Sendable` violation; now passes all 150 tests.
- **`generate-sbom.sh`** — passes; its committed artefact had drifted.

The lesson generalises beyond these four: **a green routine check says nothing
about a pipeline the routine does not invoke.** Every increment in this session
before the sweep ran `swift test`, `swift format`, `validate-docs.sh` and the
integrity ledger, all green, while the documentation build had been broken for
days and the scaffold gate for longer.

## Decision on what follows

4. **The sweep is closed and no further pipeline hunting is warranted** — there
   are no more unrun scripts. Re-running these four belongs at release time,
   which is where `prepare-release.sh` now puts three of them.
5. **`validate-scaffold.sh` remains red and remains red honestly.** It is the
   single outstanding defect from the sweep, it is a toolchain bug, and the
   reproduction is recorded in `ADR-0224` for re-testing against a future
   toolchain.

## Alternatives considered

### Regenerate the SBOM in `validate-docs.sh`

Rejected; see decision 2.

### Leave the stale SBOM, since the release gate would regenerate it

Rejected. It is committed, it under-reports dependencies, and it claims to
describe a dirty tree. Correcting it costs one command.

### Treat the SBOM drift as equivalent to the DocC failure

Rejected; see the findings. One was an ungated broken build, the other a gated
artefact that had gone stale. Reporting them as the same kind of problem would
overstate this one.

## Consequences

All four pipelines have been run. Three are green; `validate-scaffold.sh` fails
on a recorded, attributed toolchain crash. The committed bill of materials now
describes the repository as it actually is.

## Affected modules

The generated SBOM artefact only. No source changed.

## Compatibility impact

None.

## Security impact

Positive: the bill of materials no longer under-reports two module dependencies,
and no longer claims to have been produced from an unclean tree.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/generate-sbom.sh                                    # passes
python3 Tools/Scripts/generate_sbom.py --validate <artefact>      # passes
```

## Migration

None. The next release runs all of these through `prepare-release.sh`.

## Supersession

This record supersedes nothing and closes the sweep `ADR-0223` opened.

## References

- [ADR-0223 - Documentation build gate](ADR-0223-documentation-build-gate.md)
- [ADR-0224 - Scaffold gate findings](ADR-0224-scaffold-gate-findings.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
