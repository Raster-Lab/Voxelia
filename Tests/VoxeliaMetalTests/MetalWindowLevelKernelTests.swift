// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

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
                == "302cd86e30ac67c064b9ce20833bb61585a46d636de3e952c3e95cc3504f7cbd"
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

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
