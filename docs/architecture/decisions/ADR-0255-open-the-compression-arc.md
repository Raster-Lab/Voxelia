---
document_id: "ADR-0255"
title: "Open the compression arc"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CMP-002"
  - "VOX-CMP-003"
  - "VOX-CMP-004"
  - "VOX-CMP-005"
  - "VOX-CMP-006"
  - "VOX-CMP-007"
  - "VOX-CMP-008"
  - "VOX-CMP-009"
  - "VOX-CMP-010"
  - "VOX-CMP-011"
  - "VOX-CMP-012"
  - "VOX-CMP-013"
  - "VOX-CMP-014"
---

# ADR-0255 - Open the compression arc

## Context

With the first vertical slice's claimable work discharged (`ADR-0254`), the
project's largest remaining debt is a single coherent block: **all thirteen
untraced requirements in `docs/progress/untraced-requirements.txt` are
`VOX-CMP-002` through `VOX-CMP-014`.** They are not scattered debt; they are one
unopened arc.

M5 is entered — `check_requirement_traceability.py` records
`HIGHEST_ENTERED_MILESTONE = 6` — so these rows are due rather than premature.

`VOX-CMP-001`, the arc's own supply-chain row, is already traced by `ADR-0231` and
`ADR-0233` and was released by the owner's approval of the Raster-Lab codec
libraries. That approval is what makes opening this arc possible at all.

This record opens the arc: decomposition and binding rules only. It freezes no
numeric boundary, so it carries no algorithm specification and no oracle, following
`ADR-0197` and `ADR-0208`.

## Landscape: the arc is greenfield

- **`VoxeliaCompression` does not exist.** `VOX-CMP-002` requires codec integration
  to be isolated in it.
- **No transfer-syntax vocabulary exists anywhere in `Sources`.** Nothing reads,
  names or dispatches on a DICOM transfer syntax.
- **`VoxeliaDICOMKit` touches no compression.** The adapter reads geometry and
  sample attributes; `DICOMFrameTransfer` asks DICOMKit for decoded frame bytes and
  never sees a codestream.

So nothing here is a composition of existing parts, which distinguishes this arc
from the last several.

## The finding: the arc splits in two, and one half conflicts with a standing owner instruction

Reading each row for **whose behaviour it constrains** — Voxelia's boundary, or the
codec's — produces a clean split.

**Buildable now, because the subject is Voxelia's own boundary:**

| Row | Methods | Subject |
|---|---|---|
| `VOX-CMP-002` | `I,T` | Module isolation — a `VoxeliaCompression` target and adapters |
| `VOX-CMP-003` | `I,T` | Adapter shapes for sources, slices, slabs and bricks |
| `VOX-CMP-007` | `I,T` | Compressed data is never a sampleable Metal texture |
| `VOX-CMP-008` | `T,A` | Caller-provided or reusable destination storage |
| `VOX-CMP-009` | `T` | Adapter cancellation, and no partial data published as complete |
| `VOX-CMP-010` | `T` | Adapter validation of dimensions, formats and byte counts |
| `VOX-CMP-013` | `I,T` | JP3D is never represented as a standard transfer syntax |

**Requires characterising the Raster-Lab codecs, and therefore blocked:**

| Row | Methods | What it needs from the codec |
|---|---|---|
| `VOX-CMP-004` | `A,T` | JP3D lossless 3D evaluated as a volume cache — needs measured codec output |
| `VOX-CMP-005` | `A,T` | HTJ2K evaluated for throughput — needs measured encode and decode |
| `VOX-CMP-006` | `I,T,R` | "the **actual** Raster-Lab codec output and interoperability status are **documented**" |
| `VOX-CMP-011` | `T,A` | Bounded failure on **malformed or adversarial codestreams** |
| `VOX-CMP-012` | `T,R` | Original DICOM preserved when toolkit-native caches are generated |
| `VOX-CMP-014` | `T,A` | Ratio, encode time, decode time, random-access cost, memory, output equality |

**The second column is exactly what the owner instructed this project not to do.**
The instruction, verbatim:

> "These library are used and tested multiple times I dont need you to divert a new
> for testing the applicaition our target is to complete Voxiliea"

alongside the conditional:

> "If any bugs found on the library the we need to address it and fix it"

