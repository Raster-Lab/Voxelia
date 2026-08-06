// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial

/// The exact identity a group of CT frames shares, per `VOXELIA-ALG-0047`.
///
/// The key is identity only. No scanner-supplied approximate value takes part —
/// not orientation, not spacing, not position, not the grid extents, not the
/// scalar format — because a series whose orientation nearly agrees must reach
/// the geometry validator as **one** group rather than being split into several
/// internally consistent volumes. `ADR-0228` decision 3 records why.
///
/// The coordinate space is included despite being spatial, because it is a
/// Voxelia-assigned tag rather than scanner data: it cannot nearly agree, and
/// the projection has no defined meaning across two spaces.
public struct CTSeriesKey: Sendable, Hashable {
    /// The series the frames claim to belong to.
    public let seriesIdentity: SourceIdentity
    /// The coordinate space shared by every member's geometry.
    public let coordinateSpace: CoordinateSpaceID
    /// The shared frame-of-reference claim, absent when no member stated one.
    public let frameOfReference: ExternalFrameReference?

    /// Creates a key from its three exact components.
    public init(
        seriesIdentity: SourceIdentity,
        coordinateSpace: CoordinateSpaceID,
        frameOfReference: ExternalFrameReference?
    ) {
        self.seriesIdentity = seriesIdentity
        self.coordinateSpace = coordinateSpace
        self.frameOfReference = frameOfReference
    }

    /// Compares all three components on exact UTF-8 bytes.
    ///
    /// `CoordinateSpaceID` is compared byte-for-byte here rather than through
    /// its synthesised conformance, which inherits `String` equality and so
    /// treats canonically equivalent spellings as equal. `SourceIdentity` and
    /// `ExternalFrameReference` already define exact-byte identity themselves.
    public static func == (lhs: CTSeriesKey, rhs: CTSeriesKey) -> Bool {
        lhs.seriesIdentity == rhs.seriesIdentity
            && lhs.coordinateSpace.rawValue.utf8.elementsEqual(
                rhs.coordinateSpace.rawValue.utf8
            )
            && lhs.frameOfReference == rhs.frameOfReference
    }

    /// Hashes all three components on exact UTF-8 bytes.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(seriesIdentity)
        let bytes = coordinateSpace.rawValue.utf8
        hasher.combine(bytes.count)
        for byte in bytes {
            hasher.combine(byte)
        }
        hasher.combine(frameOfReference)
    }
}

/// The unnormalised axis a series is ordered along.
///
/// This is deliberately **not** a `Vector3D`. The accepted spatial primitive
/// rejects non-finite components, and an overflowing cross product is exactly
/// the evidence `VOXELIA-ALG-0047` requires to be reported rather than
/// discarded. A reference normal is a computed diagnostic value, not a spatial
/// primitive, so it carries no coordinate space and applies no validation.
public struct CTReferenceNormal: Sendable, Hashable {
    /// The X component of the cross product.
    public let x: Double
    /// The Y component of the cross product.
    public let y: Double
    /// The Z component of the cross product.
    public let z: Double

    /// Creates a normal from three unvalidated components.
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// Whether every component is exactly zero, from parallel directions.
    public var isExactlyZero: Bool { x == 0 && y == 0 && z == 0 }

    /// Whether every component is finite.
    public var isFinite: Bool { x.isFinite && y.isFinite && z.isFinite }
}

/// A reported fact about an assembled series.
///
/// None of these is an error at assembly. Whether an observation warrants
/// rejection or a warning is the geometry validator's judgement, per `ADR-0226`
/// decision 7.
public enum CTSeriesObservation: Sendable, Hashable, CaseIterable {
    /// The reference normal is exactly zero, from parallel directions.
    case degenerateReferenceNormal
    /// A reference-normal component overflowed to a non-finite value.
    case nonFiniteReferenceNormal
    /// At least one member's projection is not finite.
    case nonFiniteProjection
}

/// One frame within an assembled series, with its ordering key.
public struct CTSeriesMember: Sendable, Hashable {
    /// The frame's neutral description.
    public let frame: CTFrameDescription
    /// The frame's projection on the series reference normal.
    ///
    /// Reported even when not finite, because it is the evidence for
    /// ``CTSeriesObservation/nonFiniteProjection``.
    public let projection: Double

