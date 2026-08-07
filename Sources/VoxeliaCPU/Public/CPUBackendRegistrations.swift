// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

/// The CPU backend registrations per `ADR-0134` (`VOX-ARC-010`) — the
/// first substantive `VoxeliaCPU` API.
///
/// The standard registry names every CPU implementation with its live
/// operation token taken from the operation's own public constant —
/// token drift is structurally impossible — its current contract
/// version, its claimed precision and status, and the evidence
/// identifier naming the accepting decision record.
public enum CPUBackendRegistrations {
    /// The registered CPU backend token spelling.
    public static let backendIdentifier = "org.voxelia.backend.cpu"

    private static func evidenceID(_ raw: String) throws -> ValidationEvidenceID {
        guard let identifier = ValidationEvidenceID(rawValue: raw) else {
            throw RegistrationError.invalidEvidenceIdentifier
        }
        return identifier
    }

    /// Builds the standard registry of every CPU implementation.
    ///
    /// - Throws: The audited typed errors of the claim and registry
    ///   contracts.
    public static func standard() throws -> ImplementationRegistry {
        let backend = try ExecutionClaimToken(rawValue: Self.backendIdentifier)
        let binary64 = try ExecutionClaimToken(
            rawValue: "org.voxelia.precision.binary64-strict"
        )
        let exact = try ExecutionClaimToken(rawValue: "org.voxelia.precision.exact")
        func entry(
            operation: String,
            implementation: String,
            major: Int,
            minor: Int,
            precision: ExecutionClaimToken,
            evidence: String
        ) throws -> RegisteredImplementation {
            let version = try SemanticVersion(major: major, minor: minor, patch: 0)
            return RegisteredImplementation(
                operationID: try DerivationOperationToken(rawValue: operation),
                operationVersion: version,
                implementation: DerivationImplementationReference(
                    identifier: try DerivationOperationToken(
                        rawValue: implementation
                    ),
                    version: version
                ),
                backend: backend,
                precisionPolicy: precision,
                approximationStatus: .exact,
                evidence: try Self.evidenceID(evidence)
            )
        }
        return try ImplementationRegistry(implementations: [
            try entry(
                operation: RegionExtractionOperation.operationIdentifier,
                implementation: RegionExtractionOperation.implementationIdentifier,
                major: 1,
                minor: 2,
                precision: exact,
                evidence: "adr-0064-region-extraction"
            ),
            try entry(
                operation: WindowLevelOperation.operationIdentifier,
                implementation: WindowLevelOperation.implementationIdentifier,
                major: 1,
                minor: 5,
                precision: binary64,
                evidence: "adr-0065-window-level"
            ),
            try entry(
                operation: ResampleNearestOperation.operationIdentifier,
                implementation: ResampleNearestOperation.implementationIdentifier,
                major: 1,
                minor: 1,
                precision: binary64,
                evidence: "adr-0088-resample-nearest"
            ),
            try entry(
                operation: CompositeLayersOperation.operationIdentifier,
                implementation: CompositeLayersOperation.implementationIdentifier,
                major: 1,
                minor: 2,
                precision: binary64,
                evidence: "adr-0090-composite-layers"
            ),
            try entry(
                operation: InvertDisplayOperation.operationIdentifier,
                implementation: InvertDisplayOperation.implementationIdentifier,
                major: 1,
                minor: 0,
                precision: exact,
                evidence: "adr-0112-invert-display"
            ),
            try entry(
                operation: TransposeAxesOperation.operationIdentifier,
                implementation: TransposeAxesOperation.implementationIdentifier,
                major: 1,
                minor: 0,
                precision: exact,
                evidence: "adr-0115-transpose-axes"
            ),
            try entry(
                operation: SqueezeAxesOperation.operationIdentifier,
                implementation: SqueezeAxesOperation.implementationIdentifier,
                major: 1,
                minor: 0,
                precision: exact,
                evidence: "adr-0116-squeeze-axes"
            ),
            try entry(
                operation: ResampleLinearOperation.operationIdentifier,
                implementation: ResampleLinearOperation.implementationIdentifier,
                major: 1,
                minor: 1,
                precision: binary64,
                evidence: "adr-0123-resample-linear"
            ),
            try entry(
                operation: ObliqueSliceOperation.operationIdentifier,
                implementation: ObliqueSliceOperation.implementationIdentifier,
                major: 1,
                minor: 0,
                precision: binary64,
                evidence: "adr-0142-oblique-slice"
            ),
            try entry(
                operation: GridResampleOperation.operationIdentifier,
                implementation: GridResampleOperation.implementationIdentifier,
                major: 1,
                minor: 0,
                precision: binary64,
                evidence: "adr-0340-grid-resample"
            ),
            try entry(
                operation: LevelSelectOperation.operationIdentifier,
                implementation: LevelSelectOperation.implementationIdentifier,
                major: 1,
                minor: 0,
                precision: exact,
                evidence: "adr-0343-level-select"
            ),
            try entry(
                operation: ThresholdOperation.operationIdentifier,
                implementation: ThresholdOperation.implementationIdentifier,
                major: 1,
                minor: 0,
                precision: binary64,
                evidence: "adr-0352-threshold"
            ),
            try entry(
                operation: ProjectIntensityOperation.operationIdentifier,
                implementation: ProjectIntensityOperation.implementationIdentifier,
                major: 1,
                minor: 0,
                precision: exact,
                evidence: "adr-0160-project-intensity"
            ),
            try entry(
                operation: ResampleCubicOperation.operationIdentifier,
                implementation: ResampleCubicOperation.implementationIdentifier,
                major: 1,
                minor: 0,
                precision: binary64,
                evidence: "adr-0164-resample-cubic"
            ),
            try entry(
                operation: ScalarSurfaceExtractionRequest.operationIdentifier,
                implementation:
                    CPUScalarSurfaceExtractionOperation.implementationIdentifier,
                major: 1,
                minor: 0,
                precision: binary64,
                evidence: "adr-0191-scalar-surface-extraction"
            ),
            try entry(
                operation: LabelledSurfaceExtractionRequest.operationIdentifier,
                implementation:
                    CPULabelledSurfaceExtractionOperation.implementationIdentifier,
                major: 1,
                minor: 0,
                precision: binary64,
                evidence: "adr-0192-labelled-surface-extraction"
            ),
            try entry(
                operation:
                    TriangleMeshVertexNormalGenerationRequest
                    .operationIdentifier,
                implementation:
                    CPUTriangleMeshVertexNormalGenerationOperation
                    .implementationIdentifier,
                major: 1,
                minor: 0,
                precision: binary64,
                evidence: "adr-0193-triangle-mesh-vertex-normals"
            ),
            try entry(
                operation:
                    TriangleMeshTotalFacetAreaRequest.operationIdentifier,
                implementation:
                    CPUTriangleMeshTotalFacetAreaOperation
                    .implementationIdentifier,
                major: 1,
                minor: 0,
                precision: binary64,
                evidence: "adr-0194-triangle-mesh-total-facet-area"
            ),
            try entry(
                operation:
                    TriangleMeshEnclosedVolumeRequest.operationIdentifier,
                implementation:
                    CPUTriangleMeshEnclosedVolumeOperation
                    .implementationIdentifier,
                major: 1,
                minor: 0,
                precision: binary64,
                evidence: "adr-0195-triangle-mesh-enclosed-volume"
            ),
        ])
    }
}
