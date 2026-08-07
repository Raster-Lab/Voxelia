// SPDX-License-Identifier: MIT

import Testing
import VoxeliaTestSupport

@testable import VoxeliaInteraction

@Test("[Unit] VoxeliaInteraction M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaInteractionModuleMarker.name == "VoxeliaInteraction")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
