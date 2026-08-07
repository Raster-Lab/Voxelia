// SPDX-License-Identifier: MIT

import Testing
@testable import VoxeliaSpatial
import VoxeliaTestSupport

@Test("[Unit] VoxeliaSpatial M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaSpatialModuleMarker.name == "VoxeliaSpatial")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
