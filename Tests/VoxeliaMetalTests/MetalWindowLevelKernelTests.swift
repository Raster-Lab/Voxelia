// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaMetal

@Suite("MetalWindowLevelKernel")
struct MetalWindowLevelKernelTests {
    /// The frozen `VOXELIA-ALG-0002` binary64 reference model,
    /// replicated from the specification and anchored below against
    /// its registered fixtures.
    private func referenceModel(_ sample: Double, center: Double, width: Double) -> UInt8 {
        let halfSpan = (width - 1.0) / 2.0
        let threshold = center - 0.5
        if sample <= threshold - halfSpan {
            return 0
        }
        if sample > threshold + halfSpan {
            return 255
        }
        let mapped = ((sample - threshold) / (width - 1.0) + 0.5) * 255.0
        let rounded = mapped.rounded(.toNearestOrEven)
        return UInt8(min(255.0, max(0.0, rounded)))
    }

    @Test("[Unit][VOX-PLT-011][VOX-REP-008] the kernel is digest-pinned and fixture-exact")
    func kernelIsDigestPinnedAndFixtureExact() throws {
        // The shader manifest's digest pin must equal the embedded
        // source digest, so manifest and source can never drift.
        #expect(
            MetalWindowLevelKernel.sourceDigestHexText
                == "e97eb8c7ac120b9d592827be29c3bf127256784328e9ee53139b01d9111a5197"
        )

        // The reference model reproduces the registered ALG-0002
        // fixture values, anchoring the harness to the specification.
        #expect(referenceModel(3, center: 6, width: 8) == 36)
        #expect(referenceModel(6, center: 6, width: 8) == 146)
        #expect(referenceModel(9, center: 6, width: 8) == 255)

