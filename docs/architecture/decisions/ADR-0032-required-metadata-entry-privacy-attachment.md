---
document_id: "ADR-0032"
title: "Required metadata-entry privacy attachment"
status: "Proposed"
date: "2026-08-03"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-003"
  - "VOX-GOV-005"
  - "VOX-GOV-006"
  - "VOX-ARC-003"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-API-010"
  - "VOX-DAT-014"
  - "VOX-META-001"
  - "VOX-META-002"
  - "VOX-ERR-001"
  - "VOX-ERR-007"
  - "VOX-SEC-006"
  - "VOX-VAL-007"
---

# ADR-0032 - Required metadata-entry privacy attachment

## Context

The Core Data Model Specification separately sketches a two-field general
metadata entry and says that metadata may carry one of five privacy
classifications:

```swift
public struct MetadataEntry: Sendable, Hashable, Codable {
    public let key: AnyMetadataKey
    public let value: MetadataValue
}

public enum MetadataPrivacyClass: String, Sendable, Hashable, Codable {
    case publicData
    case technical
    case potentiallyIdentifying
    case sensitive
    case hostDefined
}
```

It does not attach the classification, define absence or a default, order the
cases, resolve `hostDefined`, scope a classification over recursive values or
state how it participates in identity and serialisation. Publishing the
two-field entry first would make unclassified records directly constructible
and serialisable. Adding a third field later would then break construction,
equality, hashing and the wire shape.

`MetadataPrivacyClass` already exists in `VoxeliaCore` as the exact five-case
raw-string vocabulary. Its previously synthesised decoder was independently
hardened before this proposal: malformed or unknown input now produces a fixed
empty-path `DecodingError` without retaining the rejected token, arbitrary
caller path or underlying decoder error. That correction preserves every valid
raw value and wire byte. This ADR does not reopen or add to the taxonomy.

Proposed `ADR-0031` deliberately distinguishes a privacy-neutral recursive
`MetadataObject.Member` from the general collection entry. A member supplies
only structural key/value pairing inside one recursive value. Treating it as a
general entry, or publishing implicit conversions between the two types, would
erase the very privacy boundary that separation was designed to preserve.

The Project Foundation assigns authentication, authorisation, patient privacy,
retention and access auditing to the host, while requiring the library to
avoid patient data in logs by default. A classification therefore cannot be an
access-control decision. It is an immutable restriction signal that a trusted
host policy evaluates together with namespace rules, provenance, destination,
purpose and principal.

Healthcare standards provide precedent but do not define Voxelia's taxonomy.
FHIR security labels attach metadata to the resource they govern and feed a
separate decision engine operating under a wider trust framework. DICOM's
confidentiality guidance treats nested sequence content as part of the
enclosing protected attribute and warns that de-identification remains
context-dependent. Apple logging privacy is a sink-specific redaction choice,
not a portable metadata-classification lattice. This ADR claims no conformance
or direct mapping to any of those systems.

This proposal decides only the general entry's privacy attachment, local
identity/wire semantics, whole-entry scope and the minimum fail-closed rules
that prohibit implicit library reclassification. It does not decide collection
multiplicity or indexing, typed access, a public host-policy resolver,
authentication, export workflows, audit storage, canonical byte ingress or a
persistent data digest. Its Proposed status does not authorise
`MetadataEntry` source or controlled-document changes.

## Decision

If this ADR and its value dependencies are accepted, `VoxeliaCore` will own
the following general entry:

```swift
public struct MetadataEntry: Sendable, Hashable, Codable {
    public let key: AnyMetadataKey
    public let value: MetadataValue
    public let privacyClass: MetadataPrivacyClass

    public init(
        key: AnyMetadataKey,
        value: MetadataValue,
        privacyClass: MetadataPrivacyClass
    )
}
```

The initializer is nonthrowing because its three inputs are already validated
values. It has no default argument, two-argument overload or optional
classification. There is no valid unclassified `MetadataEntry`.

### Required attachment and authority

Every general entry carries exactly one explicit `privacyClass`. Missing,
null, unknown or wrong-shaped classification input is invalid and never
defaults to another case. This corrects the controlled phrase “may carry” to a
safe distinction:

- every general `MetadataEntry` is classified; and
- privacy-neutral `MetadataValue` and `MetadataObject.Member` building blocks
  do not independently carry disclosure authority.

The declared class is an assertion from the constructing caller or adapter. It
may require stricter treatment, but it never grants logging, export or access.
Wire-supplied labels are data, not trusted authority. A host may enforce a
stricter namespace, source, destination or purpose rule than the declaration.

