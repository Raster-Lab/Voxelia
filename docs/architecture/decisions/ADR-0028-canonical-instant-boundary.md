---
document_id: "ADR-0028"
title: "Canonical instant boundary"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-ARC-003"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-DAT-014"
  - "VOX-META-001"
  - "VOX-META-003"
  - "VOX-META-010"
  - "VOX-ERR-001"
  - "VOX-SEC-003"
  - "VOX-DCM-003"
  - "VOX-VS1-019"
  - "VOX-REL-005"
---

# ADR-0028 - Canonical instant boundary

## Context

The Core Data Model Specification requires provenance times to use an absolute
instant and requires serialised JSON to use a canonical UTC representation. It
nevertheless exposes two unrestricted strings:

```swift
case instant(String)
public let createdAt: String
```

The first belongs to the prescribed recursive `MetadataValue`; the second
belongs to `ProvenanceRecord`. Both records are Core-owned, and neither raw
payload can prevent offsets, local times, invalid calendar dates, omitted
seconds, multiple spellings of the same instant, unbounded fractions or
formatter-dependent normalisation. Accepting those values would make invalid
state public before the required canonical JSON boundary exists.

RFC 3339 is an ISO 8601 profile for Internet timestamps, but it intentionally
permits choices that are not one canonical Voxelia representation: numeric
offsets, lowercase `t` and `z`, an arbitrary non-empty fraction and announced
leap seconds. RFC 9557 adds optional zone and calendar suffixes. Foundation
formatters also are conversion utilities rather than a stable validation
oracle: their accepted forms and fractional parsing have varied by platform
release, and `Date` cannot preserve the exact decimal spelling or full
nanosecond precision across the selected year domain.

This record selects one independently valid Core leaf and the minimum
controlled corrections required to use it. It does not authorise the
recursive metadata model, provenance record, a canonical JSON envelope,
clock acquisition, date arithmetic or external timestamp normalisation. It
was reviewed and accepted by the project owner on 2026-08-04.

## Decision

`VoxeliaCore` owns these public values:

```swift
public enum CanonicalInstantError: Error, Sendable, Equatable {
    case invalidLength
    case invalidSyntax
    case yearOutOfRange
    case monthOutOfRange
    case dayOutOfRange
    case hourOutOfRange
    case minuteOutOfRange
    case secondOutOfRange
    case unsupportedLeapSecond
    case nonCanonicalFraction
}

public struct CanonicalInstant: Sendable, Hashable, Codable {
    public static let maximumUTF8ByteCount = 30
    public let utcString: String

    public init(utcString: String) throws
}
```

The initial value will not conform to `RawRepresentable`,
`LosslessStringConvertible`, `ExpressibleByStringLiteral`, `Comparable` or
`CustomStringConvertible`. Those conformances would add a second construction
path, unapproved ordering or implicit disclosure behaviour without helping the
two governed consumers.

The value will accept exactly the following version-one ASCII profile. `DIGIT`
is the RFC 5234 ASCII digit production:

```abnf
canonical-instant = full-date %x54 clock-time [fraction] %x5A
full-date         = year "-" month "-" day
clock-time        = hour ":" minute ":" second
year              = 4DIGIT
month             = 2DIGIT
day               = 2DIGIT
hour              = 2DIGIT
minute            = 2DIGIT
second            = 2DIGIT
fraction          = "." 1*9DIGIT
```

The explicit `%x54` and `%x5A` octets make uppercase `T` and `Z` mandatory;
quoted ABNF literals would otherwise be case-insensitive.

The grammar is further constrained as follows:

- `year` is `0001...9999`; year zero, signed years and expanded years are
  rejected;
- month and day must form a valid proleptic Gregorian date, using the usual
  divisible-by-four, century and divisible-by-400 leap-year rules;
- hour is `00...23`, and minute and second are `00...59`;
- seconds are mandatory, `24:00:00` is rejected and leap-second `:60` is not
  supported in version one;
- the optional fraction contains one through nine digits and its last digit is
  non-zero, so zero fraction is omitted and trailing-zero aliases are invalid;
- uppercase `T` and `Z`, ASCII digits and the shown punctuation are mandatory;
  and
- every numeric offset, including `+00:00` and `-00:00`, plus spaces, lowercase
  letters, basic, ordinal or week dates, RFC 9557 suffixes and every other ISO
  8601 form are rejected.

Accepted values therefore occupy exactly 20 bytes without a fraction or 22
through 30 bytes with a fraction. Examples include:

```text
0001-01-01T00:00:00Z
2026-08-02T12:34:56Z
2026-08-02T12:34:56.1Z
2026-08-02T12:34:56.000001Z
9999-12-31T23:59:59.999999999Z
```