        // The GPU reproduces the registered uint8 fixture within the
        // one-display-level bound of ADR-0080, and a sub-one width
        // rejects typed.
        let kernel = try MetalWindowLevelKernel(
            context: try MetalExecutionContext()
        )
        #expect(
            kernel.kernelReference.identifier.rawValue
                == "org.voxelia.kernel.window-level"
        )
        let fixtureOutput = try kernel.mapSamples(
            Array(0..<12),
            center: 6,
            width: 8
        )
        let fixtureExpected: [UInt8] = [0, 0, 0, 36, 73, 109, 146, 182, 219, 255, 255, 255]
        #expect(fixtureOutput.count == fixtureExpected.count)
        for (produced, expected) in zip(fixtureOutput, fixtureExpected) {
            #expect(abs(Int(produced) - Int(expected)) <= 1)
        }
        do {
            _ = try kernel.mapSamples([1, 2, 3], center: 6, width: 0.5)
            #expect(Bool(false), "Expected a sub-one width to be rejected.")
        } catch MetalKernelError.invalidWindowWidth {}
        #expect(try kernel.mapSamples([], center: 6, width: 8) == [])

        requireSendable(MetalWindowLevelKernel.self)
        requireSendable(MetalKernelError.self)
    }

    @Test("[Unit][VOX-VAL-007][VOX-EXE-003] the differential harness measures the GPU model")
    func differentialHarnessMeasuresTheGPUModel() throws {
        // The exhaustive uint8 domain across a spread of windows,
        // including the degenerate unit width, measured against the
        // frozen binary64 model per ADR-0080: every GPU sample within
        // one display level, repeated execution bit-identical, and the
        // exact-match count recorded as single-device evidence.
        let kernel = try MetalWindowLevelKernel(
            context: try MetalExecutionContext()
        )
        let storedSamples = Array(UInt8(0)...UInt8(255))
        let windows: [(center: Double, width: Double)] = [
            (6, 8), (128, 256), (40, 400), (1, 4), (200, 1), (127.5, 255),
        ]

        var comparedCount = 0
        var exactMatchCount = 0
        for window in windows {
            let gpuOutput = try kernel.mapSamples(
                storedSamples,
                center: window.center,
                width: window.width
            )
            let repeated = try kernel.mapSamples(
                storedSamples,
                center: window.center,
                width: window.width
            )
            #expect(gpuOutput == repeated)
            for (stored, produced) in zip(storedSamples, gpuOutput) {
                let expected = referenceModel(
                    Double(stored),
                    center: window.center,
                    width: window.width
                )
                #expect(abs(Int(produced) - Int(expected)) <= 1)
                comparedCount += 1
                if produced == expected {
                    exactMatchCount += 1
                }
            }
        }
        #expect(comparedCount == 256 * windows.count)

        // Measured evidence floor: the float32 approximation must agree
        // exactly on at least 99 percent of the exhaustive domain; the
        // exact measured count for this device is reported here and
        // recorded in the progress ledger, not assumed.
        print(
            "ADR-0080 differential evidence: \(exactMatchCount)/\(comparedCount) exact"
        )
        #expect(exactMatchCount * 100 >= comparedCount * 99)
    }

    private func int16Image(_ values: [Int16]) throws -> ImageData {
        var bytes = [UInt8]()
        for value in values {
            withUnsafeBytes(of: value.littleEndian) { bytes.append(contentsOf: $0) }
        }
        let software = try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
        func axis(_ id: String) throws -> AxisDescriptor {
            try AxisDescriptor(
                id: try #require(AxisID(rawValue: id)),
                name: id,
                semantic: .spatialX,
                unit: nil,
                sampling: .indexOnly
            )
        }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: [4, 3]),
                scalarFormat: try ScalarFormat(
                    type: .int16,
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
                axes: [try axis("x"), try axis("y")],
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: try ImageShape(extents: [4, 3]),
                        scalarType: .int16,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-ct")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T05:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "series-ct"))),
                software: software,
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "series-ct")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.ct",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    @Test("[Unit][VOX-VAL-007][VOX-PLT-011] the sixteen-bit paths measure their differentials")
    func sixteenBitPathsMeasureTheirDifferentials() async throws {
        let kernel = try MetalWindowLevelKernel(
            context: try MetalExecutionContext()
        )

        // Deterministic seeded-LCG corpora per ADR-0093: the uint8
        // exactness evidence says nothing about the 16-bit domains, so
        // each domain is measured on this device.
        var state: UInt64 = 0x5DEE_CE66_D001
        func nextValue() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
        var int16Values = [Int16]()
        var int16Bytes = [UInt8]()
        var uint16Values = [UInt16]()
        var uint16Bytes = [UInt8]()
        for _ in 0..<4096 {
            let signed = Int16(truncatingIfNeeded: nextValue() >> 16)
            int16Values.append(signed)
            withUnsafeBytes(of: signed.littleEndian) {
                int16Bytes.append(contentsOf: $0)
            }
            let unsigned = UInt16(truncatingIfNeeded: nextValue() >> 24)
            uint16Values.append(unsigned)
            withUnsafeBytes(of: unsigned.littleEndian) {
                uint16Bytes.append(contentsOf: $0)
            }
        }

        var comparedCount = 0
        var exactMatchCount = 0
        func measure(
            bytes: [UInt8],
            values: [Double],
            scalarType: ScalarType,
            windows: [(center: Double, width: Double)]
        ) throws {
            for window in windows {
                let gpuOutput = try kernel.mapSamples(
                    storedBytes: bytes,
                    scalarType: scalarType,
                    center: window.center,
                    width: window.width
                )
                let repeated = try kernel.mapSamples(
                    storedBytes: bytes,
                    scalarType: scalarType,
                    center: window.center,
                    width: window.width
                )
                #expect(gpuOutput == repeated)
                #expect(gpuOutput.count == values.count)
                for (value, produced) in zip(values, gpuOutput) {
                    let expected = referenceModel(
                        value,
                        center: window.center,
                        width: window.width
                    )
                    #expect(abs(Int(produced) - Int(expected)) <= 1)
                    comparedCount += 1
                    if produced == expected {
                        exactMatchCount += 1
                    }
                }
            }
        }
        try measure(
            bytes: int16Bytes,
            values: int16Values.map(Double.init),
            scalarType: .int16,
            windows: [(40, 400), (0, 2000), (-500, 1), (1000, 65_535), (100, 3)]
        )
        try measure(
            bytes: uint16Bytes,
            values: uint16Values.map(Double.init),
            scalarType: .uint16,
            windows: [(32_000, 64_000), (100, 3), (500, 1), (40_000, 10_000)]
        )
        #expect(comparedCount == 4096 * 9)
        print(
            "ADR-0093 differential evidence: \(exactMatchCount)/\(comparedCount) exact"
        )
        #expect(exactMatchCount * 100 >= comparedCount * 99)

        // The operation anchor: the device implementation at 1.1.0
        // over a native int16 image stays within one display level of
        // the registered CPU implementation.
        let stored: [Int16] = [
            -1024, -200, -100, 0, 20, 40, 60, 80, 120, 200, 1000, 3000,
        ]
        let input = try int16Image(stored)
        let software = try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
        let gpuImage = try await MetalWindowLevelOperation.execute(
            input: input,
            center: try MetadataFloatingPoint(value: 40),
            width: try MetadataFloatingPoint(value: 400),
            outputObjectID: try #require(DataObjectID(rawValue: "series-gpu")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-gpu")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T05:05:00Z"),
            software: software,
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64),
            kernel: kernel
        )
        let cpuImage = try await WindowLevelOperation.execute(
            input: input,
            center: try MetadataFloatingPoint(value: 40),
            width: try MetadataFloatingPoint(value: 400),
            outputObjectID: try #require(DataObjectID(rawValue: "series-cpu")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-cpu")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T05:05:00Z"),
            software: software,
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
        let region = try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        let gpuBytes = try gpuImage.storage.read(region: region).bytes
        let cpuBytes = try cpuImage.storage.read(region: region).bytes
        #expect(gpuBytes.count == cpuBytes.count)
        for (produced, expected) in zip(gpuBytes, cpuBytes) {
            #expect(abs(Int(produced) - Int(expected)) <= 1)
        }
        let implementation = try #require(gpuImage.identity.derivation?.implementation)
        #expect(
            implementation.identifier.rawValue == "org.voxelia.impl.window-level.metal"
        )
        #expect(
            implementation.version == (try SemanticVersion(major: 1, minor: 1, patch: 0))
        )

        // Typed rejections: an unsupported scalar type and an odd
        // 16-bit byte count.
        do {
            _ = try kernel.mapSamples(
                storedBytes: [1, 2, 3, 4],
                scalarType: .int32,
                center: 40,
                width: 400
            )
            #expect(Bool(false), "Expected an unsupported scalar type to be rejected.")
        } catch MetalKernelError.unsupportedScalarType {}
        do {
            _ = try kernel.mapSamples(
                storedBytes: [1, 2, 3],
                scalarType: .int16,
                center: 40,
                width: 400
            )
            #expect(Bool(false), "Expected an odd byte count to be rejected.")
        } catch MetalKernelError.invalidSampleByteCount {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
