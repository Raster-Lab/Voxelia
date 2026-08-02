// SPDX-License-Identifier: MIT

import VoxeliaSpatial
import VoxeliaCore
import VoxeliaStorage
import VoxeliaExecution
import VoxeliaImaging
import VoxeliaGeometry
import VoxeliaRendering
import VoxeliaInteraction

/// Internal marker confirming that the Voxelia target has been linked.
///
/// M0 deliberately avoids speculative public scientific APIs.
package enum _VoxeliaModuleMarker {
    package static let name = "Voxelia"
}
