// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import VoxeliaMetal
import VoxeliaTestSupport

@Test("VoxeliaMetal M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaMetalModuleMarker.name == "VoxeliaMetal")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}

@Test("VoxeliaMetal shader manifest is accessible from its target bundle")
func shaderManifestIsBundled() throws {
    let url = try #require(
        Bundle.module.url(
            forResource: "ShaderManifest",
            withExtension: "yaml"
        )
    )
    let manifest = String(
        decoding: try Data(contentsOf: url),
        as: UTF8.self
    )

    #expect(manifest.contains(#"schema_version: "0.1""#))
    #expect(manifest.contains("shader_families: []"))
}
