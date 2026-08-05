// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// The closed projection-mode vocabulary per `ADR-0159`.
public enum ProjectionMode: String, Sendable, Hashable, CaseIterable {
    case maximum
    case minimum
    case average
}

/// An error raised by intensity-projection admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum ProjectIntensityError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case invalidProjectionAxis
    case unsupportedGeometry
    case invalidPaddingValue
}

/// The intensity-projection operation registered by `ADR-0160` under
/// the `intensity-projection/exact-v1` model of `VOXELIA-ALG-0020`.
///
/// One ray per output sample, ascending along the projected axis;
/// integer extremes, and an average that accumulates an exact integer
/// sum and rounds the exact rational half to even — no floating-point
/// step exists. A declared sentinel excludes samples under the
/// accepted padding rule and an all-excluded ray outputs exactly
/// zero. The operation mints no identifiers and acquires no clock.
public enum ProjectIntensityOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.project-intensity"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.project-intensity.cpu"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one projection through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``ProjectIntensityError``, or the audited typed
    ///   errors of the storage, metadata, identity, provenance and
    ///   aggregate contracts.
    public static func execute(
        input: ImageData,
        mode: ProjectionMode,
        axis: Int,
        paddingValue: Int64?,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // Version-one admission per ADR-0160: the display-policy value
        // domain over a rank-three volume.
        let extents = input.descriptor.shape.extents
        guard
            extents.count == 3,
            input.descriptor.scalarFormat.type == .uint8,
            input.descriptor.components.count == 1,
            input.descriptor.components.interpretation == .scalar,
            input.descriptor.semantic == .intensity,
            input.descriptor.valueTransform == nil
        else {
            throw ProjectIntensityError.unsupportedLayerFormat
        }
        guard axis >= 0, axis < 3 else {
            throw ProjectIntensityError.invalidProjectionAxis
        }
        // The squeeze precedent: projecting away an axis's calibration
        // silently would misreport it.
        guard input.descriptor.spatialGeometry == nil else {
            throw ProjectIntensityError.unsupportedGeometry
        }
        if let paddingValue {
            guard paddingValue >= 0, paddingValue <= 255 else {
                throw ProjectIntensityError.invalidPaddingValue
            }
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

        // The frozen exact model: one streaming ascending pass per ray.
        let strides = [1, extents[0], extents[0] * extents[1]]
        let remaining = (0..<3).filter { $0 != axis }
        let sentinel = paddingValue.map(UInt8.init)
        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(extents[remaining[0]] * extents[remaining[1]])
        for outer in 0..<extents[remaining[1]] {
            for inner in 0..<extents[remaining[0]] {
                let base =
                    inner * strides[remaining[0]] + outer * strides[remaining[1]]
                var maximumValue: UInt8 = 0
                var minimumValue: UInt8 = 255
                var sum: UInt64 = 0
                var includedCount: UInt64 = 0
                for depth in 0..<extents[axis] {
                    let value = storedBytes[base + depth * strides[axis]]
                    if let sentinel, value == sentinel {
                        continue
                    }
                    maximumValue = max(maximumValue, value)
                    minimumValue = min(minimumValue, value)
                    sum += UInt64(value)
                    includedCount += 1
                }
                guard includedCount > 0 else {
                    outputBytes.append(0)
                    continue
                }
                switch mode {
                case .maximum:
                    outputBytes.append(maximumValue)
                case .minimum:
                    outputBytes.append(minimumValue)
                case .average:
                    let (quotient, remainder) = sum.quotientAndRemainder(
                        dividingBy: includedCount
                    )
                    let rounded: UInt64
                    if 2 * remainder < includedCount {
                        rounded = quotient
                    } else if 2 * remainder > includedCount {
                        rounded = quotient + 1
                    } else {
                        rounded = quotient % 2 == 0 ? quotient : quotient + 1
                    }
                    outputBytes.append(UInt8(rounded))
                }
            }
        }

        let outputExtents = [extents[remaining[0]], extents[remaining[1]]]
        let outputShape = try ImageShape(extents: ContiguousArray(outputExtents))
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
        let outputDescriptor = try ImageDescriptor(
            shape: outputShape,
            scalarFormat: input.descriptor.scalarFormat,
            components: input.descriptor.components,
            semantic: input.descriptor.semantic,
            axes: [
                input.descriptor.axes[remaining[0]],
                input.descriptor.axes[remaining[1]],
            ],
            spatialGeometry: nil,
            valueTransform: nil,
            units: nil
        )

        // The frozen parameter schema digested under the registered
        // operation-parameters projection.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try parameterCollection(
                    mode: mode,
                    axis: axis,
                    paddingValue: paddingValue
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

    /// Builds the frozen parameter collection: the mode, the axis and
    /// the padding entry exactly when declared.
    static func parameterCollection(
        mode: ProjectionMode,
        axis: Int,
        paddingValue: Int64?
    ) throws -> MetadataCollection {
        var entries = [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "mode"
                ),
                value: .string(mode.rawValue),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "axis"
                ),
                value: .signedInteger(Int64(axis)),
                privacyClass: .technical
            ),
        ]
        if let paddingValue {
            entries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "padding"
                    ),
                    value: .signedInteger(paddingValue),
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
                rawValue: "org.voxelia.precision.exact"
            ),
            qualityPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.quality.full"
            ),
            approximationStatus: .exact,
            capabilityClass: nil,
            kernel: nil
        )
    }
}