    /// Creates a member pairing a frame with its computed projection.
    public init(frame: CTFrameDescription, projection: Double) {
        self.frame = frame
        self.projection = projection
    }
}

/// One assembled CT series per `VOXELIA-ALG-0047`.
public struct CTSeries: Sendable, Hashable {
    /// The exact identity every member shares.
    public let key: CTSeriesKey
    /// The axis the members are ordered along, taken from the anchor frame.
    public let referenceNormal: CTReferenceNormal
    /// The facts observed about this series, reported rather than judged.
    public let observations: Set<CTSeriesObservation>
    /// The members, ordered per ``CTSeriesAssembler``.
    public let members: [CTSeriesMember]

    /// Whether ``members`` is ordered by projection.
    ///
    /// When any observation holds, ordering by projection has no defined
    /// meaning and the members fall back to exact identity order.
    public var isOrderedByProjection: Bool { observations.isEmpty }

    /// Creates a series from its assembled parts.
    public init(
        key: CTSeriesKey,
        referenceNormal: CTReferenceNormal,
        observations: Set<CTSeriesObservation>,
        members: [CTSeriesMember]
    ) {
        self.key = key
        self.referenceNormal = referenceNormal
        self.observations = observations
        self.members = members
    }
}

/// The deterministic assembly of neutral CT frame descriptions into ordered
/// series, implementing `series-grouping/binary64-v1`
/// (`VOXELIA-ALG-0047`) for `VOX-DCM-004` and `VOX-VS1-002`.
///
/// Assembly cannot fail, so this type declares no failure family: grouping
/// rejects nothing, and every condition that might warrant rejection is
/// reported as a ``CTSeriesObservation`` for the geometry validator to judge.
public enum CTSeriesAssembler {
    /// Groups `frames` by exact identity and orders each group along its
    /// reference normal.
    ///
    /// The result is a pure function of the **set** of frames rather than of
    /// their arrival order, provided each frame's `sourceIdentity` is distinct.
    ///
    /// Frames sharing an identity *and* a projection are a case the frozen
    /// fixtures leave unspecified; they are ordered by arrival so that the
    /// order is total and deterministic in every input. Whether such a pair is
    /// a duplicate is the geometry validator's judgement.
    ///
    /// - Parameter frames: any number of descriptions, in any order.
    /// - Returns: the assembled series, ordered by exact key.
    public static func assemble(
        _ frames: [CTFrameDescription]
    ) -> [CTSeries] {
        var groups: [CTSeriesKey: [(index: Int, frame: CTFrameDescription)]] = [:]
        for (index, frame) in frames.enumerated() {
            let key = CTSeriesKey(
                seriesIdentity: frame.seriesIdentity,
                coordinateSpace: frame.coordinateSpace,
                frameOfReference: frame.frameOfReference
            )
            groups[key, default: []].append((index, frame))
        }

        return groups.keys
            .sorted(by: keyPrecedes)
            .map { key in assembleGroup(key: key, members: groups[key] ?? []) }
    }

    private static func assembleGroup(
        key: CTSeriesKey,
        members: [(index: Int, frame: CTFrameDescription)]
    ) -> CTSeries {
        // The anchor is the member first in exact identity byte order, so the
        // chosen axis does not depend on arrival order. Choosing an anchor at
        // all is a stated choice, not a claim that the group is coherent: the
        // key excludes orientation, so members may disagree on it.
        let anchor = members.min { lhs, rhs in
            identityPrecedes(lhs.frame.sourceIdentity, rhs.frame.sourceIdentity)
                ?? (lhs.index < rhs.index)
        }
        let normal =
            anchor.map { referenceNormal(of: $0.frame) }
            ?? CTReferenceNormal(x: 0, y: 0, z: 0)

        var observations: Set<CTSeriesObservation> = []
        if normal.isExactlyZero {
            observations.insert(.degenerateReferenceNormal)
        }
        if !normal.isFinite {
            observations.insert(.nonFiniteReferenceNormal)
        }

        let projected = members.map {
            (index: $0.index, frame: $0.frame, t: projection(of: $0.frame, on: normal))
        }
        if projected.contains(where: { !$0.t.isFinite }) {
            observations.insert(.nonFiniteProjection)
        }

        let ordered: [(index: Int, frame: CTFrameDescription, t: Double)] =
            if observations.isEmpty {
                projected.sorted { lhs, rhs in
                    if lhs.t != rhs.t { return lhs.t < rhs.t }
                    return identityPrecedes(lhs.frame.sourceIdentity, rhs.frame.sourceIdentity)
                        ?? (lhs.index < rhs.index)
                }
            } else {
                // Ordering by projection has no defined meaning here, so the
                // members fall back to exact identity order and the
                // projections are retained as the evidence.
                projected.sorted { lhs, rhs in
                    identityPrecedes(lhs.frame.sourceIdentity, rhs.frame.sourceIdentity)
                        ?? (lhs.index < rhs.index)
                }
            }

        return CTSeries(
            key: key,
            referenceNormal: normal,
            observations: observations,
            members: ordered.map { CTSeriesMember(frame: $0.frame, projection: $0.t) }
        )
    }

