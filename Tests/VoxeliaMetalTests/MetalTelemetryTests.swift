// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaCore

@testable import VoxeliaMetal

@Suite("MetalTelemetry")
struct MetalTelemetryTests {
    private final class TelemetryBox: @unchecked Sendable {
        private let lock = NSLock()
        private var stored = [MetalDispatchTelemetry]()

        func record(_ telemetry: MetalDispatchTelemetry) {
            lock.lock()
            defer { lock.unlock() }
            stored.append(telemetry)
        }

        var records: [MetalDispatchTelemetry] {
            lock.lock()
            defer { lock.unlock() }
            return stored
        }
    }

    @Test("[Unit][VOX-MTL-015][VOX-EXE-003] dispatches deliver measured telemetry")
    func dispatchesDeliverMeasuredTelemetry() throws {
        // A host-owned sink per ADR-0107 receives one measured value
        // per dispatch on the real device, carrying the platform's own
        // command-buffer timestamps — printed as single-device
        // evidence.
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

        _ = try windowKernel.mapSamples(Array(0..<12), center: 6, width: 8, paddingValue: nil)
        _ = try compositeKernel.blendLayers(
            [Array(0..<12), Array(repeating: 255, count: 12)],
            opacities: [1.0, 0.5]
        )

        let records = box.records
        #expect(records.count == 2)
        let window = try #require(records.first)
        #expect(window.kernelToken == "org.voxelia.kernel.window-level")
        #expect(window.entryPoint == "voxelia_window_level_u8")
        #expect(window.sampleCount == 12)
        #expect(window.gpuSeconds >= 0)
        #expect(window.commandBufferLatencySeconds >= 0)
        let composite = try #require(records.last)
        #expect(composite.kernelToken == "org.voxelia.kernel.composite-layers")
        #expect(composite.entryPoint == "voxelia_composite_layers")
        #expect(composite.sampleCount == 12)
        #expect(composite.gpuSeconds >= 0)
        for record in records {
            print(
                "ADR-0107 telemetry evidence: \(record.entryPoint) "
                    + "gpuSeconds=\(record.gpuSeconds) "
                    + "latencySeconds=\(record.commandBufferLatencySeconds) "
                    + "samples=\(record.sampleCount)"
            )
        }

        // A kernel without a sink dispatches unchanged.
        let silent = try MetalWindowLevelKernel(context: context, telemetrySink: nil)
        #expect(
            try silent.mapSamples(Array(0..<12), center: 6, width: 8, paddingValue: nil).count == 12
        )
        #expect(box.records.count == 2)

        requireSendable(MetalDispatchTelemetry.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
