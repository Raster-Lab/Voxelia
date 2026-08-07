# Voxelia v1.0.0 release notes

The first stable release: M0-M10 complete. Cut on 2026-08-08 at the
owner's direction after the 1.0 acceptance session
(`docs/releases/v1.0-session-checklist.md`, scheduled by `ADR-0413`).

## Toolchain

Apple Swift 6.3.3, macOS 26.5.1, Mac17,4 (Apple M5) — recorded in
`RELEASE.json` per the release policy.

## Diagnostic-output-affecting changes since v0.2.0

**None.** The M7-M10 programme is additive: new operations and models
(registration, similarity metrics, photorealistic rendering,
distributed seams) each entered under a frozen algorithm specification
with an independent oracle, and **no accepted numeric model changed
its numbers**. Every fixture pinned at v0.2.0 still passes bit-exact.
The photorealistic module is optional, outside the umbrella, and
non-diagnostic by declaration (`ADR-0412`).

## What is new

See `CHANGELOG.md` (1.0.0) for the complete list: the M7 registration
stack (`VOXELIA-ALG-0068..0073`), the M8 photorealistic module
(`VOXELIA-ALG-0076..0083`), the M9 headless and distributed seams, and
the M10 publication surface (umbrella re-export, module overviews,
release policy, known limitations, benchmark reporting).

## Evidence at the release commit

- Full suite: 1,461 tests in 285 suites, passed unfiltered.
- Requirement traceability debt: zero rows (`ADR-0405`).
- Benchmark campaign:
  `docs/progress/evidence/benchmark-campaign-2026-08-08.{json,md}` —
  steady-state 169.50 ms / ~6.2 M samples/s window-level on the
  reference hardware. This campaign is the approved regression
  baseline; the approved threshold is 10% (`ADR-0413`).
- Dependencies: `dicomkit` 2.2.11 and `j2kswift` 11.0.2, exact pins,
  in the generated SBOM.

## Standing from this release

- Major-version discipline: an incompatible public API change requires
  a major version; deprecation precedes removal
  (`docs/releases/release-policy.md`).
- Each stable release's benchmark campaign becomes the next regression
  baseline on acceptance, reviewed against the `RegressionCheck` seam.
- Known limitations are recorded honestly in
  `docs/releases/known-limitations.md`.
- The reference application (`Examples/VoxeliaCTReference`) ships as a
  demonstration vehicle only, not regulatory evidence.
