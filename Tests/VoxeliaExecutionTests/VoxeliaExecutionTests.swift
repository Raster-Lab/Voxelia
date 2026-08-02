// SPDX-License-Identifier: MIT

import Testing
@testable import VoxeliaExecution
import VoxeliaTestSupport

@Test("VoxeliaExecution M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaExecutionModuleMarker.name == "VoxeliaExecution")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
