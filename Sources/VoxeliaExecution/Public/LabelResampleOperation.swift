// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by label-resample admission.
public enum LabelResampleError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case unsupportedVolumeMapping
    case unsupportedRequestMapping
    case coordinateSpaceMismatch
    case invalidOutputExtent
    case outputBudgetExceeded
    case invalidMaskValue
    case invalidOutputAxis
}

/// The nearest label resampling operation registered by `ADR-0360`
/// under the `nearest-label-resample/exact-v1` model of
/// `VOXELIA-ALG-0064` — the structural nearest-neighbour default of
/// `VOX-SEG-005`.
///
/// Mask and label semantics are refused by the intensity resampler and
/// admitted only here; every output value is an input value or the
/// background zero — no interpolation exists anywhere in the chain,
/// and out-of-image positions publish background rather than a clamp,
/// which would replicate edge labels into space the source never
/// covered. The operation mints no identifiers and acquires no clock.
public enum LabelResampleOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.label-resample"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.label-resample.cpu"

    /// The aggregated warning code recording background-published
    /// samples.
    public static let paddingWarningCode = "org.voxelia.warn.label-resample-padding"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one nearest resampling through the budgeted coordinated
    /// read boundary.
    ///
    /// - Throws: ``LabelResampleError``, or the audited typed errors of
    ///   the spatial, storage, metadata, identity, provenance and
    ///   aggregate contracts.
    public static func execute(
        input: ImageData,
        request: AffineGridGeometry,
        outputExtents: [Int],
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        let scalarType = input.descriptor.scalarFormat.type
        let semantic = input.descriptor.semantic
        let extents = input.descriptor.shape.extents
        guard
            extents.count == 3,
            (semantic == .mask && scalarType == .uint8)
                || (semantic == .label && scalarType == .uint16),
            input.descriptor.components.count == 1,
            input.descriptor.valueTransform == nil
        else {
            throw LabelResampleError.unsupportedLayerFormat
        }
        guard case .affine(let volumeGeometry)? = input.descriptor.spatialGeometry
        else {
            throw LabelResampleError.unsupportedVolumeMapping
        }
        guard Set(volumeGeometry.spatialAxes.imageAxes) == Set([0, 1, 2]) else {
            throw LabelResampleError.unsupportedVolumeMapping
        }
        guard request.spatialAxes.imageAxes == [0, 1, 2] else {
            throw LabelResampleError.unsupportedRequestMapping
        }
        guard request.coordinateSpace.id == volumeGeometry.coordinateSpace.id
        else {
            throw LabelResampleError.coordinateSpaceMismatch
        }
        guard outputExtents.count == 3 else {
            throw LabelResampleError.invalidOutputExtent
        }
        for extent in outputExtents {
            guard extent >= 1, extent <= GridResampleOperation.maximumOutputExtent
            else {
                throw LabelResampleError.invalidOutputExtent
            }
        }
        let sampleCount = outputExtents[0] * outputExtents[1] * outputExtents[2]
        guard sampleCount <= GridResampleOperation.maximumOutputSampleCount else {
            throw LabelResampleError.outputBudgetExceeded
        }

        let fullRegion = try ImageRegion(
            lowerBounds: [0, 0, 0],
            upperBounds: extents
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)
        if semantic == .mask {
            guard storedBytes.allSatisfy({ $0 == 0 || $0 == 1 }) else {
                throw LabelResampleError.invalidMaskValue
            }
        }
        let sampleWidth = semantic == .mask ? 1 : 2

        // The frozen VOXELIA-ALG-0064 chain: the ALG-0055 forward
        // order, the accepted inverse, the ALG-0026 rounding, and
        // background zero outside the source.
        let map = try AffineWorldToIndexMap(geometry: volumeGeometry)
        let requestElements = request.indexToWorld.elements
        let requestSpace = request.coordinateSpace.id
        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(sampleCount * sampleWidth)
        var paddedSampleCount: UInt64 = 0
        for outputPlane in 0..<outputExtents[2] {
            for outputRow in 0..<outputExtents[1] {
                for outputColumn in 0..<outputExtents[0] {
                    let j0 = Double(outputColumn)
                    let j1 = Double(outputRow)
                    let j2 = Double(outputPlane)
                    var world = [0.0, 0.0, 0.0]
                    for r in 0...2 {
                        world[r] =
                            ((requestElements[4 * r + 3]
                                + (requestElements[4 * r] * j0))
                                + (requestElements[4 * r + 1] * j1))
                            + (requestElements[4 * r + 2] * j2)
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
                    var nearest = [0, 0, 0]
                    var inside = true
                    for axis in 0...2 {
                        let value = continuous[axis]
                        let rounded =
                            value >= 0
                            ? (value + 0.5).rounded(.down)
                            : (value - 0.5).rounded(.up)
                        let index = Int(rounded)
                        if index < 0 || index >= extents[axis] {
                            inside = false
                            break
                        }
                        nearest[axis] = index
                    }
                    if inside {
                        let linear =
                            nearest[0]
                            + extents[0] * (nearest[1] + extents[1] * nearest[2])
                        let start = linear * sampleWidth
                        outputBytes.append(
                            contentsOf: storedBytes[start..<start + sampleWidth]
                        )
                    } else {
                        paddedSampleCount += 1
                        for _ in 0..<sampleWidth {
                            outputBytes.append(0)
                        }
                    }
                }
            }
        }

        let outputShape = try ImageShape(extents: ContiguousArray(outputExtents))
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: outputShape,
                    scalarType: scalarType,
                    componentCount: 1
                ),
                bytes: outputBytes
            )
        )
        var outputAxes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        for axis in 0...2 {
            outputAxes.append(
                try Self.outputAxis(["u", "v", "w"][axis], semantic: semantics[axis])
            )
        }
        let outputDescriptor = try ImageDescriptor(
            shape: outputShape,
            scalarFormat: input.descriptor.scalarFormat,
            components: input.descriptor.components,
            semantic: semantic,
            axes: outputAxes,
            spatialGeometry: .affine(request),
            valueTransform: nil,
            units: nil
        )

        var parameterEntries = [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "coordinate-space"
                ),
                value: .string(request.coordinateSpace.id.rawValue),
                privacyClass: .technical
            )
        ]
        for (index, element) in request.indexToWorld.elements.enumerated() {
            parameterEntries.append(
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
        for (index, extent) in outputExtents.enumerated() {
            parameterEntries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "output-extent-\(index)"
                    ),
                    value: .signedInteger(Int64(extent)),
                    privacyClass: .technical
                )
            )
        }
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: parameterEntries),
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
        var warnings = ContiguousArray<ProvenanceWarning>()
        if paddedSampleCount >= 1 {
            warnings.append(
                try ProvenanceWarning(
                    code: try ProvenanceWarningCode(rawValue: Self.paddingWarningCode),
                    schemaVersion: ProvenanceWarningSchemaVersion(major: 1, minor: 0),
                    severity: .qualityAffecting,
                    occurrenceCount: paddedSampleCount
                )
            )
        }
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
                try MaskApplyOperation.executionClaim(version: version)
            ),
            inputs: [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "input"),
                    occurrence: 1,
                    identity: .object(input.identity.objectID),
                    parent: .graphNode(input.provenance.id)
                )
            ],
            warnings: warnings,
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

    private static func outputAxis(
        _ name: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: name) else {
            throw LabelResampleError.invalidOutputAxis
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
