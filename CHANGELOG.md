# Changelog

All notable project changes shall be documented in this file.

The project uses Semantic Versioning. From `1.0.0`, an incompatible public API change requires a major version, and deprecation precedes removal (`docs/releases/release-policy.md`). During the `0.x` series, breaking public API changes remained possible and were recorded explicitly.

## Unreleased

### Added

- None.

### Changed

- None.

## 1.0.0 - 2026-08-08

The first stable release: the complete M7-M10 phase-two programme per
`ADR-0338`, released after the owner's 1.0 acceptance session against
`docs/releases/v1.0-session-checklist.md`. Everything since v0.2.0 is
additive: no accepted numeric model changed its numbers.

### Added

- The M7 registration stack: rigid motions on canonical unit
  quaternions, rigid composition, landmark affine and rigid (Horn)
  estimation, similarity metrics (mean squares, histogram mutual
  information) and registration quality residuals — each under a frozen
  algorithm specification (`VOXELIA-ALG-0068..0073`) with an
  independent oracle, and failure carrying no transform by type.
- The M8 photorealistic module (`VoxeliaPhotorealistic`, optional and
  outside the umbrella, non-diagnostic by declaration): emission-
  absorption integration, shadow transmittance, lighting and
  transillumination, the deterministic SplitMix64 sequence, progressive
  Welford accumulation with the Chan merge, material separation and
  side-by-side comparison (`VOXELIA-ALG-0076..0083`).
- The M9 headless and distributed seams: distributed job descriptions
  with revalidating admission, partial-result merge validation with
  fixed precedence, worker compatibility envelopes, preemption,
  capability negotiation, diagnostic selection, and the declared
  implementation contract in the registry.
- The M10 publication surface: the umbrella module re-exporting the
  eight stable modules, all fifteen module overviews, the release
  policy and known-limitations list, benchmark reporting
  (`BenchmarkRecord`, `RegressionCheck`) and the 2026-08-08 measurement
  campaign that stands as the regression baseline.
- The owner's batch decisions `ADR-0409..0413`, including the approved
  10% regression threshold and this release session.

### Changed

- Requirement traceability debt reduced from 103 rows to zero
  (`ADR-0405`); the full suite stands at 1,461 tests in 285 suites.
- `RELEASE.json` now records the release toolchain
  (Apple Swift 6.3.3, macOS 26.5.1, Mac17,4).

## 0.2.0 - 2026-08-07

The first tagged release: the complete M0-M6 series per `ADR-0338`
decision 11, released after the owner's witnessed demonstration and
review session, including the explicit acceptance of the `VOX-PER-004`
frame-rate target standing recorded in `VOXELIA-BEN-0003`.

### Added

- The complete M1-M3 foundations: canonical data model, spatial vocabulary
  and affine machinery (composition, direction and normal transforms,
  world-to-index mapping, sample-centre physical bounds), storage and
  bricking vocabulary, CPU reference operations, and the Metal execution
  surface with checked-safety boundaries.
- The M4 first DICOM CT vertical slice: cancellable import session, series
  grouping and geometry validation, CT volume construction, multiplanar and
  arbitrary oblique reconstruction, windowed presentation, colour and
  overlay pipelines, picking, annotation registration, and the surface
  rendering stack through extraction, projection, visibility, compositing,
  shading, clipping and picking — each stage under a frozen algorithm
  specification with an independent oracle.
- The M5 compression arc: the `VoxeliaCompression` module and codec
  adapters over the approved Raster-Lab codecs, lossless equality and
  random-access evidence, adversarial-codestream bounds, and the
  compression benchmark (`VOXELIA-BEN-0002`).
- The M6 interactive stack: the study-cache generation stage with
  structurally propagated priority, the first-useful-image plan and
  assembly, grid resampling between explicit geometries, level-selection
  downsampling, the interactive level render path, refinement after
  interaction stops, and the analytical phantom validation arc.
- The frame-rate baseline on the named reference device
  (`VOXELIA-BEN-0003`) — the `VOX-PER-004` target is measured and missed on
  the CPU-exact path, with the gap attributed and reversal conditions
  recorded.
- The `VoxeliaCTReference` example application: the demonstration vehicle
  owning lifecycle, controls and the host-side interaction clock.
- Strict memory safety across all targets, the governed Metal byte-transfer
  boundary (`ADR-0186`), the test-level taxonomy, and the requirement
  traceability, decision-register and documentation gates now running in CI.

### Changed

- Accepted ADR-0024: the accepted Apple-platform decision formerly filed as
  ADR-0001 is re-identified as ADR-0025 to resolve its identifier collision
  with the Master Technical Architecture Appendix A register. The platform
  decision, its Accepted status and its requirements are unchanged; v0.1.1
  release records retain the former identifier as historical text.

### Fixed

- None.

## 0.1.1 - 2026-08-02

### Added

- Root-level Apple platform support policy.
- Accepted ADR-0001 establishing Apple Silicon and Apple operating systems as the exclusive Voxelia platform baseline.
- Compile-time Apple operating-system and ARM64 gates for every public package target.
- Apple Silicon macOS environment assertion for repository scripts.
- Static Apple-platform policy checker.
- Repository-script regression test suite.
- Corrective action and static verification records for release v0.1.1.

### Changed

- Continuous-integration workflows now require Voxelia-labelled self-hosted Apple Silicon macOS runners.
- All seven governing documents were revised to v0.1.1 and aligned to the exclusive Apple Silicon ARM64 and Apple operating-system baseline.
- Build, test, validation, benchmark and release scripts now require the approved Apple Silicon macOS environment.
- M0 release evidence was replaced with Apple-only corrective-release evidence.

### Fixed

- Corrective action M0-001: repaired `Tools/Scripts/validate-docs.sh` by replacing the malformed inline Python block with a dedicated validated Python checker.
- Added regression coverage that executes documentation validation and checks all shell and Python repository tools.

### Security

- Prevented untrusted forked pull-request code from being scheduled automatically on privileged Voxelia Apple Silicon runners.

## 0.1.0 - 2026-08-02

### Added

- Initial M0 repository and Swift package scaffold.
- Foundational module, test, validation, benchmark and tooling structure.
- Project governance, security, contribution and documentation baselines.
