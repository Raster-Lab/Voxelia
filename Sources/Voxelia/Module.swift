// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry
import VoxeliaImaging
import VoxeliaInteraction
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

/// Internal marker confirming that the Voxelia target has been linked.
///
/// M0 deliberately avoids speculative public scientific APIs.
package enum _VoxeliaModuleMarker {
    package static let name = "Voxelia"
}
