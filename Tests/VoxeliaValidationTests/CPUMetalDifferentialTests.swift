// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaMetal
import VoxeliaSpatial
import VoxeliaStorage
import VoxeliaValidation

/// `ADR-0300` (`VOX-VAL-006`): diagnostic Metal kernels compared against CPU references.
///
/// The kernel suites in `VoxeliaMetalTests` each compare the GPU against an **analytical**
/// model transcribed into the test file. That is one of the three references the row admits,
/// and it leaves one thing unchecked: whether the transcription still agrees with the
/// **shipped CPU operation**. If the two drifted, the Metal suite would keep passing while
/// the product disagreed with itself.
///
/// These tests run the same input through both shipped operations and compare their output
/// bytes, with an analytical phantom as the input so a third, independent leg is available.
@Suite("CPUMetalDifferential")
struct CPUMetalDifferentialTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func axis(_ id: String, semantic: AxisSemantic) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: semantic,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func image(
        extents: [Int],
        bytes: [UInt8],
        scalarType: ScalarType
    ) throws -> ImageData {
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        let names = ["x", "y", "z"]
        var axes = ContiguousArray<AxisDescriptor>()
        for index in 0..<extents.count {
            axes.append(try axis(names[index], semantic: semantics[index]))
        }
        let shape = try ImageShape(extents: ContiguousArray(extents))
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
                scalarFormat: try ScalarFormat(
                    type: scalarType,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 1,
                    interpretation: .scalar,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: .intensity,
                axes: axes,
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: shape,
                        scalarType: scalarType,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-07T10:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "phantom-diff"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "phantom-diff")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "voxelia.analytical-phantom",
                        identifier: "plan-55",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func bytes(_ image: ImageData) throws -> [UInt8] {
        let extents = image.descriptor.shape.extents
        return try image.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
    }

    private func coordinator() -> StorageReadCoordinator {
        StorageReadCoordinator(maximumRetainedResultByteCount: 8192)
    }

    /// The §55.1 ramp as an `int16` slice: every sample is a known value in closed form.
    private func rampSlice() throws -> (ImageData, LinearRampPhantom) {
        let phantom = try LinearRampPhantom(columns: 12, rows: 9, slices: 1)
        return (
            try image(
                extents: [12, 9],
                bytes: Array(phantom.storedBytes),
                scalarType: .int16
            ),
            phantom
        )
    }

    // MARK: - Window and level

    @Test("[Unit][VOX-VAL-006] the CPU and Metal window operations agree byte for byte")
    func cpuAndMetalWindowOperationsAgreeByteForByte() async throws {
        // The comparison the analytical suites cannot make: the shipped CPU operation
        // against the shipped GPU operation, on the same input, with equality and no
        // tolerance. Several windows, including one that saturates and one that is the
        // identity over the byte range.
        let (slice, _) = try rampSlice()
        let kernel = try MetalWindowLevelKernel(
            context: try MetalExecutionContext(), telemetrySink: nil)

        for window in [(128.0, 256.0), (110.0, 20.0), (120.0, 1.0), (0.0, 4096.0)] {
            let cpu = try await WindowLevelOperation.execute(
                input: slice,
                center: try MetadataFloatingPoint(value: window.0),
                width: try MetadataFloatingPoint(value: window.1),
                paddingValue: nil,
                outputObjectID: try #require(DataObjectID(rawValue: "cpu-out")),
                outputProvenanceID: try #require(ProvenanceID(rawValue: "record-cpu")),
                createdAt: try CanonicalInstant(utcString: "2026-08-07T10:01:00Z"),
                software: try software(),
                coordinator: coordinator()
            )
            let gpu = try await MetalWindowLevelOperation.execute(
                input: slice,
                center: try MetadataFloatingPoint(value: window.0),
                width: try MetadataFloatingPoint(value: window.1),
                paddingValue: nil,
                outputObjectID: try #require(DataObjectID(rawValue: "gpu-out")),
                outputProvenanceID: try #require(ProvenanceID(rawValue: "record-gpu")),
                createdAt: try CanonicalInstant(utcString: "2026-08-07T10:01:00Z"),
                software: try software(),
                coordinator: coordinator(),
                kernel: kernel
            )
            let cpuBytes = try bytes(cpu)
            let gpuBytes = try bytes(gpu)
            #expect(cpuBytes == gpuBytes)
        }
    }

    @Test("[Unit][VOX-VAL-006] both backends agree with the phantom's own closed form")
    func bothBackendsAgreeWithThePhantomsOwnClosedForm() async throws {
        // The third leg. CPU equals GPU proves consistency, not correctness — they could
        // share a defect. Under the identity window a stored value maps to itself, so the
        // phantom's closed form is the independent reference both are checked against.
        let (slice, phantom) = try rampSlice()
        let kernel = try MetalWindowLevelKernel(
            context: try MetalExecutionContext(), telemetrySink: nil)

        let cpu = try await WindowLevelOperation.execute(
            input: slice,
            center: try MetadataFloatingPoint(value: 128),
            width: try MetadataFloatingPoint(value: 256),
            paddingValue: nil,
            outputObjectID: try #require(DataObjectID(rawValue: "cpu-out")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-cpu")),
            createdAt: try CanonicalInstant(utcString: "2026-08-07T10:01:00Z"),
            software: try software(),
            coordinator: coordinator()
        )
        let gpu = try await MetalWindowLevelOperation.execute(
            input: slice,
            center: try MetadataFloatingPoint(value: 128),
            width: try MetadataFloatingPoint(value: 256),
            paddingValue: nil,
            outputObjectID: try #require(DataObjectID(rawValue: "gpu-out")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-gpu")),
            createdAt: try CanonicalInstant(utcString: "2026-08-07T10:01:00Z"),
            software: try software(),
            coordinator: coordinator(),
            kernel: kernel
        )

        let cpuBytes = try bytes(cpu)
        let gpuBytes = try bytes(gpu)
        var offset = 0
        for row in 0..<9 {
            for column in 0..<12 {
                let declared = try phantom.value(column: column, row: row, slice: 0)
                #expect(cpuBytes[offset] == UInt8(declared))
                #expect(gpuBytes[offset] == UInt8(declared))
                offset += 1
            }
        }
        #expect(offset == cpuBytes.count)
    }

    // MARK: - Invert

    @Test("[Unit][VOX-VAL-006] the CPU and Metal invert operations agree byte for byte")
    func cpuAndMetalInvertOperationsAgreeByteForByte() async throws {
        // Every value in the eight-bit domain, so the comparison covers the operation's
        // whole input range rather than a sample of it.
        let domain = (0...255).map { UInt8($0) }
        let slice = try image(extents: [16, 16], bytes: domain, scalarType: .uint8)
        let kernel = try MetalInvertKernel(
            context: try MetalExecutionContext(), telemetrySink: nil)

        let cpu = try await InvertDisplayOperation.execute(
            input: slice,
            outputObjectID: try #require(DataObjectID(rawValue: "cpu-out")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-cpu")),
            createdAt: try CanonicalInstant(utcString: "2026-08-07T10:02:00Z"),
            software: try software(),
            coordinator: coordinator()
        )
        let gpu = try await MetalInvertDisplayOperation.execute(
            input: slice,
            outputObjectID: try #require(DataObjectID(rawValue: "gpu-out")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-gpu")),
            createdAt: try CanonicalInstant(utcString: "2026-08-07T10:02:00Z"),
            software: try software(),
            coordinator: coordinator(),
            kernel: kernel
        )

        let cpuBytes = try bytes(cpu)
        let gpuBytes = try bytes(gpu)
        #expect(cpuBytes == gpuBytes)
        // And both against the analytical model, so agreement is not agreement on a shared
        // mistake.
        #expect(cpuBytes == domain.map { 255 - $0 })
    }

    // MARK: - Composite, where the two backends are not expected to be equal

    @Test("[Unit][VOX-VAL-006] the CPU and Metal composites agree within the accepted bound")
    func cpuAndMetalCompositesAgreeWithinTheAcceptedBound() async throws {
        // This pair is deliberately **not** asserted equal. The GPU composites in float32
        // and the CPU in binary64, and `ADR-0096` already measured that difference and
        // bounded it at one code value. The bound is composed from that accepted record
        // rather than invented here, which is why a tolerance appears in this test and in
        // no other in the suite.
        let base = (0..<256).map { UInt8($0) }
        let overlay = (0..<256).map { UInt8(255 - $0) }
        let layers = [
            try image(extents: [16, 16], bytes: base, scalarType: .uint8),
            try image(extents: [16, 16], bytes: overlay, scalarType: .uint8),
        ]
        let opacities = [1.0, 0.5]
        let kernel = try MetalCompositeKernel(
            context: try MetalExecutionContext(), telemetrySink: nil)

        let cpu = try await CompositeLayersOperation.execute(
            layers: layers,
            opacities: opacities,
            outputObjectID: try #require(DataObjectID(rawValue: "cpu-out")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-cpu")),
            createdAt: try CanonicalInstant(utcString: "2026-08-07T10:04:00Z"),
            software: try software(),
            coordinator: coordinator()
        )
        let gpu = try await MetalCompositeLayersOperation.execute(
            layers: layers,
            opacities: opacities,
            outputObjectID: try #require(DataObjectID(rawValue: "gpu-out")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-gpu")),
            createdAt: try CanonicalInstant(utcString: "2026-08-07T10:04:00Z"),
            software: try software(),
            coordinator: coordinator(),
            kernel: kernel
        )

        let cpuBytes = try bytes(cpu)
        let gpuBytes = try bytes(gpu)
        #expect(cpuBytes.count == 256)
        #expect(gpuBytes.count == 256)
        var exact = 0
        for index in 0..<cpuBytes.count {
            #expect(abs(Int(cpuBytes[index]) - Int(gpuBytes[index])) <= 1)
            if cpuBytes[index] == gpuBytes[index] {
                exact += 1
            }
        }
        // And the same ninety-nine per cent floor `ADR-0096` set, so a backend that drifted
        // to a uniform one-off would fail rather than sit inside the bound everywhere.
        #expect(exact * 100 >= cpuBytes.count * 99)
    }

    // MARK: - The differential has to be able to fail

    @Test("[Unit][VOX-VAL-006] the comparison distinguishes outputs that should differ")
    func comparisonDistinguishesOutputsThatShouldDiffer() async throws {
        // A differential asserting equality is only evidence if unequal inputs produce
        // unequal outputs. Two windows that genuinely disagree are run through the same
        // comparison, and the bytes must differ on both backends.
        let (slice, _) = try rampSlice()
        let kernel = try MetalWindowLevelKernel(
            context: try MetalExecutionContext(), telemetrySink: nil)

        func windowed(_ centre: Double, _ width: Double, onGPU: Bool) async throws -> [UInt8] {
            let output: ImageData
            if onGPU {
                output = try await MetalWindowLevelOperation.execute(
                    input: slice,
                    center: try MetadataFloatingPoint(value: centre),
                    width: try MetadataFloatingPoint(value: width),
                    paddingValue: nil,
                    outputObjectID: try #require(DataObjectID(rawValue: "gpu-out")),
                    outputProvenanceID: try #require(ProvenanceID(rawValue: "record-gpu")),
                    createdAt: try CanonicalInstant(utcString: "2026-08-07T10:03:00Z"),
                    software: try software(),
                    coordinator: coordinator(),
                    kernel: kernel
                )
            } else {
                output = try await WindowLevelOperation.execute(
                    input: slice,
                    center: try MetadataFloatingPoint(value: centre),
                    width: try MetadataFloatingPoint(value: width),
                    paddingValue: nil,
                    outputObjectID: try #require(DataObjectID(rawValue: "cpu-out")),
                    outputProvenanceID: try #require(ProvenanceID(rawValue: "record-cpu")),
                    createdAt: try CanonicalInstant(utcString: "2026-08-07T10:03:00Z"),
                    software: try software(),
                    coordinator: coordinator()
                )
            }
            return try bytes(output)
        }

        let wideCPU = try await windowed(128, 256, onGPU: false)
        let narrowCPU = try await windowed(110, 20, onGPU: false)
        let wideGPU = try await windowed(128, 256, onGPU: true)
        let narrowGPU = try await windowed(110, 20, onGPU: true)
        #expect(wideCPU != narrowCPU)
        #expect(wideGPU != narrowGPU)
        #expect(wideCPU == wideGPU)
        #expect(narrowCPU == narrowGPU)
    }
}