Version one uses a leap-unaware proleptic civil-time grid with exactly 86,400
labelled seconds per day. `Z` is its sole zero-offset serialisation token; under
RFC 9557 it leaves the local offset unknown and does not assert UTC as the
preferred reference or identify a time zone. Explicit inserted second 60 is
rejected, and the leaf does not consult a leap-event table to determine whether
second 59 was deleted on a date with a negative leap. It therefore does not
claim leap-aware UTC validation or exact ordering across leap events. A source
that requires those semantics must remain explicitly preserved until a
versioned time-scale conversion policy exists.

For dates before UTC was introduced, the spelling is a proleptic serialisation
label relative to universal time following RFC 3339 practice. It does not claim
that UTC or the proleptic Gregorian calendar was the historical civil-time
system, or that a source supplied that historical precision.

The fraction describes the instant, not source clock resolution or uncertainty.
Those properties require separate provenance fields if later needed. Inputs
such as `.0`, `.100`, a tenth fractional digit or `+00:00` will be rejected,
not trimmed, rounded or converted. An adapter may later expose an explicitly
named conversion operation for broader source timestamps, but it must not make
that conversion part of this validating initializer or discard source spelling
that provenance policy requires it to retain.

Validation will inspect UTF-8 directly with no locale, time zone database,
mutable leap-second table or Foundation formatter. It will apply this public
error precedence:

1. more than 30 UTF-8 bytes, or a byte count other than 20 or 22 through 30,
   throws `.invalidLength` before calendar work;
2. a non-ASCII byte, non-digit component, separator, suffix or other structural
   violation throws `.invalidSyntax`;
3. `0000` throws `.yearOutOfRange`;
4. invalid month and day values throw `.monthOutOfRange` and
   `.dayOutOfRange`, respectively, with day validated against its year and
   month;
5. invalid hour and minute values throw `.hourOutOfRange` and
   `.minuteOutOfRange`, respectively;
6. a second exactly equal to 60 throws `.unsupportedLeapSecond`, while a
   greater second throws `.secondOutOfRange`; and
7. a syntactically valid fraction ending in zero throws
   `.nonCanonicalFraction`.

Errors will not contain the supplied timestamp. This preserves deterministic,
privacy-safe diagnostics when several fields are invalid. The implementation
may materialise at most 30 candidate UTF-8 bytes while scanning and will stop
when it observes byte 31. It will not construct `Date`, `Calendar`, `TimeZone`,
a formatter or an actor.

`utcString` will preserve the accepted ASCII bytes exactly. Because every value
on the selected version-one grid has one spelling, exact stored-string equality
and hashing are also identity within this profile. The value will not
conform to `Comparable`: variable fractional width means ordinary lexical order
does not correctly place a whole second before a fraction within that second.
A future chronological comparison must compare validated components, including
the fraction as nanoseconds, rather than compare strings.

Type-level Codable will use one JSON string:

```json
"2026-08-02T12:34:56.000001Z"
```

Decoding will require a single string value and invoke the validating
initializer. An invariant failure will become `DecodingError.dataCorrupted` at
the current coding path with the corresponding `CanonicalInstantError` as the
underlying error and without echoing the string. Encoding will emit exactly
`utcString`. Arrays, objects, numbers, Booleans and null are invalid.

This leaf-level Codable contract is not the project's complete canonical JSON
contract. Schema-version envelopes, raw duplicate-key rejection, complete
document size limits and stable outer key ordering remain byte-ingress work.
The 30-byte leaf limit cannot recover memory already allocated by a general JSON
decoder, so untrusted ingress must enforce document and string limits before or
during allocation.

Proposed `ADR-0035` now selects the separate `VCMJ-1` envelope and requires
this instant's exact ASCII characters to appear unescaped in canonical record
bytes. It remains unaccepted and does not change this leaf's ordinary scalar-
string Codable.

With acceptance, the controlled metadata case and provenance field are
corrected through the project's controlled-correction process, without
editing any immutable `v0.1.1` baseline file, to:

```swift
case instant(CanonicalInstant)
public let createdAt: CanonicalInstant
```

Those corrections make the same invalid states unrepresentable at both public
boundaries. They do not independently authorise `MetadataValue` or
`ProvenanceRecord`, which retain their separate blockers.

Proposed `ADR-0038` records the downstream provenance blocker explicitly: a
canonical creation instant is only one claim field in a subject-bound, closed
activity record. It supplies no operation/execution completeness, graph
admission, evidence assurance or publication authority.

## Alternatives considered

### Retain unrestricted String payloads

This preserves the current sketches but lets any caller bypass UTC, calendar,
precision and canonical-spelling requirements. Post-hoc collection validation
would not make public invalid state unrepresentable and synthesized Codable
would accept the same invalid payloads.

### Store Foundation Date

