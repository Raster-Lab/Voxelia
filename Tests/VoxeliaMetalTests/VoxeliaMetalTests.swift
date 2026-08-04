// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaTestSupport

@testable import VoxeliaMetal

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

    #expect(manifest.contains(#"schema_version: "0.2""#))
    #expect(manifest.contains(#"family: "window-level""#))
    #expect(
        manifest.contains(
            "302cd86e30ac67c064b9ce20833bb61585a46d636de3e952c3e95cc3504f7cbd"
        )
    )
}
