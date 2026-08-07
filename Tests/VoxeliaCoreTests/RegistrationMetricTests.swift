// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("RegistrationMetric")
struct RegistrationMetricTests {
    private func mutualInformation() throws -> MutualInformationMetric {
        try MutualInformationMetric(
            binCount: 2,
            fixedLowerBound: 0,
            fixedUpperBound: 16,
            movingLowerBound: 0,
            movingUpperBound: 16
        )
    }

    @Test("[Unit][VOX-REG-007] mean squares reproduces the oracle with visible counts")
    func meanSquaresReproducesTheOracleWithVisibleCounts() throws {
        let metric = MeanSquaresMetric()
        #expect(metric.identifier.rawValue == "org.voxelia.metric.mean-squares")
        #expect(metric.polarity == .lowerIsBetter)
        let clean = try metric.evaluate(
            fixedSamples: [0, 1, 2, 3],
            movingSamples: [1, 1, 4, 3]
        )
        #expect(clean.value == 1.25)
        #expect(clean.contributingSampleCount == 4)
        #expect(clean.excludedSampleCount == 0)
        let excluded = try metric.evaluate(
            fixedSamples: [0, 1, .nan],
            movingSamples: [1, 1, 0]
        )
        #expect(excluded.value == 0.5)
        #expect(excluded.contributingSampleCount == 2)
        #expect(excluded.excludedSampleCount == 1)
    }

    @Test("[Unit][VOX-REG-007] mutual information reproduces the oracle bit-exactly")
    func mutualInformationReproducesTheOracleBitExactly() throws {
        let metric = try mutualInformation()
        #expect(metric.identifier.rawValue == "org.voxelia.metric.mutual-information")
        #expect(metric.polarity == .higherIsBetter)
        let correlated = try metric.evaluate(
            fixedSamples: [0, 0, 10, 10],
            movingSamples: [0, 0, 10, 10]
        )
        #expect(correlated.value == 0x1.62e42fefa39efp-1)
        #expect(correlated.contributingSampleCount == 4)
        let independent = try metric.evaluate(
            fixedSamples: [0, 0, 10, 10],
            movingSamples: [0, 10, 0, 10]
        )
        #expect(independent.value == 0)
        let outOfRange = try metric.evaluate(
            fixedSamples: [0, 0, 10, 10, 20],
            movingSamples: [0, 0, 10, 10, 5]
        )
        #expect(outOfRange.value == 0x1.62e42fefa39efp-1)
        #expect(outOfRange.contributingSampleCount == 4)
        #expect(outOfRange.excludedSampleCount == 1)
    }

    @Test("[Unit][VOX-REG-007] empty contribution publishes absence, never zero")
    func emptyContributionPublishesAbsenceNeverZero() throws {
        let metric = MeanSquaresMetric()
        let evaluation = try metric.evaluate(
            fixedSamples: [.nan, .nan],
            movingSamples: [0, 0]
        )
        #expect(evaluation.value == nil)
        #expect(evaluation.contributingSampleCount == 0)
        #expect(evaluation.excludedSampleCount == 2)
        let information = try (try mutualInformation()).evaluate(
            fixedSamples: [100, 200],
            movingSamples: [0, 0]
        )
        #expect(information.value == nil)
        #expect(information.excludedSampleCount == 2)
    }

    @Test("[Unit][VOX-REG-007] the upper bound joins the last bin")
    func theUpperBoundJoinsTheLastBin() throws {
        let metric = try mutualInformation()
        let evaluation = try metric.evaluate(
            fixedSamples: [0, 16, 0, 16],
            movingSamples: [0, 16, 0, 16]
        )
        #expect(evaluation.contributingSampleCount == 4)
        #expect(evaluation.value == 0x1.62e42fefa39efp-1)
    }

    @Test("[Unit][VOX-REG-007] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: RegistrationMetricError.countMismatch) {
            _ = try MeanSquaresMetric().evaluate(
                fixedSamples: [0, 1],
                movingSamples: [0]
            )
        }
        #expect(throws: RegistrationMetricError.emptySamples) {
            _ = try MeanSquaresMetric().evaluate(fixedSamples: [], movingSamples: [])
        }
        #expect(throws: RegistrationMetricError.invalidBinCount) {
            _ = try MutualInformationMetric(
                binCount: 1,
                fixedLowerBound: 0,
                fixedUpperBound: 16,
                movingLowerBound: 0,
                movingUpperBound: 16
            )
        }
        #expect(throws: RegistrationMetricError.invalidRange) {
            _ = try MutualInformationMetric(
                binCount: 2,
                fixedLowerBound: 16,
                fixedUpperBound: 0,
                movingLowerBound: 0,
                movingUpperBound: 16
            )
        }
    }
}
