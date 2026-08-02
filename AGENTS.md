# Voxelia autonomous engineering rules

## Authority and scope

- Follow explicit user instructions first.
- Treat the newest approved or corrective `docs/project/*v0.1.1*` documents, accepted ADRs, requirements, and validation specifications as the project baseline.
- Do not infer that a scaffold, placeholder, preview, or visually plausible output is production-ready or diagnostically validated.
- Keep Voxelia limited to Apple Silicon ARM64 and Apple operating systems unless the Project Foundation is formally revised.
- Keep PACS, clinical workflow, authentication, browser services, deployment orchestration, and regulatory claims outside the library.

## Autonomous work loop

1. Read `docs/progress/AUTONOMY_STATUS.md`, inspect Git status, and preserve user changes.
2. Select exactly one small, unblocked acceptance criterion or tightly related group.
3. Confirm the governing requirement, architecture boundary, and validation oracle before editing.
4. Implement the smallest complete change, including documentation and regression coverage.
5. Run the narrowest relevant verification described below.
6. Review the diff for API, concurrency, numerical, memory, security, and provenance risks.
7. Update the progress ledger with evidence and the next action.
8. Commit only a coherent, verified increment. Never push or publish without explicit user authorization.

If another implementation turn is active, do not start duplicate work. If blocked, continue with another independent unblocked criterion when safe. Ask the user only when a product decision, credential, unavailable required hardware/SDK, or irreversible external action is genuinely required.

## Code-quality baseline

- Use Swift 6.2 or later and strict concurrency.
- Public value types should be immutable and `Sendable` where their semantics allow it.
- Isolate mutable services such as schedulers, caches, residency managers, and render coordinators.
- Make spatial spaces, units, scalar interpretation, precision, approximation status, and failure modes explicit.
- Use overflow-checked sizes, offsets, strides, regions, and allocation calculations.
- Preserve authoritative scientific values separately from presentation values and approximations.
- Do not silently fall back, regularize geometry, loosen tolerances, alter interpolation, enhance images, or publish stale generations.
- Keep public scientific APIs independent of Metal, DICOMKit, RealityKit, UI frameworks, and physical storage layout.
- Use typed errors and structured diagnostics. Logs and provenance must exclude patient-identifying data by default.
- Document public APIs, invariants, thread-safety, numerical behaviour, unsupported cases, and diagnostic status as part of the same change.
- Add a regression test for every fixed defect.
- Avoid speculative public API. Prefer internal implementation until semantics and validation contracts are approved.

## Test selection policy

During normal development, run only the smallest test set that can detect a regression in the changed behaviour:

- One function or type: its focused unit test or test filter, plus compilation of the owning target.
- One module: affected test target(s), not the repository-wide suite.
- Shared public API or dependency edge: affected module tests plus direct dependants' compile/tests.
- Concurrency or cancellation: focused race, cancellation, generation, and stale-publication tests.
- Spatial or numerical code: analytical/property tests and the relevant tolerance profile.
- Metal code: focused kernel/shader tests and CPU differential checks on supported hardware.
- Storage/memory code: focused bounds, overflow, partial-read, ownership, pressure, and allocation-count tests.
- Defect fix: reproduce first, add a regression test, then verify it fails before and passes after when practical.
- Documentation/tooling: only the relevant document or script validation, plus a regression check for the wrapper/tool changed.

Run broader checks only when justified:

- Module-boundary or package-graph changes: affected integration tests and graph validation.
- Cross-cutting public API changes: all affected downstream targets.
- Platform code changes: affected Apple destination(s).
- Performance-sensitive changes: the named benchmark scenario after correctness passes.
- Milestone/release gates: full prescribed build, test, platform, validation, benchmark, documentation, SBOM, and evidence suites.

Record every command, test filter, result, limitation, and skipped broader gate in the progress ledger. A narrow green test is evidence only for its stated scope.

## Review and completion gates

- Map implementation and tests back to requirement IDs and ADRs.
- Require an independent CPU or analytical oracle for diagnostic Metal behaviour.
- Version numerical tolerances, algorithms, shaders, datasets, and provenance schemas.
- Treat security, privacy, malformed input, memory pressure, cancellation, and stale work as first-class test dimensions.
- Do not mark a milestone complete until every required criterion has evidence, pending external checks are closed, and required human approvals are recorded.
- Do not mark the overall goal complete until the approved roadmap and release-quality gates are genuinely satisfied.

## External-action safety

- Do not push, publish releases, create public repositories, change permissions, enable paid services, or modify external governance without explicit user authorization.
- Never place credentials, patient data, private datasets, or sensitive logs in source control.
- Prefer reversible local changes and preserve unrelated user work.