`Date` is convenient for clocks and arithmetic but is a binary floating-point
offset from a reference epoch. It cannot preserve the exact input fraction,
trailing-zero policy or every nanosecond throughout this year range. Its generic
Codable shape is encoder-strategy dependent, and it does not encode the selected
canonical UTC spelling by itself.

### Validate with ISO8601DateFormatter or Date.ISO8601FormatStyle

Foundation formatters are useful at an explicit adapter boundary, but their
accepted aliases, normalisation and fractional behaviour are broader than this
profile and may evolve with the operating system or Swift Foundation. A manual
30-byte ASCII parser is smaller than a second validation pass around a lenient
formatter and provides one deterministic cross-platform contract.

### Accept every RFC 3339 spelling and normalise to UTC

Offsets and alternate case would require conversion, create multiple accepted
spellings and conceal whether an adapter supplied local-zone information.
Rejecting noncanonical input keeps validation distinct from explicit source
conversion. Under RFC 9557, `Z` and `-00:00` both leave the local offset unknown,
while `+00:00` identifies UTC as the preferred reference. Version one records
neither that preference nor an original local offset, and uses only `Z` as the
canonical zero-offset spelling.

### Preserve arbitrary fractional precision

RFC 3339 permits an unbounded fraction, but that conflicts with a small
intrinsic limit and leaves arithmetic, equality and downstream precision
unbounded. Nine digits cover exact decimal nanoseconds. Greater source precision
must be rejected rather than silently rounded, or preserved by a separately
specified source-metadata field.

### Require a fixed fractional width

Always emitting milliseconds or nanoseconds gives uniform-length strings, but
adds precision-looking zeros to whole-second values and cannot preserve a
canonical minimal decimal spelling. Omitting a zero fraction and trailing zeros
makes instant identity unique without claiming source accuracy.

### Use a leap-aware UTC model

RFC 3339 permits an announced inserted second 60 and also accounts for a
subtracted leap second in which second 59 does not exist. Correct validation of
either event requires a versioned external leap source and a defined update and
reproducibility policy. Accepting every June or December second-60 candidate
would admit nonexistent instants, while accepting ordinary second 59 without a
table cannot prove it existed on a negative-leap date. Version one deliberately
defines an 86,400-second-per-day grid, rejects explicit second 60 and makes no
leap-aware UTC claim. A later revision may add a versioned time-scale decision
without reinterpreting existing grid values.

### Accept year zero

RFC 3339's four-digit grammar can spell `0000`, while calendar libraries and
domain systems differ on era and year-zero interpretation. Voxelia provenance
does not need that ambiguity. Version one uses Common Era years 0001 through
9999; a broader historical time model would require a separate era/calendar
decision.

### Store an integer epoch count

An integer could support exact arithmetic, but it would require choices for the
epoch, scale, leap seconds, range and fractional unit and would not satisfy the
prescribed ISO 8601 JSON representation. It may be an internal derived form,
never the authoritative public value selected here.

## Consequences

- Metadata and provenance gain one Core-owned, concurrency-safe instant
  invariant instead of two raw-string interpretations.
- Every accepted value has one zero-offset ASCII spelling on the selected
  leap-unaware grid, with at most nanosecond precision and a 30-byte intrinsic
  maximum.
- Offset conversion, source precision, uncertainty, clock acquisition,
  arithmetic and ordering remain explicit future APIs rather than hidden
  constructor behaviour.
- Inserted leap seconds, year zero, fractions beyond nanoseconds and RFC 9557
  suffixes cannot be represented by version one and must fail rather than be
  rewritten; deleted leap seconds are not validated without a future leap-event
  source.
- The canonical value remains human-readable and directly embeddable as a JSON
  string, but does not by itself establish canonical top-level JSON or digest
  bytes.
- `MetadataValue` remains blocked pending accepted recursive-value decision
  `ADR-0031`; metadata collections and complete provenance remain separately
  blocked by their privacy, graph, execution and serialisation decisions.

## Affected modules

If accepted, `VoxeliaCore` will own `CanonicalInstant` and
`CanonicalInstantError`, use the former in future Core metadata and provenance
records and contain the manual validator and single-value Codable
implementation. No package edge, product or current module ownership changes.
Adapters and future Execution or distributed modules are consumers and must
perform any broader source-time conversion explicitly before construction.

## Compatibility impact

No public `MetadataValue` or `ProvenanceRecord` implementation or serialised
fixture exists, so replacing the two prescribed raw strings will not move a
compiled symbol or live artefact. The correction is intentionally made before
those aggregates become public.

Once implemented, the type name, error cases, `utcString`, year and precision
ranges, no-leap-second rule and exact single-string encoding become pre-1.0
compatibility contracts. Changes require a recorded decision, changelog and
migration evidence. Provenance document format versions remain separately
required by `VOX-REL-005`.

## Security impact

