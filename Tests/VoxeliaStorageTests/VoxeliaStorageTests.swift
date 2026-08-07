// SPDX-License-Identifier: MIT

import Testing
import VoxeliaTestSupport

@testable import VoxeliaStorage

@Test("[Unit] VoxeliaStorage M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaStorageModuleMarker.name == "VoxeliaStorage")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
