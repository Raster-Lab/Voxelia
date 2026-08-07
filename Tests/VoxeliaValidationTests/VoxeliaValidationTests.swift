// SPDX-License-Identifier: MIT

import Testing
import VoxeliaTestSupport

@testable import VoxeliaValidation

@Test("[Unit] VoxeliaValidation M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaValidationModuleMarker.name == "VoxeliaValidation")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
