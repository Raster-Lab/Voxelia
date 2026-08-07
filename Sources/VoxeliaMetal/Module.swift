// SPDX-License-Identifier: MIT

import Metal
import VoxeliaExecution
import VoxeliaRendering

/// Internal marker confirming that the VoxeliaMetal target has been linked.
///
/// M0 deliberately avoids speculative public scientific APIs.
package enum _VoxeliaMetalModuleMarker {
    package static let name = "VoxeliaMetal"
}