No case is an implicit default:

- `publicData` is not blanket permission to disclose;
- `technical` is not permission to place raw keys or values in diagnostics;
- `potentiallyIdentifying` and `sensitive` remain distinct policy inputs;
- `hostDefined` means that trusted host policy must supply context-dependent
  interpretation before host-directed reclassification or disclosure; and
- none means unknown, absent or unclassified.

`hostDefined` is not portable policy identity. The payload-free raw case does
not say which host, resolver, policy version or custom category produced it.
Receiving code without the trusted originating policy must leave it unresolved
and fail closed. Unknown wire strings are rejected rather than coerced to
`hostDefined`. A future need for portable custom categories requires a
separate versioned policy-identity record and is not inferred here.

Core adds no resolver protocol in version one. Resolver registration, trusted
namespace minima, principals, destinations, purposes, consent, declassification
and audit are host-owned contracts. A resolver failure must become a typed,
payload-free failure at the policy boundary; its public API and owning module
remain deferred until an actual consumer is approved.

### Exact preservation and aggregation

`MetadataPrivacyClass` does not conform to `Comparable` and gains no severity
ordinal, total or partial order, `max` or `join` helper, or Boolean disclosure
property. The case names mix data categories and handling obligations, and the
governed documents define no subsumption relation. Even `sensitive` cannot be
assumed to preserve every technical or host-specific obligation.

Library-owned one-to-one transformations preserve the exact stored class. An
operation that retains complete entries retains their declarations unchanged.
If multiple classified inputs must become one new entry, generic Core code
does exactly one of the following:

- preserves the inputs as separate entries;
- requires a trusted host to supply the output class explicitly under its
  versioned policy, with applicable provenance and audit; or
- returns a typed, payload-free failure.

Core never infers an aggregate class from the enum cases. A declared
`hostDefined` remains declared and unresolved through generic library
operations. Because the entry stores no host-policy identity, generic code
must preserve an input carrying `hostDefined` separately or fail. Producing a
new entry with a concrete class is an explicit, audited host reclassification;
it is not an automatic resolution or a mutation of the original declaration.

A public immutable value cannot enforce system-wide declassification policy.
An owning host can always construct a new entry with another class. This
contract prohibits implicit library reclassification and requires focused
preservation, explicit-reclassification and failure tests, but it does not
claim to defend against a caller or host that supplies an incorrect class.

### Scope over recursive values

The entry class governs the complete entry record:

- both arbitrary UTF-8 fields of `key`;
- the full `MetadataValue` payload;
- every array element;
- every nested object-member key and value; and
- presentation strings retained inside code and unit leaves.

Nested `MetadataObject.Member` remains privacy-neutral and stores no override.
This is whole-entry scope, not a second copied class on every child. A bare
`MetadataValue`, `MetadataArray`, `MetadataObject` or member carries no
permission to log or export and must be treated as potentially sensitive until
placed under trusted policy.

No implicit conversion is published between `MetadataEntry` and
`MetadataObject.Member`. Constructing an entry from a member requires an
explicit class. Projecting an entry to a member erases privacy information and
receives no convenience API. Private implementation reuse may not make that
erasure observable in the public surface.

Mixed-policy source data should remain separate entries where the future
namespace schema permits that representation. If a host deliberately combines
it into one object entry, the host supplies one explicit output class under its
own versioned policy and records applicable provenance or audit. Generic Core
code neither infers that class nor recovers child labels after a caller has
discarded them into privacy-neutral members.

### Equality, hashing and type-level Codable

Entry equality and hashing include all three semantic components:

1. exact `AnyMetadataKey` identity;
2. semantic `MetadataValue` identity selected by `ADR-0031`; and
3. the exact declared `MetadataPrivacyClass` case.

Two entries with the same key and value but different classes are unequal.
This prevents a set, cache or whole-entry deduplication step from silently
discarding a distinct handling restriction. Host resolver output, policy
version and an operation-local effective class are not stored and do not enter
entry identity.

Future collection duplicate detection must compare entry keys under the
approved namespace schema, not rely on whole-entry equality. Differently
classified records with the same key remain duplicate candidates unless that
schema explicitly permits multiplicity. Collection cardinality, ordering and
deduplication remain outside this ADR.

`MetadataEntry` implements Codable manually as exactly three fixed fields:

```json
{
  "key": {"namespace":"example","name":"field"},
  "value": {"string":"x"},
  "privacyClass": "potentiallyIdentifying"
}
```

