# Contributing to Voxelia

Thank you for contributing to Voxelia. The project accepts code, tests, validation assets, benchmark scenarios, documentation, design proposals and issue reports.

## Before starting

- Read the documents in `docs/project/`.
- Read `PLATFORM_SUPPORT.md` and ADR-0025.
- Open or link an issue for material work.
- Use an RFC for significant API, data-model, execution, storage or diagnostic behaviour changes.
- Use an ADR for an architectural decision.
- Never place patient-identifying information in issues, logs, fixtures or public validation artefacts.

## Development baseline

- Apple Silicon Mac running macOS 15 or later
- Xcode with Swift 6.2 or later
- Swift 6 language mode
- Strict concurrency
- Metal and Apple platform frameworks
- British English in project documentation
- MIT-compatible contribution provenance

Voxelia does not accept portability changes for Intel, x86/x64, non-Apple operating systems or non-Apple-hosted Swift toolchains.

Run:

```bash
Tools/Scripts/bootstrap.sh
Tools/Scripts/build.sh
Tools/Scripts/test.sh
Tools/Scripts/validate-scaffold.sh
Tools/Scripts/test-platforms.sh
```

## Developer Certificate of Origin

Every commit shall include a sign-off:

```text
Signed-off-by: Contributor Name <contributor@example.com>
```

Use `git commit -s` to add it. The full certificate is in `DCO.txt`.

## Pull requests

A pull request shall identify:

- linked issue;
- affected requirement IDs;
- linked RFC or ADR when applicable;
- public API and compatibility impact;
- diagnostic-output impact;
- concurrency, memory and security impact;
- Apple Silicon and Apple-platform impact;
- validation performed;
- benchmark impact; and
- documentation changes.

The author shall not be the sole approver of diagnostic algorithms, tolerance changes, golden-result changes, unsafe code, shader precision changes, dependency licence decisions or benchmark baseline replacements.

## Code and documentation

- Keep canonical scientific models independent of Metal, RealityKit, DICOMKit and codecs while retaining Apple-only platform scope.
- Do not introduce speculative public APIs during M0.
- Use typed errors and explicit ownership.
- Avoid force unwraps and force casts in library code.
- Isolate and document unsafe code.
- Add target-local DocC and Markdown documentation.
- Link tests and validation evidence to requirement IDs where useful.

## Dependencies

New dependencies require licence, security, Apple-platform and maintenance review. Attach a dependency only to the target that uses it. Strong copyleft runtime dependencies are prohibited in the core distribution.

## Security

Do not report exploitable vulnerabilities publicly. Follow `SECURITY.md`.
