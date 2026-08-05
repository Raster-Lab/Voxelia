// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial

/// The one shared implementation of the registered `VOXELIA-ALG-0008`
/// revision 1.1 rescale rules, reused by every resampling operation
/// per the shared-authority precedent — two copies of one registered
/// rule could drift silently.
enum ResampleRescale {
    /// Rebuilds per-axis sampling under the frozen rule: a regular
    /// axis `(origin, spacing)` becomes
    /// `(origin + (h * spacing), scale * spacing)` with
    /// `h = ((0.5 * scale) - 0.5)`.
    static func rescaledAxes(
        of descriptor: ImageDescriptor,
        scales: [Double]
    ) throws -> ContiguousArray<AxisDescriptor> {
        var outputAxes = ContiguousArray<AxisDescriptor>()
        for (axisIndex, axis) in descriptor.axes.enumerated() {
            switch axis.sampling {
            case .regular(let origin, let spacing):
                let scale = scales[axisIndex]
                let shift = ((0.5 * scale) - 0.5)
                outputAxes.append(
                    try AxisDescriptor(
                        id: axis.id,
                        name: axis.name,
                        semantic: axis.semantic,
                        unit: axis.unit,
                        sampling: .regular(
                            origin: origin + (shift * spacing),
                            spacing: scale * spacing
                        )
                    )
                )
            default:
                outputAxes.append(axis)
            }
        }
        return outputAxes
    }

    /// Rebuilds an affine geometry under the frozen two-pass rule:
    /// translations accumulate over the original columns in ascending
    /// slot order, then spatial columns scale.
    static func rescaledGeometry(
        of descriptor: ImageDescriptor,
        scales: [Double]
    ) throws -> SpatialGeometry? {
        guard case .affine(let affine)? = descriptor.spatialGeometry else {
            return descriptor.spatialGeometry
        }
        var elements = affine.indexToWorld.elements
        for (slot, imageAxis) in affine.spatialAxes.imageAxes.enumerated() {
            let shift = ((0.5 * scales[imageAxis]) - 0.5)
            for row in 0..<3 {
                elements[4 * row + 3] =
                    elements[4 * row + 3] + (elements[4 * row + slot] * shift)
            }
        }
        for (slot, imageAxis) in affine.spatialAxes.imageAxes.enumerated() {
            for row in 0..<3 {
                elements[4 * row + slot] =
                    elements[4 * row + slot] * scales[imageAxis]
            }
        }
        return .affine(
            try AffineGridGeometry(
                spatialAxes: affine.spatialAxes,
                indexToWorld: try Matrix4x4Double(elements: elements),
                coordinateSpace: affine.coordinateSpace
            )
        )
    }
}
