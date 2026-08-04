# Changelog

All notable project changes shall be documented in this file.

The project uses Semantic Versioning. During the `0.x` series, breaking public API changes remain possible and shall be recorded explicitly.

## Unreleased

### Added

- None.

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
