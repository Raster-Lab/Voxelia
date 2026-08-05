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

This migration stage intentionally exposes no mesh-only public operation.
Identity and provenance assembly, the atomic public result boundary and CPU
backend registration remain the next accepted `ADR-0191` migration stage.
