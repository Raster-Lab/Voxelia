// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by implementation registration.
///
/// Cases deliberately carry no payload; the registry states what
/// exists and rejects what collides.
public enum RegistrationError: Error, Sendable, Equatable {
    case duplicateImplementation
    case invalidEvidenceIdentifier
}

/// An error raised by declaration-contract admission, per `ADR-0380`.
public enum ImplementationContractError: Error, Sendable, Equatable {
    /// A rank range's lower bound was below one.
    case invalidRankRange
    /// A scalar list was empty or repeated a scalar type.
    case invalidScalarSupport
    /// The quality-profile list was empty or repeated a token.
    case invalidQualityProfiles
    /// The capability-requirement list repeated a token.
    case duplicateCapabilityRequirement
}

/// Declared rank support: an honest `any`, or a validated range.
public enum DeclaredRankSupport: Sendable, Hashable {
    case any
    case range(ClosedRange<Int>)
}

/// Declared scalar-format support: an honest `any`, or a non-empty
/// unique list.
public enum DeclaredScalarSupport: Sendable, Hashable {
    case any
    case scalars(ContiguousArray<ScalarType>)
}

/// Declared geometry support: an honest `any`, or a calibrated-affine
/// requirement.
public enum DeclaredGeometrySupport: Sendable, Hashable {
    case any
    case requiresAffine
}

/// The declared sample domain: image envelopes, or the mesh domain —
/// forcing mesh operations to fake image envelopes would be exactly
/// the kind of lie the registry exists to prevent.
public enum DeclaredSampleDomain: Sendable, Hashable {
    case image(
        ranks: DeclaredRankSupport,
        scalars: DeclaredScalarSupport,
        geometry: DeclaredGeometrySupport
    )
    case triangleMesh
}

/// The `VOX-EXT-003` envelope declaration, per `ADR-0380`: required on
/// every registration, defaultless. The declaration is selection
/// metadata — the operation's own typed admission stays authoritative,
/// so a declaration cannot admit anything the operation would refuse.
public struct DeclaredImplementationContract: Sendable, Hashable {
    public let domain: DeclaredSampleDomain
    /// The quality profiles the implementation may serve; non-empty.
    public let qualityProfiles: ContiguousArray<ExecutionClaimToken>
    /// Required host capabilities; may be empty, never repeated.
    public let capabilityRequirements: ContiguousArray<ExecutionClaimToken>

    /// Creates a validated contract.
    ///
    /// - Throws: ``ImplementationContractError``.
    public init(
        domain: DeclaredSampleDomain,
        qualityProfiles: ContiguousArray<ExecutionClaimToken>,
        capabilityRequirements: ContiguousArray<ExecutionClaimToken>
    ) throws {
        if case .image(let ranks, let scalars, _) = domain {
            if case .range(let range) = ranks {
                guard range.lowerBound >= 1 else {
                    throw ImplementationContractError.invalidRankRange
                }
            }
            if case .scalars(let list) = scalars {
                guard !list.isEmpty, Set(list).count == list.count else {
                    throw ImplementationContractError.invalidScalarSupport
                }
            }
        }
        guard
            !qualityProfiles.isEmpty,
            Set(qualityProfiles).count == qualityProfiles.count
        else {
            throw ImplementationContractError.invalidQualityProfiles
        }
        guard Set(capabilityRequirements).count == capabilityRequirements.count
        else {
            throw ImplementationContractError.duplicateCapabilityRequirement
        }
        self.domain = domain
        self.qualityProfiles = qualityProfiles
        self.capabilityRequirements = capabilityRequirements
    }
}

/// One registered implementation per `ADR-0134`.
///
/// Registration is data, not dispatch: the value names an operation
/// contract, an implementation, its backend and precision claims, and
/// the recorded evidence identifier — execution stays with the typed
/// operation surfaces, and planners may consult registrations through
/// their own decisions.
public struct RegisteredImplementation: Sendable, Hashable {
    public let operationID: DerivationOperationToken
    public let operationVersion: SemanticVersion
    public let implementation: DerivationImplementationReference
    public let backend: ExecutionClaimToken
    public let precisionPolicy: ExecutionClaimToken
    public let approximationStatus: ExecutionApproximationStatus
    public let evidence: ValidationEvidenceID
    /// The `ADR-0380` envelope declaration; required, defaultless.
    public let declaredContract: DeclaredImplementationContract

    public init(
        operationID: DerivationOperationToken,
        operationVersion: SemanticVersion,
        implementation: DerivationImplementationReference,
        backend: ExecutionClaimToken,
        precisionPolicy: ExecutionClaimToken,
        approximationStatus: ExecutionApproximationStatus,
        evidence: ValidationEvidenceID,
        declaredContract: DeclaredImplementationContract
    ) {
        self.operationID = operationID
        self.operationVersion = operationVersion
        self.implementation = implementation
        self.backend = backend
        self.precisionPolicy = precisionPolicy
        self.approximationStatus = approximationStatus
        self.evidence = evidence
        self.declaredContract = declaredContract
    }
}

/// The backend-neutral implementation registry per `ADR-0134`.
///
/// Every backend registers into one vocabulary; the pairs of
/// operation token and implementation identifier are unique, and
/// lookup preserves registration order.
public struct ImplementationRegistry: Sendable {
    public let implementations: [RegisteredImplementation]

    /// Creates a validated registry.
    ///
    /// - Throws: ``RegistrationError/duplicateImplementation``.
    public init(implementations: [RegisteredImplementation]) throws {
        var seen = Set<String>()
        for entry in implementations {
            let key =
                entry.operationID.rawValue + "\u{0}"
                + entry.implementation.identifier.rawValue
            guard seen.insert(key).inserted else {
                throw RegistrationError.duplicateImplementation
            }
        }
        self.implementations = implementations
    }

    /// Returns every registration for one operation, in registration
    /// order.
    public func implementations(
        for operationID: DerivationOperationToken
    ) -> [RegisteredImplementation] {
        implementations.filter { $0.operationID == operationID }
    }
}
