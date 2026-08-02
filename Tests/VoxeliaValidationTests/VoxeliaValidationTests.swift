// SPDX-License-Identifier: MIT

import Testing
@testable import VoxeliaValidation
import VoxeliaTestSupport

@Test("VoxeliaValidation M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaValidationModuleMarker.name == "VoxeliaValidation")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
