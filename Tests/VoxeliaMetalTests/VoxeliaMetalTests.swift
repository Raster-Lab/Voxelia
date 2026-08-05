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
    #expect(manifest.contains(#"semantic_version: "1.1.0""#))
    #expect(manifest.contains(#""voxelia_window_level_i16""#))
    #expect(manifest.contains(#""voxelia_window_level_u16""#))
    #expect(
        manifest.contains(
            "e97eb8c7ac120b9d592827be29c3bf127256784328e9ee53139b01d9111a5197"
        )
    )
    #expect(manifest.contains(#"family: "composite-layers""#))
    #expect(manifest.contains(#""voxelia_composite_layers""#))
    #expect(
        manifest.contains(
            "6ed663f6d20d71091c5c704e11e1f7dc7c8cda955253c89770c782cecfd1f1c7"
        )
    )
    #expect(manifest.contains(#"family: "invert-display""#))
    #expect(manifest.contains(#""voxelia_invert_display_u8""#))
    #expect(
        manifest.contains(
            "eeb2126fe4c6e66801c5444a33a0f371520c2528c5d5a807e7bfe95ccc9652c5"
        )
    )
}
