// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import VoxeliaMetal

@Suite("ResidencyPolicy")
struct ResidencyPolicyTests {
    @Test("[Unit][MTA-18.2] exposes the exact residency vocabulary")
    func exposesExactVocabulary() {
        let policies: [ResidencyPolicy] = [
            .automatic,
            .cpuOnly,
            .shared,
            .gpuOptimised,
            .streamed,
            .sparse,
        ]

        #expect(
            policies.map(testDiscriminator) == [
                "automatic",
                "cpuOnly",
                "shared",
                "gpuOptimised",
                "streamed",
                "sparse",
            ]
        )
    }

    @Test("[Unit][MTA-18.2] Codable round trips every policy")
    func codableRoundTripsEveryPolicy() throws {
        let policies: [ResidencyPolicy] = [
            .automatic,
            .cpuOnly,
            .shared,
            .gpuOptimised,
            .streamed,
            .sparse,
        ]

        for policy in policies {
            let data = try JSONEncoder().encode(policy)
            let decoded = try JSONDecoder().decode(
                ResidencyPolicy.self,
                from: data
            )
            #expect(testDiscriminator(decoded) == testDiscriminator(policy))
        }
    }

    @Test("[Unit][MTA-18.2] Codable rejects non-policy values")
    func codableRejectsMalformedValues() {
        let malformed = [
            Data("null".utf8),
            Data("1".utf8),
        ]

        for data in malformed {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(ResidencyPolicy.self, from: data)
            }
        }
    }

    @Test("[Unit][MTA-18.2] residency policies are Sendable")
    func policiesAreSendable() {
        requireSendable(ResidencyPolicy.automatic)
        requireSendable(ResidencyPolicy.sparse)
    }

    private func testDiscriminator(_ policy: ResidencyPolicy) -> String {
        switch policy {
        case .automatic: "automatic"
        case .cpuOnly: "cpuOnly"
        case .shared: "shared"
        case .gpuOptimised: "gpuOptimised"
        case .streamed: "streamed"
        case .sparse: "sparse"
        }
    }

    private func requireSendable<Value: Sendable>(_: Value) {}
}
