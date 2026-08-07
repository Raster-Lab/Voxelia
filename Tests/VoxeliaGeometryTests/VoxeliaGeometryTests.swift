// SPDX-License-Identifier: MIT

import Testing
import VoxeliaTestSupport

@testable import VoxeliaGeometry

@Test("[Unit] VoxeliaGeometry M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaGeometryModuleMarker.name == "VoxeliaGeometry")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
