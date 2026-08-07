// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaExecution

@Suite("CapabilityNegotiation")
struct CapabilityNegotiationTests {
    @Test("[Unit][VOX-EXT-008] negotiation is explicit and refuses missing capabilities")
    func negotiationIsExplicitAndRefusesMissingCapabilities() throws {
        let simd = try ExecutionClaimToken(rawValue: "com.example.capability.simd")
        let gpu = try ExecutionClaimToken(rawValue: "com.example.capability.gpu")

        // The satisfied intersection admits, including the empty
        // requirement (requiring nothing is a legitimate declaration).
        try CapabilityNegotiation.negotiate(required: [], offered: [])
        try CapabilityNegotiation.negotiate(required: [simd], offered: [simd, gpu])

        // A missing token refuses typed — nothing negotiates
        // implicitly, and nothing downgrades silently.
        #expect(throws: CapabilityNegotiationError.missingCapability) {
            try CapabilityNegotiation.negotiate(required: [simd, gpu], offered: [simd])
        }
    }
}
