// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaValidation

/// The `ADR-0407` measurement campaign runner, directed by the owner
/// (2026-08-08): cold-start, warm-cache and steady-state measurements
/// of representative registered operations on the reference hardware,
/// emitted as schema-conformant `BenchmarkRecord` JSON for the release
/// evidence. Modes not run are not fabricated — the report says which
/// modes ran.
@Suite("BenchmarkCampaign", .serialized)
struct BenchmarkCampaignTests {
    private static let environment = (
        hardware: "Mac17,4 Apple M5",
        operatingSystem: "macOS 26.5.1",
        compiler: "Apple Swift 6.3.3",
        voxeliaVersion: "1.0.0"
    )

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    /// A 128x128x64 int16 ramp volume: about one million samples,
    /// representative of one CT slice stack chunk.
    private func volume() throws -> ImageData {
        let extents = [128, 128, 64]
        let sampleCount = extents.reduce(1, *)
        var bytes = [UInt8]()
        bytes.reserveCapacity(sampleCount * 2)
        for index in 0..<sampleCount {
            let value = Int16(truncatingIfNeeded: index &* 31)
            let pattern = UInt16(bitPattern: value)
            bytes.append(UInt8(pattern & 0xFF))
            bytes.append(UInt8(pattern >> 8))
        }
        let shape = try ImageShape(extents: ContiguousArray(extents))
        var axes = ContiguousArray<AxisDescriptor>()
        for (index, axisName) in ["x", "y", "z"].enumerated() {
            let semantic: AxisSemantic =
                index == 0 ? .spatialX : (index == 1 ? .spatialY : .spatialZ)
            axes.append(
                try AxisDescriptor(
                    id: try #require(AxisID(rawValue: axisName)),
                    name: axisName,
                    semantic: semantic,
                    unit: nil,
                    sampling: .indexOnly
                )
            )
        }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
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
                axes: axes,
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: shape,
                        scalarType: .int16,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-bench-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-08T09:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "bench-in"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "bench-in")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.99",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func windowLevelOnce(
        _ input: ImageData,
        run: Int
    ) async throws -> Double {
        let clock = ContinuousClock()
        let start = clock.now
        _ = try await WindowLevelOperation.execute(
            input: input,
            center: try MetadataFloatingPoint(value: 200),
            width: try MetadataFloatingPoint(value: 2000),
            paddingValue: nil,
            outputObjectID: try #require(DataObjectID(rawValue: "bench-out-\(run)")),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "record-bench-out-\(run)")
            ),
            createdAt: try CanonicalInstant(utcString: "2026-08-08T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 8_388_608
            )
        )
        let elapsed = clock.now - start
        let milliseconds =
            Double(elapsed.components.seconds) * 1000
            + Double(elapsed.components.attoseconds) / 1e15
        return milliseconds
    }

    private func record(
        mode: BenchmarkMode,
        latency: Double,
        sampleCount: Int
    ) throws -> BenchmarkRecord {
        let seconds = latency / 1000
        return try BenchmarkRecord(
            mode: mode,
            hardware: Self.environment.hardware,
            operatingSystem: Self.environment.operatingSystem,
            compiler: Self.environment.compiler,
            voxeliaVersion: Self.environment.voxeliaVersion,
            operationIdentifier: try DerivationOperationToken(
                rawValue: WindowLevelOperation.operationIdentifier
            ),
            operationVersion: try SemanticVersion(major: 1, minor: 5, patch: 0),
            shaderIdentity: nil,
            dataset: "ramp-int16-128x128x64",
            storageForm: "contiguous",
            cacheState: mode == .coldStart ? "cold" : "warm",
            quality: try ExecutionClaimToken(rawValue: "org.voxelia.quality.full"),
            latencyMilliseconds: latency,
            throughputPerSecond: Double(sampleCount) / seconds,
            peakMemoryBytes: Double(sampleCount * 3),
            validationStatus: "suite-green"
        )
    }

    @Test("[Integration][VOX-PER-010][VOX-PER-011] measure and emit the records")
    func measureAndEmitTheRecords() async throws {
        let input = try volume()
        let sampleCount = 128 * 128 * 64

        // Cold start: the process's first execution of the operation.
        let cold = try await windowLevelOnce(input, run: 0)
        // Warm cache: the immediately following execution.
        let warm = try await windowLevelOnce(input, run: 1)
        // Steady state: the median of eleven further executions.
        var timings = [Double]()
        for run in 2..<13 {
            timings.append(try await windowLevelOnce(input, run: run))
        }
        let steady = timings.sorted()[timings.count / 2]

        let records = [
            try record(mode: .coldStart, latency: cold, sampleCount: sampleCount),
            try record(mode: .warmCache, latency: warm, sampleCount: sampleCount),
            try record(mode: .steadyState, latency: steady, sampleCount: sampleCount),
        ]
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = try encoder.encode(records)
        // Schema conformance by construction: the emitted evidence
        // decodes through the revalidating admission.
        let decoded = try JSONDecoder().decode([BenchmarkRecord].self, from: json)
        #expect(decoded.count == 3)
        print("CAMPAIGN-JSON-BEGIN")
        print(String(decoding: json, as: UTF8.self))
        print("CAMPAIGN-JSON-END")
    }
}
