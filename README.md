# Voxelia

Voxelia is an MIT-licensed, Apple-native scientific image processing, spatial computing and visualisation toolkit. It is designed for Swift 6.2+, Apple Silicon, Unified Memory Architecture, Metal acceleration, explicit scientific semantics and validation-ready use in diagnostic-grade applications.

> **Project status:** Repository and Package Scaffold v0.1.1 - M0 corrective release. Scientific algorithms and stable public APIs have not yet been implemented.

## Apple ecosystem only

Voxelia is deliberately restricted to Apple Silicon hardware and Apple operating systems:

- macOS 15 or later;
- iOS and iPadOS 18 or later;
- visionOS 2 or later; and
- tvOS 18 or later.

Development, CI, validation, benchmarking and release preparation require an Apple Silicon Mac with Xcode and Swift 6.2 or later. Intel, x86/x64, non-Apple operating systems and non-Apple-hosted Swift toolchains are unsupported and excluded. See [PLATFORM_SUPPORT.md](PLATFORM_SUPPORT.md).

## Products

The root package exposes focused libraries:

- `VoxeliaSpatial`
- `VoxeliaCore`
- `VoxeliaStorage`
- `VoxeliaExecution`
- `VoxeliaImaging`
- `VoxeliaGeometry`
- `VoxeliaRendering`
- `VoxeliaInteraction`
- `VoxeliaCPU`
- `VoxeliaMetal`
- `VoxeliaValidation`
- `Voxelia`

Optional DICOMKit, codec, segmentation, registration, headless, distributed, RealityKit and Photorealistic Rendering products are deliberately not activated at M0.

## Build and test

On an Apple Silicon Mac with the approved Xcode toolchain:

```bash
Tools/Scripts/bootstrap.sh
Tools/Scripts/build.sh
Tools/Scripts/test.sh
Tools/Scripts/validate-scaffold.sh
Tools/Scripts/test-platforms.sh
```

The scripts fail immediately when the required Apple Silicon macOS environment is not present.

## Documentation

The governing documents are stored in [`docs/project`](docs/project/README.md). Start with:

1. Project Foundation v0.1.1
2. Master Technical Architecture v0.1.1
3. Requirements Baseline v0.1.1
4. Validation and Benchmark Strategy v0.1.1
5. Repository and Package Scaffold Specification v0.1.1
6. Core Data Model Specification v0.1.1
7. First Vertical Slice Plan v0.1.1

The accepted platform decision is recorded in [`ADR-0025`](docs/architecture/decisions/ADR-0025-apple-ecosystem-only.md).

## Diagnostic-use statement

Voxelia is a toolkit. Its presence in a downstream application does not by itself make that application suitable or approved for diagnostic use. A host product must validate its selected Voxelia version, algorithms, Apple Silicon device classes, workflows and presentation environment.

## Contributing and security

Read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes. Report security vulnerabilities privately using [SECURITY.md](SECURITY.md), not as public issues.

## Licence

Voxelia is released under the [MIT Licence](LICENSE).
