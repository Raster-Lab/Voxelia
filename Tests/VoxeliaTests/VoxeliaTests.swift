// SPDX-License-Identifier: MIT

import Testing
@testable import Voxelia
import VoxeliaTestSupport

@Test("[Unit] Voxelia M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaModuleMarker.name == "Voxelia")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
