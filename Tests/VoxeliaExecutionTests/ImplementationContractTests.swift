// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaExecution

@Suite("ImplementationContract")
struct ImplementationContractTests {
    private func quality() throws -> ExecutionClaimToken {
        try ExecutionClaimToken(rawValue: "org.voxelia.quality.full")
    }

    @Test("[Unit][VOX-EXT-003] a full declaration admits and reads back")
    func aFullDeclarationAdmitsAndReadsBack() throws {
        let contract = try DeclaredImplementationContract(
            domain: .image(
                ranks: .range(2...3),
                scalars: .scalars([.uint8, .float32]),
                geometry: .requiresAffine
            ),
            qualityProfiles: [try quality()],
            capabilityRequirements: [
                try ExecutionClaimToken(rawValue: "com.example.capability.simd")
            ]
        )
        guard
            case .image(let ranks, let scalars, let geometry) = contract.domain
        else {
            Issue.record("the image domain was lost")
            return
        }
        #expect(ranks == .range(2...3))
        #expect(scalars == .scalars([.uint8, .float32]))
        #expect(geometry == .requiresAffine)
        #expect(contract.qualityProfiles.count == 1)
        #expect(contract.capabilityRequirements.count == 1)

        // The mesh domain declares no image envelope at all.
        let mesh = try DeclaredImplementationContract(
            domain: .triangleMesh,
            qualityProfiles: [try quality()],
            capabilityRequirements: []
        )
        #expect(mesh.domain == .triangleMesh)
    }

    @Test("[Unit][VOX-EXT-003] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: ImplementationContractError.invalidRankRange) {
            _ = try DeclaredImplementationContract(
                domain: .image(ranks: .range(0...3), scalars: .any, geometry: .any),
                qualityProfiles: [try quality()],
                capabilityRequirements: []
            )
        }
        #expect(throws: ImplementationContractError.invalidScalarSupport) {
            _ = try DeclaredImplementationContract(
                domain: .image(ranks: .any, scalars: .scalars([]), geometry: .any),
                qualityProfiles: [try quality()],
                capabilityRequirements: []
            )
        }
        #expect(throws: ImplementationContractError.invalidScalarSupport) {
            _ = try DeclaredImplementationContract(
                domain: .image(
                    ranks: .any,
                    scalars: .scalars([.uint8, .uint8]),
                    geometry: .any
                ),
                qualityProfiles: [try quality()],
                capabilityRequirements: []
            )
        }
        #expect(throws: ImplementationContractError.invalidQualityProfiles) {
            _ = try DeclaredImplementationContract(
                domain: .triangleMesh,
                qualityProfiles: [],
                capabilityRequirements: []
            )
        }
        #expect(throws: ImplementationContractError.duplicateCapabilityRequirement) {
            _ = try DeclaredImplementationContract(
                domain: .triangleMesh,
                qualityProfiles: [try quality()],
                capabilityRequirements: [try quality(), try quality()]
            )
        }
    }
}
