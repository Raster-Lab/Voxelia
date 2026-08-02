// SPDX-License-Identifier: MIT

import Testing
@testable import VoxeliaCore
import VoxeliaTestSupport

@Test("VoxeliaCore M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaCoreModuleMarker.name == "VoxeliaCore")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
