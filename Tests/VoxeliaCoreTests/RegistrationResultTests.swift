// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("RegistrationResult")
struct RegistrationResultTests {
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
                    identifier: "1.2.840.113619.27",
                    version: nil,
                    contentID: nil
                )
            ],
            derivation: nil
        )
    }

    private func rigidTransform() throws -> RegistrationTransform {
        RegistrationTransform(
            sourceSpace: try space("moving"),
            destinationSpace: try space("fixed"),
            category: .rigid(
                try RigidMotion(
                    quaternionW: 1,
                    quaternionX: 0,
                    quaternionY: 0,
                    quaternionZ: 0,
                    translationX: 2,
                    translationY: 0,
                    translationZ: 0
                )
            )
        )
    }

    @Test("[Unit][VOX-REG-002] the record identifies every declared part")
    func theRecordIdentifiesEveryDeclaredPart() throws {
        let result = try RegistrationResult(
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
                try RegistrationScheduleLevel(shrinkFactor: 4, smoothingSigma: 2),
                try RegistrationScheduleLevel(shrinkFactor: 2, smoothingSigma: 1),
                try RegistrationScheduleLevel(shrinkFactor: 1, smoothingSigma: 0),
            ],
            convergenceStatus: .converged,
            iterationCount: 120,
            finalMetricValue: 0.125,
            transform: try rigidTransform()
        )
        #expect(result.fixedIdentity.objectID.rawValue == "fixed-ct")
        #expect(result.movingIdentity.objectID.rawValue == "moving-ct")
        #expect(result.metric.rawValue == "org.voxelia.metric.mean-squares")
        #expect(result.optimiser.rawValue == "org.voxelia.optimiser.gradient-descent")
        #expect(result.schedule.count == 3)
        #expect(result.convergenceStatus == .converged)
        #expect(result.iterationCount == 120)
        #expect(result.finalMetricValue == 0.125)
        #expect(result.transform.sourceSpace.id.rawValue == "moving")
        #expect(result.transform.destinationSpace.id.rawValue == "fixed")
    }

    @Test("[Unit][VOX-REG-002] a failed run records an absent metric value honestly")
    func aFailedRunRecordsAnAbsentMetricValueHonestly() throws {
        let result = try RegistrationResult(
            fixedIdentity: try identity("fixed-ct"),
            movingIdentity: try identity("moving-ct"),
            metric: try #require(
                RegistrationMetricID(rawValue: "org.voxelia.metric.mean-squares")
            ),
            metricVersion: nil,
            optimiser: try #require(
                RegistrationOptimiserID(rawValue: "org.voxelia.optimiser.gradient-descent")
            ),
            optimiserVersion: nil,
            schedule: [
                try RegistrationScheduleLevel(shrinkFactor: 1, smoothingSigma: 0)
            ],
            convergenceStatus: .failed,
            iterationCount: 0,
            finalMetricValue: nil,
            transform: try rigidTransform()
        )
        #expect(result.convergenceStatus == .failed)
        #expect(result.finalMetricValue == nil)
    }

    @Test("[Unit][VOX-REG-002] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: RegistrationResultError.invalidShrinkFactor) {
            _ = try RegistrationScheduleLevel(shrinkFactor: 0, smoothingSigma: 1)
        }
        #expect(throws: RegistrationResultError.invalidSmoothingSigma) {
            _ = try RegistrationScheduleLevel(shrinkFactor: 1, smoothingSigma: -1)
        }
        #expect(throws: RegistrationResultError.invalidSmoothingSigma) {
            _ = try RegistrationScheduleLevel(shrinkFactor: 1, smoothingSigma: .nan)
        }
        let metric = try #require(RegistrationMetricID(rawValue: "m"))
        let optimiser = try #require(RegistrationOptimiserID(rawValue: "o"))
        #expect(throws: RegistrationResultError.emptySchedule) {
            _ = try RegistrationResult(
                fixedIdentity: try identity("fixed-ct"),
                movingIdentity: try identity("moving-ct"),
                metric: metric,
                metricVersion: nil,
                optimiser: optimiser,
                optimiserVersion: nil,
                schedule: [],
                convergenceStatus: .converged,
                iterationCount: 1,
                finalMetricValue: nil,
                transform: try rigidTransform()
            )
        }
        #expect(throws: RegistrationResultError.invalidIterationCount) {
            _ = try RegistrationResult(
                fixedIdentity: try identity("fixed-ct"),
                movingIdentity: try identity("moving-ct"),
                metric: metric,
                metricVersion: nil,
                optimiser: optimiser,
                optimiserVersion: nil,
                schedule: [
                    try RegistrationScheduleLevel(shrinkFactor: 1, smoothingSigma: 0)
                ],
                convergenceStatus: .converged,
                iterationCount: -1,
                finalMetricValue: nil,
                transform: try rigidTransform()
            )
        }
        #expect(throws: RegistrationResultError.invalidFinalMetricValue) {
            _ = try RegistrationResult(
                fixedIdentity: try identity("fixed-ct"),
                movingIdentity: try identity("moving-ct"),
                metric: metric,
                metricVersion: nil,
                optimiser: optimiser,
                optimiserVersion: nil,
                schedule: [
                    try RegistrationScheduleLevel(shrinkFactor: 1, smoothingSigma: 0)
                ],
                convergenceStatus: .converged,
                iterationCount: 1,
                finalMetricValue: .infinity,
                transform: try rigidTransform()
            )
        }
        #expect(RegistrationMetricID(rawValue: "   ") == nil)
        #expect(RegistrationOptimiserID(rawValue: "") == nil)
    }
}
