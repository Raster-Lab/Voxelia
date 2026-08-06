---
document_id: "ADR-0267"
title: "Direct codec declaration"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-LIC-007"
  - "VOX-LIC-008"
  - "VOX-LIC-009"
  - "VOX-REP-009"
  - "VOX-CMP-002"
  - "VOX-CMP-007"
  - "VOX-CMP-009"
---

# ADR-0267 - Direct codec declaration

## Context

`ADR-0266` recorded the owner's authorisation to declare a codec directly. This is
that step: `J2KSwift` becomes Voxelia's second declared dependency, linked only into
`VoxeliaCompression`.

`J2KSwift 11.0.2` was already in the approved closure as a transitive DICOMKit
dependency with its licence file read, so this widens a **linkage** claim rather than
a trust decision — and it is still a change only the owner may authorise, which is why
it waited.

## Decision

1. **`J2KSwift` is pinned exactly at `11.0.2`**, matching the version already
   resolved, so the direct declaration introduces no new code into the build.
2. **`VoxeliaCompression` links `J2KCodec` and `J2K3D`, and nothing else.**
   `J2K3D` carries `JP3DDecoder`, which `VOX-CMP-004` (JPEG 2000 Part 10) and
   `VOX-CMP-005` (HTJ2K) both need, and whose region decode matches `VOX-CMP-003`'s
   brick case. The other products stay unlinked.
3. **`J2KMetal` is refused, and reading the product list first is why.** The codec
   package ships a Metal product. Linking it into `VoxeliaCompression` would put a
   Metal surface inside the module `VOX-CMP-007` exists to keep away from textures.
   It is now barred by name in `check_prohibited_imports.py` alongside `Metal` and
   `MetalKit`, so the prohibition covers the codec's Metal product as firmly as
   Apple's.
4. **The licence gate is widened explicitly, never bypassed.** `APPROVED_DECLARED`
   gains one exact pin with the authorisation cited in a comment, and
   `TARGETS_PERMITTED_EXTERNAL_PRODUCTS` gains `VoxeliaCompression` and its test
   target. The gate's own message says "Do not widen this list to make the gate
   pass" — the widening is the authorised change the message anticipates, not a way
   around it.
5. **The four remaining codec packages stay transitive.** Declaring packages no row
   needs would assert linkage Voxelia does not have.

## The finding: the decode session could not have hosted a real codec

Reading `J2KSwift`'s API before writing an adapter showed
`JP3DDecoder.decode(_ data:)` is **`async throws`**.

`ADR-0259`'s `CompressedDecodeSession.decode` took a **synchronous** closure,
`(CompressedPayload) throws -> DecodedSamples`. **A synchronous closure cannot host
an async codec**, so the session as designed could not have been wired to the real
decoder at all.

The cause is familiar and worth naming as a repeat: the session's shape was settled by
the tests that exercised it, and those supplied bytes synchronously because no codec
existed. It is the same failure `ADR-0235` recorded against `ADR-0230` decision 10 —
a contract chosen before the dependency's API was read — and this project has now made
it twice.

**Corrected here rather than deferred**: the closure and the method are `async`. The
change is small because a synchronous closure still satisfies an `async` parameter, so
no caller had to change its closure. Every call site does now `await`, which the
existing tests adopted.

**A smaller correction inside the same change**: the first version of the source note
claimed "no existing caller changed". That was wrong — the test call sites changed. The
note now says so, because a comment that overstates compatibility is the kind of thing
a later reader trusts.

## The gate was negative-tested after being widened

A gate that has just been relaxed is exactly the gate that should be re-checked, so all
three failure modes were re-run against the new configuration:

| Attempt | Result |
|---|---|
| A third, unapproved package declared | **refused** |
| Version drift on the new pin (`11.0.2` to `11.0.3`) | **refused** |
| `VoxeliaStorage` linking `J2KCodec` | **refused** |

The gate still bites on everything except the one change it was authorised to permit.

## Alternatives considered

### Link `J2KFileFormat` too, for `decodeAnyFormat`

Deferred. It is the convenient entry point, and no row needs format sniffing yet.
`VOX-CMP-006` may want it when it documents actual codec output; that increment can
declare it.

### Link `J2KDICOMHelpers`, which ships a transfer syntax UID enum

Deferred deliberately, and it is worth recording why it is tempting. `VOX-CMP-013`'s
`CompressedRepresentation` admits UID-shaped identifiers without validating them
against any registry, and this product offers an authoritative enum. But adopting it
would make a Voxelia correctness rule depend on a codec package's vocabulary, and
`ADR-0257` deliberately admits a *shape* rather than a registry. Worth assessing on
its merits in its own increment, not adopted as a side effect of a linkage change.

### Declare all five codec packages now

Rejected; see decision 5.

### Keep the session synchronous and wrap the codec in a blocking call

Rejected. Blocking a thread on an async codec inside a library is the kind of thing
that deadlocks under an actor, and it would hide the async boundary rather than model
it.

## Consequences

`VoxeliaCompression` can now reach a real codec. The adapter itself is the next
increment.

The decode session's signature is correct for the codec it will host, found before an
adapter was built around the wrong shape rather than after.

Voxelia has two declared dependencies. The licence policy reports "2 declared
dependency and a 7-package approved closure".

## Affected modules

`VoxeliaCompression` gains two external product dependencies. `Package.swift`,
`check_licence_policy.py` and `check_prohibited_imports.py` change. No source outside
`CompressedDecodeSession`'s signature changes.

## Compatibility impact

`CompressedDecodeSession.decode` is now `async`. Callers must `await`; closures need
no change.

## Security impact

**A direct codec dependency widens the linked attack surface**, which is precisely why
`ADR-0266` authorised `VOX-CMP-011`'s adversarial testing in the same decision rather
than behind it. `J2KMetal` is barred, so the widening does not reach the Metal path.

## Performance and memory impact

None yet; nothing calls the codec.

## Validation impact

```text
swift build && swift test
python3 Tools/Scripts/check_licence_policy.py
python3 Tools/Scripts/check_prohibited_imports.py
python3 Tools/Scripts/check_package_graph.py
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1067 tests in 198 suites pass, and the licence gate's three failure modes were
re-verified after widening.

## Migration

1. This record.
2. **Next**: a real `J2KSwift` adapter behind `CompressedDecodeSession`, mapping
   `J2KImage`'s width, height and components onto `DecodedSampleClaim`.
3. Then `VOX-CMP-004`, `005`, `006`, `012`, `014`, with `011`'s adversarial work last
   so the adapter is settled before it is attacked.

## Supersession

This record supersedes nothing. It **corrects `ADR-0259`'s synchronous decode
closure**, recording the correction here rather than editing that record.

## References

- [ADR-0230 - CT affine volume construction](ADR-0230-ct-affine-volume-construction.md)
- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [ADR-0256 - Compression module boundary](ADR-0256-compression-module-boundary.md)
- [ADR-0257 - Toolkit native representation labelling](ADR-0257-toolkit-native-representation-labelling.md)
- [ADR-0259 - Cancellable decode session](ADR-0259-cancellable-decode-session.md)
- [ADR-0266 - Draw loop and codec authorisation](ADR-0266-draw-loop-and-codec-authorisation.md)
