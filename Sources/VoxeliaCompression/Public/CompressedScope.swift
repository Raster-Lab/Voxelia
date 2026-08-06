// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised while admitting a compressed payload's scope.
///
/// Payload-free, consistent with the rest of the arc.
public enum CompressedScopeError: Error, Sendable, Equatable {
    /// The region's rank differs from the parent volume's.
    case rankMismatch
    /// The region falls outside the parent volume.
    case regionOutsideVolume
    /// A parent extent is not positive.
    case invalidVolumeExtent
    /// The parent volume declares no extents.
    case missingVolumeExtents
    /// The payload's declared extents differ from the region's.
    case payloadExtentsDisagreeWithRegion
}

/// Which of `VOX-CMP-003`'s four shapes a compressed payload covers.
///
/// **Derived, never declared.** The region determines the kind, so there is one
/// source of truth and a classification cannot disagree with the region it
/// describes — the same reasoning that makes
/// `CompressedPayload.declaredDecodedByteCount` a derived value.
public enum CompressedScopeKind: Sendable, Hashable {
    /// The payload covers the whole parent volume: the original compressed source.
    case originalSource
    /// A single plane: one axis has extent one, every other axis is full.
    case slice
    /// A contiguous run of planes: one axis is partial, every other axis is full.
    case slab
    /// Bounded on two or more axes.
    case brick
}

/// What region of a parent volume a compressed payload covers, per `ADR-0260`
/// (`VOX-CMP-003`).
///
/// ## The four shapes are one region plus a frozen classification
///
/// `VOX-CMP-003` names original sources, slices, slabs and bricks. They are not four
/// unrelated things: each is a region of a parent volume, and which name applies
/// follows from the region's bounds. So this type stores the region and **derives**
/// the kind, rather than carrying a declared kind that could contradict it.
///
/// The frozen classification, applied in order:
///
/// 1. The region covers every axis fully → ``CompressedScopeKind/originalSource``.
/// 2. Exactly one axis has extent one and every other axis is full →
///    ``CompressedScopeKind/slice``.
/// 3. Exactly one axis is partial and every other axis is full →
///    ``CompressedScopeKind/slab``.
/// 4. Otherwise → ``CompressedScopeKind/brick``.
///
/// **Order matters and clause 1 wins deliberately.** A volume whose slice axis has
/// extent one is simultaneously "the whole volume" and "a single plane"; both
/// descriptions are true, and a classification that depended on which was checked
/// first would be ambiguous. Covering everything is the stronger statement, so it
/// takes precedence, and the ambiguity is resolved by the rule rather than left to
/// the reader.
///
/// ## The payload's declarations must agree with the region
///
/// A payload declaring `512x512x8` cannot describe a region of extent
/// `512x512x899`. The disagreement is refused at admission, because a scope whose
/// region and payload disagree is a lie about what the codestream contains, and it
/// is exactly the sort of thing that would later be discovered as a truncated
/// decode.
public struct CompressedScope: Sendable, Hashable {
    /// The parent volume's extents, in image-axis order.
    public let volumeExtents: ContiguousArray<Int>

    /// The region of that volume this payload covers.
    public let region: ImageRegion

    /// Which of the four shapes this is, derived from the region.
    public let kind: CompressedScopeKind

    /// Admits a scope for `payload` covering `region` of a volume with
    /// `volumeExtents`.
    ///
    /// - Throws: ``CompressedScopeError``.
    public init(
        payload: CompressedPayload,
        region: ImageRegion,
        volumeExtents: ContiguousArray<Int>
    ) throws {
        guard !volumeExtents.isEmpty else {
            throw CompressedScopeError.missingVolumeExtents
        }
        guard volumeExtents.allSatisfy({ $0 >= 1 }) else {
            throw CompressedScopeError.invalidVolumeExtent
        }
        guard region.rank == volumeExtents.count else {
            throw CompressedScopeError.rankMismatch
        }

        var regionExtents = ContiguousArray<Int>()
        for axis in 0..<volumeExtents.count {
            let lower = region.lowerBounds[axis]
            let upper = region.upperBounds[axis]
            guard lower >= 0, upper <= volumeExtents[axis] else {
                throw CompressedScopeError.regionOutsideVolume
            }
            regionExtents.append(upper - lower)
        }

        guard payload.declaredExtents == regionExtents else {
            throw CompressedScopeError.payloadExtentsDisagreeWithRegion
        }

        self.volumeExtents = volumeExtents
        self.region = region
        self.kind = Self.classify(
            regionExtents: regionExtents,
            volumeExtents: volumeExtents
        )
    }

    /// The frozen `ADR-0260` classification.
    ///
    /// `internal` rather than private so a test can exercise it over enumerated
    /// shapes without constructing a payload for each.
    static func classify(
        regionExtents: ContiguousArray<Int>,
        volumeExtents: ContiguousArray<Int>
    ) -> CompressedScopeKind {
        // Clause 1: covering everything is the strongest statement and wins.
        if regionExtents == volumeExtents { return .originalSource }

        let partialAxes = (0..<regionExtents.count).filter {
            regionExtents[$0] != volumeExtents[$0]
        }
        guard partialAxes.count == 1 else { return .brick }

        // Clause 2 before clause 3: extent one is a plane, any other partial
        // extent is a run of planes.
        return regionExtents[partialAxes[0]] == 1 ? .slice : .slab
    }

    /// The region's extents, in image-axis order.
    public var regionExtents: ContiguousArray<Int> {
        var extents = ContiguousArray<Int>()
        for axis in 0..<region.rank {
            extents.append(region.upperBounds[axis] - region.lowerBounds[axis])
        }
        return extents
    }
}
