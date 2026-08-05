// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaMetal

@Suite("MetalCompositeLayersOperation")
struct MetalCompositeLayersOperationTests {
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

    private func axis(_ id: String) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: .spatialX,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func layer(
        bytes: [UInt8],
        name: String,
        valueTransform: ValueTransform? = nil
    ) throws -> ImageData {
        try ImageData(
            descriptor: try ImageDescriptor(
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
                axes: [try axis("x"), try axis("y")],
                spatialGeometry: nil,
                valueTransform: valueTransform,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: try ImageShape(extents: [4, 3]),
                        scalarType: .uint8,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-\(name)")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T05:50:00Z"),
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
        opacities: [Double],
        kernel: MetalCompositeKernel,
        suffix: String
    ) async throws -> ImageData {
        try await MetalCompositeLayersOperation.execute(
            layers: layers,
            opacities: opacities,
            outputObjectID: try #require(DataObjectID(rawValue: "blend-\(suffix)")),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "record-blend-\(suffix)")
            ),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T05:55:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64),
            kernel: kernel
        )
    }

    @Test("[Integration][VOX-EXE-002][VOX-PLT-013] the device composite carries honest claims")
    func deviceCompositeCarriesHonestClaims() async throws {
        let kernel = try MetalCompositeKernel(
            context: try MetalExecutionContext()
        )
        let first = try layer(bytes: Self.layerA, name: "series-a")
        let second = try layer(bytes: Self.layerB, name: "series-b")

        // The device operation stays within one display level of the
        // registered CPU implementation over the fixture scene, with
        // the measured count printed as evidence.
        let device = try await execute(
            layers: [first, second],
            opacities: [1.0, 0.5],
            kernel: kernel,
            suffix: "gpu"
        )
        let reference = try await CompositeLayersOperation.execute(
            layers: [first, second],
            opacities: [1.0, 0.5],
            outputObjectID: try #require(DataObjectID(rawValue: "blend-cpu")),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "record-blend-cpu")
            ),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T05:55:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
        let region = try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        let deviceBytes = try device.storage.read(region: region).bytes
        let referenceBytes = try reference.storage.read(region: region).bytes
        #expect(deviceBytes.count == referenceBytes.count)
        let exactCount = zip(deviceBytes, referenceBytes).count(where: ==)
        for (produced, expected) in zip(deviceBytes, referenceBytes) {
            #expect(abs(Int(produced) - Int(expected)) <= 1)
        }
        print(
            "ADR-0098 differential evidence: \(exactCount)/\(referenceBytes.count) "
                + "device samples exactly match the CPU implementation on this device."
        )

        // The honest device claim, the metal implementation reference
        // and the one shared parameter authority.
        guard case .operation(let operation, let claim) = device.provenance.activity
        else {
            #expect(Bool(false), "Expected an operation activity.")
            return
        }
        #expect(
            operation.implementationID.rawValue
                == "org.voxelia.impl.composite-layers.metal"
        )
        #expect(
            operation.operationID.rawValue == "org.voxelia.op.composite-layers"
        )
        #expect(
            claim.precisionPolicy.rawValue == "org.voxelia.precision.binary32-device"
        )
        #expect(claim.approximationStatus == .approximate)
        #expect(
            claim.kernel?.identifier.rawValue == "org.voxelia.kernel.composite-layers"
        )
        #expect(
            claim.capabilityClass?.rawValue == "org.voxelia.capability.metal3"
        )
        #expect(
            operation.parameterDigest
                == reference.identity.derivation?.parameterDigest
        )
        #expect(device.provenance.inputs.count == 2)
    }

    @Test("[Integration][VOX-ERR-001] device composite admission rejects typed")
    func deviceCompositeAdmissionRejectsTyped() async throws {
        let kernel = try MetalCompositeKernel(
            context: try MetalExecutionContext()
        )
        let first = try layer(bytes: Self.layerA, name: "series-a")

        // A transformed layer and an out-of-range opacity reject typed
        // through the operation's own admission surface.
        do {
            let transformed = try layer(
                bytes: Self.layerB,
                name: "series-t",
                valueTransform: .identity
            )
            _ = try await execute(
                layers: [first, transformed],
                opacities: [1.0, 0.5],
                kernel: kernel,
                suffix: "reject-1"
            )
            #expect(Bool(false), "Expected a value transform to be rejected.")
        } catch CompositeError.unsupportedLayerFormat {}
        do {
            _ = try await execute(
                layers: [first],
                opacities: [1.5],
                kernel: kernel,
                suffix: "reject-2"
            )
            #expect(Bool(false), "Expected an out-of-range opacity to be rejected.")
        } catch CompositeError.invalidOpacity {}
    }
}
