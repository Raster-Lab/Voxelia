// SPDX-License-Identifier: MIT

import Testing
@testable import VoxeliaStorage
import VoxeliaTestSupport

@Test("VoxeliaStorage M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaStorageModuleMarker.name == "VoxeliaStorage")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
