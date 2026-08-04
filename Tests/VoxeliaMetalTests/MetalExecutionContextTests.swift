// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaMetal

@Suite("MetalExecutionContext")
struct MetalExecutionContextTests {
    @Test("[Unit][VOX-PLT-014][VOX-EXE-003] the context acquires by capability only")
    func contextAcquiresByCapabilityOnly() throws {
        // Real host evidence per ADR-0079: acquisition must succeed on
        // a supported Apple-silicon development host, and an
        // environment without a device fails loudly rather than
        // skipping silently.
        let context = try MetalExecutionContext()

        // The detected capability is the closed Metal 3 token and
        // parses as the accepted execution-claim capability class, so
        // GPU claims plug into the existing provenance discipline.
        #expect(
            context.capabilityClass
                == (try ExecutionClaimToken(
                    rawValue: "org.voxelia.capability.metal3"
                ))
        )
        let claim = ExecutionProvenanceClaim(
            profile: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.profile.default"
                ),
                version: try SemanticVersion(major: 1, minor: 0, patch: 0)
            ),
            backend: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.backend.metal"
                ),
                version: try SemanticVersion(major: 1, minor: 0, patch: 0)
            ),
            precisionPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.precision.binary32-device"
            ),
            qualityPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.quality.full"
            ),
            approximationStatus: .approximate,
            capabilityClass: context.capabilityClass,
            kernel: nil
        )
        #expect(claim.capabilityClass == context.capabilityClass)

        // Apple silicon shares one memory space; the registry
        // identifier is opaque evidence, not a name.
        #expect(context.supportsUnifiedMemory)
        #expect(context.deviceRegistryIdentifier != 0)

        requireSendable(MetalExecutionContext.self)
        requireSendable(MetalContextError.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
