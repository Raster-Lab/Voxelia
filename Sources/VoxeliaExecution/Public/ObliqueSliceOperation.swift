// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by oblique-slice admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum ObliqueSliceError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case volumeNotSpatiallyCalibrated
    case unsupportedVolumeMapping
    case unsupportedRequestMapping
    case coordinateSpaceMismatch
    case invalidOutputExtent
    case invalidOutputAxis
}

/// The oblique slice operation registered by `ADR-0142` under the
/// `oblique-slice-sampling/binary64-v1` model of `VOXELIA-ALG-0017`.
///
/// The request is the output's own affine geometry and the output
/// claims it verbatim; sampling composes only accepted authorities —
/// the claimed forward evaluation, the `ADR-0138` world-to-index
/// composition and the trilinear reduction over the declared
/// pixel-centre support with exact zero padding outside it. The
/// operation mints no identifiers and acquires no clock.
public enum ObliqueSliceOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.oblique-slice"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.oblique-slice.cpu"

    /// The inclusive per-dimension output extent ceiling.
    public static let maximumOutputExtent = 16_384

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one oblique extraction through the budgeted
    /// coordinated read boundary.
    ///
    /// - Throws: ``ObliqueSliceError``, or the audited typed errors
    ///   of the spatial, storage, metadata, identity, provenance and
    ///   aggregate contracts.
    public static func execute(
        input: ImageData,
        request: AffineGridGeometry,
        outputWidth: Int,
        outputHeight: Int,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // Version-one admission per ADR-0142: the display-policy
        // value domain over a calibrated rank-three volume.
        let extents = input.descriptor.shape.extents
        guard
            extents.count == 3,
            input.descriptor.scalarFormat.type == .uint8,
            input.descriptor.components.count == 1,
            input.descriptor.components.interpretation == .scalar,
            input.descriptor.semantic == .intensity,
            input.descriptor.valueTransform == nil
        else {
            throw ObliqueSliceError.unsupportedLayerFormat
        }
        guard case .affine(let volumeGeometry)? = input.descriptor.spatialGeometry
        else {
            throw ObliqueSliceError.volumeNotSpatiallyCalibrated
        }
        guard Set(volumeGeometry.spatialAxes.imageAxes) == Set([0, 1, 2]) else {
            throw ObliqueSliceError.unsupportedVolumeMapping
        }
        guard request.spatialAxes.imageAxes == [0, 1] else {
            throw ObliqueSliceError.unsupportedRequestMapping
        }
        guard request.coordinateSpace.id == volumeGeometry.coordinateSpace.id
        else {
            throw ObliqueSliceError.coordinateSpaceMismatch
        }
        guard
            outputWidth >= 1, outputWidth <= Self.maximumOutputExtent,
            outputHeight >= 1, outputHeight <= Self.maximumOutputExtent
        else {
            throw ObliqueSliceError.invalidOutputExtent
        }

        // One budgeted coordinated full read; the retention is released
        // as soon as the owned bytes are staged.
        let fullRegion = try ImageRegion(
            lowerBounds: [0, 0, 0],
            upperBounds: extents
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)

        // The frozen VOXELIA-ALG-0017 chain: claimed forward world
        // positions, the accepted inverse composition, then the
        // trilinear reduction over the declared support.
        let map = try AffineWorldToIndexMap(geometry: volumeGeometry)
        let requestElements = request.indexToWorld.elements
        let requestSpace = request.coordinateSpace.id
        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(outputWidth * outputHeight)
        for outputRow in 0..<outputHeight {
            for outputColumn in 0..<outputWidth {
                let column = Double(outputColumn)
                let row = Double(outputRow)
                var world = [0.0, 0.0, 0.0]
                for r in 0...2 {
                    world[r] =
                        (requestElements[4 * r + 3]
                            + (requestElements[4 * r] * column))
                        + (requestElements[4 * r + 1] * row)
                }
                let slots = try map.continuousSlotIndices(
                    of: try Point3D(
                        x: world[0],
                        y: world[1],
                        z: world[2],
                        coordinateSpace: requestSpace
                    )
                )
                var continuous = [0.0, 0.0, 0.0]
                for (slot, axis) in map.spatialAxes.imageAxes.enumerated() {
                    continuous[axis] = slots[slot]
                }
                outputBytes.append(
                    Self.sample(continuous, extents: extents, bytes: storedBytes)
                )
            }
        }

        let outputShape = try ImageShape(extents: [outputWidth, outputHeight])
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: outputShape,
                    scalarType: .uint8,
                    componentCount: 1
                ),
                bytes: outputBytes
            )
        )
        // Fresh index-only axes: the verbatim request claim is the one
        // calibration authority for the oblique grid.
        let outputDescriptor = try ImageDescriptor(
            shape: outputShape,
            scalarFormat: input.descriptor.scalarFormat,
            components: input.descriptor.components,
            semantic: input.descriptor.semantic,
            axes: [
                try Self.outputAxis("u", semantic: .spatialX),
                try Self.outputAxis("v", semantic: .spatialY),
            ],
            spatialGeometry: .affine(request),
            valueTransform: nil,
            units: nil
        )

        // The frozen parameter schema digested under the registered
        // operation-parameters projection.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try parameterCollection(
                    request: request,
                    outputWidth: outputWidth,
                    outputHeight: outputHeight
                ),
                maximumOutputByteCount: Self.parameterDocumentByteCeiling
            )
        )

        // Registered tokens, derivation recipe, content identity and
        // the subject-bound record with its parent edge, per the
        // accepted operation pattern.
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
                    identity: .object(input.identity.objectID)
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
                try executionClaim(version: version)
            ),
            inputs: [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "input"),
                    occurrence: 1,
                    identity: .object(input.identity.objectID),
                    parent: .graphNode(input.provenance.id)
                )
            ],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )

        return try ImageData(
            descriptor: outputDescriptor,
            storage: outputStorage,
            metadata: input.metadata,
            provenance: provenance,
            identity: outputIdentity
        )
    }

    /// The exact `VOXELIA-ALG-0017` sample: the declared pixel-centre
    /// support with exact zero padding outside it, the accepted
    /// unclamped-floor tap rule per axis, and the trilinear reduction
    /// over ascending volume axes.
    ///
    /// This is the one public sampling authority per `ADR-0174`:
    /// consumers compose it rather than restating the frozen rule.
    public static func sample(
        _ continuous: [Double],
        extents: ContiguousArray<Int>,
        bytes: [UInt8]
    ) -> UInt8 {
        for axis in 0...2 {
            let upper = Double(extents[axis]) - 0.5
            guard continuous[axis] >= -0.5, continuous[axis] <= upper else {
                return 0
            }
        }
        let a = Self.axisTaps(continuous[0], count: extents[0])
        let b = Self.axisTaps(continuous[1], count: extents[1])
        let d = Self.axisTaps(continuous[2], count: extents[2])
        let width = extents[0]
        let height = extents[1]
        func value(_ x: Int, _ y: Int, _ z: Int) -> Double {
            Double(bytes[x + width * (y + height * z)])
        }
        func acrossX(_ y: Int, _ z: Int) -> Double {
            (value(a.lower, y, z) * (1.0 - a.weight))
                + (value(a.upper, y, z) * a.weight)
        }
        func acrossXY(_ z: Int) -> Double {
            (acrossX(b.lower, z) * (1.0 - b.weight))
                + (acrossX(b.upper, z) * b.weight)
        }
        let sampled =
            (acrossXY(d.lower) * (1.0 - d.weight))
            + (acrossXY(d.upper) * d.weight)
        let rounded = sampled.rounded(.toNearestOrEven)
        return UInt8(min(255.0, max(0.0, rounded)))
    }

    /// The accepted per-axis tap rule over an in-support continuous
    /// coordinate: the weight comes from the unclamped floor so border
    /// coordinates replicate the border sample.
    static func axisTaps(
        _ continuous: Double,
        count: Int
    ) -> (lower: Int, upper: Int, weight: Double) {
        let floored = floor(continuous)
        let weight = continuous - floored
        let index = Int(floored)
        let lower = min(count - 1, max(0, index))
        let upper = min(count - 1, max(0, index + 1))
        return (lower, upper, weight)
    }

    /// Builds the frozen parameter collection: the full request matrix,
    /// its coordinate space and the output extents — the complete
    /// reproduction recipe.
    static func parameterCollection(
        request: AffineGridGeometry,
        outputWidth: Int,
        outputHeight: Int
    ) throws -> MetadataCollection {
        var entries = [MetadataEntry]()
        for (index, element) in request.indexToWorld.elements.enumerated() {
            entries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "matrix-\(index)"
                    ),
                    value: .floatingPoint(try MetadataFloatingPoint(value: element)),
                    privacyClass: .technical
                )
            )
        }
        entries.append(
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "coordinate-space"
                ),
                value: .string(request.coordinateSpace.id.rawValue),
                privacyClass: .technical
            )
        )
        entries.append(
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "output-width"
                ),
                value: .signedInteger(Int64(outputWidth)),
                privacyClass: .technical
            )
        )
        entries.append(
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "output-height"
                ),
                value: .signedInteger(Int64(outputHeight)),
                privacyClass: .technical
            )
        )
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
            throw ObliqueSliceError.invalidOutputAxis
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
