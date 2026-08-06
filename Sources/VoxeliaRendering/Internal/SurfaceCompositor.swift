// SPDX-License-Identifier: MIT

/// One covering fragment retained for compositing.
///
/// Unlike ``SurfaceHit``, which records only the nearest facet at a pixel, a
/// fragment is one of possibly many at that pixel and carries its layer's
/// opacity so the compositing order can weigh it.
struct SurfaceFragment: Sendable, Equatable {
    let depth: Double
    let weightA: Double
    let weightB: Double
    let weightC: Double
    let layerIndex: Int
    let facetOrdinal: Int
    let opacity: Double

    /// Whether the coverage rule exchanged the facet's second and third
    /// vertices, so a consumer can map each weight to its original vertex.
    let swapped: Bool
}

/// One fragment's front-to-back contribution weight.
///
/// Colour is deliberately absent: the weight is fixed by opacity and order
/// alone, so shading and colour mapping multiply colours into it later without
/// changing it.
struct SurfaceContribution: Sendable, Equatable {
    let fragment: SurfaceFragment
    let contribution: Double
}

/// One pixel's ordered contributions and its accumulated alpha.
struct SurfaceCompositeResult: Sendable, Equatable {
    let contributions: [SurfaceContribution]
    let accumulatedAlpha: Double
}

/// The exact `surface-opacity-compositing/binary64-v1` reference.
///
/// This stateless internal compositor orders one pixel's fragments and applies
/// per-object opacity front to back. It produces no colour and no image.
enum SurfaceCompositor {
    /// Orders and composites one pixel's fragments.
    ///
    /// The order is the strict total order `(depth, layerIndex, facetOrdinal)`.
    /// It can never tie, because one facet covers a pixel at most once, so
    /// `(layerIndex, facetOrdinal)` is unique among a pixel's fragments. That
    /// order is deliberately consistent with ``SurfaceVisibilityResolver``'s
    /// strict-less rule, so an opaque scene composited here selects exactly the
    /// fragment the resolver would have selected.
    ///
    /// There is no representability failure and this method does not throw:
    /// `SurfaceLayer` admits only a finite opacity in `[0, 1]` and the
    /// accumulator starts at zero, so every intermediate lies in `[0, 1]`.
    /// Infinity is unreachable, and NaN would require `0 * infinity` or
    /// `infinity - infinity`. Carrying an unreachable failure case would be an
    /// error with no possible evidence.
    static func composite(
        fragments: [SurfaceFragment]
    ) -> SurfaceCompositeResult {
        let ordered = fragments.sorted { lhs, rhs in
            if lhs.depth != rhs.depth {
                return lhs.depth < rhs.depth
            }
            if lhs.layerIndex != rhs.layerIndex {
                return lhs.layerIndex < rhs.layerIndex
            }
            return lhs.facetOrdinal < rhs.facetOrdinal
        }

        var accumulated = 0.0
        var contributions = [SurfaceContribution]()
        contributions.reserveCapacity(ordered.count)
        for fragment in ordered {
            // Occlusion is not a special case: a fully opaque fragment drives
            // the accumulator to exactly one, so every later `remaining` is
            // exactly zero and every later contribution is exactly zero. An
            // implementation may stop here, which is bit-identical.
            let remaining = 1 - accumulated
            let contribution = fragment.opacity * remaining
            accumulated += contribution
            contributions.append(
                SurfaceContribution(
                    fragment: fragment,
                    contribution: contribution
                )
            )
        }
        return SurfaceCompositeResult(
            contributions: contributions,
            accumulatedAlpha: accumulated
        )
    }
}

/// Required host ceilings for one fragment collection.
///
/// This ceiling differs in kind from ``SurfaceVisibilityLimits``. A visibility
/// buffer is bounded by the viewport alone; a fragment list is bounded by
/// scene depth complexity, which no viewport bound constrains — a scene of one
/// thousand overlapping layers retains one thousand fragments per covered
/// pixel.
struct SurfaceFragmentLimits: Sendable {
    /// The exact logical bytes one fragment occupies: one depth, three
    /// weights, one layer index, one facet ordinal and one opacity.
    static let fragmentByteCount: UInt64 = 56

    /// The inclusive maximum operation-controlled retained logical bytes.
    let maximumRetainedLogicalByteCount: UInt64

    init(maximumRetainedLogicalByteCount: UInt64) {
        self.maximumRetainedLogicalByteCount = maximumRetainedLogicalByteCount
    }
}

/// Retains every covering fragment so transparency can be composited.
///
/// ``SurfaceVisibilityResolver`` is not superseded: its nearest-only buffer
/// stays correct and strictly cheaper whenever every layer is fully opaque,
/// and it is the natural input for picking. Both retention policies share the
/// one ``SurfaceCoverage`` enumeration.
enum SurfaceFragmentCollector {
    /// Collects every covering fragment, grouped per pixel in row-major order.
    static func collect(
        layers: [[ProjectedFacet]],
        opacities: [Double],
        viewport: ViewportSize,
        limits: SurfaceFragmentLimits,
        cancellation: SurfaceVisibilityProbe
    ) throws -> [[SurfaceFragment]] {
        if cancellation(.admission) {
            throw SurfaceVisibilityError.cancelled
        }
        guard layers.count == opacities.count else {
            throw SurfaceVisibilityError.resourceLimitExceeded
        }
        let pixelCount = viewport.width * viewport.height
        var buckets = [[SurfaceFragment]](
            repeating: [],
            count: pixelCount
        )
        var retained: UInt64 = 0

        for (layerIndex, facets) in layers.enumerated() {
            let opacity = opacities[layerIndex]
            for (facetOrdinal, facet) in facets.enumerated() {
                let ordinal = UInt64(facetOrdinal)
                if ordinal.isMultiple(of: 64),
                    cancellation(
                        .facet(layer: UInt64(layerIndex), ordinal: ordinal)
                    )
                {
                    throw SurfaceVisibilityError.cancelled
                }
                try SurfaceCoverage.enumerateCoveredSamples(
                    facet,
                    viewport: viewport
                ) { sample in
                    retained = try checkedRetained(
                        retained,
                        limit: limits.maximumRetainedLogicalByteCount
                    )
                    buckets[sample.row * viewport.width + sample.column]
                        .append(
                            SurfaceFragment(
                                depth: sample.depth,
                                weightA: sample.weightA,
                                weightB: sample.weightB,
                                weightC: sample.weightC,
                                layerIndex: layerIndex,
                                facetOrdinal: facetOrdinal,
                                opacity: opacity,
                                swapped: sample.swapped
                            )
                        )
                }
            }
        }
        return buckets
    }

    /// Charges one more fragment against the retained-byte ceiling.
    static func checkedRetained(
        _ current: UInt64,
        limit: UInt64
    ) throws -> UInt64 {
        let next = current.addingReportingOverflow(
            SurfaceFragmentLimits.fragmentByteCount
        )
        guard !next.overflow, next.partialValue <= limit else {
            throw SurfaceVisibilityError.resourceLimitExceeded
        }
        return next.partialValue
    }
}