Encoding always writes `key`, `value` and `privacyClass`. Decoding requires all
three and rejects missing, null, distinct extra, unknown or wrong-shaped
semantic fields. It never maps an unknown token to `hostDefined`.
The entry decoder catches child failures at each fixed field boundary and emits
a value-redacted error whose model-relative coding path contains only `key`,
`value` or `privacyClass`, never an arbitrary caller prefix. It may retain only
an explicitly audited payload-free project error as an underlying error; it
does not retain arbitrary Foundation, adapter or decoder failures.

Type-level encoding is storage representation, not export authorisation. A
caller can invoke an encoder without host context, so Codable cannot decide a
principal, purpose, destination, consent or sink policy. Ordinary encoder
output is also not canonical document bytes: `ADR-0031` permits semantically
equal code or unit leaves whose presentation text encodes differently.

Raw duplicate-member detection, field ordering, lexical JSON rules, schema
versions and a persistent canonical digest remain canonical-ingress work. Any
future canonical metadata-record projection must preserve the declared class
or define a separately named content-only identity that cannot be used for
privacy authorisation.

### Logging and export boundary

No privacy class makes `MetadataEntry`, its key or its value safe for direct
string interpolation. The type adds no textual/debug-description conformance
and no `isLoggable`, `canExport` or OSLog-privacy mapping. Swift reflection can
still expose stored fields, so hosts and library code must not pass raw entries
to generic diagnostic interpolation.

Default library logging and telemetry omit arbitrary entry keys and values for
all five classes. Fixed type names, fixed field vocabulary and aggregate counts
may be logged only where they cannot reveal source data. `.publicData` makes an
entry eligible for an explicitly configured trusted policy; it does not bypass
that decision. `.technical` may still identify devices, paths or institutions
and is not raw-log permission.

Disclosure requires trusted host policy that evaluates the declaration and
any stricter namespace/source rule against destination, purpose, principal and
consent. Unresolved `hostDefined`, missing policy or a destination unable to
preserve required handling fails closed. Whether a collection export rejects,
filters, redacts or reports denied entries is a future export/collection API
decision and must not be inferred from Codable.

Hosts retain responsibility for authentication, authorisation,
declassification approval, retention, access auditing, secure transport and
regulatory controls. Classifications support those decisions but do not replace
them.

### Error and privacy boundary

The already implemented `MetadataPrivacyClass` manual decoder preserves the
five exact successful raw strings and replaces all malformed/unknown failures
with a fixed empty-path `DecodingError.dataCorrupted`. It retains no raw token,
caller-controlled path or arbitrary underlying error.

Future entry-originated failures follow the same rule. They may name only the
fixed fields `key`, `value` and `privacyClass`. They never include a namespace,
name, value, rejected class token, raw JSON fragment, resolver text,
destination, principal or caller-supplied path. A host must still sanitise
errors produced before the entry decoder, by an arbitrary decoder, or by its
own policy implementation before logging.

## Alternatives considered

### Keep the two-field general entry

This exactly preserves the sketch but makes unclassified serialisable entries
public and leaves classification unattached. A later field would be a breaking
API and wire change. It is not safe by construction.

### Make privacyClass optional

An optional field would create a sixth implicit state absent from the governed
five-case vocabulary. Missing input could silently become `nil`, and synthesis
would omit it during encoding. Even if `nil` were documented as fail-closed, it
would overlap the unresolved purpose of explicitly selected `hostDefined` and
require every consumer to distinguish two unknown states. Required explicit
classification is smaller and safer.

### Give the required field a default

Defaulting to `publicData` is an obvious disclosure risk. `technical` and
`sensitive` invent source meaning, while `hostDefined` would turn omission into
a silently accepted unresolved policy. No case is an honest universal default.

### Add an unclassified enum case

This expands an already public and serialised taxonomy without a controlled
requirement and still permits ambiguous records. The strict entry contract
rejects missing classification instead.

### Publish a classified wrapper around a two-field MetadataEntry

That leaves the unclassified inner entry independently public, hashable and
serialisable and creates two competing record/wire surfaces. Direct attachment
to the one general entry is smaller and cannot be bypassed accidentally.

### Attach classification to MetadataValue

The key itself may be identifying, so a value-only label has the wrong scope.
It would also force structural recursive members to carry policy state and
make the same semantic value unequal merely because two hosts apply different
entry restrictions. General record policy belongs on the key/value pair.

### Classify every nested object member

This reopens `ADR-0031`, requires mixed-label aggregation inside every value,
and lets nested structural records masquerade as collection entries. Whole-
entry scope is sufficient for version one; heterogeneous policy remains in
separate general entries or receives one explicit outer classification.

### Define a total or partial privacy lattice

