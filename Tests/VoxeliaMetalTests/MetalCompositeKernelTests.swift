// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaMetal

@Suite("MetalCompositeKernel")
struct MetalCompositeKernelTests {
    /// The frozen `VOXELIA-ALG-0009` binary64 reference model,
    /// replicated from the specification and anchored below against
    /// its registered fixtures.
    private func referenceModel(
        _ samples: [Double],
        opacities: [Double]
    ) -> UInt8 {
        var accumulator = 0.0
        for (sample, opacity) in zip(samples, opacities) {
            let transparency = 1.0 - opacity
            let retained = accumulator * transparency
            let contributed = sample * opacity
            accumulator = retained + contributed
        }
        let rounded = accumulator.rounded(.toNearestOrEven)
        return UInt8(min(255.0, max(0.0, rounded)))
    }

    @Test("[Kernel][VOX-PLT-011][VOX-REP-008] the composite kernel is pinned and anchored")
    func compositeKernelIsPinnedAndAnchored() throws {
        #expect(
            MetalCompositeKernel.sourceDigestHexText
                == "6ed663f6d20d71091c5c704e11e1f7dc7c8cda955253c89770c782cecfd1f1c7"
        )
        let kernel = try MetalCompositeKernel(
            context: try MetalExecutionContext(),
            telemetrySink: nil
        )
        #expect(
            kernel.kernelReference.identifier.rawValue
                == "org.voxelia.kernel.composite-layers"
        )

        // The registered ALG-0009 fixtures anchor the device within
        // one display level.
        let layerA: [UInt8] = [0, 0, 0, 36, 73, 109, 146, 182, 219, 255, 255, 255]
        let layerB: [UInt8] = [0, 51, 102, 153, 204, 255, 255, 255, 255, 255, 255, 255]
        let fixtures: [(opacities: [Double], expected: [UInt8])] = [
            ([1.0, 0.5], [0, 26, 51, 94, 138, 182, 200, 218, 237, 255, 255, 255]),
            ([0.75, 0.25], [0, 13, 26, 58, 92, 125, 146, 166, 187, 207, 207, 207]),
            ([1.0, 0.0], layerA),
        ]
        for fixture in fixtures {
            let produced = try kernel.blendLayers(
                [layerA, layerB],
                opacities: fixture.opacities
            )
            #expect(produced.count == fixture.expected.count)
            for (device, expected) in zip(produced, fixture.expected) {
                #expect(abs(Int(device) - Int(expected)) <= 1)
            }
        }
        #expect(try kernel.blendLayers([[], []], opacities: [1, 0.5]) == [])

        // Ragged layers and malformed opacity lists reject typed.
        do {
            _ = try kernel.blendLayers([layerA, [1, 2]], opacities: [1, 0.5])
            #expect(Bool(false), "Expected ragged layers to be rejected.")
        } catch MetalCompositeKernelError.invalidLayerShape {}
        do {
            _ = try kernel.blendLayers([], opacities: [])
            #expect(Bool(false), "Expected an empty layer list to be rejected.")
        } catch MetalCompositeKernelError.invalidLayerShape {}
        do {
            _ = try kernel.blendLayers([layerA, layerB], opacities: [1.0])
            #expect(Bool(false), "Expected a short opacity list to be rejected.")
        } catch MetalCompositeKernelError.invalidOpacity {}
        do {
            _ = try kernel.blendLayers([layerA, layerB], opacities: [1.0, 1.5])
            #expect(Bool(false), "Expected an out-of-range opacity to be rejected.")
        } catch MetalCompositeKernelError.invalidOpacity {}

        requireSendable(MetalCompositeKernel.self)
        requireSendable(MetalCompositeKernelError.self)
    }

    @Test("[Kernel][VOX-SEC-001][VOX-REP-008] composite parameters have exact bytes")
    func compositeParametersHaveExactBytes() throws {
        #expect(
            try MetalCompositeKernel.parameterBytes(
                elementCount: 12,
                layerCount: 2
            ) == [
                0x0C, 0x00, 0x00, 0x00,
                0x02, 0x00, 0x00, 0x00,
            ]
        )
        #expect(
            try MetalCompositeKernel.opacityBytes([0, 0.5, 1]) == [
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x3F,
                0x00, 0x00, 0x80, 0x3F,
            ]
        )
        #expect(
            try MetalCompositeKernel.validatedPackedSampleCount(
                elementCount: 12,
                layerCount: 2
            ) == 24
        )

        do {
            _ = try MetalCompositeKernel.parameterBytes(
                elementCount: Int(UInt32.max) + 1,
                layerCount: 2
            )
            #expect(Bool(false), "Expected an unrepresentable element count to reject.")
        } catch MetalCompositeKernelError.invalidLayerShape {}
        do {
            _ = try MetalCompositeKernel.parameterBytes(
                elementCount: 12,
                layerCount: Int(UInt32.max) + 1
            )
            #expect(Bool(false), "Expected an unrepresentable layer count to reject.")
        } catch MetalCompositeKernelError.invalidLayerShape {}
        do {
            _ = try MetalCompositeKernel.validatedPackedSampleCount(
                elementCount: Int.max,
                layerCount: 2
            )
            #expect(Bool(false), "Expected a packed-sample overflow to reject.")
        } catch MetalCompositeKernelError.invalidLayerShape {}
    }

    @Test("[Kernel][VOX-VAL-007][VOX-EXE-003] the composite differential measures the GPU model")
    func compositeDifferentialMeasuresTheGPUModel() throws {
        let kernel = try MetalCompositeKernel(
            context: try MetalExecutionContext(),
            telemetrySink: nil
        )

        // Deterministic seeded-LCG layer stacks per ADR-0096,
        // including the 64-layer scene ceiling; the accumulation error
        // of iterated float32 composite-over is measured, never
        // assumed.
        var state: UInt64 = 0x0096_C0FF_EE01
        func nextValue() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
        var comparedCount = 0
        var exactMatchCount = 0
        let scenarios: [(layerCount: Int, elementCount: Int)] = [
            (2, 4096), (4, 4096), (8, 4096), (64, 1024),
        ]
        for scenario in scenarios {
            var layers = [[UInt8]]()
            var opacities = [Double]()
            for layerIndex in 0..<scenario.layerCount {
                var layer = [UInt8]()
                layer.reserveCapacity(scenario.elementCount)
                for _ in 0..<scenario.elementCount {
                    layer.append(UInt8(truncatingIfNeeded: nextValue() >> 32))
                }
                layers.append(layer)
                if layerIndex == 0 {
                    opacities.append(1.0)
                } else {
                    opacities.append(Double(nextValue() % 1001) / 1000.0)
                }
            }
            let gpuOutput = try kernel.blendLayers(layers, opacities: opacities)
            let repeated = try kernel.blendLayers(layers, opacities: opacities)
            #expect(gpuOutput == repeated)
            #expect(gpuOutput.count == scenario.elementCount)
            for index in 0..<scenario.elementCount {
                let expected = referenceModel(
                    layers.map { Double($0[index]) },
                    opacities: opacities
                )
                let produced = gpuOutput[index]
                #expect(abs(Int(produced) - Int(expected)) <= 1)
                comparedCount += 1
                if produced == expected {
                    exactMatchCount += 1
                }
            }
        }
        #expect(comparedCount == 4096 * 3 + 1024)
        print(
            "ADR-0096 differential evidence: \(exactMatchCount)/\(comparedCount) exact "
                + "(source sha256 \(MetalCompositeKernel.sourceDigestHexText))"
        )
        #expect(exactMatchCount * 100 >= comparedCount * 99)
    }

    @Test("[Concurrency][VOX-CON-003][VOX-MTL-004] one composite kernel dispatches concurrently")
    func oneCompositeKernelDispatchesConcurrently() async throws {
        let context = try MetalExecutionContext()
        let kernel = try MetalCompositeKernel(
            context: context,
            telemetrySink: nil
        )
        let first = Array(UInt8(0)...UInt8(255))
        let second = first.reversed()
        let layers = [first, Array(second)]
        let opacities = [1.0, 0.5]
        let expected = try kernel.blendLayers(layers, opacities: opacities)

        try await withThrowingTaskGroup(of: [UInt8].self) { group in
            for _ in 0..<16 {
                group.addTask {
                    try kernel.blendLayers(layers, opacities: opacities)
                }
            }
            for try await produced in group {
                #expect(produced == expected)
            }
        }

        #expect(context.pipelineCache.libraryBuildCount == 1)
        #expect(context.pipelineCache.pipelineBuildCount == 1)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
