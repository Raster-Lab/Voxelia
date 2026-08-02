// SPDX-License-Identifier: MIT

import Testing
@testable import VoxeliaImaging
import VoxeliaTestSupport

@Test("VoxeliaImaging M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaImagingModuleMarker.name == "VoxeliaImaging")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
