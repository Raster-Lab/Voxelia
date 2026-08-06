---
document_id: "ADR-0256"
title: "Compression module boundary"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SEC-001"
  - "VOX-CMP-002"
  - "VOX-CMP-007"
---

# ADR-0256 - Compression module boundary

## Context

`ADR-0255` opened the compression arc and ordered its increments. This is
increment (a): `VOX-CMP-002`, which requires codec integration to be isolated in
`VoxeliaCompression`, and `VOX-CMP-007`, which requires that compressed data is
never treated as directly sampleable Metal texture data.

Both are chosen first because **neither needs a codec dependency**, and the two
supply-chain questions `ADR-0255` referred to the owner are still open. The
boundary is worth establishing before a codec arrives rather than retrofitted
around one.

## Decision

1. **`VoxeliaCompression` is added, depending on `VoxeliaCore` alone.** It needs
   `ScalarFormat` to describe what a decode claims to produce and nothing more;
   depending on `VoxeliaStorage` or higher would let it reach the reconstruction
   and rendering contracts it must stay below.
2. **`VOX-CMP-007` is enforced three independent ways, none of them a comment
   asking the reader to be careful:**
   - `CompressedPayload` **does not conform to `ImageStorageContract`**, so the
     accepted storage and render paths cannot consume it in place of decoded
     samples. A test asserts the non-conformance.
   - **`VoxeliaCompression` may not import Metal**, so the module cannot construct
     a texture at all.
   - **`VoxeliaMetal` may not import `VoxeliaCompression`**, so the module that
     *can* build textures cannot even name a compressed value.

   The third is the strongest and is the one a reader would not think to add.
   `ADR-0196` found a record claiming independence that no tooling enforced; that
   lesson is applied here in advance of an audit rather than after one.
3. **The payload carries no format identifier.** It names no codec, transfer
   syntax or container format. `VOX-CMP-013` requires that a toolkit-native
   representation is never represented as a standard DICOM transfer syntax, and a
   format field added here would have to be either a bare string — which is
   exactly how a toolkit-native cache gets mislabelled as interoperable — or a
   vocabulary this increment has no rule to constrain. Labelling is increment (b).
4. **Every shape-bearing member is named `declared`.** `declaredExtents`,
   `declaredScalarFormat`, `declaredDecodedByteCount` are what the *source* says
   the codestream decodes to. Nothing here verifies that, because verifying it
   requires decoding, which requires a codec. The naming is what stops a claim
   being read as a measurement, and checking a decode against these declarations
   is `VOX-CMP-010`'s job.
5. **The decoded byte count is derived at admission, never supplied.** A
   separately provided count would be a second place for one fact to live and
   could disagree with the extents it came from.
6. **The declared shape's product is checked for overflow, not argued.** A hostile
   or corrupt source can declare extents whose product exceeds the host integer
   range, and this is the only place that product is formed. Both multiplications
   — sample count, then bytes per sample — are checked, and a maximal admissible
   shape is tested from the accepted side so the checks are known to reject only
   what genuinely overflows. This follows `ADR-0235` decision 5's reasoning about
   where being wrong is unrecoverable.
7. **The failure family is payload-free**, and here that matters more than usual: a
   malformed codestream is exactly the input where a diagnostic quoting lengths or
   extents becomes an information leak.
8. **No algorithm specification and no oracle.** The only arithmetic is a checked
   product; no numeric boundary is frozen.

## The finding: two graph checks could not see a new module

Adding a target exposed a gap in the tooling that was supposed to police the
package graph. **`check_package_graph.py` and `check_package_graph_static.py` both
iterate over their own `EXPECTED` map**, so a target absent from that map was never
visited — and therefore never checked.

The consequence was already live, not hypothetical: **`VoxeliaDICOMKit` had been
unregistered since `ADR-0233`**, and its dependencies had never been graph-reviewed
by either tool. `VoxeliaTestSupport` had never been reviewed either.

Both checks now fail on any Voxelia target the manifest declares and the map omits,
and all three missing targets are registered. Test targets are excluded from the
rule, because they depend on products by design and are not part of the layered
graph.

