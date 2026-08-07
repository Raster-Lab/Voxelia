---
document_id: "ADR-0289"
title: "Repository self test recovery"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-008"
---

# ADR-0289 - Repository self test recovery

## Context

`ADR-0288` found one failing test in `Tools/Tests/Python/test_repository_scripts.py` and
recorded it for its own increment. Fixing it found six more, and then found why none of
them had been noticed.

## What was wrong

**`Tools/Scripts/test-repository-scripts.sh` was wired to nothing.** No workflow ran it and
no gate called it. It is the runner for every checker's own regression tests, and it had no
caller.

**Seven of its hundred and fifty tests were failing**, in three groups:

| Tests | Cause |
|---|---|
| 4 in `test_adr_register.py` | **mine** — `ADR-0282` added `check_readme_index`, which fails a synthetic fixture directory that has records but no register |
| 1 in `test_docc_archives.py` | `ADR-0233` narrowed the gate to `Voxelia`-prefixed archives; the fixture still used an unprefixed name the checker ignores by design |
| 2 in `test_generate_sbom.py` | hardcoded counts (`12`, `13`, `12`) and a hardcoded index (`[0]`) that drifted when modules and dependencies were added |
| 1 in `test_repository_scripts.py` | `ADR-0233` removed a global DocC flag; the test still required it (`ADR-0288`) |

**Four of the seven were mine, from two increments earlier.** `ADR-0282` added a function to
`check_adr_register.py` and I never ran that checker's own tests — because nothing runs
them, which is the same gap in a smaller frame.

## Decision

1. **All seven are fixed and the suite is green at 150.**
2. **The register fixtures now generate a matching register** rather than each test
   hand-writing one. They therefore exercise `check_readme_index` as well, so the fixture
   cannot drift from the checker it feeds.
3. **The SBOM counts are cross-checked against `Package.swift`, not pinned to literals.**
   The literals had been wrong since modules were added, and a hardcoded count drifts on
   every new target while saying nothing about whether the SBOM covers the package. The
   manifest is an independent source, so counting against it is a cross-check rather than a
   tautology.
4. **The unreviewed-licence index is derived from where the fixture is appended**, rather
   than pinned to zero — which it was, and which broke the moment a dependency was declared.
5. **The external-package assertions now test the property rather than the count.** Every
   external package must carry a reviewed licence; how many there are is not the point and
   was the thing that rotted.
6. **The DocC archive fixture uses a `Voxelia`-prefixed name**, which is the case the gate
   exists for — a new Voxelia module nobody registered — and asserts the checker's complete
   message rather than a prefix of it.

## The fix I got wrong, immediately

The obvious durable fix was to call `test-repository-scripts.sh` from `validate-docs.sh`,
so the self-tests run whenever the gates do. That was done, and it **recursed without
bound**: `test_repository_scripts.py` executes `validate-docs.sh` as a subprocess, so the
gate ran the tests which ran the gate.

It was caught within a minute because the command was actually run rather than assumed —
six nested `test-repository-scripts.sh` processes were visible before anything was
committed. The change was reverted and the validation chain is byte-identical to before.

**The self-tests run as their own workflow step instead**, immediately after
`validate-docs.sh` in `documentation.yml`, where the two are separate processes and no
recursion is possible.

Recorded because "add it to the obvious gate" is what anyone would try next, and the reason
it cannot work is not visible from the outside.

## Alternatives considered

### Guard the recursion with an environment variable

Rejected. It would make the self-tests behave differently depending on how they were
invoked, which is exactly the property a regression suite should not have — and the test
that runs `validate-docs.sh` is testing something real about it.

### Delete the test that executes `validate-docs.sh`

Rejected. It is a genuine end-to-end check of the gate, and removing evidence to make a
wiring convenient is backwards.

### Update the SBOM counts to the current literals

Rejected. They would be correct today and wrong at the next module, which is precisely the
history being repaired. The same reasoning applies as `ADR-0282`'s generated register rows.

### Leave the runner unwired and fix only the failures

Rejected. The failures are a symptom; seven of them accumulated silently because the runner
had no caller, and four were introduced by a change to a checker whose tests would have
caught it in the same increment.

## Consequences

The repository's checkers now have working, running regression tests. A change to a checker
that breaks its own tests fails in CI rather than two increments later.

Three fixtures no longer carry literals that drift: the register is generated, the SBOM
counts are cross-checked against the manifest, and the licence index is derived.

**A fourth instance of the same pattern is on the record.** `ADR-0196` found a rule asserted
and not enforced, `ADR-0282` an authoritative document no gate read, `ADR-0287` a policy
describing compiler enforcement with no compiler enabled, and this a test suite with no
caller. The shape recurs: **something exists, and nothing runs it.**

## Affected modules

None. Four test files and one workflow change; no Swift source and no checker logic
changes.

## Compatibility impact

None to the package. CI gains a step that was always meant to run.

## Security impact

Indirect and positive. `check_swift_safety.py` and `check_licence_policy.py` both have
regression tests in this suite, and neither suite was running.

## Performance and memory impact

The documentation workflow gains roughly fifteen seconds.

## Validation impact

```text
Tools/Scripts/test-repository-scripts.sh
Tools/Scripts/validate-docs.sh
swift test
python3 Tools/Scripts/check_release_integrity.py --write
```

150 repository script tests pass, up from 143 passing and 7 failing. 1152 Swift tests in
207 suites pass, unchanged. `validate-docs.sh` is byte-identical to before this increment
after the recursion was reverted.

## Migration

1. This record, the seven fixes and the workflow step.
2. **Next**: a re-derived queue.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **completes `ADR-0288`'s deferred item** and repairs
four tests `ADR-0282` broke.

## References

- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0233 - DICOMKit adapter and dependency](ADR-0233-dicomkit-adapter-and-dependency.md)
- [ADR-0282 - Decision register enforcement](ADR-0282-decision-register-enforcement.md)
- [ADR-0287 - Strict memory safety readiness](ADR-0287-strict-memory-safety-readiness.md)
- [ADR-0288 - Enable strict memory safety](ADR-0288-enable-strict-memory-safety.md)
