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

    public init(
        operationID: DerivationOperationToken,
        operationVersion: SemanticVersion,
        implementation: DerivationImplementationReference,
        backend: ExecutionClaimToken,
        precisionPolicy: ExecutionClaimToken,
        approximationStatus: ExecutionApproximationStatus,
        evidence: ValidationEvidenceID
    ) {
        self.operationID = operationID
        self.operationVersion = operationVersion
        self.implementation = implementation
        self.backend = backend
        self.precisionPolicy = precisionPolicy
        self.approximationStatus = approximationStatus
        self.evidence = evidence
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
