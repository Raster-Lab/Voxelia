// SPDX-License-Identifier: MIT

/// The closed failure family for surface visibility resolution.
///
/// Cases carry no payload so diagnostics disclose no coordinates, depths,
/// counts or scene contents.
///
/// There is deliberately no unsupported-projection case: this stage never sees
/// a camera, and `VOXELIA-ALG-0033` already rejected an unsupported projection
/// before any vertex was projected.
enum SurfaceVisibilityError: Error, Sendable, Equatable {
    /// The checked visibility buffer exceeds the accepted caller ceiling.
    case resourceLimitExceeded

    /// A required ordered binary64 intermediate was NaN or infinite.
    case coverageNotRepresentable

    /// Cancellation won the operation's fixed failure precedence.
    case cancelled
}

/// Internal cancellation sites frozen by `ADR-0200` and `ALG-0034`.
///
/// The facet ordinal is per layer, so a scene of many small layers polls at
/// least once per layer while a single large layer still polls every sixty-four
/// facets. Neither shape can starve cancellation.
enum SurfaceVisibilityCheckpoint: Sendable, Equatable {
    case admission
    case facet(layer: UInt64, ordinal: UInt64)
}

typealias SurfaceVisibilityProbe =
    @Sendable (SurfaceVisibilityCheckpoint) -> Bool

/// Required host ceilings for one visibility resolution.
///
/// Unlike ``SurfaceVertexProjector``, this stage owns payload that scales with
/// the viewport rather than with a mesh the caller already holds, so it
/// declares its own ceiling. `ViewportSize` alone admits 16,384 by 16,384,
/// which is far more buffer than a caller may intend to allocate.
struct SurfaceVisibilityLimits: Sendable {
    /// The exact logical bytes one hit record occupies: one depth, three
    /// weights, one layer index and one facet ordinal.
    static let hitRecordByteCount: UInt64 = 48

    /// The inclusive maximum operation-controlled additional logical bytes.
    let maximumAdditionalLogicalByteCount: UInt64

    init(maximumAdditionalLogicalByteCount: UInt64) {
        self.maximumAdditionalLogicalByteCount =
            maximumAdditionalLogicalByteCount
    }
}

/// One facet's three projected vertices, in mesh topology order.
struct ProjectedFacet: Sendable {
    let first: ProjectedVertex
    let second: ProjectedVertex
    let third: ProjectedVertex

    init(
        _ first: ProjectedVertex,
        _ second: ProjectedVertex,
        _ third: ProjectedVertex
    ) {
        self.first = first
        self.second = second
        self.third = third
    }
}

/// The nearest facet at one pixel, with its barycentric weights.
///
/// The weights correspond to the **canonicalised** vertex order: when a facet
/// projected with negative area, its second and third vertices were swapped,
/// so `weightB` belongs to the original third vertex. A consumer that ignored
/// the swap would mis-attribute vertex attributes.
struct SurfaceHit: Sendable, Equatable {
    let depth: Double
    let weightA: Double
    let weightB: Double
    let weightC: Double
    let layerIndex: Int
    let facetOrdinal: Int

    /// Whether the coverage rule exchanged the facet's second and third
    /// vertices, so a consumer can map each weight to its original vertex.
    let swapped: Bool
}

/// One resolved visibility buffer in row-major order.
struct SurfaceVisibilityBuffer: Sendable {
    let width: Int
    let height: Int
    let hits: ContiguousArray<SurfaceHit?>

    /// The nearest facet at one pixel, or `nil` when nothing covered it.
    func hit(column: Int, row: Int) -> SurfaceHit? {
        hits[row * width + column]
    }

    /// The number of covered pixels.
    var coveredCount: Int {
        hits.reduce(into: 0) { total, hit in
            if hit != nil { total += 1 }
        }
    }
}