Those two together read as: fix defects that surface in the course of building
Voxelia, but do not go looking. **`VOX-CMP-011` requires going looking** — feeding
adversarial codestreams to a codec is a search for defects in it, not a by-product
of building. `VOX-CMP-004`, `005`, `006` and `014` require measuring and
documenting codec behaviour, which is characterisation of the dependency.

**This is a genuine conflict between an accepted requirement baseline and a
standing owner instruction, and it is not this project's to resolve.** Proceeding
would disregard the instruction; silently dropping the rows would leave P0
requirements unmet without saying so. So it is stated here and referred to the
owner, and meanwhile the buildable half proceeds.

## A distinction that reduces the blocked set

`VOX-CMP-010` and `VOX-CMP-011` look similar and are not.

**`VOX-CMP-010` is adapter-side and fully buildable.** Validating declared
dimensions, component formats and decoded byte counts is an admission Voxelia
performs on values it holds — before and after a decode — and testing it tests
Voxelia's adapter, not the codec.

**`VOX-CMP-011` is not fully achievable adapter-side**, and the reason is worth
stating rather than glossing: a codestream cannot be validated without parsing it,
and parsing it is the codec's job. An adapter can bound *its own* exposure —
refusing implausible declared extents before allocating, capping the destination,
and rejecting a decode whose output byte count disagrees with the admitted layout —
but if a codec faults on malformed input, no adapter-side check prevents that.

So the adapter-side mitigation is real and worth building under `VOX-CMP-010`; it
narrows `VOX-CMP-011`'s residual exposure without closing it, and the record should
not claim otherwise.

## A second supply-chain distinction the owner may need to make

The five codec packages — `J2KSwift`, `JLSwift`, `JLISwift`, `JXLSwift`,
`CompressionFamily` — are currently approved as **transitive dependencies of
DICOMKit**. `Package.swift` declares exactly one dependency, and
`check_licence_policy.py` enforces that: `APPROVED_DECLARED` holds one exact pin,
and the five codecs sit in `APPROVED_CLOSURE`.

`VOX-CMP-002`'s adapters would very likely need at least one codec **declared
directly**, which is a different act from tolerating it transitively: it changes
what Voxelia links against by name and what its manifest asserts. The licence gate
would refuse it today, correctly.

Whether direct declaration is authorised is therefore an owner question of its own,
separate from the approval already given. It is raised now rather than discovered
when a build fails.

## Decision

1. **The arc is opened, and its decomposition is the split above**: the seven
   Voxelia-boundary rows proceed; the six codec-characterisation rows are recorded
   as blocked on an owner reconciliation.
2. **No codec is characterised, benchmarked or fuzzed by this project** until the
   owner reconciles the requirement baseline with the standing instruction. This
   record does not decide which should give way.
3. **No codec is declared as a direct `Package.swift` dependency** until the owner
   authorises it. The licence gate stays as it is; it is doing its job.
4. **Binding rules for every increment in this arc**, stated once here:
   - **Compressed bytes are never sampleable.** `VOX-CMP-007` is an architectural
     invariant, not a caution: no compressed representation may be bound as a
     Metal texture or handed to a sampler. Enforce it with tooling, following
     `ADR-0196`'s lesson that a claimed independence nothing enforces is not one.
   - **A toolkit-native representation is never labelled a standard transfer
     syntax.** `VOX-CMP-013`. Mislabelling a JP3D cache as a DICOM transfer syntax
     would make Voxelia produce objects that claim interoperability they do not
     have — the most consequential correctness rule in the arc.
   - **The original instance is preserved.** `VOX-CMP-012`. A generated cache is
     derived data and never replaces its source.
   - **Cancellation publishes nothing.** `VOX-CMP-009` reuses `ADR-0249`'s accepted
     shape — a checkpoint enum, an injected probe, a `.final` check before the
     publication aggregate — rather than inventing a second cancellation model.
   - **Validation is admission, not inspection.** `VOX-CMP-010`'s checks reject
     typed and payload-free, consistent with every other failure family.
   - **A decode is a value transformation, not a geometry decision.** Nothing in
     this arc may re-derive spacing, orientation or a rescale; `ADR-0235`
     decision 2's boundary holds.
