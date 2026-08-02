---
document_id: "ADR-0024"
title: "Architecture decision register reconciliation"
status: "Proposed"
date: "2026-08-02"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REP-004"
---

# ADR-0024 - Architecture decision register reconciliation

## Context

The Master Technical Architecture section 2.4 requires architecture decisions
to use stable identifiers and says that its Appendix A contains the initial
decision register. That register already assigns `ADR-0001` through
`ADR-0020`, with `ADR-0001` identifying the independent, backend-neutral
canonical scientific data model.

The corrective repository scaffold independently contains an accepted platform
decision named `ADR-0001`. It establishes Apple Silicon and Apple operating
systems as the exclusive platform baseline. The two decisions are both
substantive, were imported in the same repository baseline and do not supersede
one another, but they currently share one identifier.

The repository has since allocated proposed `ADR-0021` through `ADR-0023`
without changing either existing decision. Leaving the duplicate identifier in
place would make links, review records and future supersession statements
ambiguous. This proposal records a one-time reconciliation for review; its
Proposed status does not authorise any rename or reference migration.

## Decision

If this ADR is accepted:

1. The Master Technical Architecture Appendix A assignments `ADR-0001`
   through `ADR-0020` will remain the canonical initial register.
2. Proposed `ADR-0021` through `ADR-0023` and this reconciliation record will
   keep their existing identifiers.
3. The accepted Apple-platform record will be re-identified as `ADR-0025`
   without changing its decision, Accepted status, original date, owners or
   affected-requirement mapping.
4. The platform record will state its former identifier, exact former path
   `docs/architecture/decisions/ADR-0001-apple-ecosystem-only.md`, title and
   migration effective date, and will link to `ADR-0024` as the authority for
   the migration.
5. Live links, repository checks and the decision index will move to
   `ADR-0025` in the same change as the record rename. Release-integrity ledgers
   will be regenerated rather than edited as independent source data.
6. The v0.1.1 entry in `CHANGELOG.md`, the v0.1.1 Corrective Release Notes and
   the v0.1.1 Static Verification Report will remain unchanged as records of
   the identifier used at that release.

After migration, an unqualified current reference to `ADR-0001` will mean the
Master Technical Architecture's canonical-data-model decision. Historical
references to the exact former platform path, or to `ADR-0001` specifically in
the Apple-platform sections of the preserved v0.1.1 records, will mean the
platform decision re-identified as `ADR-0025`.

While this ADR remains Proposed, `ADR-0025` is an allocator hold only. It is
not an existing or accepted decision, and no platform record, live link or
policy check may be renamed. Any new proposal created before this one is
resolved must begin at `ADR-0026` or later. Rejection of this proposal releases
the hold.

This decision does not revise the platform policy, the Project Foundation, the
Master Technical Architecture decision text or any Swift API.

## Alternatives considered

### Keep both ADR-0001 records and qualify references by source

This preserves every current path, but it is not recommended because a stable
identifier would still name two unrelated decisions. Tooling, links and
supersession statements would require permanent out-of-band qualification.

### Renumber the Master Technical Architecture register

Moving all or part of `ADR-0001` through `ADR-0020` could free the local
identifier. It is not recommended because it changes up to twenty governing
assignments to avoid moving one repository-local record and would create a much
larger traceability migration.

### Renumber the existing repository proposals

The platform record could take one of `ADR-0021` through `ADR-0023` if those
proposals moved. It is not recommended because those identifiers are already
unambiguous and there is a free identifier after this reconciliation record.

### Combine registry reconciliation and platform policy in ADR-0024

Using one record for both decisions would avoid `ADR-0025`. It is not
recommended because registry governance and Apple-only platform policy have
different contexts, histories, consequences and approval implications.

### Delete the platform ADR as redundant

The platform policy is also present in governing documents and automated
checks. Deleting its accepted record is not recommended because it would erase
the explicit decision history and weaken traceability for the platform
requirements.

## Consequences

- Every current decision will have a unique repository-wide identifier after
  the accepted migration.
- One accepted record and its active references will change identifier once;
  its platform meaning and approval state will not change.
- The next generally available identifier will be `ADR-0026` while the
  `ADR-0025` migration hold exists and after the migration completes.
- The Master Technical Architecture register and proposed `ADR-0021` through
  `ADR-0023` require no content or identifier changes.
- Historical release text will continue to say `ADR-0001`; the path- and
  context-specific legacy mapping above distinguishes it from the Master
  Technical Architecture's canonical-data-model decision.

## Affected modules

No Swift module is affected. The migration is limited to repository governance
documents, active documentation links, two repository-policy scripts and
generated release-integrity ledgers.

## Compatibility impact

There is no source, binary, data or wire-format impact. Active repository links
will be updated atomically, but an external link to the former platform ADR
path may require the identifier mapping or Git history after migration.

## Security impact

The decision changes no security or privacy control. Keeping the platform
policy record and its enforcement checks aligned avoids an ambiguous policy
reference in validation evidence.

## Performance and memory impact

There is no runtime, performance or memory impact.

## Validation impact

After acceptance, focused evidence must cover:

- a file-backed ADR check proving that each front-matter identifier matches its
  filename prefix and heading, and that no file-backed identifier collides with
  the Master Technical Architecture Appendix A register;
- absence of the former platform path from active links and policy scripts;
- successful required-file and Apple-platform-policy checks against the new
  path;
- preservation of the platform record's status, date, owners, requirements and
  decision text, plus the exact former path, title and migration effective date;
- an unchanged Master Technical Architecture file, including its Appendix A
  assignments `ADR-0001` through `ADR-0020`;
- unchanged identifiers and file contents for proposed `ADR-0021` through
  `ADR-0023`; and
- complete, canonical release-integrity ledgers after the rename.

## Migration

Once maintainers grant governance approval, record acceptance and perform the
migration in one atomic repository change:

1. mark `ADR-0024` Accepted;
2. perform a Git-aware rename of `ADR-0001-apple-ecosystem-only.md` to
   `ADR-0025-apple-ecosystem-only.md` in the migration commit;
3. change that record's identifier and heading to `ADR-0025` and add the
   exact former path, title and migration-date note plus an `ADR-0024` backlink,
   without changing its substantive decision;
4. update the root README, contributing guide, governing-document index,
   decision index, current progress record, required-file check and Apple
   platform-policy check, and update this ADR's own platform-record link;
5. add an Unreleased changelog entry for the identifier correction while
   preserving the v0.1.1 changelog and release evidence;
6. regenerate the manifest, inventory and checksum ledgers; and
7. implement, if it is not already available, and run a focused file-backed
   ADR-register checker for the identifier, filename, heading and MTA-collision
   rules in the Validation section; and
8. run `validate-docs.sh`, `check_required_files.py`,
   `check_apple_platform_policy.py`, `check_manifest_paths.py` and
   `check_release_integrity.py` as the focused migration checks.

No rename, identifier mutation or live-reference migration may be committed
before governance approval.

## Supersession

This ADR does not supersede either substantive decision. Acceptance corrects
and retires only the conflicting local identifier assignment, retains its
history and establishes the platform record's mapping to `ADR-0025`.

## References

- [Voxelia Master Technical Architecture v0.1.1, sections 2.4 and Appendix A](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, VOX-REP-004](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1, section 9.2](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
- [Current architecture decision index](README.md)
- [Accepted Apple-platform decision with the conflicting local identifier](ADR-0001-apple-ecosystem-only.md)
