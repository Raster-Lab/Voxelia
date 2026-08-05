# Swift safety policy

Voxelia currently permits no compiler-classified unsafe Swift constructs or
concurrency-checking exceptions in repository-owned executable source. This
preserves the project's M1 baseline while storage ownership, no-copy access and
type-erasure contracts remain under governance review.

`Tools/Scripts/check_swift_safety.py` inventories Swift package manifests,
product source, tests, validation tools, benchmarks, repository tools and
active shell, workflow and Xcode build configuration. It rejects:

- `@unchecked Sendable`, `@preconcurrency`, `nonisolated(unsafe)` and unsafe
  executor inheritance;
- every Swift `unsafe` marker and a conditional that tests the strict-memory-
  safety compiler mode;
- SwiftPM unsafe flags, external compilation conditions, direct script/compiler
  execution and compiler escape channels;
- settings that suppress warnings or weaken memory safety, exclusivity, Swift
  6 or complete strict-concurrency enforcement; and
- unexpected manifests or Swift sources, non-`.swift` Swift scripts,
  non-regular source/configuration files and file or directory symlinks.

The escape-hatch spelling scan is intentionally raw and fail closed. Exact
spellings such as `@unchecked`, `@preconcurrency`, `StrictMemorySafety` and the
Swift word `unsafe` are reserved even in comments, strings and regex literals
inside executable Swift files. Ordinary checked vocabulary such as `free`,
`UnsafePointer` in explanatory text outside manifests or an identifier
containing `unsafe` is not reserved. Manifests have the stricter raw foreign-
symbol, pointer, lifetime and nondeterministic-input spelling rules because
SwiftPM executes them before target compilation. In addition, manifests are
lexed against an explicit deterministic declarative subset: one exact tools-
version header, one `PackageDescription` import and one literal `Package`
declaration composed only from the package APIs currently in use. Closures,
operators, interpolation, runtime clocks/tasks, computed settings and
unapproved package APIs fail closed. Configuration-only flag rules are not
applied to normal Swift expressions, so a value such as `-Double` is not
misclassified as an attached `-D` condition.

Individual source/configuration inputs are capped at 1 MiB, findings are
bounded per file and repository, and rendered diagnostic tokens are truncated.
An oversized, unreadable or non-UTF-8 input fails closed before lexical
allocation or diagnostic generation. Captured SwiftPM metadata output has a
combined 4 MiB stdout/stderr ceiling; the entire process group is killed on
that breach or on timeout, preventing a manifest from exhausting checker
memory by printing indefinitely.

The scaffold and security workflows invoke the checker with `--compile`. This
also verifies effective Swift 6 manifest settings, the exact governed local-
dependency set and bidirectional target-source coverage. It rejects every
resolved SwiftPM `unsafeFlags` setting and every target language-mode override,
foreign-memory execution and environment/random/process-dependent manifest
composition, then builds product and test targets in the root, validation,
benchmark and tool packages in both debug and release configurations. The
compiler's strict-memory-safety diagnostics are promoted to errors. SwiftPM
metadata is evaluated without mutable repository metadata, and package/build
commands have bounded process-group cleanup so a child process cannot hang the
self-hosted gate.

Generated build trees and the controlled non-product probes in
`docs/progress/evidence/` are excluded. Effective SwiftPM target descriptions
must prove both that every compiled source is inventoried and that every Swift
file in a governed package source/test tree is compiled by a target. This
prevents target exclusions, orphan files and custom target paths from escaping
the semantic compiler gate.

The host compiler gate is paired with `Tools/Scripts/test-platforms.sh`. The
platform workflow builds product and test targets for macOS, iOS device and
simulator, tvOS device and simulator, and visionOS device and simulator with
Xcode strict-memory-safety enabled and warnings treated as errors in Debug and
Release. Current local evidence passes both configurations for the first five
destinations. Xcode reports its visionOS 26.5 platform component as not
installed, so both visionOS destinations remain explicit open evidence; this
policy does not treat them as passing.

## Current inventory

The permitted-exception inventory remains empty, and the raw escape-hatch scan
now passes with no findings. The 2026-08-05 recovery replaced three test-only
lock wrappers and the production pipeline cache with checked
`Synchronization.Mutex` state, isolated the execution context's device/queue
pair and all three kernel pipeline sets behind checked synchronous borrowing,
removed the immutable residency manager's obsolete exception and proved the
exact slice renderer is immutable checked composition.

The complete semantic gate is not green. `check_swift_safety.py --compile`
currently reports fourteen strict-memory-safety diagnostics across five
`VoxeliaCore` files: four canonical literal/ingress implementations traverse
`StaticString` unsafe buffers, while `ContentID` uses unsafe-buffer hashing and
constant-time comparison calls. None is an accepted exception; recovery must
use checked Swift without weakening canonical-byte or timing-safety contracts.

| Exception ID | Declaration | Owner | Invariant | Review | Tests |
|---|---|---|---|---|---|
| None permitted | No escape-hatch declaration remains | Repository | No exception accepted | Raw scan green; semantic compile red on five Core files | Focused canonical and identity recovery suites pending |

## Introducing an exception

Do not suppress, rename or split a token to evade the gate. A necessary future
exception requires a dedicated policy change that:

1. identifies the exact declaration and owner;
2. documents its memory, lifetime and concurrency invariants;
3. explains why checked Swift cannot express the required behaviour;
4. adds focused stress, lifetime and failure tests;
5. records an independent reviewer and review evidence; and
6. narrows any scanner exception to that exact reviewed declaration.

The exception may be enabled only after the governing public contract is
accepted. Proposed ADRs and RFCs are review material and grant no exception.

This policy provides implementation and review evidence for `VOX-CON-010` and
`VOX-SEC-002`. It supports, but does not by itself complete, `VOX-CON-003`,
`VOX-SEC-001` or the complete M1 acceptance checklist.
