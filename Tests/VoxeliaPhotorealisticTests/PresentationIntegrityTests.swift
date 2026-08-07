// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaPhotorealistic

@Suite("MaterialSeparation")
struct MaterialSeparationTests {
    private func tagged(
        _ material: Int, _ r: Double, _ g: Double, _ b: Double, _ a: Double
    ) throws -> MaterialRaySample {
        MaterialRaySample(
            material: material,
            sample: try RaySample(
                emissionRed: r,
                emissionGreen: g,
                emissionBlue: b,
                opacity: a
            )
        )
    }

    @Test("[Unit][VOX-PRR-009] the shared walk partitions radiance exactly")
    func theSharedWalkPartitionsRadianceExactly() throws {
        let result = try MaterialSeparatedIntegrator.integrate(
            samples: [
                try tagged(0, 1, 0.5, 0.25, 0.5),
                try tagged(1, 0.5, 1, 0, 0.5),
                try tagged(0, 0.25, 0.25, 1, 0.5),
            ],
            materialCount: 2
        )
        #expect(result.opacity == 0.875)
        #expect(result.materials[0].red == 0.53125)
        #expect(result.materials[0].green == 0.28125)
        #expect(result.materials[0].blue == 0.25)
        #expect(result.materials[1].red == 0.125)
        #expect(result.materials[1].green == 0.25)
        #expect(result.materials[1].blue == 0)
    }

    @Test("[Unit][VOX-PRR-009] an opaque foreign material still occludes")
    func anOpaqueForeignMaterialStillOccludes() throws {
        // Separation changes where radiance is recorded, never how
        // light travels.
        let result = try MaterialSeparatedIntegrator.integrate(
            samples: [
                try tagged(1, 0.5, 0.5, 0.5, 1),
                try tagged(0, 9, 9, 9, 1),
            ],
            materialCount: 2
        )
        #expect(result.materials[0].red == 0)
        #expect(result.materials[1].red == 0.5)
        #expect(result.opacity == 1)
    }

    @Test("[Unit][VOX-PRR-009] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: MaterialSeparationError.invalidMaterialCount) {
            _ = try MaterialSeparatedIntegrator.integrate(
                samples: [],
                materialCount: 0
            )
        }
        #expect(throws: MaterialSeparationError.materialIndexOutOfRange) {
            _ = try MaterialSeparatedIntegrator.integrate(
                samples: [try tagged(2, 1, 1, 1, 0.5)],
                materialCount: 2
            )
        }
    }
}

@Suite("PostProcessDeclaration")
struct PostProcessDeclarationTests {
    private func processor() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Example Denoise Ltd",
            version: try SemanticVersion(major: 3, minor: 1, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    @Test("[Unit][VOX-PRR-013][VOX-PRR-014] every step is declared or unrepresentable")
    func everyStepIsDeclaredOrUnrepresentable() throws {
        let denoise = try PostProcessDeclaration(
            kind: .denoising,
            processor: try processor(),
            methodIdentifier: "org.example.method.bilateral"
        )
        #expect(denoise.processor.name == "Example Denoise Ltd")
        #expect(denoise.processor.version.major == 3)

        // The untouched output declares nothing and claims nothing.
        let untouched = PhotorealisticOutputRecord(postProcessing: [])
        #expect(!untouched.declaresGenerativeReconstruction)

        // Generative reconstruction exists only as an explicit
        // declared step; the host's acceptance policy reads it.
        let generative = PhotorealisticOutputRecord(postProcessing: [
            try PostProcessDeclaration(
                kind: .generativeReconstruction,
                processor: try processor(),
                methodIdentifier: "org.example.method.diffusion-upsample"
            )
        ])
        #expect(generative.declaresGenerativeReconstruction)

        #expect(throws: PostProcessDeclarationError.emptyMethodIdentifier) {
            _ = try PostProcessDeclaration(
                kind: .denoising,
                processor: try processor(),
                methodIdentifier: "   "
            )
        }
    }
}

@Suite("SideBySide")
struct SideBySideTests {
    @Test("[Unit][VOX-PRR-015] both panes bind to one scene state by construction")
    func bothPanesBindToOneSceneStateByConstruction() throws {
        let state = SceneStateFingerprint(
            sceneIdentity: "scene-1",
            cameraIdentity: "camera-1",
            transferFunctionIdentity: "tf-1",
            sourceDataIdentity: "data-1"
        )
        let comparison = SideBySideComparison(
            sceneState: state,
            leftPane: .conventional,
            rightPane: .photorealistic(.reference)
        )
        // One fingerprint, two panes: divergent inputs are not
        // expressible through any initialiser.
        #expect(comparison.sceneState == state)
        #expect(comparison.leftPane == .conventional)
        #expect(comparison.rightPane == .photorealistic(.reference))
    }
}
