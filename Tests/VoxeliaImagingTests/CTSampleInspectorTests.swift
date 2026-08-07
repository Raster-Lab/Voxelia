// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaImaging

@Suite("CTSampleInspector")
struct CTSampleInspectorTests {
    private func space() throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: "patient"))
    }

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 0, minor: 1, patch: 1),
            commit: nil,
            buildIdentifier: nil
        )
    }

    /// A 2x2 rank-two slice whose four uint16 samples are 0, 1, 2, 3 with axis
    /// zero fastest, carrying the supplied value transform.
    private func slice(
        transform: ValueTransform?,
        type: ScalarType = .uint16,
        rank2: Bool = true
    ) throws -> ImageData {
        let format = try ScalarFormat(
            type: type,
            validBitCount: nil,
            byteOrder: .native
        )
        let extents = rank2 ? [2, 2] : [2, 2, 1]
        var axes = ContiguousArray<AxisDescriptor>()
        for (index, name) in ["column", "row", "slice"].prefix(extents.count).enumerated() {
            axes.append(
                try AxisDescriptor(
                    id: try #require(AxisID(rawValue: name)),
                    name: name,
                    semantic: [AxisSemantic.spatialX, .spatialY, .spatialZ][index],
                    unit: nil,
                    sampling: .indexOnly
                )
            )
        }
        let descriptor = try ImageDescriptor(
            shape: try ImageShape(extents: extents),
            scalarFormat: format,
            components: try ComponentDescriptor(
                count: 1,
                interpretation: .scalar,
                layout: .interleaved
            ),
            semantic: .intensity,
            axes: axes,
            spatialGeometry: nil,
            valueTransform: transform,
            units: nil
        )
        var bytes: [UInt8] = []
        for sample in 0..<4 {
            if type.byteCount == 2 {
                bytes.append(UInt8(sample & 0xFF))
                bytes.append(0)
            } else {
                bytes.append(UInt8(sample & 0xFF))
            }
        }
        let storage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: descriptor.shape,
                    scalarFormat: format,
                    components: descriptor.components
                ),
                bytes: bytes
            )
        )
        let objectID = try #require(DataObjectID(rawValue: "slice.1"))
        let identity = try DataIdentity(
            objectID: objectID,
            contentID: nil,
            sourceIdentities: [
                try SourceIdentity(
                    namespace: "dicom",
                    identifier: "instance.1",
                    version: nil,
                    contentID: nil
                )
            ],
            derivation: nil
        )
        let provenance = try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: "slice.1.prov")),
            kind: .source,
            createdAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z"),
            subject: .object(objectID),
            software: try software(),
            activity: .origin,
            inputs: [],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
        return try ImageData(
            descriptor: descriptor,
            storage: storage,
            metadata: try MetadataCollection(entries: []),
            provenance: provenance,
            identity: identity
        )
    }

    // MARK: - The rescale

    @Test("[Unit] A linear transform is applied to the stored value")
    func appliesLinearTransform() throws {
        // The CT case: slope 1, intercept -8192, as the real corpus declares.
        let subject = try slice(
            transform: .linear(
                try LinearValueTransformDescriptor(scale: 1.0, offset: -8192.0)
            )
        )
        let inspection = try CTSampleInspector.inspect(
            slice: subject,
            column: 1,
            row: 1,
            paddingValue: nil
        )
        #expect(inspection.storedValue == 3)
        #expect(inspection.value == .measured(-8189.0))
    }

    @Test("[Unit] A non-unit slope scales before the intercept")
    func nonUnitSlope() throws {
        let subject = try slice(
            transform: .linear(
                try LinearValueTransformDescriptor(scale: 2.5, offset: -1024.0)
            )
        )
        let inspection = try CTSampleInspector.inspect(
            slice: subject,
            column: 0,
            row: 1,
            paddingValue: nil
        )
        #expect(inspection.storedValue == 2)
        #expect(inspection.value == .measured(-1019.0))
    }

    @Test(
        "[Unit] An identity or absent transform reports the stored value unchanged",
        arguments: [ValueTransform.identity, nil]
    )
    func identityTransform(_ transform: ValueTransform?) throws {
        let subject = try slice(transform: transform)
        let inspection = try CTSampleInspector.inspect(
            slice: subject,
            column: 1,
            row: 0,
            paddingValue: nil
        )
        #expect(inspection.storedValue == 1)
        #expect(inspection.value == .measured(1.0))
    }

    // MARK: - Indexing

    @Test("[Unit] Axis zero is the fastest-varying index")
    func axisZeroIsFastest() throws {
        let subject = try slice(transform: .identity)
        // Samples 0, 1, 2, 3 laid out with axis zero fastest.
        for (column, row, expected) in [(0, 0, 0), (1, 0, 1), (0, 1, 2), (1, 1, 3)] {
            let inspection = try CTSampleInspector.inspect(
                slice: subject,
                column: column,
                row: row,
                paddingValue: nil
            )
            #expect(inspection.storedValue == Int64(expected))
            #expect(inspection.column == column)
            #expect(inspection.row == row)
        }
    }

    @Test("[Unit] An index outside the slice is refused")
    func refusesOutOfRange() throws {
        let subject = try slice(transform: .identity)
        for (column, row) in [(-1, 0), (0, -1), (2, 0), (0, 2), (99, 99)] {
            #expect(throws: CTSampleInspectionError.indexOutOfRange) {
                try CTSampleInspector.inspect(
                    slice: subject,
                    column: column,
                    row: row,
                    paddingValue: nil
                )
            }
        }
    }

    // MARK: - Padding

    @Test("[Unit] A stored value matching the supplied padding reports padding")
    func reportsPadding() throws {
        let subject = try slice(transform: .identity)
        let inspection = try CTSampleInspector.inspect(
            slice: subject,
            column: 0,
            row: 1,
            paddingValue: 2
        )
        #expect(inspection.storedValue == 2)
        #expect(inspection.value == .padding)
    }

    @Test("[Unit] Padding is compared on the stored value, not the rescaled one")
    func paddingComparedOnStoredValue() throws {
        // Stored 2 with intercept -8192 rescales to -8190. Supplying -8190 as the
        // padding must NOT match, because the comparison is on the stored value.
        let subject = try slice(
            transform: .linear(
                try LinearValueTransformDescriptor(scale: 1.0, offset: -8192.0)
            )
        )
        let inspection = try CTSampleInspector.inspect(
            slice: subject,
            column: 0,
            row: 1,
            paddingValue: -8190
        )
        #expect(inspection.value == .measured(-8190.0))
    }

    // MARK: - Admission

    @Test("[Unit] A rank-three image is refused: this inspects slices")
    func refusesRankThree() throws {
        let subject = try slice(transform: .identity, rank2: false)
        #expect(throws: CTSampleInspectionError.unsupportedRank) {
            try CTSampleInspector.inspect(
                slice: subject,
                column: 0,
                row: 0,
                paddingValue: nil
            )
        }
    }

    @Test("[Unit] A lookup-table transform is refused rather than half-evaluated")
    func refusesLookupTable() throws {
        // A general evaluator would duplicate the model VOXELIA-ALG-0005 governs;
        // ADR-0237 records what re-freezing a governed boundary costs.
        let table = try LookupTableDescriptor(
            firstMappedValue: 0,
            values: [0.0, 1.0, 2.0, 3.0]
        )
        let subject = try slice(transform: .lookupTable(table))
        #expect(throws: CTSampleInspectionError.unsupportedValueTransform) {
            try CTSampleInspector.inspect(
                slice: subject,
                column: 0,
                row: 0,
                paddingValue: nil
            )
        }
    }

    @Test("[Unit] An eight-bit slice inspects correctly")
    func eightBitSlice() throws {
        let subject = try slice(transform: .identity, type: .uint8)
        let inspection = try CTSampleInspector.inspect(
            slice: subject,
            column: 1,
            row: 1,
            paddingValue: nil
        )
        #expect(inspection.storedValue == 3)
    }
}
