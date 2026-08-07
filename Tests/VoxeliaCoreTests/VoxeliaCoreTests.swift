// SPDX-License-Identifier: MIT

import Testing
import VoxeliaTestSupport

@testable import VoxeliaCore

@Test("[Unit] VoxeliaCore M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaCoreModuleMarker.name == "VoxeliaCore")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
