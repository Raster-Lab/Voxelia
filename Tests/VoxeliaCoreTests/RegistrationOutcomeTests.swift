// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("RegistrationOutcome")
struct RegistrationOutcomeTests {
    private func space(_ id: String) throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func identity(_ name: String) throws -> DataIdentity {
        try DataIdentity(
            objectID: try #require(DataObjectID(rawValue: name)),
            contentID: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: Array(name.utf8)
            ),
            sourceIdentities: [
                try SourceIdentity(
                    namespace: "dicom.sop-instance-uid",
                    identifier: "1.2.840.113619.30",
                    version: nil,
                    contentID: nil
                )
            ],
            derivation: nil
        )
    }

    private func result(
        status: RegistrationConvergenceStatus
    ) throws -> RegistrationResult {
        try RegistrationResult(
            fixedIdentity: try identity("fixed-ct"),
            movingIdentity: try identity("moving-ct"),
            metric: try #require(
                RegistrationMetricID(rawValue: "org.voxelia.metric.mean-squares")
            ),
            metricVersion: "1.0.0",
            optimiser: try #require(
                RegistrationOptimiserID(rawValue: "org.voxelia.optimiser.gradient-descent")
            ),
            optimiserVersion: nil,
            schedule: [
                try RegistrationScheduleLevel(shrinkFactor: 1, smoothingSigma: 0)
            ],
            convergenceStatus: status,
            iterationCount: 40,
            finalMetricValue: status == .failed ? nil : 0.25,
            transform: RegistrationTransform(
                sourceSpace: try space("moving"),
                destinationSpace: try space("fixed"),
                category: .rigid(
                    try RigidMotion(
                        quaternionW: 1,
                        quaternionX: 0,
                        quaternionY: 0,
                        quaternionZ: 0,
                        translationX: 5,
                        translationY: 0,
                        translationZ: 0
                    )
                )
            )
        )
    }

    @Test("[Unit][VOX-REG-008] only a converged run presents a transform")
    func onlyAConvergedRunPresentsATransform() throws {
        let succeeded = RegistrationOutcome.classify(try result(status: .converged))
        guard case .succeeded(let record) = succeeded else {
            Issue.record("a converged run classified as non-converged")
            return
        }
        #expect(record.convergenceStatus == .converged)
        #expect(succeeded.successfulTransform != nil)
    }

    @Test("[Unit][VOX-REG-008] every non-converged status surrenders the transform")
    func everyNonConvergedStatusSurrendersTheTransform() throws {
        for status in [
            RegistrationConvergenceStatus.iterationLimitReached,
            .stoppedByUser,
            .failed,
        ] {
            let outcome = RegistrationOutcome.classify(try result(status: status))
            guard case .notConverged(let report) = outcome else {
                Issue.record("\(status) classified as success")
                continue
            }
            // The report carries the honest measurements and, by type,
            // no transform; the accessor agrees.
            #expect(report.convergenceStatus == status)
            #expect(report.iterationCount == 40)
            #expect(outcome.successfulTransform == nil)
        }
    }

    @Test("[Unit][VOX-REG-008] a failure report of a success refuses typed")
    func aFailureReportOfASuccessRefusesTyped() throws {
        #expect(throws: RegistrationOutcomeError.notAFailure) {
            _ = try RegistrationFailureReport(
                fixedIdentity: try identity("fixed-ct"),
                movingIdentity: try identity("moving-ct"),
                metric: try #require(RegistrationMetricID(rawValue: "m")),
                optimiser: try #require(RegistrationOptimiserID(rawValue: "o")),
                convergenceStatus: .converged,
                iterationCount: 1,
                finalMetricValue: nil
            )
        }
    }
}