The controlled documents define no subsumption relation between the cases.
Their names mix data categories with handling obligations, so even a seemingly
conservative diamond can erase an obligation: replacing `technical` plus
`potentiallyIdentifying` with `sensitive` loses the original technical
declaration. Algebraic consistency does not prove policy fidelity. Ordering or
aggregation must wait for a governed, versioned policy schema rather than be
inferred from this enum.

### Treat hostDefined as sensitive automatically

This seems conservative but discards the fact that an unknown host obligation
remains unresolved. A recipient might then treat the record as fully resolved
and omit required custom handling. Unresolved policy fails closed until a
trusted resolver acts.

### Put a resolver or export protocol in VoxeliaCore now

No approved logger, destination, principal, policy-version or audit API exists.
Core owns the immutable restriction signal; host applications own operational
policy. A speculative protocol would freeze the wrong authority boundary.

### Make Codable enforce export policy

An encoder has no authenticated host, destination, purpose or consent context.
Treating encoding as disclosure authorisation would be both bypassable and
host-policy coupling. Storage representation and export permission remain
separate.

## Consequences

- Every future general entry has an explicit immutable privacy declaration;
  no unclassified public record or wire form exists.
- The class covers the arbitrary key and whole recursive value subtree, while
  privacy-neutral object members remain structural.
- Entry equality, hashing and semantic wire preserve handling distinctions.
- One-to-one library transformations preserve the exact declaration; generic
  multi-input aggregation preserves entries separately or requires explicit
  trusted-host classification, otherwise it fails.
- Default logging remains value-free for every class, and serialisation never
  becomes disclosure permission.
- The contract prohibits implicit library reclassification but correctly leaves
  deliberate host declassification, authorisation and audit to the owning
  application.
- The strict field requirement is less permissive than an optional reading of
  “may carry”; the controlled specification must be corrected before source.
- Resolver shape, portable custom policy identity, collection behaviour and
  canonical bytes remain explicit future work rather than hidden in the entry.
- No `MetadataEntry` implementation is authorised while this ADR or a value
  dependency remains Proposed.

## Affected modules

If accepted, `VoxeliaCore` owns `MetadataEntry` and continues to own
`MetadataPrivacyClass`, `AnyMetadataKey` and the proposed `MetadataValue`.
There is no new dependency edge, product or backend ownership.

Adapters construct explicitly classified entries under their source/host
policy. Imaging, Storage, provenance, DICOM, distributed, rendering and host
applications remain downstream consumers. Operational resolver, logging and
export APIs belong with a concrete host or appropriately approved higher-level
module, not in Core by convenience.

## Compatibility impact

No public `MetadataEntry`, `MetadataCollection`, recursive metadata source or
serialised entry fixture exists. Correcting the two-field sketch before
implementation moves no compiled symbol or persisted record.

`MetadataPrivacyClass` is already public. This proposal preserves its five
cases, raw values, equality, hashing and successful wire. The independent
manual-Codable hardening changed only malformed-input diagnostics from
source-reflecting synthesis to a fixed redacted `DecodingError`.

After implementation, the required third field, absence rejection,
whole-entry scope, exact class preservation, identity and field names become
pre-1.0 compatibility contracts. Adding optional legacy decoding or silently
supplying a default later would weaken the privacy invariant and requires a new
reviewed decision.

## Security impact

Required attachment prevents accidental construction, decoding or encoding of
an unclassified general entry. Whole-entry scope prevents an apparently safe
value label from overlooking sensitive key text or nested members.
Classification-sensitive identity prevents equal-value deduplication from
dropping a different restriction. Exact preservation and fail-closed
aggregation keep generic library code from silently rewriting declarations,
including unresolved `hostDefined`.

These controls do not validate that a caller chose the correct class and do
not authenticate a wire label. Malicious or mistaken callers can misclassify
data, and an owning host can construct a new lower-class entry. Trusted host
policy must enforce namespace/source floors, resolver registration,
declassification, consent, destination and audit.

Type-level decoding occurs after a general decoder may already have allocated
or reflected source text. Entry errors are value-redacted, but canonical and
adapter ingress must still bound input and sanitise upstream failures. Generic
reflection, encoder errors, resolver errors and host logs remain unsafe unless
their owning boundary explicitly redacts them.

The taxonomy does not prove de-identification. Pixel data, nested strings,
identifiers and cross-record correlations may remain identifying regardless of
the declared case. DICOM confidentiality processing, regulatory assessment and
host privacy review remain separate responsibilities.

## Performance and memory impact

The entry adds one small enum field. Construction is constant time after its
inputs exist. Equality and hashing add one constant-size class comparison after
the key/value work. Type-level encoding adds one fixed scalar string.

