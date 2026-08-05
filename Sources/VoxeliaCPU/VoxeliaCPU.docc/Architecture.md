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

The public operation returns only the completely validated immutable aggregate.
It assembles the fixed CPU implementation/execution claims, caller-authorized
output identity and transformed source-linked provenance after its final
cancellation check. No callback, mutable destination, provisional mesh digest
or partial result exists; host generation and stale-result policy remain the
caller's responsibility after return.