**Both failure modes were negative-tested rather than assumed:** unregistering
`VoxeliaCompression` produces "unregistered Voxelia targets: VoxeliaCompression",
and declaring a wrong dependency produces "expected ['VoxeliaImaging'], got
['VoxeliaCore']". The `VOX-CMP-007` boundary was negative-tested too — adding
`import VoxeliaCompression` to a `VoxeliaMetal` source produces the expected
refusal.

One limitation recorded rather than hidden: the dynamic check extracts only
`byName` dependencies, so `VoxeliaDICOMKit`'s external `DICOMKit` product linkage
is invisible to it. That linkage is gated by `check_licence_policy.py`'s
`TARGETS_PERMITTED_EXTERNAL_PRODUCTS` instead, and the expectation carries a
comment saying so rather than silently listing a dependency the extractor cannot
see.

## Alternatives considered

### Make the payload conform to `ImageStorageContract` for pipeline convenience

Rejected, and it is the whole point of `VOX-CMP-007`. A conforming compressed
payload would be bindable wherever decoded samples are, which is precisely the
confusion the requirement forbids.

### Enforce "never sampleable" by documentation and review

Rejected; see decision 2. `ADR-0196` recorded a case where two accepted places
asserted an independence that tooling did not enforce. Three enforcements cost one
tool edit.

### Depend on `VoxeliaStorage` so the module can describe storage

Rejected. It would place `VoxeliaCompression` beside the reconstruction stack
rather than below it, and nothing in this increment needs the storage contract.

### Include a format or transfer-syntax identifier now

Rejected; see decision 3. Getting the standard-versus-toolkit-native distinction
right is `VOX-CMP-013`'s own increment, and a string field added early is how that
distinction gets lost.

### Register only `VoxeliaCompression` in the graph checks and leave the gap

Rejected. Registering one module while the check still cannot notice the next one
would leave the tool asserting more than it verifies.

## Consequences

`VoxeliaCompression` exists as an enforced boundary with no codec attached, so
increments (b) to (e) can proceed while the owner's two supply-chain questions stay
open.

**The package graph is now genuinely checked**, and two targets that had escaped
review since `ADR-0233` are registered.

`VOX-CMP-002` and `VOX-CMP-007` are discharged in their `I` and `T` methods:
inspection of the module boundary and the enforcing tooling, and tests for the
non-conformance and the admissions.

## Affected modules

`VoxeliaCompression` is new. `Package.swift` gains a product, a target and a test
target. No existing module's dependencies change.

## Compatibility impact

Additive.

## Security impact

Positive, and this is the increment's most load-bearing part. Compressed bytes
cannot reach a texture binding by construction rather than by discipline. The
overflow check makes a hostile declared shape a typed refusal instead of a trap,
and the failure family discloses nothing about the codestream.

## Performance and memory impact

None. The payload stores the codestream it is given and computes one product.

## Validation impact

```text
swift build && swift test
swift test --filter "CompressedPayload"
python3 Tools/Scripts/check_prohibited_imports.py
python3 Tools/Scripts/check_package_graph_static.py
python3 Tools/Scripts/check_package_graph.py
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1031 tests in 192 suites pass. `VoxeliaCompression.doccarchive` is registered in
`check_docc_archives.py`.

## Migration

1. This record: the module, the payload, and the three enforcements.
2. Increment (b): `VOX-CMP-013`, the labelling rule that lets a format identifier
   exist safely.
3. Then (c) `VOX-CMP-010`, (d) `VOX-CMP-009`, (e) `VOX-CMP-003` and `VOX-CMP-008`.
4. **Owner decisions, unchanged**: reconciling the six blocked rows, and whether a
   codec may be declared a direct dependency.

## Supersession

This record supersedes nothing. It **corrects a tooling gap** that let
`VoxeliaDICOMKit` escape graph review from `ADR-0233` onward, recording the
correction here rather than editing that record.

## References

- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0233 - DICOMKit adapter and dependency](ADR-0233-dicomkit-adapter-and-dependency.md)
- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [ADR-0255 - Open the compression arc](ADR-0255-open-the-compression-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