Exact class preservation adds no aggregation algorithm. No resolver cache,
policy graph or audit record is stored in the entry. Host policy evaluation may
be more expensive and must key any cache by all relevant policy version and
context; that performance belongs to the future policy boundary.

Strict field-set validation is constant in the three declared entry fields.
Recursive value costs and ceilings remain governed by `ADR-0031`.

## Validation impact

Before acceptance and implementation, focused evidence must cover:

- strict Swift concurrency and `Sendable` checking for the key/value/entry
  shape;
- an API compile check proving the initializer requires a class and exposes no
  default, optional or two-argument overload;
- equality, hashing and set behaviour for equal key/value pairs under every
  distinct class;
- exact class preservation by library-owned one-to-one transformations;
- explicit host classification or typed payload-free failure when multiple
  classified inputs must become one entry;
- `hostDefined` round-trips without generic resolution and remains separate or
  is rejected before aggregation, logging and export policy;
- whole-entry scope across key text, arrays, nested object members and code/unit
  presentation strings;
- absence of implicit entry/member conversions that erase classification;
- exact three-field round trips for all five classes;
- rejection of missing, null, extra, unknown and wrong-shaped fields;
- explicit proof that unknown class tokens never become `hostDefined`;
- model-relative fixed coding paths and absence of caller keys, rejected
  tokens, metadata values and arbitrary underlying errors in both descriptive
  and reflective error rendering;
- default diagnostics that contain no arbitrary entry key or value for every
  class, including `publicData` and `technical`;
- library transformation preservation, explicit reclassification and failure
  behaviour; and
- owning-Core and directly affected dependent builds with no prohibited import
  or dependency edge.

The checked-in isolated Swift probe exercises the proposed required shape,
class-sensitive identity, strict malformed forms, redacted caller paths,
whole-entry nested scope and exact `hostDefined` round-tripping. The current
focused Core tests independently prove the existing taxonomy's accepted raw
wire and value-redacted failures. Collection multiplicity, typed access,
canonical raw ingress, persistent digests and actual host logging/export
integration require their own later evidence. No full package suite is warranted
for this Proposed documentation boundary.

## Migration

After `ADR-0028` through `ADR-0032` are accepted and the `ADR-0031` ceiling
evidence is approved:

1. correct Core Data Model Specification sections 34.4, 34.6, 34.8, 64.6 and
   Appendix A to require the three-field entry and whole-entry privacy scope;
2. implement `MetadataEntry` in `VoxeliaCore` with the nondefaulted initializer,
   explicit identity and strict value-redacted three-field Codable;
3. add the focused API, identity, preservation, nesting, malformed-wire,
   redaction and static-dependency evidence listed above;
4. ensure library transformations preserve exact declarations, require an
   explicit trusted-host output class or fail without introducing a speculative
   Core resolver API;
5. keep `MetadataCollection`, namespace multiplicity, typed access, policy
   resolver shape, concrete logging/export APIs, canonical ingress and
   persistent identity deferred to their own accepted decisions; and
6. update traceability, changelog, API documentation and release-integrity
   evidence.

The `MetadataPrivacyClass` decoder hardening already in source is an independent
compatibility-preserving privacy defect fix, not partial implementation of this
entry proposal. No `MetadataEntry` migration step may begin while this ADR or
`ADR-0028` through `ADR-0031` remains Proposed.

## Supersession

This Proposed ADR neither supersedes nor is superseded by another file-backed
ADR. It depends on the semantic value selected by Proposed `ADR-0031` and
completes only the general entry's privacy attachment if accepted. It does not
supersede recursive-value, collection, provenance, canonical JSON, host policy,
logging, export, authentication or audit decisions.

## References

- [Voxelia Core Data Model Specification v0.1.1, sections 34, 64.6, 66 through 68 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, sections 12, 36 and 37](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Project Foundation v0.1.1, section 22](../../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, sections 6.1, 6.6, 6.10 and 6.34 through 6.36](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1, sections 13, 17 and 38](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [ADR-0031 - Bounded recursive metadata value boundary](ADR-0031-bounded-recursive-metadata-value-boundary.md)
- [HL7 FHIR R5 - Security Labels](https://fhir.hl7.org/fhir/security-labels.html)
- [DICOM PS3.15 - Attribute Confidentiality Profiles](https://dicom.nema.org/medical/dicom/current/output/chtml/part15/chapter_E.html)
- [Apple Developer Documentation - OSLogPrivacy](https://developer.apple.com/documentation/os/oslogprivacy)
