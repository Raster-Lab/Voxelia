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

    @Test("[Unit][MTA-18.2][VOX-ERR-001] Codable rejects non-policy values")
    func codableRejectsMalformedValues() {
        do {
            _ = try JSONDecoder().decode(ResidencyPolicy.self, from: Data("null".utf8))
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // The keyed-container request rejects null.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        do {
            _ = try JSONDecoder().decode(ResidencyPolicy.self, from: Data("1".utf8))
            #expect(Bool(false), "Expected a number to fail decoding.")
        } catch DecodingError.typeMismatch {
            // The keyed-container request rejects the non-object shape.
        } catch {
            #expect(Bool(false), "Expected typeMismatch, received \(error).")
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
