---
document_id: "ADR-0224"
title: "Scaffold gate findings"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-PLT-007"
  - "VOX-SEC-001"
---

# ADR-0224 - Scaffold gate findings

## Context

`ADR-0223` repaired a documentation build that nothing invoked, and set the
next action: run the remaining pipelines nobody runs and repair what they
surface. Four were outstanding — `validate-scaffold.sh`,
`test-repository-scripts.sh`, the SBOM generator, and
`check_swift_safety.py --compile`.

Both suites that were run failed. This record states what was found, what was
repaired, **what remains broken**, and who caused each.

## Findings

### One violation was mine, introduced two increments ago

`Tests/VoxeliaMetalTests/MultiplanarRenderCoordinatorTests.swift` declared a
`NamingCounter` as `@unchecked Sendable` over an `NSLock`. The Swift safety
policy permits **no ungoverned escape hatches**, and
`check_swift_safety.py` rejects it. It reached `main` in `ADR-0221` because the
increment ran `swift test` and `swift format`, neither of which applies that
policy, and `validate-docs.sh` does not invoke the safety gate.

The irony is instructive: two increments later I replaced the same `NSLock`
pattern with `Synchronization.Mutex` in the CPU test files **for idiom
consistency**, and that stylistic choice silently avoided the same violation.
The gate would have caught it immediately.

It is now a `Mutex`, matching every other concurrent helper in the suites.

### Three diagnostics were pre-existing

Under `-warnings-as-errors`, the strict build also rejected a redundant
`#require` in each of `TriangleMeshEnclosedVolumeTests` and
`TriangleMeshTotalFacetAreaTests` — the receiving helper takes an **optional**
identifier, so the unwrap was never needed — and two unused locals in
`SurfaceColourMapperTests`. All three are repaired.

### The release strict build crashes the compiler, and it is not ours

With the four diagnostics fixed, the **debug** strict build passes and the
**release** strict build fails with **signal 11** — a `swift-frontend` crash
compiling `VoxeliaCPUTests` under `-O -strict-memory-safety
-enable-default-cmo` on **Apple Swift 6.3.3 (swiftlang-6.3.3.1.3)**.

**Attribution was established rather than assumed.** A worktree at `ba2da18` —
before this session's progress-reporting work — was patched with **only** the
three pre-existing diagnostic fixes and run: it crashes identically. The crash
therefore predates the progress increments and is a toolchain defect, not a
consequence of recent changes.

## Decision

1. **The four diagnostics are repaired**, and each is attributed above rather
   than reported as a single anonymous batch.
2. **The compiler crash is recorded as an open finding, and the gate is not
   claimed green.** `validate-scaffold.sh` currently **fails** at its release
   strict-memory-safety stage. Saying otherwise would be the clearest kind of
   false report, and the crash is a `swift-frontend` bug this project cannot
   fix.
3. **No workaround is applied to hide it.** Disabling `-strict-memory-safety`,
   dropping `-warnings-as-errors`, or excluding `VoxeliaCPUTests` from the
   release build would each turn a visible toolchain bug into an invisible
   policy hole. The gate stays honest and red.
4. **The reproduction is recorded exactly** — command, flags, target and
   toolchain version — so the finding can be re-tested against a future
   toolchain in one step rather than rediscovered.
5. **`test-repository-scripts.sh` now passes**, all 150 tests, having failed
   only through the same `@unchecked Sendable` violation.

## Alternatives considered

### Relax the strict-memory-safety or warnings-as-errors flags

Rejected; see decision 3. The flags are the policy; removing them to get a
green gate would delete the check rather than satisfy it.

### Exclude `VoxeliaCPUTests` from the release strict build

Rejected; see decision 3. It is the largest CPU reference-kernel suite, so
excluding it would exempt precisely the code the policy most needs to cover.

### Bisect the crash to a minimal reproduction now

Not done in this increment, and the reason is proportionality: attribution —
whether recent work caused it — was the question that mattered, and it is
answered. A minimal reproduction is worth building when the finding is reported
upstream, which is an owner decision about external communication.

### Report the scaffold gate as passing because everything else in it passes

Rejected outright. Every other stage of `validate-scaffold.sh` does pass, and
that is worth recording — but the script fails, and a partial pass reported as
a pass is exactly the overstatement these records exist to prevent.

## Consequences

`test-repository-scripts.sh` is green. `validate-scaffold.sh` reaches its final
stage and fails there on a toolchain crash, with everything before it passing.
The project has an exact, attributed reproduction rather than an unexplained red
pipeline.

Two of the four pipelines `ADR-0223` listed remain unrun: the SBOM generator and
its validator. They are the next action.

## Affected modules

Test sources only, in `VoxeliaMetalTests`, `VoxeliaGeometryTests` and
`VoxeliaRenderingTests`. **No product source changed.**

## Compatibility impact

None.

## Security impact

Positive: an ungoverned `@unchecked Sendable` is gone from the test suites, and
the policy that forbids it is demonstrably enforced.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_swift_safety.py           # passes
python3 Tools/Scripts/check_swift_safety.py --compile # debug passes,
                                                      # release: signal 11
Tools/Scripts/test-repository-scripts.sh              # 150 tests pass
Tools/Scripts/validate-scaffold.sh                    # FAILS at the release
                                                      # strict build
swift test                                            # green
```

Toolchain: Apple Swift 6.3.3 (swiftlang-6.3.3.1.3 clang-2100.1.1.101),
`arm64-apple-macosx26.0`.

## Migration

1. Run the SBOM generator and validator; repair whatever they surface.
2. Re-test the release strict build when the toolchain changes. If it still
   crashes, a minimal reproduction and an upstream report become an owner
   decision.

## Supersession

This record supersedes nothing. It continues the sweep `ADR-0223` began.

## References

- [ADR-0221 - Multiplanar render path](ADR-0221-multiplanar-render-path.md)
- [ADR-0223 - Documentation build gate](ADR-0223-documentation-build-gate.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
