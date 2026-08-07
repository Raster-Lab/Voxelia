// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaTestSupport

@testable import VoxeliaMetal

/// Appends one exact little-endian 16-bit fixture without exposing memory
/// layout or pointer-backed storage to the test target.
func appendLittleEndianUInt16(_ value: UInt16, to bytes: inout [UInt8]) {
    bytes.append(UInt8(truncatingIfNeeded: value))
    bytes.append(UInt8(truncatingIfNeeded: value >> 8))
}

@Test("[Unit][VOX-VAL-007][VOX-PLT-011] sixteen-bit fixtures serialize explicitly")
func sixteenBitFixturesSerializeExplicitly() {
    var bytes = [UInt8]()
    for value: UInt16 in [0x0000, 0x0001, 0x1234, 0xFFFF] {
        appendLittleEndianUInt16(value, to: &bytes)
    }

    #expect(bytes == [0x00, 0x00, 0x01, 0x00, 0x34, 0x12, 0xFF, 0xFF])
}

@Test("[Unit] VoxeliaMetal M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaMetalModuleMarker.name == "VoxeliaMetal")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}

@Test("[Unit] VoxeliaMetal shader manifest is accessible from its target bundle")
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
    #expect(manifest.contains(#"semantic_version: "1.2.0""#))
    #expect(manifest.contains(#""voxelia_window_level_i16""#))
    #expect(manifest.contains(#""voxelia_window_level_u16""#))
    #expect(
        manifest.contains(
            "4aa39856054ed2f22b2f5de891c7a640c423288eec1415a2ba5f1120626beff4"
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
