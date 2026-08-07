// SPDX-License-Identifier: MIT

// The umbrella genuinely re-exports its eight stable general-purpose
// modules, per `ADR-0406` (`VOX-REP-007`): `import Voxelia` is the
// one-line stable surface. The optional integrations (CPU and Metal
// backends, compression, DICOM, photorealistic rendering, validation)
// are not dependencies of this target, so their non-re-export is
// structural, not a convention.
@_exported import VoxeliaCore
@_exported import VoxeliaExecution
@_exported import VoxeliaGeometry
@_exported import VoxeliaImaging
@_exported import VoxeliaInteraction
@_exported import VoxeliaRendering
@_exported import VoxeliaSpatial
@_exported import VoxeliaStorage

/// Internal marker confirming that the Voxelia target has been linked.
package enum _VoxeliaModuleMarker {
    package static let name = "Voxelia"
}
