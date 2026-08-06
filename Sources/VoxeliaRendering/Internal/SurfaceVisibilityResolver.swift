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
    private static func rasterise(
        _ facet: ProjectedFacet,
        layerIndex: Int,
        facetOrdinal: Int,
        viewport: ViewportSize,
        into hits: inout ContiguousArray<SurfaceHit?>
    ) throws {
        guard let oriented = try canonicalise(facet) else {
            // A facet projecting to exactly zero area covers nothing. It is
            // not an error: `ADR-0198` admits the singular placement that
            // produces one, and an edge-on facet is ordinary.
            return
        }
        let first = oriented.facet.first
        let second = oriented.facet.second
        let third = oriented.facet.third

        guard
            let columns = pixelRange(
                low: min(min(first.column, second.column), third.column),
                high: max(max(first.column, second.column), third.column),
                limit: viewport.width
            ),
            let rows = pixelRange(
                low: min(min(first.row, second.row), third.row),
                high: max(max(first.row, second.row), third.row),
                limit: viewport.height
            )
        else {
            return
        }

        let claimsFirst = isTopLeft(second, third)
        let claimsSecond = isTopLeft(third, first)
        let claimsThird = isTopLeft(first, second)

        for rowIndex in rows {
            for columnIndex in columns {
                let sampleColumn = try checkedAdd(Double(columnIndex), 0.5)
                let sampleRow = try checkedAdd(Double(rowIndex), 0.5)
                let edgeFirst = try edge(
                    second,
                    third,
                    column: sampleColumn,
                    row: sampleRow
                )
                let edgeSecond = try edge(
                    third,
                    first,
                    column: sampleColumn,
                    row: sampleRow
                )
                let edgeThird = try edge(
                    first,
                    second,
                    column: sampleColumn,
                    row: sampleRow
                )
                guard
                    covers(edgeFirst, claims: claimsFirst),
                    covers(edgeSecond, claims: claimsSecond),
                    covers(edgeThird, claims: claimsThird)
                else {
                    continue
                }

                let weightA = try checkedDivide(edgeFirst, oriented.area)
                let weightB = try checkedDivide(edgeSecond, oriented.area)
                let weightC = try checkedDivide(edgeThird, oriented.area)
                let depth = try checkedAdd(
                    try checkedAdd(
                        try checkedMultiply(weightA, first.depth),
                        try checkedMultiply(weightB, second.depth)
                    ),
                    try checkedMultiply(weightC, third.depth)
                )

                let offset = rowIndex * viewport.width + columnIndex
                // A candidate replaces the incumbent ONLY when strictly
                // nearer, so an exactly equal depth keeps the earlier
                // (layer, facet). This single comparison is the whole
                // tie-break: there is no separate branch to get wrong.
                if let incumbent = hits[offset], !(depth < incumbent.depth) {
                    continue
                }
                hits[offset] = SurfaceHit(
                    depth: depth,
                    weightA: weightA,
                    weightB: weightB,
                    weightC: weightC,
                    layerIndex: layerIndex,
                    facetOrdinal: facetOrdinal
                )
            }
        }
    }

    private struct OrientedFacet: Sendable {
        let facet: ProjectedFacet
        let area: Double
    }

    /// Canonicalises to a positive projected area.
    ///
    /// A projection may mirror a facet, so screen winding is not mesh winding.
    /// Swapping the last two vertices makes every later rule see a positive
    /// area. Back-facing facets are **not** culled: extraction publishes open
    /// surfaces whose interior faces a diagnostic reader needs.
    private static func canonicalise(
        _ facet: ProjectedFacet
    ) throws -> OrientedFacet? {
        let area = try doubledArea(facet)
        if area == 0 {
            return nil
        }
        if area < 0 {
            let swapped = ProjectedFacet(facet.first, facet.third, facet.second)
            return OrientedFacet(
                facet: swapped,
                area: try doubledArea(swapped)
            )
        }
        return OrientedFacet(facet: facet, area: area)
    }

    private static func doubledArea(
        _ facet: ProjectedFacet
    ) throws -> Double {
        try checkedSubtract(
            try checkedMultiply(
                try checkedSubtract(facet.second.column, facet.first.column),
                try checkedSubtract(facet.third.row, facet.first.row)
            ),
            try checkedMultiply(
                try checkedSubtract(facet.second.row, facet.first.row),
                try checkedSubtract(facet.third.column, facet.first.column)
            )
        )
    }

    /// The frozen ordered edge function for the directed edge `a -> b`.
    private static func edge(
        _ a: ProjectedVertex,
        _ b: ProjectedVertex,
        column: Double,
        row: Double
    ) throws -> Double {
        try checkedSubtract(
            try checkedMultiply(
                try checkedSubtract(b.column, a.column),
                try checkedSubtract(row, a.row)
            ),
            try checkedMultiply(
                try checkedSubtract(b.row, a.row),
                try checkedSubtract(column, a.column)
            )
        )
    }

    /// The frozen top-left fill rule, on a positive-area winding.
    ///
    /// Without it a sample lying exactly on an edge shared by two facets is
    /// claimed by both — a double-composited seam — or by neither — a crack.
    private static func isTopLeft(
        _ a: ProjectedVertex,
        _ b: ProjectedVertex
    ) -> Bool {
        if a.row == b.row {
            return b.column < a.column
        }
        return b.row > a.row
    }

    private static func covers(_ value: Double, claims: Bool) -> Bool {
        if value > 0 {
            return true
        }
        return value == 0 && claims
    }

    /// The clamped integer bounding range, or `nil` when nothing is inside.
    ///
    /// Clamping is not clipping: no geometry is cut and no vertex is moved.
    /// The bounds are decided in `Double` space so an extreme but finite
    /// projected coordinate cannot trap an `Int` conversion.
    private static func pixelRange(
        low: Double,
        high: Double,
        limit: Int
    ) -> ClosedRange<Int>? {
        let last = Double(limit - 1)
        let flooredLow = low.rounded(.down)
        let ceiledHigh = high.rounded(.up)
        let first = flooredLow < 0 ? 0 : (flooredLow > last ? limit : Int(flooredLow))
        let bound = ceiledHigh > last ? limit - 1 : (ceiledHigh < 0 ? -1 : Int(ceiledHigh))
        guard first <= bound else {
            return nil
        }
        return first...bound
    }

    // Keeping each primitive out of line prevents contraction and
    // reassociation across the operation boundaries frozen by ALG-0034.
    @inline(never)
    private static func checkedSubtract(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs - rhs
        guard value.isFinite else {
            throw SurfaceVisibilityError.coverageNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedAdd(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs + rhs
        guard value.isFinite else {
            throw SurfaceVisibilityError.coverageNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedMultiply(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs * rhs
        guard value.isFinite else {
            throw SurfaceVisibilityError.coverageNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedDivide(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs / rhs
        guard value.isFinite else {
            throw SurfaceVisibilityError.coverageNotRepresentable
        }
        return value
    }
}
