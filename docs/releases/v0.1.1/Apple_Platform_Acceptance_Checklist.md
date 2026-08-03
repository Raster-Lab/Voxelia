---
document_id: "VOXELIA-REL-0.1.1-APPLE-CHECKLIST"
title: "Voxelia v0.1.1 Apple Platform Acceptance Checklist"
version: "0.1.1"
status: "Local Execution Partially Complete"
document_type: "Acceptance Checklist"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-03"
owner: "Voxelia Project"
---

# Apple platform acceptance checklist

- [x] Apple Silicon macOS debug build
- [x] Apple Silicon macOS release build
- [x] Root package tests
- [x] Validation package build, tests and self-check
- [x] Benchmark package build, tests and self-check
- [x] Tools package build, tests and self-check
- [x] Repository-script regression suite
- [x] Generic iOS ARM64 build
- [x] iOS Simulator ARM64 build
- [x] Generic tvOS ARM64 build
- [x] tvOS Simulator ARM64 build
- [ ] Generic visionOS ARM64 build
- [ ] visionOS Simulator ARM64 build
- [x] Swift 6 strict-concurrency diagnostics
- [x] Swift strict-memory-safety diagnostics on available destinations
- [x] Metal resource-bundle verification
- [x] DocC archive generation
- [ ] GitHub branch protection and required checks
- [ ] DCO and CODEOWNERS enforcement
- [ ] Self-hosted runner isolation review
- [x] Release SBOM generation
- [ ] M0 acceptance review and signatures

## Local execution evidence

Evidence was produced on 2026-08-02 on an Apple Silicon Mac using Xcode 26.6
(build 17F113) and Swift 6.3.3.

Strict-memory-safety evidence was refreshed on 2026-08-03 on the same host and
toolchain.

- The complete M0 scaffold gate passed, including 29 repository-script tests,
  12 root-package tests, and the Validation, Benchmark and Tools package
  self-checks.
- `swift build -c release` completed successfully.
- `Tools/Scripts/test-platforms.sh` completed macOS, generic iOS, iOS
  Simulator, generic tvOS and tvOS Simulator builds before stopping at the
  first unavailable visionOS destination.
- The refreshed platform wrapper compiled product and test targets in Debug and
  Release for those five available destinations with strict memory safety and
  warnings-as-errors. A separate visionOS Simulator attempt confirmed the same
  unavailable platform-component blocker; no visionOS pass is claimed.
- `python3 Tools/Scripts/check_swift_safety.py --compile` validated effective
  Swift 6 manifests and bidirectional target coverage, then compiled product
  and test targets for all four repository packages in Debug and Release with
  strict memory safety and warnings-as-errors.
- `swift build -Xswiftc -strict-concurrency=complete -Xswiftc
  -warnings-as-errors` completed without diagnostics.
- The focused `VoxeliaMetalTests.shaderManifestIsBundled` test loaded
  `ShaderManifest.yaml` through the owning target's resource bundle and passed.
- `Tools/Scripts/build-docc.sh` generated the exact expected set of 12
  target-local documentation archives with DocC warnings treated as errors.
- `Tools/Scripts/generate-sbom.sh` generated and validated the versioned
  Voxelia release-SBOM profile. It records the checked-out commit and dirty
  state, 12 products, 13 source targets, 12 test targets, the MIT licence,
  source/tool/resource checksums, five release tools, 10 bundled resources,
  external packages and optional-dependency classification. This scaffold has
  no external Swift package dependency.

## Open evidence

- Both visionOS builds are blocked because the visionOS 26.5 Xcode platform
  component is not installed. SDK directory presence alone is not accepted as
  build evidence.
- GitHub controls cannot be verified until a repository remote and governance
  settings exist.
- Runner isolation requires review in the eventual CI environment.
- Formal M0 review and signatures remain human approval actions.

This checklist records local technical evidence only and does not declare M0
formally accepted.
