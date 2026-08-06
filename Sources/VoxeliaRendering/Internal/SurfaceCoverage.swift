// SPDX-License-Identifier: MIT

/// One covered sample: the pixel, its interpolated depth and its barycentric
/// weights in the **canonicalised** vertex order.
struct CoveredSample: Sendable, Equatable {
    let column: Int
    let row: Int
    let depth: Double
    let weightA: Double
    let weightB: Double
    let weightC: Double
}

/// The shared coverage rules frozen by `VOXELIA-ALG-0034`.
///
/// Two consumers need the same coverage with different retention:
/// ``SurfaceVisibilityResolver`` keeps only the nearest sample per pixel, and
/// ``SurfaceFragmentCollector`` keeps every sample so transparency can be
/// composited. Both call this one enumeration, so the sample rule,
/// orientation canonicalisation, fill rule and interpolation cannot drift
/// apart between them.
enum SurfaceCoverage {
    /// Enumerates every sample the facet covers, in row-major order.
    ///
    /// A facet projecting to exactly zero area covers nothing and is not an
    /// error, and a facet outside the viewport enumerates nothing.
    static func enumerateCoveredSamples(
        _ facet: ProjectedFacet,
        viewport: ViewportSize,
        body: (CoveredSample) throws -> Void
    ) throws {
        guard let oriented = try canonicalise(facet) else {
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
                try body(
                    CoveredSample(
                        column: columnIndex,
                        row: rowIndex,
                        depth: depth,
                        weightA: weightA,
                        weightB: weightB,
                        weightC: weightC
                    )
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
    /// Back-facing facets are **not** culled: extraction publishes open
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
        let first =
            flooredLow < 0 ? 0 : (flooredLow > last ? limit : Int(flooredLow))
        let bound =
            ceiledHigh > last ? limit - 1 : (ceiledHigh < 0 ? -1 : Int(ceiledHigh))
        guard first <= bound else {
            return nil
        }
        return first...bound
    }

    // Keeping each primitive out of line prevents contraction and
    // reassociation across the operation boundaries frozen by ALG-0034.
    @inline(never)
    static func checkedSubtract(
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
    static func checkedAdd(_ lhs: Double, _ rhs: Double) throws -> Double {
        let value = lhs + rhs
        guard value.isFinite else {
            throw SurfaceVisibilityError.coverageNotRepresentable
        }
        return value
    }

    @inline(never)
    static func checkedMultiply(
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
    static func checkedDivide(
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
