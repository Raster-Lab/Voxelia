// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

@testable import VoxeliaCPU

@Suite("CPUBackendRegistrations")
struct CPUBackendRegistrationsTests {
    @Test("[Unit][VOX-ARC-010][VOX-ERR-001] the standard registry names every implementation")
    func standardRegistryNamesEveryImplementation() throws {
        // Every CPU implementation registers with tokens structurally
        // equal to the operations' own constants, the pinned current
        // contract versions, and the CPU backend claim.
        let registry = try CPUBackendRegistrations.standard()
        #expect(registry.implementations.count == 29)
        #expect(
            registry.implementations.allSatisfy {
                $0.backend.rawValue == "org.voxelia.backend.cpu"
            }
        )
        let windowEntries = registry.implementations(
            for: try DerivationOperationToken(
                rawValue: WindowLevelOperation.operationIdentifier
            )
        )
        #expect(windowEntries.count == 1)
        #expect(
            windowEntries[0].operationVersion
                == (try SemanticVersion(major: 1, minor: 5, patch: 0))
        )
        #expect(
            windowEntries[0].implementation.identifier.rawValue
                == WindowLevelOperation.implementationIdentifier
        )
        #expect(
            windowEntries[0].precisionPolicy.rawValue
                == "org.voxelia.precision.binary64-strict"
        )
        let operationTokens = Set(registry.implementations.map(\.operationID.rawValue))
        let expectedTokens: Set<String> = [
            RegionExtractionOperation.operationIdentifier,
            WindowLevelOperation.operationIdentifier,
            ResampleNearestOperation.operationIdentifier,
            CompositeLayersOperation.operationIdentifier,
            InvertDisplayOperation.operationIdentifier,
            TransposeAxesOperation.operationIdentifier,
            SqueezeAxesOperation.operationIdentifier,
            ResampleLinearOperation.operationIdentifier,
            ObliqueSliceOperation.operationIdentifier,
            GridResampleOperation.operationIdentifier,
            LevelSelectOperation.operationIdentifier,
            ThresholdOperation.operationIdentifier,
            MaskApplyOperation.operationIdentifier,
            ArithmeticOperation.operationIdentifier,
            ConvolveOperation.operationIdentifier,
            GaussianFilterOperation.operationIdentifier,
            MorphologyOperation.operationIdentifier,
            ConnectedComponentsOperation.operationIdentifier,
            DistanceTransformOperation.operationIdentifier,
            LabelResampleOperation.operationIdentifier,
            RegionGrowOperation.operationIdentifier,
            MaskEditOperation.operationIdentifier,
            ProjectIntensityOperation.operationIdentifier,
            ResampleCubicOperation.operationIdentifier,
            ScalarSurfaceExtractionRequest.operationIdentifier,
            LabelledSurfaceExtractionRequest.operationIdentifier,
            TriangleMeshVertexNormalGenerationRequest.operationIdentifier,
            TriangleMeshTotalFacetAreaRequest.operationIdentifier,
            TriangleMeshEnclosedVolumeRequest.operationIdentifier,
        ]
        #expect(operationTokens == expectedTokens)
        let surfaceEntries = registry.implementations(
            for: try DerivationOperationToken(
                rawValue: ScalarSurfaceExtractionRequest.operationIdentifier
            )
        )
        #expect(surfaceEntries.count == 1)
        let surfaceEntry = surfaceEntries[0]
        #expect(
            surfaceEntry.implementation.identifier.rawValue
                == CPUScalarSurfaceExtractionOperation.implementationIdentifier
        )
        let expectedSurfaceVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0
        )
        #expect(
            surfaceEntry.operationVersion == expectedSurfaceVersion
        )
        #expect(surfaceEntry.operationVersion.prerelease == nil)
        #expect(surfaceEntry.operationVersion.buildMetadata == nil)
        #expect(surfaceEntry.implementation.version == expectedSurfaceVersion)
        #expect(surfaceEntry.implementation.version.prerelease == nil)
        #expect(surfaceEntry.implementation.version.buildMetadata == nil)
        #expect(
            surfaceEntry.precisionPolicy.rawValue
                == "org.voxelia.precision.binary64-strict"
        )
        #expect(surfaceEntry.approximationStatus == .exact)
        #expect(
            surfaceEntry.evidence.rawValue
                == "adr-0191-scalar-surface-extraction"
        )
        let labelledSurfaceEntries = registry.implementations(
            for: try DerivationOperationToken(
                rawValue: LabelledSurfaceExtractionRequest.operationIdentifier
            )
        )
        #expect(labelledSurfaceEntries.count == 1)
        let labelledSurfaceEntry = labelledSurfaceEntries[0]
        #expect(
            labelledSurfaceEntry.implementation.identifier.rawValue
                == CPULabelledSurfaceExtractionOperation
                .implementationIdentifier
        )
        let expectedLabelledSurfaceVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0
        )
        #expect(
            labelledSurfaceEntry.operationVersion
                == expectedLabelledSurfaceVersion
        )
        #expect(labelledSurfaceEntry.operationVersion.prerelease == nil)
        #expect(labelledSurfaceEntry.operationVersion.buildMetadata == nil)
        #expect(
            labelledSurfaceEntry.implementation.version
                == expectedLabelledSurfaceVersion
        )
        #expect(labelledSurfaceEntry.implementation.version.prerelease == nil)
        #expect(
            labelledSurfaceEntry.implementation.version.buildMetadata == nil
        )
        #expect(
            labelledSurfaceEntry.precisionPolicy.rawValue
                == "org.voxelia.precision.binary64-strict"
        )
        #expect(labelledSurfaceEntry.approximationStatus == .exact)
        #expect(
            labelledSurfaceEntry.evidence.rawValue
                == "adr-0192-labelled-surface-extraction"
        )
        let normalEntries = registry.implementations(
            for: try DerivationOperationToken(
                rawValue: TriangleMeshVertexNormalGenerationRequest
                    .operationIdentifier
            )
        )
        #expect(normalEntries.count == 1)
        let normalEntry = normalEntries[0]
        #expect(
            normalEntry.implementation.identifier.rawValue
                == CPUTriangleMeshVertexNormalGenerationOperation
                .implementationIdentifier
        )
        let expectedNormalVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0
        )
        #expect(normalEntry.operationVersion == expectedNormalVersion)
        #expect(normalEntry.operationVersion.prerelease == nil)
        #expect(normalEntry.operationVersion.buildMetadata == nil)
        #expect(normalEntry.implementation.version == expectedNormalVersion)
        #expect(normalEntry.implementation.version.prerelease == nil)
        #expect(normalEntry.implementation.version.buildMetadata == nil)
        #expect(
            normalEntry.precisionPolicy.rawValue
                == "org.voxelia.precision.binary64-strict"
        )
        #expect(normalEntry.approximationStatus == .exact)
        #expect(
            normalEntry.evidence.rawValue
                == "adr-0193-triangle-mesh-vertex-normals"
        )

        let areaEntries = registry.implementations(
            for: try DerivationOperationToken(
                rawValue: TriangleMeshTotalFacetAreaRequest
                    .operationIdentifier
            )
        )
        #expect(areaEntries.count == 1)
        let areaEntry = areaEntries[0]
        #expect(
            areaEntry.implementation.identifier.rawValue
                == CPUTriangleMeshTotalFacetAreaOperation
                .implementationIdentifier
        )
        let expectedAreaVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0
        )
        #expect(areaEntry.operationVersion == expectedAreaVersion)
        #expect(areaEntry.operationVersion.prerelease == nil)
        #expect(areaEntry.operationVersion.buildMetadata == nil)
        #expect(areaEntry.implementation.version == expectedAreaVersion)
        #expect(areaEntry.implementation.version.prerelease == nil)
        #expect(areaEntry.implementation.version.buildMetadata == nil)
        #expect(
            areaEntry.precisionPolicy.rawValue
                == "org.voxelia.precision.binary64-strict"
        )
        #expect(areaEntry.approximationStatus == .exact)
        #expect(
            areaEntry.evidence.rawValue
                == "adr-0194-triangle-mesh-total-facet-area"
        )

        let volumeEntries = registry.implementations(
            for: try DerivationOperationToken(
                rawValue: TriangleMeshEnclosedVolumeRequest
                    .operationIdentifier
            )
        )
        #expect(volumeEntries.count == 1)
        let volumeEntry = volumeEntries[0]
        #expect(
            volumeEntry.implementation.identifier.rawValue
                == CPUTriangleMeshEnclosedVolumeOperation
                .implementationIdentifier
        )
        let expectedVolumeVersion = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0
        )
        #expect(volumeEntry.operationVersion == expectedVolumeVersion)
        #expect(volumeEntry.operationVersion.prerelease == nil)
        #expect(volumeEntry.operationVersion.buildMetadata == nil)
        #expect(volumeEntry.implementation.version == expectedVolumeVersion)
        #expect(volumeEntry.implementation.version.prerelease == nil)
        #expect(volumeEntry.implementation.version.buildMetadata == nil)
        #expect(
            volumeEntry.precisionPolicy.rawValue
                == "org.voxelia.precision.binary64-strict"
        )
        #expect(volumeEntry.approximationStatus == .exact)
        #expect(
            volumeEntry.evidence.rawValue
                == "adr-0195-triangle-mesh-enclosed-volume"
        )

        // Duplicate registration rejects typed.
        do {
            _ = try ImplementationRegistry(
                implementations: [
                    registry.implementations[0], registry.implementations[0],
                ]
            )
            #expect(Bool(false), "Expected a duplicate registration to be rejected.")
        } catch RegistrationError.duplicateImplementation {}

        requireSendable(ImplementationRegistry.self)
        requireSendable(RegisteredImplementation.self)
        requireSendable(RegistrationError.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