/// The exact `surface-visibility-resolution/binary64-v1` reference.
///
/// This stateless internal resolver consumes projected vertices and decides,
/// for every pixel, which facet of which layer is nearest. It produces no
/// colour and no image.
enum SurfaceVisibilityResolver {
    /// Resolves the nearest facet at every pixel.
    static func resolve(
        layers: [[ProjectedFacet]],
        viewport: ViewportSize,
        limits: SurfaceVisibilityLimits,
        cancellation: SurfaceVisibilityProbe
    ) throws -> SurfaceVisibilityBuffer {
        if cancellation(.admission) {
            throw SurfaceVisibilityError.cancelled
        }
        let pixelCount = try checkedBufferByteCount(
            width: viewport.width,
            height: viewport.height,
            maximumAdditionalLogicalByteCount:
                limits.maximumAdditionalLogicalByteCount
        )
        var hits = ContiguousArray<SurfaceHit?>(
            repeating: nil,
            count: pixelCount
        )

        for (layerIndex, facets) in layers.enumerated() {
            for (facetOrdinal, facet) in facets.enumerated() {
                let ordinal = UInt64(facetOrdinal)
                if ordinal.isMultiple(of: 64),
                    cancellation(
                        .facet(layer: UInt64(layerIndex), ordinal: ordinal)
                    )
                {
                    throw SurfaceVisibilityError.cancelled
                }
                try rasterise(
                    facet,
                    layerIndex: layerIndex,
                    facetOrdinal: facetOrdinal,
                    viewport: viewport,
                    into: &hits
                )
            }
        }
        return SurfaceVisibilityBuffer(
            width: viewport.width,
            height: viewport.height,
            hits: hits
        )
    }

    /// Performs the exact checked `width * height * 48` admission.
    ///
    /// - Returns: The pixel count, once the byte product is admitted.
    static func checkedBufferByteCount(
        width: Int,
        height: Int,
        maximumAdditionalLogicalByteCount: UInt64
    ) throws -> Int {
        guard
            let widthCount = UInt64(exactly: width),
            let heightCount = UInt64(exactly: height)
        else {
            throw SurfaceVisibilityError.resourceLimitExceeded
        }
        let pixels = widthCount.multipliedReportingOverflow(by: heightCount)
        guard !pixels.overflow else {
            throw SurfaceVisibilityError.resourceLimitExceeded
        }
        let bytes = pixels.partialValue.multipliedReportingOverflow(
            by: SurfaceVisibilityLimits.hitRecordByteCount
        )
        guard
            !bytes.overflow,
            bytes.partialValue <= maximumAdditionalLogicalByteCount,
            let pixelCount = Int(exactly: pixels.partialValue)
        else {
            throw SurfaceVisibilityError.resourceLimitExceeded
        }
        return pixelCount
    }

    /// Rasterises one facet, keeping only strictly nearer hits.
    ///
    /// Coverage comes from the shared ``SurfaceCoverage`` enumeration, so this
    /// resolver and the fragment collector cannot drift apart on the sample
    /// rule, orientation canonicalisation, fill rule or interpolation.
    private static func rasterise(
        _ facet: ProjectedFacet,
        layerIndex: Int,
        facetOrdinal: Int,
        viewport: ViewportSize,
        into hits: inout ContiguousArray<SurfaceHit?>
    ) throws {
        try SurfaceCoverage.enumerateCoveredSamples(
            facet,
            viewport: viewport
        ) { sample in
            let offset = sample.row * viewport.width + sample.column
            // A candidate replaces the incumbent ONLY when strictly nearer,
            // so an exactly equal depth keeps the earlier (layer, facet).
            // This single comparison is the whole tie-break: there is no
            // separate branch to get wrong.
            if let incumbent = hits[offset], !(sample.depth < incumbent.depth) {
                return
            }
            hits[offset] = SurfaceHit(
                depth: sample.depth,
                weightA: sample.weightA,
                weightB: sample.weightB,
                weightC: sample.weightC,
                layerIndex: layerIndex,
                facetOrdinal: facetOrdinal,
                swapped: sample.swapped
            )
        }
    }
}
