# Voxelia platform support

## Supported ecosystem

Voxelia is exclusively an Apple ecosystem toolkit.

Supported execution targets are:

- Apple Silicon Macs running macOS 15 or later;
- Apple Silicon iPhone and iPad devices running iOS or iPadOS 18 or later;
- Apple spatial-computing devices running visionOS 2 or later; and
- Apple TV devices running tvOS 18 or later.

Development, continuous integration, validation, benchmarking, release preparation and diagnostic-reference execution shall be performed on Apple Silicon hardware using the Apple toolchain.

## Required architecture

Voxelia targets Apple Silicon ARM64 exclusively. Unified Memory Architecture, Metal and Apple platform frameworks are foundational design assumptions rather than optional accelerators.

## Explicit exclusions

Intel processors, x86 and x64 targets, non-Apple operating systems and Swift toolchains hosted outside the Apple ecosystem are unsupported and excluded from all Voxelia build, validation, benchmark, release and compatibility claims.

Platform-neutral internal abstractions exist to preserve clean scientific architecture. They shall not be interpreted as a portability commitment or a basis for adding non-Apple support.