The fixed profile prevents unbounded fractional parsing and avoids locale,
time-zone-database and mutable formatter state. Validation errors expose only a
category, never the timestamp, because acquisition or operation times can
themselves be sensitive context. No parser path performs arithmetic outside
small fixed-width decimal components.

The public initializer receives an already allocated Swift `String` and cannot
serve as the sole defence against an oversized JSON document. Adapters and the
future canonical byte-ingress layer must cap input before allocation, reject
malformed encodings and avoid logging rejected timestamp contents. This value
does not confer clock trust, freshness, authenticity or authorisation.

## Performance and memory impact

Validation is deterministic linear work over at most 30 accepted UTF-8 bytes;
oversized input is rejected after counting no more than 31 bytes. Calendar
validation uses fixed integer component arithmetic. Storage is one immutable
short string. Equality and hashing are bounded by the same maximum. There is no
formatter allocation, lock, locale lookup, time-zone lookup, network access,
global cache or actor hop.

## Validation impact

After acceptance and leaf implementation, focused Core evidence must cover:

- valid lower and upper year boundaries, whole seconds and every fractional
  width from one through nine;
- Gregorian month lengths and leap-year boundaries, including 1900, 2000, 2100
  and an exhaustive 400-year cycle oracle;
- rejection of year zero, invalid months/days, hour 24, minute 60, second 61 and
  leap-second 60 with the exact typed error;
- rejection of missing seconds, offsets including `+00:00` and `-00:00`, spaces,
  lowercase `t`/`z`, Unicode digits, basic, ordinal and week dates and RFC 9557
  suffixes;
- rejection of absent fraction digits, all-zero and trailing-zero fractions,
  a tenth digit and inputs longer than 30 UTF-8 bytes;
- deterministic error precedence for values with several defects and
  privacy-safe errors that do not include source text;
- exact string preservation, equality, hashing and `Sendable` conformance;
- exact single-string round trips and rejection of null, number, Boolean, array
  and object JSON shapes;
- decode-time invariant revalidation with the current coding path and typed
  underlying error; and
- a static check that the Core target adds no dependency or prohibited import.

Focused parser fuzzing should cover ASCII inputs through the maximum boundary
and oversized prefixes without invoking a Foundation date parser. A complete
Swift suite is not warranted while this ADR remains Proposed. Canonical JSON
envelope, raw duplicate-key and pre-allocation tests remain separate.

## Migration

After acceptance:

1. correct Core Data Model Specification section 7.7 with the exact profile and
   add `CanonicalInstant` to the Core type inventory at M1;
2. replace `MetadataValue.instant(String)` with
   `MetadataValue.instant(CanonicalInstant)` and replace
   `ProvenanceRecord.createdAt: String` with
   `ProvenanceRecord.createdAt: CanonicalInstant`;
3. implement only the standalone leaf and typed error in `VoxeliaCore`, using a
   manual bounded ASCII parser and strict single-value Codable;
4. add the focused Core tests and static dependency evidence listed above;
5. use the leaf in `MetadataValue` only after bounded recursive-value decision
   `ADR-0031` is accepted, while keeping general entries, collections, privacy
   attachment and full provenance deferred until their own contracts are
   approved, and use it in canonical metadata bytes only after `ADR-0035` is
   accepted; and
6. update traceability, changelog and release-integrity evidence.

These migration steps are authorised as of the 2026-08-04 acceptance and are
executed in order through the progress ledger; step 5 remains gated on its
named decisions.

## Supersession

This ADR neither supersedes nor is superseded by another file-backed ADR. It
resolves only the two raw instant-string boundaries and their shared leaf
contract through the controlled corrections in the Migration section. It
does not supersede canonical JSON, metadata, provenance, execution, privacy
or distributed-format decisions.

## References

- [Voxelia Core Data Model Specification v0.1.1, sections 7.3, 7.7, 34, 36, 55, 64, 72 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, sections 8, 9, 12 and 31](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, sections 6.5 through 6.7, 6.10, 6.29, 6.34, 6.35, 6.39 and 6.40](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [ADR-0038 - Closed provenance record and graph admission boundary](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [RFC 3339 - Date and Time on the Internet: Timestamps](https://www.rfc-editor.org/rfc/rfc3339.html)
- [RFC 5234 - Augmented BNF for Syntax Specifications](https://www.rfc-editor.org/rfc/rfc5234.html)
- [RFC 9557 - Date and Time on the Internet: Timestamps with Additional Information](https://www.rfc-editor.org/rfc/rfc9557.html)
- [Apple ISO8601DateFormatter documentation](https://developer.apple.com/documentation/foundation/iso8601dateformatter)
- [Apple Date.ISO8601FormatStyle fractional-seconds documentation](https://developer.apple.com/documentation/foundation/date/iso8601formatstyle/includingfractionalseconds)
- [ADR-0035 - Versioned canonical metadata JSON and raw ingress boundary](ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md)
