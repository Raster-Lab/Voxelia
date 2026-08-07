# Changelog

All notable project changes shall be documented in this file.

The project uses Semantic Versioning. During the `0.x` series, breaking public API changes remain possible and shall be recorded explicitly.

## Unreleased

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
