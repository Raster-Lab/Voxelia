// SPDX-License-Identifier: MIT

import Testing
@testable import VoxeliaMetal
import VoxeliaTestSupport

@Test("VoxeliaMetal M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaMetalModuleMarker.name == "VoxeliaMetal")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
