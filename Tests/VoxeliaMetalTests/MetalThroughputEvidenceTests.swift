// SPDX-License-Identifier: MIT

import Foundation
import Synchronization
import Testing
import VoxeliaCore

@testable import VoxeliaMetal

@Suite("MetalThroughputEvidence")
struct MetalThroughputEvidenceTests {
    private final class TelemetryBox: Sendable {
        private let stored = Mutex<[MetalDispatchTelemetry]>([])

        func record(_ telemetry: MetalDispatchTelemetry) {
            stored.withLock { records in
                records.append(telemetry)
            }
        }

        var records: [MetalDispatchTelemetry] {
            stored.withLock { $0 }
        }
    }

    @Test("[Unit][VOX-MTL-007][VOX-VAL-007] kernel throughput measures across scaled corpora")
    func kernelThroughputMeasuresAcrossScaledCorpora() throws {
        // The ADR-0109 campaign: both families over scaled corpora
        // through the megasample range, timed by the platform's own
        // command-buffer timestamps, single-device evidence. On this
        // unified-memory device the shared-storage buffers are host
        // memory — no upload pass exists to measure, and that measured
        // absence with the sampling cost beside it is the VOX-MTL-007
        // justification.
        let context = try MetalExecutionContext()
        let box = TelemetryBox()
        let windowKernel = try MetalWindowLevelKernel(
            context: context,
            telemetrySink: { box.record($0) }
        )
        let compositeKernel = try MetalCompositeKernel(
            context: context,
            telemetrySink: { box.record($0) }
        )

        var state: UInt64 = 0x0109_BEEF_0001
        func nextByte() -> UInt8 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return UInt8(truncatingIfNeeded: state >> 32)
        }

        let windowSizes = [4_096, 65_536, 1_048_576]
        for size in windowSizes {
            var samples = [UInt8]()
            samples.reserveCapacity(size)
            for _ in 0..<size {
                samples.append(nextByte())
            }
            let output = try windowKernel.mapSamples(
                samples, center: 128, width: 256, paddingValue: nil)
            #expect(output.count == size)
        }
        let compositeElements = 262_144
        var layerA = [UInt8]()
        var layerB = [UInt8]()
        layerA.reserveCapacity(compositeElements)
        layerB.reserveCapacity(compositeElements)
        for _ in 0..<compositeElements {
            layerA.append(nextByte())
            layerB.append(nextByte())
        }
        let blended = try compositeKernel.blendLayers(
            [layerA, layerB],
            opacities: [1.0, 0.5]
        )
        #expect(blended.count == compositeElements)

        // Every dispatch delivered telemetry with the exact sample
        // count; throughput prints per measured size.
        let records = box.records
        #expect(records.count == windowSizes.count + 1)
        for (record, expectedCount) in zip(records, windowSizes + [compositeElements]) {
            #expect(record.sampleCount == expectedCount)
            #expect(record.gpuSeconds >= 0)
            let throughput =
                record.gpuSeconds > 0
                ? Double(record.sampleCount) / record.gpuSeconds
                : Double.infinity
            print(
                "ADR-0109 throughput evidence: \(record.entryPoint) "
                    + "samples=\(record.sampleCount) "
                    + "gpuSeconds=\(record.gpuSeconds) "
                    + "samplesPerSecond=\(throughput) "
                    + "(shared storage, zero upload passes)"
            )
        }
        let largest = try #require(
            records.first(where: { $0.sampleCount == 1_048_576 })
        )
        #expect(largest.gpuSeconds > 0)
    }
}
