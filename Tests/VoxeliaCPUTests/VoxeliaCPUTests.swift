// SPDX-License-Identifier: MIT

import Testing
@testable import VoxeliaCPU
import VoxeliaTestSupport

@Test("[Unit] VoxeliaCPU M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaCPUModuleMarker.name == "VoxeliaCPU")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
