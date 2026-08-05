// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("CompositeLayersOperation")
struct CompositeLayersOperationTests {
    private static let layerA: [UInt8] = [
        0, 0, 0, 36, 73, 109, 146, 182, 219, 255, 255, 255,
    ]
    private static let layerB: [UInt8] = [
        0, 51, 102, 153, 204, 255, 255, 255, 255, 255, 255, 255,
    ]

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func axis(
        _ id: String,
        sampling: AxisSampling = .indexOnly
    ) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: .spatialX,
            unit: nil,
            sampling: sampling
        )
    }

    private func layer(
        bytes: [UInt8],
        name: String,
        extents: [Int] = [4, 3],
        sampling: AxisSampling = .indexOnly,
        valueTransform: ValueTransform? = nil,
        geometry: SpatialGeometry? = nil
    ) throws -> ImageData {
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: ContiguousArray(extents)),
            scalarType: .uint8,
            componentCount: 1
        )
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
                axes: [try axis("x", sampling: sampling), try axis("y")],
                spatialGeometry: geometry,
                valueTransform: valueTransform,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(binding: binding, bytes: bytes)
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-\(name)")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T05:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: name))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: name)),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.\(name)",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func execute(
        layers: [ImageData],
        opacities: [Double]
    ) async throws -> ImageData {
        try await CompositeLayersOperation.execute(
            layers: layers,
            opacities: opacities,
            outputObjectID: try #require(DataObjectID(rawValue: "series-blend")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-blend")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T05:05:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func bytes(_ image: ImageData) throws -> [UInt8] {
        try image.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        ).bytes
    }

    @Test("[Unit][VOX-EXE-002][VOX-IMG-001] the frozen blend reproduces the fixtures")
    func frozenBlendReproducesTheFixtures() async throws {
        // The VOXELIA-ALG-0009 fixtures: half-opacity overlay, the
        // fractional pair, and exact reproduction through opacity one
        // over a fully transparent overlay.
        let first = try layer(bytes: Self.layerA, name: "series-a")
        let second = try layer(bytes: Self.layerB, name: "series-b")
        let half = try await execute(layers: [first, second], opacities: [1.0, 0.5])
        #expect(
            try bytes(half) == [0, 26, 51, 94, 138, 182, 200, 218, 237, 255, 255, 255]
        )
        let fractional = try await execute(
            layers: [first, second],
            opacities: [0.75, 0.25]
        )
        #expect(
            try bytes(fractional)
                == [0, 13, 26, 58, 92, 125, 146, 166, 187, 207, 207, 207]
        )
        let reproduced = try await execute(
            layers: [first, second],
            opacities: [1.0, 0.0]
        )
        #expect(try bytes(reproduced) == Self.layerA)

        // The ADR-0094 single-layer fade: one layer at half opacity
        // over the black background, and the widened versions carried
        // in the recipe.
        let faded = try await execute(layers: [first], opacities: [0.5])
        #expect(
            try bytes(faded) == [0, 0, 0, 18, 36, 54, 73, 91, 110, 128, 128, 128]
        )
        #expect(
            faded.identity.derivation?.operationVersion
                == (try SemanticVersion(major: 1, minor: 2, patch: 0))
        )

        // The parameter digest reproduces independently, and the
        // output admits into a complete graph with both layer parents.
        let expectedDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try CompositeLayersOperation.parameterCollection(
                    opacities: [1.0, 0.5]
                ),
                maximumOutputByteCount: 65_536
            )
        )
        #expect(half.identity.derivation?.parameterDigest == expectedDigest)
        #expect(half.provenance.inputs.count == 2)
        let graph = try ProvenanceGraph.admitCompleteGraph(
            records: [first.provenance, second.provenance, half.provenance],
            roots: [half.provenance.id],
            limits: try ProvenanceGraphLimits(
                maximumRecordCount: 8,
                maximumParentEdgeCount: 8,
                maximumAncestryDepth: 8,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            )
        )
        #expect(graph.maximumResolvedAncestryDepth == 2)
        #expect(graph.authority == .complete)

        requireSendable(CompositeError.self)
    }

    @Test("[Unit][VOX-EXE-002][VOX-SPA-013] equal calibration blends and passes through")
    func equalCalibrationBlendsAndPassesThrough() async throws {
        // The ADR-0128 rule: identically calibrated layers blend with
        // the shared axes and geometry carried through untouched, at
        // the widened version.
        let space = try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                dimension: .length
            ),
            externalReferences: []
        )
        func geometry(translationX: Double) throws -> SpatialGeometry {
            .affine(
                try AffineGridGeometry(
                    spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
                    indexToWorld: try Matrix4x4Double(elements: [
                        0, -2, 0, translationX,
                        2, 0, 0, 20,
                        0, 0, 1, 30,
                        0, 0, 0, 1,
                    ]),
                    coordinateSpace: space
                )
            )
        }
        let sampling = AxisSampling.regular(origin: 5, spacing: 2.5)
        let first = try layer(
            bytes: Self.layerA,
            name: "series-a",
            sampling: sampling,
            geometry: try geometry(translationX: 10)
        )
        let second = try layer(
            bytes: Self.layerB,
            name: "series-b",
            sampling: sampling,
            geometry: try geometry(translationX: 10)
        )
        let blended = try await execute(
            layers: [first, second],
            opacities: [1.0, 0.5]
        )
        #expect(
            try bytes(blended) == [0, 26, 51, 94, 138, 182, 200, 218, 237, 255, 255, 255]
        )
        #expect(blended.descriptor.axes == first.descriptor.axes)
        #expect(
            blended.descriptor.spatialGeometry == first.descriptor.spatialGeometry
        )
        #expect(
            blended.identity.derivation?.operationVersion
                == (try SemanticVersion(major: 1, minor: 2, patch: 0))
        )

        // A geometry mismatch rejects typed.
        do {
            let shifted = try layer(
                bytes: Self.layerB,
                name: "series-s",
                sampling: sampling,
                geometry: try geometry(translationX: 11)
            )
            _ = try await execute(layers: [first, shifted], opacities: [1.0, 0.5])
            #expect(Bool(false), "Expected a geometry mismatch to be rejected.")
        } catch CompositeError.layerCalibrationMismatch {}
    }

    @Test("[Unit][VOX-EXE-006][VOX-ERR-001] admission rejects unsupported layers typed")
    func admissionRejectsUnsupportedLayersTyped() async throws {
        let first = try layer(bytes: Self.layerA, name: "series-a")
        let second = try layer(bytes: Self.layerB, name: "series-b")

        // An empty layer list, unequal extents, a value transform,
        // regular sampling and malformed opacity lists reject typed.
        do {
            _ = try await execute(layers: [], opacities: [])
            #expect(Bool(false), "Expected an empty layer list to be rejected.")
        } catch CompositeError.invalidLayerCount {}
        do {
            let narrow = try layer(
                bytes: [0, 1, 2, 3, 4, 5],
                name: "series-c",
                extents: [2, 3]
            )
            _ = try await execute(layers: [first, narrow], opacities: [1.0, 0.5])
            #expect(Bool(false), "Expected unequal extents to be rejected.")
        } catch CompositeError.extentMismatch {}
        do {
            let transformed = try layer(
                bytes: Self.layerB,
                name: "series-d",
                valueTransform: .identity
            )
            _ = try await execute(layers: [first, transformed], opacities: [1.0, 0.5])
            #expect(Bool(false), "Expected a value transform to be rejected.")
        } catch CompositeError.unsupportedLayerFormat {}
        do {
            let regular = try layer(
                bytes: Self.layerB,
                name: "series-e",
                sampling: .regular(origin: 0, spacing: 1)
            )
            _ = try await execute(layers: [first, regular], opacities: [1.0, 0.5])
            #expect(Bool(false), "Expected a calibration mismatch to be rejected.")
        } catch CompositeError.layerCalibrationMismatch {}
        for opacities in [[1.0], [1.0, 1.5], [1.0, -0.1], [1.0, Double.infinity]] {
            do {
                _ = try await execute(layers: [first, second], opacities: opacities)
                #expect(Bool(false), "Expected a malformed opacity list to be rejected.")
            } catch CompositeError.invalidOpacity {}
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
