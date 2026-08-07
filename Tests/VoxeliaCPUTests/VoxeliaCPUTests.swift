// SPDX-License-Identifier: MIT

import Testing
import VoxeliaTestSupport

@testable import VoxeliaCPU

@Test("[Unit] VoxeliaCPU M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaCPUModuleMarker.name == "VoxeliaCPU")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
