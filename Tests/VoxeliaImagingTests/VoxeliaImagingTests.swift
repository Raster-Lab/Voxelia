// SPDX-License-Identifier: MIT

import Testing
import VoxeliaTestSupport

@testable import VoxeliaImaging

@Test("[Unit] VoxeliaImaging M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaImagingModuleMarker.name == "VoxeliaImaging")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
