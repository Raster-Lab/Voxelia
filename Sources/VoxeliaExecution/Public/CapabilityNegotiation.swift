// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by capability negotiation.
public enum CapabilityNegotiationError: Error, Sendable, Equatable {
    /// A required capability was not offered.
    case missingCapability
}

/// The one explicit negotiation seam of `VOX-EXT-008`, per `ADR-0403`:
/// a requirer's declared capability tokens intersect an offerer's, and
/// any missing token refuses typed. Nothing negotiates implicitly —
/// this is the vocabulary the `ADR-0380` contract and the `ADR-0402`
/// worker admission already speak, and any future runtime plug-in
/// boundary routes through the same seam.
public enum CapabilityNegotiation {
    /// Requires every capability in `required` to be present in
    /// `offered`.
    ///
    /// - Throws: ``CapabilityNegotiationError/missingCapability``.
    public static func negotiate(
        required: Set<ExecutionClaimToken>,
        offered: Set<ExecutionClaimToken>
    ) throws {
        guard required.isSubset(of: offered) else {
            throw CapabilityNegotiationError.missingCapability
        }
    }
}
