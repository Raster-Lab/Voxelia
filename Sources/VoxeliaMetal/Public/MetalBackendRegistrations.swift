// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution

/// The metal backend registrations per `ADR-0135`.
///
/// Each backend registers its own implementations in its own module;
/// the device entries carry their honest split versions — the
/// contract each implements and the implementation's own version —
/// so the registry states, in one queryable vocabulary, exactly the
/// contract gaps the decision records narrate.
public enum MetalBackendRegistrations {
    /// The registered metal backend token spelling.
    public static let backendIdentifier = "org.voxelia.backend.metal"

    /// Builds the standard registry of the three device
    /// implementations.
    ///
    /// - Throws: The audited typed errors of the claim and registry
    ///   contracts.
    public static func standard() throws -> ImplementationRegistry {
        let backend = try ExecutionClaimToken(rawValue: Self.backendIdentifier)
        let binary32 = try ExecutionClaimToken(
            rawValue: "org.voxelia.precision.binary32-device"
        )
        let exact = try ExecutionClaimToken(rawValue: "org.voxelia.precision.exact")
        func entry(
            operation: String,
            implementation: String,
            contract: (Int, Int),
            implementationVersion: (Int, Int),
            precision: ExecutionClaimToken,
            status: ExecutionApproximationStatus,
            evidence: String
        ) throws -> RegisteredImplementation {
            guard let evidenceID = ValidationEvidenceID(rawValue: evidence) else {
                throw RegistrationError.invalidEvidenceIdentifier
            }
            return RegisteredImplementation(
                operationID: try DerivationOperationToken(rawValue: operation),
                operationVersion: try SemanticVersion(
                    major: contract.0,
                    minor: contract.1,
                    patch: 0
                ),
                implementation: DerivationImplementationReference(
                    identifier: try DerivationOperationToken(
                        rawValue: implementation
                    ),
                    version: try SemanticVersion(
                        major: implementationVersion.0,
                        minor: implementationVersion.1,
                        patch: 0
                    )
                ),
                backend: backend,
                precisionPolicy: precision,
                approximationStatus: status,
                evidence: evidenceID
            )
        }
        return try ImplementationRegistry(implementations: [
            try entry(
                operation: WindowLevelOperation.operationIdentifier,
                implementation: MetalWindowLevelOperation.implementationIdentifier,
                contract: (1, 5),
                implementationVersion: (1, 2),
                precision: binary32,
                status: .approximate,
                evidence: "adr-0146-padded-device-window"
            ),
            try entry(
                operation: CompositeLayersOperation.operationIdentifier,
                implementation: MetalCompositeLayersOperation.implementationIdentifier,
                contract: (1, 2),
                implementationVersion: (1, 1),
                precision: binary32,
                status: .approximate,
                evidence: "adr-0131-device-composite"
            ),
            try entry(
                operation: InvertDisplayOperation.operationIdentifier,
                implementation: MetalInvertDisplayOperation.implementationIdentifier,
                contract: (1, 0),
                implementationVersion: (1, 0),
                precision: exact,
                status: .exact,
                evidence: "adr-0133-device-invert"
            ),
        ])
    }
}
