// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCPU
import VoxeliaCore
import VoxeliaExecution
import VoxeliaMetal
import VoxeliaSpatial

@testable import VoxeliaValidation

@Suite("RegistrationReference")
struct RegistrationReferenceTests {
    private func space(_ id: String) throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func points(
        _ coordinates: [(Double, Double, Double)],
        space: String
    ) throws -> ContiguousArray<Point3D> {
        var out = ContiguousArray<Point3D>()
        for (x, y, z) in coordinates {
            out.append(
                try Point3D(
                    x: x,
                    y: y,
                    z: z,
                    coordinateSpace: try #require(CoordinateSpaceID(rawValue: space))
                )
            )
        }
        return out
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
                    identifier: "1.2.840.113619.31",
                    version: nil,
                    contentID: nil
                )
            ],
            derivation: nil
        )
    }

    @Test("[Integration][VOX-REG-010] the reference chain runs end to end on CPU")
    func theReferenceChainRunsEndToEndOnCPU() throws {
        // Landmark rigid: subject -> atlas, the exact permutation
        // motion with translation (1, 2, 3).
        let rigid = try LandmarkRigidRegistration.register(
            moving: try points(
                [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 2)],
                space: "subject"
            ),
            fixed: try points(
                [(1, 2, 3), (1, 3, 3), (1, 2, 4), (3, 2, 3)],
                space: "atlas"
            ),
            sourceSpace: try space("subject"),
            destinationSpace: try space("atlas")
        )
        guard case .rigid(let motion) = rigid.category else {
            Issue.record("the rigid reference did not stay rigid")
            return
        }
        #expect(motion.translation == [1, 2, 3])

        // Landmark affine: atlas -> template, the exact scaling.
        let affine = try LandmarkAffineRegistration.register(
            moving: try points(
                [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 1, 1)],
                space: "atlas"
            ),
            fixed: try points(
                [(1, 2, 3), (3, 2, 3), (1, 5, 3), (1, 2, 7), (3, 5, 7)],
                space: "template"
            ),
            sourceSpace: try space("atlas"),
            destinationSpace: try space("template")
        )

        // Composition validates the seam and spans the chain.
        let chained = try RegistrationTransformComposition.compose(
            affine,
            after: rigid
        )
        #expect(chained.sourceSpace.id.rawValue == "subject")
        #expect(chained.destinationSpace.id.rawValue == "template")

        // A result record classifies as success and hands out the
        // transform only through the outcome seam.
        let result = try RegistrationResult(
            fixedIdentity: try identity("fixed-ct"),
            movingIdentity: try identity("moving-ct"),
            metric: try #require(
                RegistrationMetricID(rawValue: "org.voxelia.metric.mean-squares")
            ),
            metricVersion: "1.0.0",
            optimiser: try #require(
                RegistrationOptimiserID(rawValue: "org.voxelia.optimiser.landmark")
            ),
            optimiserVersion: nil,
            schedule: [
                try RegistrationScheduleLevel(shrinkFactor: 1, smoothingSigma: 0)
            ],
            convergenceStatus: .converged,
            iterationCount: 1,
            finalMetricValue: 0,
            transform: chained
        )
        let outcome = RegistrationOutcome.classify(result)
        #expect(outcome.successfulTransform != nil)

        // Residual quality over the fitting landmarks: the estimated
        // quaternion carries its pinned one-ulp rounding, so the
        // residuals are the frozen chain's exact bits, not zero — the
        // reference is deterministic, not romantic.
        let quality = try RegistrationQuality.evaluate(
            transform: rigid,
            moving: try points(
                [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 2)],
                space: "subject"
            ),
            fixed: try points(
                [(1, 2, 3), (1, 3, 3), (1, 2, 4), (3, 2, 3)],
                space: "atlas"
            )
        )
        #expect(quality.rootMeanSquare == 0x1.2548eb9151e85p-52)
        #expect(quality.maximum == 0x1.1e3779b97f4a8p-51)
    }

    @Test("[Unit][VOX-REG-010] no Metal-backend entry names a registration operation")
    func noMetalBackendEntryNamesARegistrationOperation() throws {
        // The tripwire for the row's ordering constraint: the day a
        // Metal registration implementation registers, this fails until
        // the reference-first ordering is re-confirmed by the owner.
        let metal = try MetalBackendRegistrations.standard()
        for implementation in metal.implementations {
            let operation = implementation.operationID.rawValue
            #expect(!operation.contains("registration"))
            #expect(!operation.contains("landmark"))
        }
    }
}
