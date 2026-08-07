# Voxelia release policy

Recorded by `ADR-0408`; the acceptance half of every clause is the
owner's release session. Requirement identifiers are cited in the
record, not repeated here.

## Versioning and API stability

- **After 1.0, an incompatible public API change requires a major
  semantic version.** The public surface is the eight umbrella-exported
  modules plus the optional products' public APIs; the semantic-version
  vocabulary already in `VoxeliaCore` is the arbiter.
- **After 1.0, deprecation precedes removal** of public API, except for
  urgent security or correctness fixes, which must say so in the
  release notes and carry the evidence.
- **Source-package compatibility is the commitment.** No
  Voxelia-specific binary ABI promise exists or is implied; any future
  ABI commitment is a separate owner decision, consistent with the
  runtime plug-in record (`ADR-0403`).

## Release notes and diagnostic changes

- **Diagnostic-output-affecting changes are identified explicitly** in
  the release notes — an operation's numbers changing is never a
  bullet under "improvements" — and each such change requires updated
  validation evidence before the release is cut. The frozen-model
  discipline makes these changes visible: a model version bump is the
  trigger.

## What a stable release publishes

Every stable release publishes, as release artefacts:

1. **A supported-platform matrix** (currently: Apple Silicon `arm64`;
   macOS 15+, iOS 18+, tvOS 18+, visionOS 2+).
2. **Test, benchmark and validation status** — the literal suite pass
   line, the `ADR-0407` benchmark records for the modes that ran, and
   the validation evidence index.
3. **Known limitations** — `docs/releases/known-limitations.md`,
   organised by operation, format and platform, updated per release.
4. **A dependency inventory** — the SBOM the release gate already
   produces, listing every dependency with exact versions, sufficient
   for vulnerability assessment.
5. **The toolchain used** — recorded in `RELEASE.json`; artefacts are
   reproducible where practical (Swift builds on pinned toolchains from
   clean checkouts), and where they are not, the record says what
   varies.

## Dependency security

- External dependencies are pinned to **exact versions** with
  **approved identities** (the supply-chain gate refuses others), and
  they are **monitored for known vulnerabilities** against public
  advisory sources per release cycle; a vulnerable dependency blocks
  the release until updated or explicitly waived by the owner with the
  reason recorded.
