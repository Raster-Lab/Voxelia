// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaPhotorealistic

@Suite("ProgressiveAccumulation")
struct ProgressiveAccumulationTests {
    private func fingerprint(
        scene: String = "scene-1",
        camera: String = "camera-1",
        transferFunction: String = "tf-1",
        sourceData: String = "data-1"
    ) -> SceneStateFingerprint {
        SceneStateFingerprint(
            sceneIdentity: scene,
            cameraIdentity: camera,
            transferFunctionIdentity: transferFunction,
            sourceDataIdentity: sourceData
        )
    }

    @Test("[Unit][VOX-PRR-011] the accumulator reproduces the oracle")
    func theAccumulatorReproducesTheOracle() throws {
        var welford = ProgressiveAccumulator()
        for value in [1.0, 2.0, 3.0, 4.0] {
            try welford.accumulate(value)
        }
        #expect(welford.count == 4)
        #expect(welford.mean == 2.5)
        #expect(welford.variance == 0x1.aaaaaaaaaaaabp+0)

        var single = ProgressiveAccumulator()
        try single.accumulate(0.5)
        #expect(single.mean == 0.5)
        // A variance nobody measured is not reported as certainty.
        #expect(single.variance == nil)

        var irrational = ProgressiveAccumulator()
        for value in [0.1, 0.7, 0.2, 0.9, 0.4] {
            try irrational.accumulate(value)
        }
        #expect(irrational.mean == 0x1.d70a3d70a3d71p-2)
        #expect(irrational.variance == 0x1.ced916872b020p-4)

        var poisoned = ProgressiveAccumulator()
        #expect(throws: ProgressiveAccumulationError.nonFiniteSample) {
            try poisoned.accumulate(.nan)
        }
        #expect(poisoned.count == 0)
    }

    @Test("[Unit][VOX-PRR-012] every declared trigger resets the accumulation")
    func everyDeclaredTriggerResetsTheAccumulation() throws {
        var accumulation = TemporalAccumulation()
        #expect(
            try accumulation.accumulate(1, under: fingerprint()) == .accumulated
        )
        #expect(
            try accumulation.accumulate(2, under: fingerprint()) == .accumulated
        )
        #expect(accumulation.accumulator.count == 2)

        // Each of the row's four triggers, alone, resets before the
        // sample joins — stale accumulation is unrepresentable.
        let changes = [
            fingerprint(scene: "scene-2"),
            fingerprint(camera: "camera-2"),
            fingerprint(transferFunction: "tf-2"),
            fingerprint(sourceData: "data-2"),
        ]
        for changed in changes {
            var fresh = TemporalAccumulation()
            _ = try fresh.accumulate(1, under: fingerprint())
            _ = try fresh.accumulate(2, under: fingerprint())
            let outcome = try fresh.accumulate(10, under: changed)
            #expect(outcome == .resetAndAccumulated)
            #expect(fresh.accumulator.count == 1)
            #expect(fresh.accumulator.mean == 10)
        }
    }
}
