// SPDX-License-Identifier: MIT

import Testing
import VoxeliaTestSupport

@testable import VoxeliaExecution

@Test("[Unit] VoxeliaExecution M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaExecutionModuleMarker.name == "VoxeliaExecution")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
