# CCR-0023 - Controlled correction for ADR-0057 provenance claim leaves

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0023` |
| Authority | Accepted [`ADR-0057`](../decisions/ADR-0057-provenance-claim-leaf-shapes.md) |
| Approved by | Project owner (recorded autonomous delegation of 2026-08-04) |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

## Corrections

### CCR-0023-A - Software identity profile

Target: the CDMS `SoftwareIdentity` sketch (section 36.3).

The corrected record binds every string field (`name`, optional
`commit`, optional `buildIdentifier`) to the accepted identity field
profile — 255-UTF-8-byte inclusive ceiling checked before content
rules, control-scalar rejection, frozen blank oracle — with exact
accepted UTF-8 comparison, and compares the semantic version exactly
including build metadata.

### CCR-0023-B - Operation provenance contract

Target: the CDMS `OperationProvenance` sketch (section 36.4).

The corrected record replaces the raw operation and implementation
strings with `DerivationOperationToken` values from the shared
semantic-operation naming domain, requires the implementation
identifier and exact implementation version, compares every version
exactly including build metadata and constrains `parameterDigest` to
the registered `org.voxelia.operation-parameters` projection with
every other tuple a typed rejection.

### CCR-0023-C - Execution provenance supersession note

Target: the CDMS `ExecutionProvenance` sketch (section 36.5).

The displayed record naming undeclared live descriptor types is
superseded by the accepted `ADR-0051` `ExecutionProvenanceClaim`
backend-neutral value.

### CCR-0023-D - Validation claim

Target: the CDMS `ValidationStatus` sketch (section 36.6).

The corrected claim is `ProvenanceValidationClaim`: `unknown`,
`experimental`, `preview`, `validated` and `diagnosticReady` carrying
a bounded `ValidationEvidenceID` under the accepted persistent
identifier exactness rule, and a payload-free `deprecated` case. The
displayed free-text deprecation reason is removed; deprecation context
belongs to governed warning codes. A decoded case is a claim referring
to separately governed evidence, and no ordering exists between cases.

### CCR-0023-E - Warning record correction (late record)

Target: the CDMS `ProvenanceWarning` sketch (section 36.7).

Under the authority of accepted `ADR-0052`, whose increment omitted
this correction record: the corrected warning is the accepted
`ProvenanceWarning` — governed bounded code, schema version, closed
severity and checked occurrence count — and the displayed free-text
`message` field is removed.

## Scope and limits

- The provenance record aggregate, its structural rules, the graph
  admission contract and every wire remain bound to their own
  decisions.
- A validation claim confers no evidence authority; evaluation belongs
  to `VoxeliaValidation` and approved governance per `ADR-0038`.

## References

- [ADR-0057 - Provenance claim leaf shapes](../decisions/ADR-0057-provenance-claim-leaf-shapes.md)
- [ADR-0052 - Provenance warning schema](../decisions/ADR-0052-provenance-warning-schema.md)
- [ADR-0038 - Closed provenance record and graph admission boundary](../decisions/ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [Voxelia Core Data Model Specification v0.1.1, section 36](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
