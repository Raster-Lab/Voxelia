// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("ObliqueSliceOperation")
struct ObliqueSliceOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func space(id: String = "patient") throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func geometry(
        elements: [Double],
        imageAxes: [Int],
        spaceID: String = "patient"
    ) throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: imageAxes),
            indexToWorld: try Matrix4x4Double(elements: elements),
            coordinateSpace: try space(id: spaceID)
        )
    }

    private func axis(_ id: String, semantic: AxisSemantic) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: semantic,
            unit: nil,
            sampling: .indexOnly
        )
    }

    /// The specification volume: extents (3, 3, 3) with stored value
    /// `2*i0 + 6*i1 + 18*i2` and identity index-to-world geometry.
    private func volume(
        extents: [Int] = [3, 3, 3],
        geometry: SpatialGeometry?
    ) throws -> ImageData {
        let count = extents.reduce(1, *)
        var bytes = [UInt8](repeating: 0, count: count)
        if extents == [3, 3, 3] {
            for i2 in 0..<3 {
                for i1 in 0..<3 {
                    for i0 in 0..<3 {
                        bytes[i0 + 3 * (i1 + 3 * i2)] = UInt8(
                            2 * i0 + 6 * i1 + 18 * i2
                        )
                    }
                }
            }
        }
        var axes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        let names = ["x", "y", "z"]
        for index in 0..<extents.count {
            axes.append(try axis(names[index], semantic: semantics[index]))
        }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: ContiguousArray(extents)),
                scalarFormat: try ScalarFormat(
                    type: .uint8,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 1,
                    interpretation: .scalar,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: .intensity,
                axes: axes,
                spatialGeometry: geometry,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: try ImageShape(extents: ContiguousArray(extents)),
                        scalarType: .uint8,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "volume-7"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "volume-7")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.7",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func identityVolumeGeometry() throws -> SpatialGeometry {
        .affine(
            try geometry(
                elements: [
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ],
                imageAxes: [0, 1, 2]
            )
        )
    }

    /// A one-by-one request whose single sample lands at the given
    /// world origin, with identity in-plane steps.
    private func pointRequest(
        origin: (Double, Double, Double)
    ) throws -> AffineGridGeometry {
        try geometry(
            elements: [
                1, 0, 0, origin.0,
                0, 1, 0, origin.1,
                0, 0, 1, origin.2,
                0, 0, 0, 1,
            ],
            imageAxes: [0, 1]
        )
    }

    private func execute(
        _ input: ImageData,
        request: AffineGridGeometry,
        width: Int,
        height: Int
    ) async throws -> ImageData {
        try await ObliqueSliceOperation.execute(
            input: input,
            request: request,
            outputWidth: width,
            outputHeight: height,
            outputObjectID: try #require(DataObjectID(rawValue: "slice-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func bytes(_ image: ImageData) throws -> [UInt8] {
        let extents = image.descriptor.shape.extents
        return try image.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
    }

    @Test("[Unit][VOX-MPR-003][VOX-SPA-004] the diagonal fixture samples exactly")
    func diagonalFixtureSamplesExactly() async throws {
        // The frozen ALG-0017 diagonal request over the affine-field
        // volume: trilinear reduction reproduces the field exactly,
        // and the output claims the request geometry verbatim.
        let request = try geometry(
            elements: [
                0.5, 0, 1, 0.5,
                0.5, 0, -1, 0.5,
                0, 1, 0, 0.5,
                0, 0, 0, 1,
            ],
            imageAxes: [0, 1]
        )
        let output = try await execute(
            try volume(geometry: try identityVolumeGeometry()),
            request: request,
            width: 2,
            height: 2
        )
        #expect(try bytes(output) == [13, 17, 31, 35])
        #expect(output.descriptor.spatialGeometry == .affine(request))
        #expect(output.descriptor.shape.extents == [2, 2])
        #expect(output.identity.derivation != nil)
        guard case .operation(let operation, _) = output.provenance.activity else {
            #expect(Bool(false), "Expected operation provenance.")
            return
        }
        #expect(
            operation.operationID.rawValue
                == ObliqueSliceOperation.operationIdentifier
        )
        guard case .graphNode(let parent)? = output.provenance.inputs.first?.parent
        else {
            #expect(Bool(false), "Expected a graph-node parent edge.")
            return
        }
        #expect(parent.rawValue == "record-in")
    }

    @Test("[Unit][VOX-MPR-003] padding, border and rounding fixtures hold")
    func paddingBorderAndRoundingFixturesHold() async throws {
        // The remaining frozen fixtures: out-of-support padding is
        // exactly zero, a border coordinate replicates the border
        // sample, and the one-third weight rounds half-to-even.
        let input = try volume(geometry: try identityVolumeGeometry())
        let padded = try await execute(
            input,
            request: try pointRequest(origin: (-5, 0, 0)),
            width: 1,
            height: 1
        )
        #expect(try bytes(padded) == [0])
        let border = try await execute(
            input,
            request: try pointRequest(origin: (-0.25, 1, 0)),
            width: 1,
            height: 1
        )
        #expect(try bytes(border) == [6])
        let thirds = try await execute(
            input,
            request: try pointRequest(origin: (1.0 / 3.0, 0, 0)),
            width: 1,
            height: 1
        )
        #expect(try bytes(thirds) == [1])
    }

    @Test("[Unit][VOX-MPR-003][VOX-MPR-004] integer coordinates reproduce the stored plane")
    func integerCoordinatesReproduceTheStoredPlane() async throws {
        // The axial plane at index two as an oblique request: every
        // sample lands on an integer in-support coordinate and the
        // stored bytes reproduce exactly.
        let output = try await execute(
            try volume(geometry: try identityVolumeGeometry()),
            request: try pointRequest(origin: (0, 0, 2)),
            width: 3,
            height: 3
        )
        #expect(
            try bytes(output) == [36, 38, 40, 42, 44, 46, 48, 50, 52]
        )
    }

    @Test("[Unit][VOX-ERR-001] oblique admissions reject typed")
    func obliqueAdmissionsRejectTyped() async throws {
        let calibrated = try volume(geometry: try identityVolumeGeometry())
        let request = try pointRequest(origin: (0, 0, 0))
        await #expect(throws: ObliqueSliceError.volumeNotSpatiallyCalibrated) {
            _ = try await self.execute(
                try self.volume(geometry: nil),
                request: request,
                width: 1,
                height: 1
            )
        }
        await #expect(throws: ObliqueSliceError.unsupportedVolumeMapping) {
            _ = try await self.execute(
                try self.volume(
                    geometry: .affine(
                        try self.geometry(
                            elements: [
                                1, 0, 0, 0,
                                0, 1, 0, 0,
                                0, 0, 1, 0,
                                0, 0, 0, 1,
                            ],
                            imageAxes: [0, 1]
                        )
                    )
                ),
                request: request,
                width: 1,
                height: 1
            )
        }
        await #expect(throws: ObliqueSliceError.unsupportedRequestMapping) {
            _ = try await self.execute(
                calibrated,
                request: try self.geometry(
                    elements: [
                        1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1,
                    ],
                    imageAxes: [1, 0]
                ),
                width: 1,
                height: 1
            )
        }
        await #expect(throws: ObliqueSliceError.coordinateSpaceMismatch) {
            _ = try await self.execute(
                calibrated,
                request: try self.geometry(
                    elements: [
                        1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1,
                    ],
                    imageAxes: [0, 1],
                    spaceID: "device"
                ),
                width: 1,
                height: 1
            )
        }
        await #expect(throws: ObliqueSliceError.invalidOutputExtent) {
            _ = try await self.execute(
                calibrated,
                request: request,
                width: 0,
                height: 1
            )
        }
        await #expect(throws: ObliqueSliceError.unsupportedLayerFormat) {
            _ = try await self.execute(
                try self.volume(extents: [3, 3], geometry: nil),
                request: request,
                width: 1,
                height: 1
            )
        }
    }
}
