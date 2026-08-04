// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("WindowLevelOperation")
struct WindowLevelOperationTests {
    private let int16LittleEndianBytes: [UInt8] = [
        0, 252, 56, 255, 156, 255, 0, 0, 20, 0, 40, 0,
        60, 0, 80, 0, 120, 0, 200, 0, 232, 3, 184, 11,
    ]

    private func axis(_ id: String) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: .spatialX,
            unit: nil,
            sampling: .indexOnly
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

    private func input(
        scalarType: ScalarType = .uint8,
        bytes: [UInt8]? = nil,
        semantic: ImageSemantic = .intensity,
        componentCount: Int = 1,
        interpretation: ComponentInterpretation = .scalar,
        valueTransform: ValueTransform? = nil
    ) throws -> ImageData {
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: scalarType,
            componentCount: componentCount
        )
        let storedBytes =
            bytes ?? Array(0..<UInt8(truncatingIfNeeded: binding.logicalByteCount))
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: [4, 3]),
                scalarFormat: try ScalarFormat(
                    type: scalarType,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: componentCount,
                    interpretation: interpretation,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: semantic,
                axes: [try axis("x"), try axis("y")],
                spatialGeometry: nil,
                valueTransform: valueTransform,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: binding,
                    bytes: storedBytes
                )
            ),
            metadata: try MetadataCollection(entries: [
                MetadataEntry(
                    key: try AnyMetadataKey(namespace: "org.voxelia", name: "modality"),
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
                    overCanonicalPackedBytes: storedBytes
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

    private func execute(
        input: ImageData,
        center: Double,
        width: Double,
        budget: UInt64 = 64
    ) async throws -> ImageData {
        try await WindowLevelOperation.execute(
            input: input,
            center: try MetadataFloatingPoint(value: center),
            width: try MetadataFloatingPoint(value: width),
            outputObjectID: try #require(DataObjectID(rawValue: "series-8")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:05:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: budget
            )
        )
    }

    private func outputBytes(_ image: ImageData) throws -> [UInt8] {
        try image.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        ).bytes
    }

    @Test("[Unit][VOX-EXE-002][VOX-IMG-001] the frozen model reproduces every fixture")
    func frozenModelReproducesEveryFixture() async throws {
        // The uint8 conformance fixture of VOXELIA-ALG-0002.
        let displayInput = try input()
        let display = try await execute(input: displayInput, center: 6, width: 8)
        #expect(
            try outputBytes(display)
                == [0, 0, 0, 36, 73, 109, 146, 182, 219, 255, 255, 255]
        )
        #expect(display.descriptor.scalarFormat.type == .uint8)
        #expect(display.descriptor.shape == displayInput.descriptor.shape)
        #expect(display.descriptor.units == nil)
        #expect(display.metadata == displayInput.metadata)

        // The int16 CT fixture and the degenerate unit-width threshold,
        // both assembled under the declared byte order.
        let ctInput = try input(scalarType: .int16, bytes: int16LittleEndianBytes)
        let softTissue = try await execute(input: ctInput, center: 40, width: 400)
        #expect(
            try outputBytes(softTissue)
                == [0, 0, 38, 102, 115, 128, 141, 153, 179, 230, 255, 255]
        )
        let threshold = try await execute(input: ctInput, center: 40, width: 1)
        #expect(
            try outputBytes(threshold)
                == [0, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255]
        )

        // The revision-1.1 uint16 fixture registered by ADR-0068.
        let uint16Input = try input(
            scalarType: .uint16,
            bytes: [
                0, 0, 100, 0, 244, 1, 232, 3, 208, 7, 160, 15,
                64, 31, 128, 62, 0, 125, 128, 187, 96, 234, 255, 255,
            ]
        )
        let unsignedWide = try await execute(
            input: uint16Input,
            center: 32_000,
            width: 64_000
        )
        #expect(
            try outputBytes(unsignedWide)
                == [0, 0, 2, 4, 8, 16, 32, 64, 128, 191, 239, 255]
        )
        #expect(
            unsignedWide.identity.derivation?.operationVersion
                == (try SemanticVersion(major: 1, minor: 3, patch: 0))
        )

        // The parameter digest reproduces independently from the frozen
        // schema, and the recipe, record and graph bind exactly as in
        // the first operation.
        let expectedDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: [
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: "org.voxelia.op.window-level",
                            name: "center"
                        ),
                        value: .floatingPoint(try MetadataFloatingPoint(value: 40)),
                        privacyClass: .technical
                    ),
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: "org.voxelia.op.window-level",
                            name: "width"
                        ),
                        value: .floatingPoint(try MetadataFloatingPoint(value: 400)),
                        privacyClass: .technical
                    ),
                ]),
                maximumOutputByteCount: 65_536
            )
        )
        let derivation = try #require(softTissue.identity.derivation)
        #expect(derivation.parameterDigest == expectedDigest)
        #expect(derivation.operationID.rawValue == "org.voxelia.op.window-level")
        #expect(
            softTissue.identity.contentID
                == (try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: try outputBytes(softTissue)
                ))
        )
        #expect(softTissue.provenance.kind == .transformed)
        #expect(
            softTissue.provenance.inputs[0].parent
                == .graphNode(ctInput.provenance.id)
        )
        let graph = try ProvenanceGraph.admitCompleteGraph(
            records: [ctInput.provenance, softTissue.provenance],
            roots: [softTissue.provenance.id],
            limits: try ProvenanceGraphLimits(
                maximumRecordCount: 4,
                maximumParentEdgeCount: 4,
                maximumAncestryDepth: 4,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            )
        )
        #expect(graph.authority == .complete)
        #expect(graph.maximumResolvedAncestryDepth == 2)

        // Repeated execution is bit-identical.
        let repeated = try await execute(input: ctInput, center: 40, width: 400)
        #expect(repeated.identity.contentID == softTissue.identity.contentID)
        #expect(repeated.provenance == softTissue.provenance)

        requireSendable(WindowLevelError.self)
    }

    @Test("[Unit][VOX-EXE-002][VOX-DAT-014] the composition rule reproduces real-domain fixtures")
    func compositionRuleReproducesRealDomainFixtures() async throws {
        // The VOXELIA-ALG-0003 CT rescale fixture: rescaled stored
        // values windowed in the Hounsfield domain reproduce the exact
        // VOXELIA-ALG-0002 real-domain outputs.
        let rescale = ValueTransform.linear(
            try LinearValueTransformDescriptor(scale: 1, offset: -1024)
        )
        let ctStored: [UInt8] = [
            0, 0, 56, 3, 156, 3, 0, 4, 20, 4, 40, 4,
            60, 4, 80, 4, 120, 4, 200, 4, 232, 7, 184, 15,
        ]
        let hounsfield = try await execute(
            input: try input(
                scalarType: .int16,
                bytes: ctStored,
                valueTransform: rescale
            ),
            center: 40,
            width: 400
        )
        #expect(
            try outputBytes(hounsfield)
                == [0, 0, 38, 102, 115, 128, 141, 153, 179, 230, 255, 255]
        )

        // The fractional-scale fixture exercises non-integral real
        // values.
        let fractional = try await execute(
            input: try input(
                valueTransform: .linear(
                    try LinearValueTransformDescriptor(scale: 0.5, offset: -2)
                )
            ),
            center: 1,
            width: 4
        )
        #expect(
            try outputBytes(fractional)
                == [0, 0, 0, 43, 85, 128, 170, 212, 255, 255, 255, 255]
        )

        // The identity transform is bit-identical to the absent
        // transform, and the extended contract carries the advanced
        // version tokens.
        let absent = try await execute(input: try input(), center: 6, width: 8)
        let identity = try await execute(
            input: try input(valueTransform: .identity),
            center: 6,
            width: 8
        )
        #expect(try outputBytes(identity) == (try outputBytes(absent)))
        #expect(identity.identity.contentID == absent.identity.contentID)
        // The ADR-0069 lookup-table fixture: below-clamp, in-range
        // including a fractional output, and above-clamp, windowed in
        // the table's output domain.
        let tableMapped = try await execute(
            input: try input(
                valueTransform: .lookupTable(
                    try LookupTableDescriptor(
                        firstMappedValue: 2,
                        values: [-100, 0, 50.5, 200]
                    )
                )
            ),
            center: 25,
            width: 300
        )
        #expect(
            try outputBytes(tableMapped)
                == [21, 21, 21, 107, 150, 255, 255, 255, 255, 255, 255, 255]
        )

        let advanced = try SemanticVersion(major: 1, minor: 3, patch: 0)
        let derivation = try #require(hounsfield.identity.derivation)
        #expect(derivation.operationVersion == advanced)
        #expect(derivation.implementation?.version == advanced)
    }

    @Test("[Unit][VOX-EXE-006][VOX-ERR-001] admission and budgets reject typed")
    func admissionAndBudgetsRejectTyped() async throws {
        // A width below one is a typed rejection, never a substitution.
        do {
            _ = try await execute(input: try input(), center: 6, width: 0.5)
            #expect(Bool(false), "Expected a sub-one width to be rejected.")
        } catch WindowLevelError.invalidWindowWidth {}

        // Unsupported scalar types, component layouts, semantics and
        // value transforms each reject with their own case.
        do {
            _ = try await execute(
                input: try input(
                    scalarType: .int32,
                    bytes: Array(repeating: 0, count: 48)
                ),
                center: 6,
                width: 8
            )
            #expect(Bool(false), "Expected an unsupported scalar type to be rejected.")
        } catch WindowLevelError.unsupportedScalarType {}
        do {
            _ = try await execute(
                input: try input(
                    bytes: Array(repeating: 0, count: 24),
                    componentCount: 2,
                    interpretation: .vector
                ),
                center: 6,
                width: 8
            )
            #expect(Bool(false), "Expected a non-scalar layout to be rejected.")
        } catch WindowLevelError.unsupportedComponentLayout {}
        do {
            _ = try await execute(
                input: try input(semantic: .mask),
                center: 6,
                width: 8
            )
            #expect(Bool(false), "Expected a non-intensity semantic to be rejected.")
        } catch WindowLevelError.unsupportedSemantic {}
        do {
            _ = try await execute(
                input: try input(
                    valueTransform: .composed(
                        try ValueTransformComposition(transforms: [.identity])
                    )
                ),
                center: 6,
                width: 8
            )
            #expect(Bool(false), "Expected a composed transform to be rejected.")
        } catch WindowLevelError.unsupportedValueTransform {}
        do {
            _ = try await execute(
                input: try input(
                    valueTransform: .lookupTable(
                        try LookupTableDescriptor(firstMappedValue: 0, values: [])
                    )
                ),
                center: 6,
                width: 8
            )
            #expect(Bool(false), "Expected an empty table to be rejected.")
        } catch WindowLevelError.emptyLookupTable {}

        // The coordinator budget stays authoritative, and rejections
        // stay payload-free.
        do {
            _ = try await execute(input: try input(), center: 6, width: 8, budget: 2)
            #expect(Bool(false), "Expected an insufficient budget to be rejected.")
        } catch StorageContractError.resourceLimitExceeded {}
        do {
            _ = try await execute(input: try input(), center: 6, width: 0)
            #expect(Bool(false), "Expected a zero width to be rejected.")
        } catch let error as WindowLevelError {
            #expect(error == .invalidWindowWidth)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("series"))
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
