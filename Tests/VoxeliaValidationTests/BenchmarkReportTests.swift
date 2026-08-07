// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaCore
import VoxeliaExecution

@testable import VoxeliaValidation

@Suite("BenchmarkReport")
struct BenchmarkReportTests {
    private func record(
        mode: BenchmarkMode = .steadyState,
        latency: Double = 10,
        throughput: Double = 100,
        memory: Double = 1_000_000
    ) throws -> BenchmarkRecord {
        try BenchmarkRecord(
            mode: mode,
            hardware: "Mac17,4 Apple M5",
            operatingSystem: "macOS 26.0",
            compiler: "Swift 6.3.3",
            voxeliaVersion: "0.2.0",
            operationIdentifier: try DerivationOperationToken(
                rawValue: "org.voxelia.op.level-select"
            ),
            operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
            shaderIdentity: nil,
            dataset: "phantom-899-slice-ct",
            storageForm: "contiguous",
            cacheState: "warm",
            quality: try ExecutionClaimToken(rawValue: "org.voxelia.quality.full"),
            latencyMilliseconds: latency,
            throughputPerSecond: throughput,
            peakMemoryBytes: memory,
            validationStatus: "suite-green-1458"
        )
    }

    @Test("[Unit][VOX-PER-010][VOX-PER-011][VOX-ERR-008] records carry the fields and round-trip")
    func recordsCarryTheFieldsAndRoundTrip() throws {
        let original = try record()
        let decoded = try JSONDecoder().decode(
            BenchmarkRecord.self,
            from: try JSONEncoder().encode(original)
        )
        #expect(decoded.hardware == original.hardware)
        #expect(decoded.operationIdentifier == original.operationIdentifier)
        #expect(decoded.quality == original.quality)
        #expect(decoded.latencyMilliseconds == 10)
        // Every declared mode is expressible; a report says which ran.
        #expect(BenchmarkMode.allCases.count == 8)
        // The vocabulary is pure data: nothing here collects anything,
        // which is the removable-instrumentation fact in miniature —
        // the telemetry producers all accept a nil sink.
        #expect(throws: BenchmarkReportError.emptyField) {
            _ = try BenchmarkRecord(
                mode: .coldStart,
                hardware: " ",
                operatingSystem: "macOS",
                compiler: "Swift",
                voxeliaVersion: "0.2.0",
                operationIdentifier: try DerivationOperationToken(
                    rawValue: "org.voxelia.op.level-select"
                ),
                operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
                shaderIdentity: nil,
                dataset: "d",
                storageForm: "s",
                cacheState: "c",
                quality: try ExecutionClaimToken(
                    rawValue: "org.voxelia.quality.full"
                ),
                latencyMilliseconds: 1,
                throughputPerSecond: 1,
                peakMemoryBytes: 1,
                validationStatus: "v"
            )
        }
    }

    @Test("[Unit][VOX-PER-012] the threshold seam reports regressions typed")
    func theThresholdSeamReportsRegressionsTyped() throws {
        let baseline = try record()
        #expect(
            try RegressionCheck.evaluate(
                baseline: baseline,
                candidate: try record(latency: 10.5),
                threshold: 0.1
            ) == .pass
        )
        #expect(
            try RegressionCheck.evaluate(
                baseline: baseline,
                candidate: try record(latency: 12),
                threshold: 0.1
            ) == .regression(dimension: "latency")
        )
        #expect(
            try RegressionCheck.evaluate(
                baseline: baseline,
                candidate: try record(throughput: 80),
                threshold: 0.1
            ) == .regression(dimension: "throughput")
        )
        // The approved threshold is the owner's: no default exists.
        #expect(throws: BenchmarkReportError.invalidThreshold) {
            _ = try RegressionCheck.evaluate(
                baseline: baseline,
                candidate: baseline,
                threshold: 0
            )
        }
    }
}
