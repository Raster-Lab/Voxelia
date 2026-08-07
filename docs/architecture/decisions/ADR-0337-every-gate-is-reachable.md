---
document_id: "ADR-0337"
title: "Every gate is reachable"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
---

# ADR-0337 - Every gate is reachable

## Context

Eleven times in this arc a rule was found asserted with nothing running it — `ADR-0196`,
`ADR-0282`, `ADR-0287`, `ADR-0289`, `ADR-0301`, `ADR-0302`, `ADR-0303`, `ADR-0309`, `ADR-0311`,
`ADR-0326` and `ADR-0328`. The pattern was reliable enough to turn on itself: **do the gates
that enforce those rules actually run?**

Three of them — `check_prohibited_imports.py`, `check_required_files.py` and the windowing and
Model I/O boundaries inside them — were strengthened in this session on the assumption that
they do.

## The measurement, and the negative result

**Twenty-one `check_*.py` gates exist. Every one is reachable from CI on every push.**

| Runner | Gates |
|---|---|
| `validate-docs.sh` | `adr_links`, `adr_register`, `british_english`, `document_text`, `example_safety`, `front_matter`, `licence_policy`, `requirement_traceability`, `rfc_register`, `temporary_files`, `test_levels`, `unstructured_concurrency` |
| `validate-scaffold.sh` | `adr_register`, `apple_platform_policy`, `document_text`, `front_matter`, `manifest_paths`, `package_graph`, `package_graph_static`, `prohibited_imports`, `release_integrity`, `required_files`, `rfc_register`, `swift_safety` |
| Named directly in a workflow | `docc_archives` |

`ci.yml` invokes both shell scripts, and its triggers are `pull_request` and `push` to `main`.
So the union is all twenty-one, on every change.

**The hypothesis was wrong, and it was wrong twice.** The first reading — that seven gates ran
nowhere — came from grepping workflow files for gate *filenames*, which misses a gate invoked
through a shell script. The second doubt — that `validate-scaffold.sh` might be nightly-only,
since the ledger records "do not rerun the complete scaffold suite unless a later cross-cutting
change affects its gate" — was resolved by reading `ci.yml`'s triggers rather than inferring
from that note. **That ledger line is about a local habit during development, not about CI.**

## Decision

1. **No change is made.** The enforcement surface is complete, and this record exists because a
   negative result that took two wrong readings to reach is worth writing down.
2. **The mapping above is recorded so it can be rechecked**, in the same spirit as `ADR-0319`'s
   queue criterion: a future gate added to `Tools/Scripts/` and to neither shell script would be
   invisible, and the way to notice is to rerun this comparison rather than to remember it.
3. **The three gates strengthened this session are confirmed to run** — `ADR-0303`'s windowing
   prohibition, `ADR-0311`'s Model I/O boundary and `ADR-0320`'s required-file additions all sit
   inside `validate-scaffold.sh`, which `ci.yml` runs on every push.
4. **The "asserted but unenforced" thread closes at the meta level.** It found eleven real
   defects and, turned on the enforcement layer itself, finds none.

## Alternatives considered

### Add a gate that checks every gate is invoked

Rejected, narrowly. It is the obvious next move and it would be a gate whose own invocation
needs checking — the regress has to stop somewhere, and a recorded, rerunnable comparison is a
better stopping point than one more script. If a gate is ever found unreachable, that is the
moment to reconsider.

### Report the first reading as a finding

Refused. Grepping workflow files for filenames produced a plausible list of seven unenforced
gates, and publishing it would have been a fabricated defect with real-looking evidence. The
second and third measurements exist because the first result was too convenient.

## Consequences

The enforcement surface is verified complete for the first time, and the pattern that drove
eleven increments is confirmed not to apply to the gates themselves.

## Affected modules

None. This record changes nothing.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: rerun the comparison when a gate is added, rather than assuming this result holds.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **verifies** the enforcement layer the arc's other records
depend on.

## References

- [ADR-0282 - Decision register enforcement](ADR-0282-decision-register-enforcement.md)
- [ADR-0303 - Headless rendering enforced](ADR-0303-headless-rendering-enforced.md)
- [ADR-0311 - Metal performance shaders boundary](ADR-0311-metal-performance-shaders-boundary.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0328 - Model I/O is optional](ADR-0328-model-io-is-optional.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
