// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("RegionExtractionOperation")
struct RegionExtractionOperationTests {
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

    private func descriptor(
        geometry: SpatialGeometry? = nil,
        sampling: AxisSampling = .indexOnly
    ) throws -> ImageDescriptor {
        try ImageDescriptor(
            shape: try ImageShape(extents: [4, 3]),
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
            valueTransform: nil,
            units: nil
        )
    }

    private func input(
        geometry: SpatialGeometry? = nil,
        sampling: AxisSampling = .indexOnly
    ) throws -> ImageData {
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .uint8,
            componentCount: 1
        )
        return try ImageData(
            descriptor: try descriptor(geometry: geometry, sampling: sampling),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: binding,
                    bytes: Array(0..<12)
                )
            ),
            metadata: try MetadataCollection(entries: [
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: "org.voxelia",
                        name: "modality"
                    ),
                    value: .string("CT"),
                    privacyClass: .technical
                )
            ]),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "series-7"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "series-7")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: Array(0..<12)
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.2",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func execute(
        input: ImageData,
        region: ImageRegion,
        budget: UInt64 = 64
    ) async throws -> ImageData {
        try await RegionExtractionOperation.execute(
            input: input,
            region: region,
            outputObjectID: try #require(DataObjectID(rawValue: "series-8")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:05:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: budget
            )
        )
    }

    @Test("[Unit][VOX-EXE-002][VOX-IMG-001] the crop is byte-exact end to end")
    func cropIsByteExactEndToEnd() async throws {
        let source = try input()
        let region = try ImageRegion(lowerBounds: [1, 0], upperBounds: [3, 2])
        let output = try await execute(input: source, region: region)

        // The output bytes are exactly the packed region samples, and
        // the descriptor keeps every per-sample property with the
        // region's shape.
        #expect(output.descriptor.shape == (try ImageShape(extents: [2, 2])))
        let outputBytes = try output.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [2, 2])
        ).bytes
        #expect(outputBytes == [1, 2, 5, 6])
        #expect(output.descriptor.scalarFormat == source.descriptor.scalarFormat)
        #expect(output.metadata == source.metadata)

        // The content identity covers the exact output bytes, and the
        // parameter digest reproduces from the frozen schema
        // independently.
        #expect(
            output.identity.contentID
                == (try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [1, 2, 5, 6]
                ))
        )
        let expectedParameters = try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: "org.voxelia.op.extract-region",
                    name: "lower-bounds"
                ),
                value: .array(
                    try MetadataArray(values: [.signedInteger(1), .signedInteger(0)])
                ),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: "org.voxelia.op.extract-region",
                    name: "upper-bounds"
                ),
                value: .array(
                    try MetadataArray(values: [.signedInteger(3), .signedInteger(2)])
                ),
                privacyClass: .technical
            ),
        ])
        let expectedDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: expectedParameters,
                maximumOutputByteCount: 65_536
            )
        )
        let derivation = try #require(output.identity.derivation)
        #expect(derivation.parameterDigest == expectedDigest)
        #expect(
            derivation.operationID.rawValue == "org.voxelia.op.extract-region"
        )
        #expect(
            derivation.inputs
                == [
                    DerivationInput(
                        role: try DerivationInputRole(rawValue: "input"),
                        identity: .object(source.identity.objectID)
                    )
                ]
        )

        // The provenance record binds the output subject, the input
        // edge and the parent edge; both records admit into one
        // complete graph of depth two.
        #expect(output.provenance.kind == .transformed)
        #expect(output.provenance.subject == .object(output.identity.objectID))
        #expect(output.provenance.inputs.count == 1)
        #expect(
            output.provenance.inputs[0].parent
                == .graphNode(source.provenance.id)
        )
        guard case .operation(let operation, let claim) = output.provenance.activity
        else {
            #expect(Bool(false), "Expected an operation activity.")
            return
        }
        #expect(operation.parameterDigest == expectedDigest)
        #expect(claim.approximationStatus == .exact)
        let graph = try ProvenanceGraph.admitCompleteGraph(
            records: [source.provenance, output.provenance],
            roots: [output.provenance.id],
            limits: try ProvenanceGraphLimits(
                maximumRecordCount: 4,
                maximumParentEdgeCount: 4,
                maximumAncestryDepth: 4,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            )
        )
        #expect(graph.maximumResolvedAncestryDepth == 2)
        #expect(graph.authority == .complete)

        // Repeated execution is byte-identical and identity-identical.
        let repeated = try await execute(input: source, region: region)
        #expect(repeated.identity.contentID == output.identity.contentID)
        #expect(repeated.provenance == output.provenance)

        requireSendable(RegionExtractionError.self)
    }

    @Test("[Unit][VOX-EXE-006][VOX-ERR-001] admission and budgets reject typed")
    func admissionAndBudgetsRejectTyped() async throws {
        let region = try ImageRegion(lowerBounds: [1, 0], upperBounds: [3, 2])

        // The ADR-0071 origin shifts: the affine translation and the
        // regular origin update per VOXELIA-ALG-0006 so every extracted
        // sample keeps its source position; the rotation-scale block,
        // spacing, mapped axes and coordinate space are unchanged.
        let space = try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
        let affine = try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
            indexToWorld: try Matrix4x4Double(elements: [
                0, -2, 0, 10,
                2, 0, 0, 20,
                0, 0, 1, 30,
                0, 0, 0, 1,
            ]),
            coordinateSpace: space
        )
        let calibrated = try await execute(
            input: try input(
                geometry: .affine(affine),
                sampling: .regular(origin: 5, spacing: 2.5)
            ),
            region: region
        )
        guard
            case .affine(let shifted)? = calibrated.descriptor.spatialGeometry
        else {
            #expect(Bool(false), "Expected the affine geometry to be preserved.")
            return
        }
        #expect(
            shifted.indexToWorld.elements
                == [
                    0, -2, 0, 10,
                    2, 0, 0, 22,
                    0, 0, 1, 30,
                    0, 0, 0, 1,
                ]
        )
        #expect(shifted.spatialAxes == affine.spatialAxes)
        #expect(shifted.coordinateSpace == affine.coordinateSpace)
        #expect(
            calibrated.descriptor.axes[0].sampling
                == .regular(origin: 7.5, spacing: 2.5)
        )
        #expect(calibrated.descriptor.axes[1].sampling == .indexOnly)
        #expect(
            calibrated.identity.derivation?.operationVersion
                == (try SemanticVersion(major: 1, minor: 1, patch: 0))
        )

        // Slicing other sampling payloads is a different model.
        do {
            _ = try await execute(
                input: try input(sampling: .externallyDefined(identifier: "ext-1")),
                region: region
            )
            #expect(Bool(false), "Expected external sampling to be rejected.")
        } catch RegionExtractionError.unsupportedAxisSampling {}

        // Region validity stays owned by the read-transaction rules,
        // and the coordinator budget stays authoritative.
        do {
            _ = try await execute(
                input: try input(),
                region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [9, 9])
            )
            #expect(Bool(false), "Expected an invalid region to be rejected.")
        } catch StorageContractError.invalidRegion {}
        do {
            _ = try await execute(input: try input(), region: region, budget: 2)
            #expect(Bool(false), "Expected an insufficient budget to be rejected.")
        } catch StorageContractError.resourceLimitExceeded {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
