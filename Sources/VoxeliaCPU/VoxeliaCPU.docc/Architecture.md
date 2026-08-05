# Architecture

The `VoxeliaCPU` target follows the dependency and ownership rules in the
Voxelia Master Technical Architecture and Repository and Package Scaffold
Specification.

The CPU scalar-surface reference composes the Execution-owned
`StorageReadCoordinator` with Geometry-owned request and mesh values. Its
internal source adapter stages exactly one coordinated full packed-byte read,
releases the retention token before transform admission or traversal, validates
authoritative samples without retaining a second binary64 lattice, and then
runs the `freudenthal-surface-extraction/binary64-v1` kernel.

The labelled-surface reference follows the same one-read ownership
boundary while decoding all eight integer containers without binary64
conversion. It admits only an exact label descriptor/domain, searches the
bounded canonical requested array directly, places opposite-membership edges
at exactly representable image midpoints and runs
`freudenthal-label-set-surface/binary64-v1`. Its public stateless entry performs
the final cancellation check before atomically binding identity and provenance,
and its exact CPU implementation is registered only with that complete
publication boundary.

Both public surface operations return only a completely validated immutable
aggregate. They assemble fixed CPU implementation/execution claims,
caller-authorized output identity and transformed source-linked provenance
after final cancellation. No callback, mutable destination, provisional mesh
digest or partial result exists; host generation and stale-result policy remain
the caller's responsibility after return.
