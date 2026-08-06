// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaImaging

/// Verifies `series-grouping/binary64-v1` against every frozen fixture of
/// `VOXELIA-ALG-0047`. Expected values are the oracle's exact binary64 results,
/// written as hexadecimal float literals so a decimal round-trip cannot soften
/// a mismatch.
@Suite("CTSeriesAssembler")
struct CTSeriesAssemblerTests {
    private static let patient = "patient"
    private static let table = "table"

    private func space(_ raw: String) throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: raw))
    }

    private func identity(_ identifier: String) throws -> SourceIdentity {
        try SourceIdentity(
            namespace: "dicom",
            identifier: identifier,
            version: nil,
            contentID: nil
        )
    }

    private func reference() throws -> ExternalFrameReference {
        try ExternalFrameReference(namespace: "dicom", identifier: "1.2.840.frame.1")
    }

    private func make(
        _ ident: String,
        series: String = "1.2.840.series.A",
        space raw: String = patient,
        reference: ExternalFrameReference? = nil,
        row: (Double, Double, Double) = (1, 0, 0),
        column: (Double, Double, Double) = (0, 1, 0),
        position: (Double, Double, Double) = (0, 0, 0),
        omitReference: Bool = false
    ) throws -> CTFrameDescription {
        let coordinateSpace = try space(raw)
        return try CTFrameDescription(
            sourceIdentity: try identity(ident),
            seriesIdentity: try identity(series),
            rows: 512,
            columns: 512,
            scalarFormat: try ScalarFormat(
                type: .int16,
                validBitCount: nil,
                byteOrder: .littleEndian
            ),
            photometricInterpretation: .monochrome2,
            rowSpacingMillimetres: 0.7,
            columnSpacingMillimetres: 0.7,
            rowDirection: try Vector3D(
                x: row.0,
                y: row.1,
                z: row.2,
                coordinateSpace: coordinateSpace
            ),
            columnDirection: try Vector3D(
                x: column.0,
                y: column.1,
                z: column.2,
                coordinateSpace: coordinateSpace
            ),
            imagePosition: try Point3D(
                x: position.0,
                y: position.1,
                z: position.2,
                coordinateSpace: coordinateSpace
            ),
            frameOfReference: omitReference ? nil : (reference ?? (try self.reference())),
            rescaleSlope: 1.0,
            rescaleIntercept: -1024.0,
            pixelPadding: nil,
            sourceMetadata: try MetadataCollection(entries: [])
        )
    }

    private func identifiers(_ series: CTSeries) -> [String] {
        series.members.map(\.frame.sourceIdentity.identifier)
    }

    private func projections(_ series: CTSeries) -> [Double] {
        series.members.map(\.projection)
    }

    // MARK: - F1 and F2: ordering is a function of the frame set

    @Test("F1 an axial series orders by ascending projection")
    func f1AxialSeries() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f1", position: (-175.5, -175.5, 0.0)),
            try make("f2", position: (-175.5, -175.5, 2.5)),
            try make("f3", position: (-175.5, -175.5, 5.0)),
        ])

        #expect(series.count == 1)
        let assembled = try #require(series.first)
        #expect(assembled.referenceNormal == CTReferenceNormal(x: 0, y: 0, z: 0x1.0p+0))
        #expect(assembled.observations.isEmpty)
        #expect(assembled.isOrderedByProjection)
        #expect(identifiers(assembled) == ["f1", "f2", "f3"])
        #expect(projections(assembled) == [0x0.0p+0, 0x1.4p+1, 0x1.4p+2])
    }

    @Test("F2 a shuffled arrival order gives the identical result")
    func f2ShuffledInput() throws {
        let ordered = CTSeriesAssembler.assemble([
            try make("f1", position: (-175.5, -175.5, 0.0)),
            try make("f2", position: (-175.5, -175.5, 2.5)),
            try make("f3", position: (-175.5, -175.5, 5.0)),
        ])
        let shuffled = CTSeriesAssembler.assemble([
            try make("f3", position: (-175.5, -175.5, 5.0)),
            try make("f1", position: (-175.5, -175.5, 0.0)),
            try make("f2", position: (-175.5, -175.5, 2.5)),
        ])

        #expect(ordered == shuffled)
    }

    // MARK: - F3, F4, F5, F10: the projection is the ordering, not a coordinate

    @Test("F3 a flipped column direction reverses the ordering axis")
    func f3FlippedColumn() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f1", column: (0, -1, 0), position: (0, 0, 0.0)),
            try make("f2", column: (0, -1, 0), position: (0, 0, 2.5)),
            try make("f3", column: (0, -1, 0), position: (0, 0, 5.0)),
        ])

        let assembled = try #require(series.first)
        #expect(assembled.referenceNormal == CTReferenceNormal(x: 0, y: 0, z: -0x1.0p+0))
        #expect(identifiers(assembled) == ["f3", "f2", "f1"])
        #expect(projections(assembled) == [-0x1.4p+2, -0x1.4p+1, 0x0.0p+0])
    }

    @Test("F4 an oblique series does not order by any single coordinate")
    func f4Oblique() throws {
        let row = (0.7071067811865476, 0.7071067811865475, 0.0)
        let series = CTSeriesAssembler.assemble([
            try make("f1", row: row, column: (0, 0, 1), position: (1, 2, 3)),
            try make("f2", row: row, column: (0, 0, 1), position: (4, 5, 6)),
        ])

        let assembled = try #require(series.first)
        #expect(
            assembled.referenceNormal
                == CTReferenceNormal(
                    x: 0x1.6a09e667f3bccp-1,
                    y: -0x1.6a09e667f3bcdp-1,
                    z: 0
                )
        )
        #expect(assembled.observations.isEmpty)
        // f2 sits further from the origin on every axis yet comes first,
        // because the reference normal has a negative y component. Sorting by
        // any positional coordinate passes F1 and fails here.
        #expect(identifiers(assembled) == ["f2", "f1"])
        #expect(
            projections(assembled) == [-0x1.6a09e667f3bd0p-1, -0x1.6a09e667f3bcep-1]
        )
    }

    @Test("F5 non-orthogonal directions are ordered, not judged")
    func f5NonOrthogonal() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f1", column: (0.5, 0.5, 0), position: (0, 0, 4.0)),
            try make("f2", column: (0.5, 0.5, 0), position: (0, 0, 1.0)),
        ])

        let assembled = try #require(series.first)
        #expect(assembled.referenceNormal == CTReferenceNormal(x: 0, y: 0, z: 0x1.0p-1))
        #expect(assembled.observations.isEmpty)
        #expect(identifiers(assembled) == ["f2", "f1"])
        #expect(projections(assembled) == [0x1.0p-1, 0x1.0p+1])
    }

    @Test("F10 a nearly cancelling cross product keeps two slices distinct")
    func f10NearCancellation() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f1", row: (1.0, 1e-16, 0), column: (1, 0, 0), position: (0, 0, 1)),
            try make("f2", row: (1.0, 1e-16, 0), column: (1, 0, 0), position: (0, 0, 2)),
        ])

        let assembled = try #require(series.first)
        #expect(
            assembled.referenceNormal
                == CTReferenceNormal(x: 0, y: 0, z: -0x1.cd2b297d889bcp-54)
        )
        #expect(assembled.observations.isEmpty)
        // Any epsilon large enough to look reasonable would merge these.
        #expect(identifiers(assembled) == ["f2", "f1"])
        #expect(
            projections(assembled)
                == [-0x1.cd2b297d889bcp-53, -0x1.cd2b297d889bcp-54]
        )
    }

    // MARK: - F6, F7, F8: observations are reported, never judged

    @Test("F6 parallel directions give an exactly zero normal")
    func f6DegenerateNormal() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f1", column: (2, 0, 0), position: (0, 0, 1)),
            try make("f2", column: (2, 0, 0), position: (0, 0, 9)),
        ])

        let assembled = try #require(series.first)
        #expect(assembled.referenceNormal == CTReferenceNormal(x: 0, y: 0, z: 0))
        #expect(assembled.referenceNormal.isExactlyZero)
        #expect(assembled.observations == [.degenerateReferenceNormal])
        #expect(!assembled.isOrderedByProjection)
        #expect(identifiers(assembled) == ["f1", "f2"])
        #expect(projections(assembled) == [0.0, 0.0])
    }

    @Test("F7 an overflowing cross product reports both non-finite observations")
    func f7NonFiniteNormal() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f1", row: (1e200, 0, 0), column: (0, 1e200, 0), position: (0, 0, 1)),
            try make("f2", row: (1e200, 0, 0), column: (0, 1e200, 0), position: (0, 0, 2)),
        ])

        let assembled = try #require(series.first)
        #expect(assembled.referenceNormal.z == .infinity)
        #expect(!assembled.referenceNormal.isFinite)
        #expect(
            assembled.observations == [.nonFiniteReferenceNormal, .nonFiniteProjection]
        )
        #expect(identifiers(assembled) == ["f1", "f2"])
        #expect(projections(assembled).allSatisfy { $0 == .infinity })
    }

    @Test("F8 a finite normal with an overflowing projection reports only that")
    func f8NonFiniteProjectionOnly() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f1", row: (1e100, 0, 0), column: (0, 1e100, 0), position: (0, 0, 1)),
            try make(
                "f2",
                row: (1e100, 0, 0),
                column: (0, 1e100, 0),
                position: (0, 0, 1e200)
            ),
        ])

        let assembled = try #require(series.first)
        #expect(assembled.referenceNormal.z == 0x1.4e718d7d7625ap+664)
        #expect(assembled.referenceNormal.isFinite)
        // The two non-finite conditions are distinct; conflating them fails.
        #expect(assembled.observations == [.nonFiniteProjection])
        #expect(projections(assembled) == [0x1.4e718d7d7625ap+664, .infinity])
    }

    // MARK: - F9: ties

    @Test("F9 co-located frames tie and break by exact identity order")
    func f9Tie() throws {
        let series = CTSeriesAssembler.assemble([
            try make("fb", position: (0, 0, 3)),
            try make("fa", position: (0, 0, 3)),
        ])

        let assembled = try #require(series.first)
        #expect(assembled.observations.isEmpty)
        #expect(identifiers(assembled) == ["fa", "fb"])
        #expect(projections(assembled) == [0x1.8p+1, 0x1.8p+1])
    }

    // MARK: - F11 to F14: the grouping key

    @Test("F11 two series identities in one frame of reference stay separate")
    func f11TwoSeries() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f1", series: "1.2.840.series.A", position: (0, 0, 1)),
            try make("f2", series: "1.2.840.series.B", position: (0, 0, 2)),
        ])

        #expect(series.count == 2)
        #expect(identifiers(series[0]) == ["f1"])
        #expect(identifiers(series[1]) == ["f2"])
        #expect(series[0].key.seriesIdentity.identifier == "1.2.840.series.A")
        #expect(series[1].key.seriesIdentity.identifier == "1.2.840.series.B")
    }

    @Test("F12 an absent frame of reference never joins a present one")
    func f12AbsentReference() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f1", position: (0, 0, 1), omitReference: true),
            try make("f2", position: (0, 0, 2)),
        ])

        #expect(series.count == 2)
        // Absent sorts before present.
        #expect(series[0].key.frameOfReference == nil)
        #expect(identifiers(series[0]) == ["f1"])
        #expect(series[1].key.frameOfReference == (try reference()))
        #expect(identifiers(series[1]) == ["f2"])
    }

    @Test("F13 a differing coordinate space separates a series")
    func f13DifferingSpace() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f1", space: Self.patient, position: (0, 0, 1)),
            try make("f2", space: Self.table, position: (0, 0, 2)),
        ])

        #expect(series.count == 2)
        // "patient" sorts before "table" in UTF-8 byte order.
        #expect(identifiers(series[0]) == ["f1"])
        #expect(identifiers(series[1]) == ["f2"])
    }

    @Test("F14 disagreeing orientation stays in ONE group for the validator")
    func f14DisagreeingOrientation() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f1", row: (1, 0, 0), column: (0, 1, 0), position: (0, 0, 1)),
            try make("f2", row: (0, 1, 0), column: (1, 0, 0), position: (0, 0, 2)),
        ])

        // This is the specification's central rule: the group is NOT split, so
        // increment (c) can reject it as one thing and name the frames.
        #expect(series.count == 1)
        let assembled = try #require(series.first)
        #expect(assembled.referenceNormal == CTReferenceNormal(x: 0, y: 0, z: 0x1.0p+0))
        #expect(assembled.observations.isEmpty)
        #expect(identifiers(assembled) == ["f1", "f2"])
        #expect(projections(assembled) == [0x1.0p+0, 0x1.0p+1])
    }

    // MARK: - The anchor and the group order

    @Test("The anchor is chosen by identity, not by arrival")
    func anchorIsIdentityChosen() throws {
        // f1 is axial and fz is flipped. Whichever arrives first, f1 wins the
        // anchor because "f1" precedes "fz" in exact byte order, so the
        // reference normal is +z in both arrangements.
        let forward = CTSeriesAssembler.assemble([
            try make("f1", row: (1, 0, 0), column: (0, 1, 0), position: (0, 0, 1)),
            try make("fz", row: (1, 0, 0), column: (0, -1, 0), position: (0, 0, 2)),
        ])
        let reversed = CTSeriesAssembler.assemble([
            try make("fz", row: (1, 0, 0), column: (0, -1, 0), position: (0, 0, 2)),
            try make("f1", row: (1, 0, 0), column: (0, 1, 0), position: (0, 0, 1)),
        ])

        #expect(forward == reversed)
        let assembled = try #require(forward.first)
        #expect(assembled.referenceNormal == CTReferenceNormal(x: 0, y: 0, z: 0x1.0p+0))
    }

    @Test("Groups are emitted in exact key order regardless of arrival")
    func groupsAreKeyOrdered() throws {
        let series = CTSeriesAssembler.assemble([
            try make("f3", series: "1.2.840.series.C", position: (0, 0, 1)),
            try make("f1", series: "1.2.840.series.A", position: (0, 0, 1)),
            try make("f2", series: "1.2.840.series.B", position: (0, 0, 1)),
        ])

        #expect(
            series.map(\.key.seriesIdentity.identifier) == [
                "1.2.840.series.A", "1.2.840.series.B", "1.2.840.series.C",
            ]
        )
    }

    // MARK: - Degenerate inputs

    @Test("An empty input assembles no series")
    func emptyInput() throws {
        #expect(CTSeriesAssembler.assemble([]).isEmpty)
    }

    @Test("A single frame assembles one series of one member")
    func singleFrame() throws {
        let series = CTSeriesAssembler.assemble([try make("f1", position: (0, 0, 7))])
        let assembled = try #require(series.first)
        #expect(assembled.members.count == 1)
        #expect(assembled.observations.isEmpty)
        #expect(projections(assembled) == [0x1.cp+2])
    }

    @Test("Frames sharing an identity and a projection stay ordered and total")
    func duplicateIdentityIsTotal() throws {
        // The frozen fixtures leave this case unspecified: identity ties and so
        // does the projection. Arrival order breaks it, so the result is always
        // deterministic. Increment (c) is what judges a duplicate.
        let series = CTSeriesAssembler.assemble([
            try make("f1", position: (0, 0, 3)),
            try make("f1", position: (0, 0, 3)),
        ])

        let assembled = try #require(series.first)
        #expect(assembled.members.count == 2)
        #expect(identifiers(assembled) == ["f1", "f1"])
    }
}
