// SPDX-License-Identifier: MIT

import Testing
@testable import VoxeliaRendering
import VoxeliaTestSupport

@Test("VoxeliaRendering M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaRenderingModuleMarker.name == "VoxeliaRendering")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
