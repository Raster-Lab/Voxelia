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
    case maskNotPublished
    case maskExtentMismatch
    case unsupportedMaskFormat
    case accelerationExtentMismatch
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
            quality: request.quality,
            clip: request.clip,
            crop: request.crop
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

        // The mask volume, read and validated only when declared: it
        // must share the primary volume's extents and be a
        // single-component byte-labelled format, both typed.
        var maskBytes: [UInt8]?
        if let maskSelection = request.mask {
            guard
                let maskImage = await publisher.publishedImage(
                    for: maskSelection.maskObjectID
                )
            else {
                throw VolumeRenderError.maskNotPublished
            }
            guard maskImage.descriptor.shape.extents == extents else {
                throw VolumeRenderError.maskExtentMismatch
            }
            guard
                maskImage.descriptor.scalarFormat.type == .uint8,
                maskImage.descriptor.components.count == 1,
                maskImage.descriptor.components.interpretation == .scalar,
                maskImage.descriptor.semantic == .label,
                maskImage.descriptor.valueTransform == nil
            else {
                throw VolumeRenderError.unsupportedMaskFormat
            }
            let maskRegion = try ImageRegion(
                lowerBounds: [0, 0, 0],
                upperBounds: extents
            )
            let maskRead = try await readCoordinator.read(
                from: maskImage.storage,
                region: maskRegion
            )
            maskBytes = maskRead.result.bytes
            try await readCoordinator.release(maskRead.retention)
        }

        // The per-brick skippability map, computed once from bytes
        // already resident: a brick is skippable exactly when its
        // accepted BrickStatistics included range has zero opacity at
        // every table entry — declared only once the transfer
        // function is known, never fabricated ahead of it.
        var skippableBricks: [ContiguousArray<Int>: Bool] = [:]
        if let grid = request.acceleration {
            guard grid.volumeExtents == extents else {
                throw VolumeRenderError.accelerationExtentMismatch
            }
            let counts = grid.brickCounts
            let width = extents[0]
            let height = extents[1]
            for k in 0..<counts[2] {
                for j in 0..<counts[1] {
                    for i in 0..<counts[0] {
                        let coordinate: ContiguousArray<Int> = [i, j, k]
                        let core = try grid.coreRegion(of: coordinate)
                        var payload = [UInt8]()
                        for z in core.lowerBounds[2]..<core.upperBounds[2] {
                            for y in core.lowerBounds[1]..<core.upperBounds[1] {
                                for x in core.lowerBounds[0]..<core.upperBounds[0] {
                                    payload.append(
                                        storedBytes[x + width * (y + height * z)]
                                    )
                                }
                            }
                        }
                        let stats = try BrickStatistics(
                            overCorePayload: payload,
                            sentinel: nil
                        )
                        var skippable = true
                        if let lower = stats.includedMinimum,
                            let upper = stats.includedMaximum
                        {
                            skippable = (Int(lower)...Int(upper)).allSatisfy {
                                request.table.entry(at: $0).opacity == 0
                            }
                        }
                        skippableBricks[coordinate] = skippable
                    }
                }
            }
        }

        // The headlight path builds the accepted inverse once; the
        // unshaded path calls the accepted compositor unchanged, so
        // its byte identity is structural.
        let inverse: AffineSpatialInverse? =
            request.lighting == .headlight
            ? try AffineSpatialInverse(spatialPartOf: geometry.indexToWorld)
            : nil
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
                var skipped = [Bool]()
                skipped.reserveCapacity(plan.sampleCount)
                for index in 0..<plan.sampleCount {
                    let position = Array(plan.indexPosition(at: index))
                    var isSkipped = false
                    if let grid = request.acceleration {
                        isSkipped = Self.isSampleSkippable(
                            atIndexPosition: position,
                            extents: extents,
                            grid: grid,
                            skippableBricks: skippableBricks
                        )
                    }
                    skipped.append(isSkipped)
                    samples.append(
                        isSkipped
                            ? 0
                            : ObliqueSliceOperation.sample(
                                position,
                                extents: extents,
                                bytes: storedBytes
                            )
                    )
                }
                var inclusion: [Bool]?
                if request.mask != nil || request.acceleration != nil {
                    var flags = [Bool]()
                    flags.reserveCapacity(plan.sampleCount)
                    for index in 0..<plan.sampleCount {
                        var included = !skipped[index]
                        if included, let maskSelection = request.mask, let maskBytes {
                            let label = VolumeMaskSampler.sample(
                                Array(plan.indexPosition(at: index)),
                                extents: extents,
                                bytes: maskBytes
                            )
                            included = maskSelection.visibleLabels.contains(label)
                        }
                        flags.append(included)
                    }
                    inclusion = flags
                }
                let composited: CompositedRay
                if let inverse {
                    let unitDirection = Self.unitDirection(of: ray)
                    var factors = [Double]()
                    factors.reserveCapacity(plan.sampleCount)
                    for index in 0..<plan.sampleCount {
                        factors.append(
                            skipped[index]
                                ? 1.0
                                : Self.shadingFactor(
                                    atIndexPosition: Array(
                                        plan.indexPosition(at: index)
                                    ),
                                    extents: extents,
                                    bytes: storedBytes,
                                    inverse: inverse,
                                    unitRayDirection: unitDirection
                                )
                        )
                    }
                    if let inclusion {
                        composited = VolumeRayCompositor.composite(
                            samples: samples,
                            shadingFactors: factors,
                            inclusion: inclusion,
                            table: request.table
                        )
                    } else {
                        composited = VolumeRayCompositor.composite(
                            samples: samples,
                            shadingFactors: factors,
                            table: request.table
                        )
                    }
                } else if let inclusion {
                    composited = VolumeRayCompositor.composite(
                        samples: samples,
                        inclusion: inclusion,
                        table: request.table
                    )
                } else {
                    composited = VolumeRayCompositor.composite(
                        samples: samples,
                        table: request.table
                    )
                }
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

    /// The accepted `VOXELIA-ALG-0010` normalisation: the ray
    /// parameter is world distance, so the headlight is the negated
    /// unit direction.
    static func unitDirection(of ray: Ray3D) -> [Double] {
        let dx = ray.direction.x
        let dy = ray.direction.y
        let dz = ray.direction.z
        let norm = (((dx * dx) + (dy * dy)) + (dz * dz)).squareRoot()
        return [dx / norm, dy / norm, dz / norm]
    }

    /// The frozen `VOXELIA-ALG-0025` factor at one sample position:
    /// central differences through the one public sampling authority,
    /// the world gradient through the accepted inverse's transpose,
    /// and the declared headlight Lambert factor — exactly one for a
    /// zero gradient, because shading a surface that does not exist
    /// would fabricate one.
    static func shadingFactor(
        atIndexPosition position: [Double],
        extents: ContiguousArray<Int>,
        bytes: [UInt8],
        inverse: AffineSpatialInverse,
        unitRayDirection: [Double]
    ) -> Double {
        var gradientIndex = [0.0, 0.0, 0.0]
        for axis in 0...2 {
            var forward = position
            var backward = position
            forward[axis] = position[axis] + 1.0
            backward[axis] = position[axis] - 1.0
            let ahead = Double(
                ObliqueSliceOperation.sample(
                    forward,
                    extents: extents,
                    bytes: bytes
                )
            )
            let behind = Double(
                ObliqueSliceOperation.sample(
                    backward,
                    extents: extents,
                    bytes: bytes
                )
            )
            gradientIndex[axis] = (ahead - behind) / 2.0
        }
        var world = [0.0, 0.0, 0.0]
        for row in 0...2 {
            var component = 0.0
            for slot in 0...2 {
                component =
                    component
                    + (inverse.elements[3 * slot + row] * gradientIndex[slot])
            }
            world[row] = component
        }
        let norm =
            (((world[0] * world[0]) + (world[1] * world[1]))
            + (world[2] * world[2]))
            .squareRoot()
        guard norm > 0 else {
            return 1.0
        }
        let normalX = -world[0] / norm
        let normalY = -world[1] / norm
        let normalZ = -world[2] / norm
        let lightX = -unitRayDirection[0]
        let lightY = -unitRayDirection[1]
        let lightZ = -unitRayDirection[2]
        let dot =
            ((normalX * lightX) + (normalY * lightY)) + (normalZ * lightZ)
        let diffuse = max(0.0, dot)
        return 0.25 + (0.75 * diffuse)
    }

    /// Whether a sample is safe to skip under `ADR-0182`: every one
    /// of its trilinear corner voxels — not just its nearest one —
    /// must belong to a skippable brick.
    ///
    /// A brick's nearest voxel alone is not a safe proxy: the
    /// trilinear window the one public sampling authority actually
    /// reads can reach one voxel past a boundary even when the
    /// nearest voxel sits safely inside a skippable brick, so every
    /// corner the interpolation could touch is checked. The per-axis
    /// floor-and-clamp tap restates the sampling authority's own
    /// corner rule, since that function is not exposed publicly.
    static func isSampleSkippable(
        atIndexPosition position: [Double],
        extents: ContiguousArray<Int>,
        grid: BrickGridDescriptor,
        skippableBricks: [ContiguousArray<Int>: Bool]
    ) -> Bool {
        func taps(_ continuous: Double, extent: Int) -> Set<Int> {
            let index = Int(continuous.rounded(.down))
            return Set([
                min(extent - 1, max(0, index)),
                min(extent - 1, max(0, index + 1)),
            ])
        }
        let xTaps = taps(position[0], extent: extents[0])
        let yTaps = taps(position[1], extent: extents[1])
        let zTaps = taps(position[2], extent: extents[2])
        for x in xTaps {
            for y in yTaps {
                for z in zTaps {
                    let brickCoordinate: ContiguousArray<Int> = [
                        x / grid.nominalBrickExtents[0],
                        y / grid.nominalBrickExtents[1],
                        z / grid.nominalBrickExtents[2],
                    ]
                    guard skippableBricks[brickCoordinate] == true else {
                        return false
                    }
                }
            }
        }
        return true
    }

    /// The full reproduction recipe: the table bytes, the camera, the
    /// viewport, the quality token and the lighting mode.
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
                    name: "lighting"
                ),
                value: .string(request.lighting.rawValue),
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
        // The clip corners and crop bounds join exactly when
        // declared — the padding-entry precedent, so undeclared
        // documents and digests are unchanged.
        if let clip = request.clip {
            cameraComponents.append(("clip-minimum-x", clip.minimum.x))
            cameraComponents.append(("clip-minimum-y", clip.minimum.y))
            cameraComponents.append(("clip-minimum-z", clip.minimum.z))
            cameraComponents.append(("clip-maximum-x", clip.maximum.x))
            cameraComponents.append(("clip-maximum-y", clip.maximum.y))
            cameraComponents.append(("clip-maximum-z", clip.maximum.z))
        }
        if let crop = request.crop {
            for axis in 0..<crop.rank {
                entries.append(
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: Self.operationIdentifier,
                            name: "crop-lower-\(axis)"
                        ),
                        value: .signedInteger(Int64(crop.lowerBounds[axis])),
                        privacyClass: .technical
                    )
                )
                entries.append(
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: Self.operationIdentifier,
                            name: "crop-upper-\(axis)"
                        ),
                        value: .signedInteger(Int64(crop.upperBounds[axis])),
                        privacyClass: .technical
                    )
                )
            }
        }
        // The mask identity and its ascending-sorted visible labels
        // join exactly when declared — the same padding-entry
        // precedent as clip and crop.
        if let mask = request.mask {
            entries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "mask-object-id"
                    ),
                    value: .string(mask.maskObjectID.rawValue),
                    privacyClass: .technical
                )
            )
            entries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "mask-visible-labels"
                    ),
                    value: .binary(
                        MetadataBinary(
                            bytes: ContiguousArray(mask.visibleLabels.sorted())
                        )
                    ),
                    privacyClass: .technical
                )
            )
        }
        // The acceleration grid's nominal brick extents join exactly
        // when declared — the halo plays no role in classification,
        // so only the extents that actually affect the render are
        // digested.
        if let grid = request.acceleration {
            for axis in 0..<grid.nominalBrickExtents.count {
                entries.append(
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: Self.operationIdentifier,
                            name: "acceleration-nominal-brick-\(axis)"
                        ),
                        value: .signedInteger(
                            Int64(grid.nominalBrickExtents[axis])
                        ),
                        privacyClass: .technical
                    )
                )
            }
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