5. **`VoxeliaCompression` sits above `VoxeliaCore` and below `VoxeliaImaging`**, by
   the same reasoning that placed `VoxeliaDICOMKit`: it produces sample bytes and
   descriptors, and must not depend on reconstruction or rendering. Its exact
   position is the implementing record's to fix, not this one's.
6. **No algorithm specification and no oracle**, because no numeric boundary is
   frozen here.

## Increment order

1. **(a)** `VOX-CMP-002` and `VOX-CMP-007`: the `VoxeliaCompression` target, its
   vocabulary, and the tooling that enforces "never sampleable". No codec
   dependency is needed for either — the module can exist with adapters declared
   and no codec linked, which is also the cheapest way to establish the boundary
   before the supply-chain question is answered.
2. **(b)** `VOX-CMP-013`: the labelling invariant, with a test that a
   toolkit-native representation cannot be presented as a standard transfer syntax.
3. **(c)** `VOX-CMP-010`: adapter admission — dimensions, component formats,
   decoded byte counts — with the destination ceiling that narrows `VOX-CMP-011`.
4. **(d)** `VOX-CMP-009`: adapter cancellation, composing `ADR-0249`.
5. **(e)** `VOX-CMP-003` and `VOX-CMP-008`: the source, slice, slab and brick
   shapes, and caller-provided destination storage.
6. **Blocked**: `VOX-CMP-004`, `005`, `006`, `011`, `012`, `014`.

## Alternatives considered

### Proceed with the codec characterisation rows anyway

Rejected. The owner's instruction is explicit and recent, and the requirement
baseline is not authority to override it. Raising the conflict costs one record;
disregarding it would spend an arc's worth of work the owner said not to spend.

### Drop the six blocked rows from the traceability debt

Rejected outright. They are P0. Removing them from
`untraced-requirements.txt` would make the debt look smaller while nothing changed,
and that file's own comment says a line may be removed only "when its row is
genuinely traced".

### Declare a codec dependency now and ask afterwards

Rejected. It is a supply-chain change, which is the one category this project has
consistently reserved to the owner, and the licence gate would refuse it — correctly.

### Wait for the owner before opening the arc at all

Rejected. Five increments need no codec and no new dependency, and the module
boundary is worth establishing before any codec arrives rather than retrofitted
around one.

## Consequences

The last untraced debt block has an opened arc, a decomposition, and binding rules.
Five increments can proceed immediately.

**The traceability debt baseline is now empty.** Naming these thirteen rows traced
them by `check_requirement_traceability.py`'s definition — named in a decision
record — so all thirteen were removed from `docs/progress/untraced-requirements.txt`
and the check reports **356 requirements in entered milestones, 0 untraced**.

That file now carries an explicit warning, because the distinction matters:
**traced is not satisfied.** Six of these rows are blocked, and an empty allowlist
must not be read as an arc completed. The ratchet measures whether a requirement is
accounted for, not whether it is met.

**Two new owner questions are on the table**, both raised before they could become
blocked work discovered mid-increment:

1. Reconcile `VOX-CMP-004`, `005`, `006`, `011`, `012` and `014` — which require
   characterising, benchmarking and adversarially testing the Raster-Lab codecs —
   with the standing instruction not to divert into testing those libraries.
2. Whether any codec may be declared a **direct** dependency, given the current
   approval covers them transitively through DICOMKit.

These join the six from `ADR-0254`.

## Affected modules

None yet. This record adds no source and no dependency.

## Compatibility impact

None.

## Security impact

None yet, and two of the arc's rules are security-bearing: compressed bytes never
sampleable (`VOX-CMP-007`) and bounded failure on hostile input (`VOX-CMP-011`,
blocked). `VOX-CMP-011`'s residual exposure is named above rather than assumed
away.

## Performance and memory impact

None yet.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

No source changed, so no build or test result is claimed for this record.

## Migration

1. This record.
2. Increments (a) to (e) above.
3. **Owner decisions**: the two questions under Consequences.

## Supersession

This record supersedes nothing.

## References

- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0231 - DICOMKit supply chain assessment](ADR-0231-dicomkit-supply-chain-assessment.md)
- [ADR-0233 - DICOMKit adapter and dependency](ADR-0233-dicomkit-adapter-and-dependency.md)
- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [ADR-0254 - First slice validation and benchmark reports](ADR-0254-first-slice-validation-and-benchmark-reports.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