    /// The anchor frame's cross product, in the frozen expression order of
    /// `VOXELIA-ALG-0047`, with no fused multiply-add and no normalisation.
    private static func referenceNormal(of frame: CTFrameDescription) -> CTReferenceNormal {
        let rx = frame.rowDirection.x
        let ry = frame.rowDirection.y
        let rz = frame.rowDirection.z
        let cx = frame.columnDirection.x
        let cy = frame.columnDirection.y
        let cz = frame.columnDirection.z
        return CTReferenceNormal(
            x: (ry * cz) - (rz * cy),
            y: (rz * cx) - (rx * cz),
            z: (rx * cy) - (ry * cx)
        )
    }

    /// The projection of a frame's position on `normal`, in the frozen
    /// expression order of `VOXELIA-ALG-0047`, with no fused multiply-add.
    private static func projection(
        of frame: CTFrameDescription,
        on normal: CTReferenceNormal
    ) -> Double {
        let px = frame.imagePosition.x
        let py = frame.imagePosition.y
        let pz = frame.imagePosition.z
        return ((px * normal.x) + (py * normal.y)) + (pz * normal.z)
    }

    // MARK: - Exact byte ordering

    /// Whether `lhs` precedes `rhs` in exact UTF-8 byte order, or `nil` when
    /// the two byte sequences are identical.
    private static func bytesPrecede(_ lhs: String, _ rhs: String) -> Bool? {
        if lhs.utf8.elementsEqual(rhs.utf8) { return nil }
        return lhs.utf8.lexicographicallyPrecedes(rhs.utf8)
    }

    /// Whether `lhs` precedes `rhs` by namespace, identifier and version, with
    /// an absent version ordered before every present one, or `nil` when all
    /// three are identical.
    ///
    /// `contentID` deliberately takes no part, matching the frozen fixtures.
    /// Two identities differing only in their content claim therefore tie here
    /// and are separated by arrival order, which keeps the ordering total.
    private static func identityPrecedes(
        _ lhs: SourceIdentity,
        _ rhs: SourceIdentity
    ) -> Bool? {
        if let result = bytesPrecede(lhs.namespace, rhs.namespace) { return result }
        if let result = bytesPrecede(lhs.identifier, rhs.identifier) { return result }
        switch (lhs.version, rhs.version) {
        case (nil, nil):
            return nil
        case (nil, _):
            return true
        case (_, nil):
            return false
        case (let lhsVersion?, let rhsVersion?):
            return bytesPrecede(lhsVersion, rhsVersion)
        }
    }

    /// Whether `lhs` precedes `rhs` in the frozen group order.
    private static func keyPrecedes(_ lhs: CTSeriesKey, _ rhs: CTSeriesKey) -> Bool {
        if let result = identityPrecedes(lhs.seriesIdentity, rhs.seriesIdentity) {
            return result
        }
        if let result = bytesPrecede(
            lhs.coordinateSpace.rawValue,
            rhs.coordinateSpace.rawValue
        ) {
            return result
        }
        switch (lhs.frameOfReference, rhs.frameOfReference) {
        case (nil, nil):
            return false
        case (nil, _):
            return true
        case (_, nil):
            return false
        case (let lhsReference?, let rhsReference?):
            if let result = bytesPrecede(lhsReference.namespace, rhsReference.namespace) {
                return result
            }
            return bytesPrecede(lhsReference.identifier, rhsReference.identifier) ?? false
        }
    }
}
