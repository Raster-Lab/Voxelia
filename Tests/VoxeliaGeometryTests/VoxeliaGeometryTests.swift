// SPDX-License-Identifier: MIT

import Testing
@testable import VoxeliaGeometry
import VoxeliaTestSupport

@Test("[Unit] VoxeliaGeometry M0 target is linked")
func targetIsLinked() {
    #expect(_VoxeliaGeometryModuleMarker.name == "VoxeliaGeometry")
    #expect(VoxeliaTestSupport.scaffoldRequirement == "VOX-REP-001")
}
