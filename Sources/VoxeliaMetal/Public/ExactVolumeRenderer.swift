// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by volume-render admission.
///
/// Cases deliberately carry no payload; the generator's and sampler's
/// own typed admissions propagate unchanged.
public enum VolumeRenderError: Error, Sendable, Equatable {
    case volumeNotPublished
    case unsupportedLayerFormat
    case volumeNotSpatiallyCalibrated
}

/// The deterministic CPU volume renderer per `ADR-0175` — the
/// sibling surface beside the slice renderers.
///
/// Per pixel: the accepted generator's ray, the accepted sampler's
/// plan, the one public sampling authority at each midpoint, and the
/// accepted compositor. The rendered image is presentation, never a
/// source of authoritative quantitative measurement, per the arc's
/// binding rule; determinism is structural — every composed model is
/// a pure frozen function.
public final class ExactVolumeRenderer: Sendable {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.volume-render"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.volume-render.cpu"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    private let publisher: PublicationCoordinator
    private let readCoordinator: StorageReadCoordinator
    private let software: SoftwareIdentity

    public init(
        publisher: PublicationCoordinator,
        readCoordinator: StorageReadCoordinator,
        software: SoftwareIdentity
    ) {
        self.publisher = publisher
        self.readCoordinator = readCoordinator
        self.software = software
    }

