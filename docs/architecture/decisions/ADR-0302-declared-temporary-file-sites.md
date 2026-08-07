---
document_id: "ADR-0302"
title: "Declared temporary file sites"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SEC-005"
---

# ADR-0302 - Declared temporary file sites

## Context

`VOX-SEC-005` requires that "temporary-file creation shall be explicit, documented and
configurable". P1, **`I,T`**, milestone M5, from `ADR-0290`'s sweep.

## The measurement

The product surface was scanned for every Foundation and POSIX spelling that creates or names
a temporary location — `temporaryDirectory`, `NSTemporaryDirectory`, `itemReplacementDirectory`,
`mkstemp`, `mkdtemp`, `tmpfile`, `tmpnam`, and literal `/tmp` and `/var/tmp` paths.

**Zero hits across 242 product sources.** The same scan over `Tools/`, `Benchmarks/` and
`Validation/` is also clean. `FileManager` appears in `Sources/` exactly four times, all of
them existence or attribute queries in `CanonicalDocumentStore`, which writes only to a
directory the caller supplies and whose own documentation already states that the directory
"is never created implicitly".

Three **tests** use a scratch directory. That is the whole of it.

## The finding

The product's temporary-file behaviour is *none*, and that was **an accident of implementation
rather than a stated property**. Nothing documented it, and nothing stopped the next increment
from adding a temporary file silently — which is the same shape as the five unenforced rules
this arc has already found.

A requirement reading "shall be explicit, documented and configurable" is not satisfied by a
codebase that happens, today, to create nothing.

## Decision

1. **The rule is a declaration requirement, not a ban.** The row asks for creation to be
   explicit and documented, not absent. Banning it would be easier to enforce and would answer
   a different requirement than the one written.
2. **Any temporary-file site in `Sources/` must be declared** in
   `docs/progress/temporary-file-sites.txt`, as `path:line`, the record that authorised it,
   and what a caller does to configure it. `check_temporary_files.py` fails on any undeclared
   site.
3. **The declaration file is empty**, and the gate is therefore **clean from day one** rather
   than a ratchet. `ADR-0301` needed a ratchet because its backlog was 219 tests; here the
   backlog is nothing, so the stricter form is available and is used.
4. **Configurability stays with the site, not the gate.** Whether a given temporary file is
   configurable is a design question the authorising record has to answer; a script cannot
   judge it. What the gate guarantees is that such a record exists before the site does.
5. **Tests are out of scope.** A test creating a scratch directory produces no artefact on a
   user's machine, and requiring declarations for them would bury the product sites the rule
   is about.
6. **`VOX-SEC-005` is discharged**: the `I` by the gate and its declaration file, the `T` by
   six self-tests.

## The gate is proven able to fail

An undeclared site was added to `CanonicalDocumentStore.swift` and the check reported it by
file and line, then the file was restored. Beyond that, the self-tests cover:

- an undeclared site **fails**, naming the line and the requirement;
- a declared site **passes**;
- a declaration for a *different* line does **not** excuse this one, so moving a site without
  updating its entry is caught rather than silently inherited;
- **every one of the nine spellings** the check claims to cover is detected, so a pattern
  cannot be listed in the source and be dead;
- clean source passes, and the live repository passes with zero declared sites.

That fourth case matters most. Four times in this arc a rule existed with nothing exercising
it; a pattern list nobody tests is the same defect one level down.

## Alternatives considered

### Forbid temporary files outright

Rejected; see decision 1. It is a stricter rule than the requirement states, and a stricter
rule is not a better answer to a requirement that says "explicit, documented and configurable".

### Record the row as already satisfied because the count is zero

Rejected. That is exactly the reasoning this arc has had to correct five times. A property
that holds by accident is not a property the project maintains.

### Include tests in the scan

Rejected; see decision 5. Three legitimate scratch directories would need permanent
declarations, diluting a list whose value is that it is short and product-facing.

### Make it a ratchet like `ADR-0301`'s

Rejected because it is not needed. A ratchet exists to make a gate landable against an
existing backlog; with no backlog it would only weaken the rule.

## Consequences

`VOX-SEC-005` is discharged, and the product's "no temporary files" property is now stated and
enforced rather than incidental.

**13 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. One gate, one declaration file, one self-test module and one `validate-docs.sh` step. No
source file changed.

## Compatibility impact

None.

## Security impact

Positive, and this is the row's point. Temporary files are a disclosure surface for patient
data, and the product now cannot acquire one without a record saying so.

## Performance and memory impact

None. The gate scans the product tree once.

## Validation impact

```text
python3 Tools/Scripts/check_temporary_files.py
python3 -m unittest discover -s Tools/Tests/Python -p 'test_temporary_files.py'
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

Six self-tests pass. The Swift suite is unchanged at 1229 tests in 217 suites, because this
increment adds no Swift.

## Migration

1. This record, the gate, the empty declaration file, six self-tests and the
   `validate-docs.sh` step.
2. **Next**: the derived queue's remaining 13 rows.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **enforces** a requirement that held by accident.

## References

- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0301 - Enforce the test level taxonomy](ADR-0301-enforce-the-test-level-taxonomy.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
