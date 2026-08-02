// SPDX-License-Identifier: MIT

import Testing
@testable import VoxeliaInteraction
import VoxeliaTestSupport

@Test("VoxeliaInteraction M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaInteractionModuleMarker.name == "VoxeliaInteraction")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