    /// Renders one volume scene and publishes the four-component
    /// output.
    ///
    /// - Throws: ``VolumeRenderError``, the generator's, sampler's
    ///   and map's own typed admissions, or the audited typed errors
    ///   of the storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public func render(
        _ request: VolumeRenderRequest,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant
    ) async throws -> RenderResult {
        guard
            let volume = await publisher.publishedImage(
                for: request.volumeObjectID
            )
        else {
            throw VolumeRenderError.volumeNotPublished
        }
        let extents = volume.descriptor.shape.extents
        guard
            extents.count == 3,
            volume.descriptor.scalarFormat.type == .uint8,
            volume.descriptor.components.count == 1,
            volume.descriptor.components.interpretation == .scalar,
            volume.descriptor.semantic == .intensity,
            volume.descriptor.valueTransform == nil
        else {
            throw VolumeRenderError.unsupportedLayerFormat
        }
        guard case .affine(let geometry)? = volume.descriptor.spatialGeometry
        else {
            throw VolumeRenderError.volumeNotSpatiallyCalibrated
        }

        let generator = try OrthographicRayGenerator(
            camera: request.camera,
            viewport: request.viewport
        )
        let sampler = try VolumeRaySampler(
            geometry: geometry,
            extents: extents,
            quality: request.quality
        )

        // One budgeted coordinated full read; the retention is
        // released as soon as the owned bytes are staged.
        let fullRegion = try ImageRegion(
            lowerBounds: [0, 0, 0],
            upperBounds: extents
        )
        let read = try await readCoordinator.read(
            from: volume.storage,
            region: fullRegion
        )
        let storedBytes = read.result.bytes
        try await readCoordinator.release(read.retention)

        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(
            request.viewport.width * request.viewport.height * 4
        )
        for pixelY in 0..<request.viewport.height {
            for pixelX in 0..<request.viewport.width {
                let ray = try generator.ray(atPixelX: pixelX, pixelY: pixelY)
                let plan = try sampler.plan(for: ray)
                var samples = [UInt8]()
                samples.reserveCapacity(plan.sampleCount)
                for index in 0..<plan.sampleCount {
                    samples.append(
                        ObliqueSliceOperation.sample(
                            Array(plan.indexPosition(at: index)),
                            extents: extents,
                            bytes: storedBytes
                        )
                    )
                }
                let composited = VolumeRayCompositor.composite(
                    samples: samples,
                    table: request.table
                )
                outputBytes.append(composited.red)
                outputBytes.append(composited.green)
                outputBytes.append(composited.blue)
                outputBytes.append(composited.alpha)
            }
        }

        let outputShape = try ImageShape(
            extents: [request.viewport.width, request.viewport.height]
        )
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: outputShape,
                    scalarType: .uint8,
                    componentCount: 4
                ),
                bytes: outputBytes
            )
        )
        let outputDescriptor = try ImageDescriptor(
            shape: outputShape,
            scalarFormat: try ScalarFormat(
                type: .uint8,
                validBitCount: nil,
                byteOrder: .native
            ),
            components: try ComponentDescriptor(
                count: 4,
                interpretation: .rgba,
                layout: .interleaved,
                componentNames: nil
            ),
            semantic: .colour,
            axes: [
                try Self.outputAxis("u", semantic: .spatialX),
                try Self.outputAxis("v", semantic: .spatialY),
            ],
            spatialGeometry: nil,
            valueTransform: nil,
            units: nil
        )

        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try Self.parameterCollection(request: request),
                maximumOutputByteCount: Self.parameterDocumentByteCeiling
            )
        )
        let version = try SemanticVersion(major: 1, minor: 0, patch: 0)
        let operationToken = try DerivationOperationToken(
            rawValue: Self.operationIdentifier
        )
        let implementationToken = try DerivationOperationToken(
            rawValue: Self.implementationIdentifier
        )
        let derivation = try DerivationIdentity(
            operationID: operationToken,
            operationVersion: version,
            implementation: DerivationImplementationReference(
                identifier: implementationToken,
                version: version
            ),
            inputs: [
                DerivationInput(
                    role: try DerivationInputRole(rawValue: "input"),
                    identity: .object(volume.identity.objectID)
                )
            ],
            parameterDigest: parameterDigest,
            declaresZeroInputGenerator: false
        )
        let outputIdentity = try DataIdentity(
            objectID: outputObjectID,
            contentID: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: outputBytes
            ),
            sourceIdentities: [],
            derivation: derivation
        )
        let provenance = try ProvenanceRecord(
            id: outputProvenanceID,
            kind: .transformed,
            createdAt: createdAt,
            subject: .object(outputObjectID),
            software: software,
            activity: .operation(
                try OperationProvenance(
                    operationID: operationToken,
                    operationVersion: version,
                    implementationID: implementationToken,
                    implementationVersion: version,
                    parameterDigest: parameterDigest
                ),
                try Self.executionClaim(version: version)
            ),
            inputs: [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "input"),
                    occurrence: 1,
                    identity: .object(volume.identity.objectID),
                    parent: .graphNode(volume.provenance.id)
                )
            ],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
        let output = try ImageData(
            descriptor: outputDescriptor,
            storage: outputStorage,
            metadata: volume.metadata,
            provenance: provenance,
            identity: outputIdentity
        )
        _ = try await publisher.publish(output, mode: .complete)

        // The assessed claim shape: an empty layer list, because the
        // layer vocabulary's transfer function is the windowed slice
        // claim and fabricating a window that never ran would
        // misreport; the volume scene's inputs live in the operation
        // parameters.
        let presentation = PresentationProvenance(
            camera: request.camera,
            viewport: request.viewport,
            layers: [],
            crop: nil,
            geometry: .affine(geometry),
            scaling: .identity,
            renderMode: .volumeDirect,
            colourOutput: .rgba8,
            accumulation: .none,
            denoising: .none
        )
        return RenderResult(
            outputObjectID: outputObjectID,
            presentation: presentation
        )
    }

    /// The full reproduction recipe: the table bytes, the camera, the
    /// viewport and the quality token.
    static func parameterCollection(
        request: VolumeRenderRequest
    ) throws -> MetadataCollection {
        var tableBytes = ContiguousArray<UInt8>()
        tableBytes.reserveCapacity(TransferFunction1D.tableSize * 4)
        for entry in request.table.entries {
            tableBytes.append(entry.red)
            tableBytes.append(entry.green)
            tableBytes.append(entry.blue)
            tableBytes.append(entry.opacity)
        }
        var entries = [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "transfer-table"
                ),
                value: .binary(MetadataBinary(bytes: tableBytes)),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "quality"
                ),
                value: .string(request.quality),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "viewport-width"
                ),
                value: .signedInteger(Int64(request.viewport.width)),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "viewport-height"
                ),
                value: .signedInteger(Int64(request.viewport.height)),
                privacyClass: .technical
            ),
        ]
        let camera = request.camera
        var cameraComponents: [(String, Double)] = [
            ("camera-position-x", camera.position.x),
            ("camera-position-y", camera.position.y),
            ("camera-position-z", camera.position.z),
            ("camera-target-x", camera.target.x),
            ("camera-target-y", camera.target.y),
            ("camera-target-z", camera.target.z),
            ("camera-up-x", camera.up.x),
            ("camera-up-y", camera.up.y),
            ("camera-up-z", camera.up.z),
        ]
        if case .orthographic(let planeHeight) = camera.projection {
            cameraComponents.append(("camera-plane-height", planeHeight))
        }
        for (name, value) in cameraComponents {
            entries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: name
                    ),
                    value: .floatingPoint(try MetadataFloatingPoint(value: value)),
                    privacyClass: .technical
                )
            )
        }
        return try MetadataCollection(entries: entries)
    }

    private static func executionClaim(
        version: SemanticVersion
    ) throws -> ExecutionProvenanceClaim {
        ExecutionProvenanceClaim(
            profile: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.profile.default"
                ),
                version: version
            ),
            backend: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.backend.cpu"
                ),
                version: version
            ),
            precisionPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.precision.binary64-strict"
            ),
            qualityPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.quality.full"
            ),
            approximationStatus: .exact,
            capabilityClass: nil,
            kernel: nil
        )
    }

    private static func outputAxis(
        _ name: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: name) else {
            throw VolumeRenderError.unsupportedLayerFormat
        }
        return try AxisDescriptor(
            id: axisID,
            name: name,
            semantic: semantic,
            unit: nil,
            sampling: .indexOnly
        )
    }
}
