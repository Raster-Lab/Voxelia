// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaSpatial

/// An error raised by volume ray-sampler admission.
///
/// Cases deliberately carry no payload; the zero-length direction is
/// rejected by the composed `Ray3D` primitive's own typed admission,
/// and a foreign-space ray surfaces the world-to-index map's own
/// case.
public enum VolumeRaySamplingError: Error, Sendable, Equatable {
    case invalidVolumeExtents
    case unsupportedVolumeMapping
    case unsupportedQualityPolicy
}

/// One ray's sample plan per `ADR-0169` (`VOX-DVR-002/003`).
///
/// The plan carries the entry and exit world distances, the derived
/// interval, the midpoint sample count and the index-space ray; the
/// miss is the empty plan — a declared outcome, never an error.
/// Everything this plan feeds is presentation, never a source of
/// authoritative quantitative measurement, per the arc's binding
/// rule.
public struct VolumeRaySamplePlan: Sendable, Hashable {
    /// The clamped entry distance along the world ray.
    public let entryDistance: Double

    /// The exit distance along the world ray.
    public let exitDistance: Double

    /// The derived sampling interval in world distance.
    public let interval: Double

    /// The midpoint sample count.
    public let sampleCount: Int

    /// The index-space ray origin in image-axis order.
    public let indexOrigin: ContiguousArray<Double>

    /// The index-space ray direction in image-axis order.
    public let indexDirection: ContiguousArray<Double>

    /// The frozen midpoint distance `entry + (k + 0.5) * interval`.
    public func sampleDistance(at index: Int) -> Double {
        entryDistance + (Double(index) + 0.5) * interval
    }

    /// The frozen index-space position `origin[c] + (t * direction[c])`
    /// at one midpoint sample.
    public func indexPosition(at index: Int) -> ContiguousArray<Double> {
        let distance = sampleDistance(at: index)
        var position = ContiguousArray<Double>()
        position.reserveCapacity(indexOrigin.count)
        for component in indexOrigin.indices {
            position.append(
                indexOrigin[component]
                    + (distance * indexDirection[component])
            )
        }
        return position
    }
}

/// The volume ray sampler per `ADR-0169`, realising the frozen
/// `VOXELIA-ALG-0022` model.
///
/// The ray normalises by the accepted norm form so its parameter is
/// world distance, maps to index space through the accepted inverse
/// composition, and intersects the pixel-centre support through the
/// `VOXELIA-ALG-0001` slab rule restated over index space — the
/// accepted specification is the authority for the rule; labelling
/// index coordinates with the world space token would misreport
/// them. The interval derives from the minimum column norm and the
/// declared quality table — never a fixed normalised constant.
public struct VolumeRaySampler: Sendable {
    /// The declared version-one quality table's one registered token.
    public static let fullQualityToken = "org.voxelia.quality.full"

    private let map: AffineWorldToIndexMap
    private let extents: ContiguousArray<Int>
    private let interval: Double

    /// Builds a sampler for one calibrated volume at one quality.
    ///
    /// - Throws: ``VolumeRaySamplingError``, or the audited typed
    ///   errors of the spatial contracts.
    public init(
        geometry: AffineGridGeometry,
        extents: ContiguousArray<Int>,
        quality: String
    ) throws {
        guard extents.count == 3, extents.allSatisfy({ $0 >= 1 }) else {
            throw VolumeRaySamplingError.invalidVolumeExtents
        }
        guard Set(geometry.spatialAxes.imageAxes) == Set([0, 1, 2]) else {
            throw VolumeRaySamplingError.unsupportedVolumeMapping
        }
        guard quality == Self.fullQualityToken else {
            throw VolumeRaySamplingError.unsupportedQualityPolicy
        }
        let m = geometry.indexToWorld.elements
        var minimumSpacing = Double.infinity
        for column in 0...2 {
            let x = m[column]
            let y = m[4 + column]
            let z = m[8 + column]
            let norm = (((x * x) + (y * y)) + (z * z)).squareRoot()
            minimumSpacing = min(minimumSpacing, norm)
        }
        self.map = try AffineWorldToIndexMap(geometry: geometry)
        self.extents = extents
        self.interval = 0.5 * minimumSpacing
    }

    /// Plans one ray's midpoint samples.
    ///
    /// - Throws: The world-to-index map's typed errors for a
    ///   foreign-space ray.
    public func plan(for ray: Ray3D) throws -> VolumeRaySamplePlan {
        // The accepted norm form makes the parameter world distance;
        // the composed Ray3D admission guarantees a non-zero
        // direction.
        let dx = ray.direction.x
        let dy = ray.direction.y
        let dz = ray.direction.z
        let norm = (((dx * dx) + (dy * dy)) + (dz * dz)).squareRoot()
        let unit = [dx / norm, dy / norm, dz / norm]

        // The accepted inverse composition: the origin as a point,
        // the direction through the inverse without the translation.
        let originSlots = try map.continuousSlotIndices(of: ray.origin)
        var indexOrigin = ContiguousArray<Double>(repeating: 0, count: 3)
        var indexDirection = ContiguousArray<Double>(repeating: 0, count: 3)
        for (slot, axis) in map.spatialAxes.imageAxes.enumerated() {
            indexOrigin[axis] = originSlots[slot]
            var component = 0.0
            for row in 0...2 {
                component =
                    component
                    + (map.inverse.elements[3 * slot + row] * unit[row])
            }
            indexDirection[axis] = component
        }

        // The ALG-0001 slab rule restated over the pixel-centre
        // support; the entry starts at zero, so the inside-camera
        // clamp is structural.
        var entry = 0.0
        var exit = Double.infinity
        for axis in 0...2 {
            let lower = -0.5
            let upper = Double(extents[axis]) - 0.5
            let origin = indexOrigin[axis]
            let direction = indexDirection[axis]
            if direction == 0 {
                guard origin >= lower, origin <= upper else {
                    return Self.emptyPlan(
                        interval: interval,
                        indexOrigin: indexOrigin,
                        indexDirection: indexDirection
                    )
                }
                continue
            }
            var near = (lower - origin) / direction
            var far = (upper - origin) / direction
            if near > far {
                swap(&near, &far)
            }
            entry = max(entry, near)
            exit = min(exit, far)
        }
        guard exit > entry else {
            return Self.emptyPlan(
                interval: interval,
                indexOrigin: indexOrigin,
                indexDirection: indexDirection
            )
        }
        let count = Int(((exit - entry) / interval).rounded(.down))
        return VolumeRaySamplePlan(
            entryDistance: entry,
            exitDistance: exit,
            interval: interval,
            sampleCount: count,
            indexOrigin: indexOrigin,
            indexDirection: indexDirection
        )
    }

    /// The declared miss outcome: the empty plan.
    private static func emptyPlan(
        interval: Double,
        indexOrigin: ContiguousArray<Double>,
        indexDirection: ContiguousArray<Double>
    ) -> VolumeRaySamplePlan {
        VolumeRaySamplePlan(
            entryDistance: 0,
            exitDistance: 0,
            interval: interval,
            sampleCount: 0,
            indexOrigin: indexOrigin,
            indexDirection: indexDirection
        )
    }
}
