// SPDX-License-Identifier: MIT

import Testing
import VoxeliaTestSupport

@testable import VoxeliaRendering

@Test("[Unit] VoxeliaRendering M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaRenderingModuleMarker.name == "VoxeliaRendering")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
