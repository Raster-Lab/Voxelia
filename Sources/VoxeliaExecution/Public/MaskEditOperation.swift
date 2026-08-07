// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by mask-edit admission.
public enum MaskEditError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case shapeMismatch
    case invalidMaskValue
    case invalidOutputAxis
}

/// The closed edit vocabulary of `VOXELIA-ALG-0066`: explicit is the
/// type system's doing.
public enum MaskEditVerb: String, Sendable, Hashable {
    /// Paint: one when either input is one.
    case union
    /// Erase: one when the base is one and the edit is zero.
    case subtract
    /// Keep-within: one when both inputs are one.
    case intersect
}

/// The mask editing operation registered by `ADR-0362` under the
/// `mask-edit/exact-v1` model of `VOXELIA-ALG-0066`.
///
/// Editing never mutates: every edit publishes a new object whose
/// provenance carries both input edges and the verb, and undo is the
/// host's re-reference of the retained prior object. The operation
/// mints no identifiers and acquires no clock.
public enum MaskEditOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.mask-edit"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.mask-edit.cpu"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one edit through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``MaskEditError``, or the audited typed errors of the
    ///   storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        base: ImageData,
        edit: ImageData,
        verb: MaskEditVerb,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        let extents = base.descriptor.shape.extents
        guard
            (2...3).contains(extents.count),
            base.descriptor.scalarFormat.type == .uint8,
            base.descriptor.semantic == .mask,
            edit.descriptor.scalarFormat.type == .uint8,
            edit.descriptor.semantic == .mask,
            base.descriptor.components.count == 1,
            edit.descriptor.components.count == 1
        else {
            throw MaskEditError.unsupportedLayerFormat
        }
        guard edit.descriptor.shape.extents == extents else {
            throw MaskEditError.shapeMismatch
        }

        let fullRegion = try ImageRegion(
            lowerBounds: [Int](repeating: 0, count: extents.count),
            upperBounds: extents
        )
        let baseRead = try await coordinator.read(from: base.storage, region: fullRegion)
        let baseBytes = baseRead.result.bytes
        try await coordinator.release(baseRead.retention)
        let editRead = try await coordinator.read(from: edit.storage, region: fullRegion)
        let editBytes = editRead.result.bytes
        try await coordinator.release(editRead.retention)
        guard
            baseBytes.allSatisfy({ $0 == 0 || $0 == 1 }),
            editBytes.allSatisfy({ $0 == 0 || $0 == 1 })
        else {
            throw MaskEditError.invalidMaskValue
        }

        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(baseBytes.count)
        for index in 0..<baseBytes.count {
            let a = baseBytes[index]
            let b = editBytes[index]
            switch verb {
            case .union:
                outputBytes.append(a | b)
            case .subtract:
                outputBytes.append(a & (1 - b))
            case .intersect:
                outputBytes.append(a & b)
            }
        }

        let outputShape = try ImageShape(extents: extents)
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
        var outputAxes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        for index in 0..<extents.count {
            outputAxes.append(
                try Self.outputAxis(["u", "v", "w"][index], semantic: semantics[index])
            )
        }
        let outputDescriptor = try ImageDescriptor(
            shape: outputShape,
            scalarFormat: base.descriptor.scalarFormat,
            components: base.descriptor.components,
            semantic: .mask,
            axes: outputAxes,
            spatialGeometry: base.descriptor.spatialGeometry,
            valueTransform: nil,
            units: nil
        )

        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: [
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: Self.operationIdentifier,
                            name: "verb"
                        ),
                        value: .string(verb.rawValue),
                        privacyClass: .technical
                    )
                ]),
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
                    role: try DerivationInputRole(rawValue: "base"),
                    identity: .object(base.identity.objectID)
                ),
                DerivationInput(
                    role: try DerivationInputRole(rawValue: "edit"),
                    identity: .object(edit.identity.objectID)
                ),
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
                try MaskApplyOperation.executionClaim(version: version)
            ),
            inputs: [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "base"),
                    occurrence: 1,
                    identity: .object(base.identity.objectID),
                    parent: .graphNode(base.provenance.id)
                ),
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "edit"),
                    occurrence: 1,
                    identity: .object(edit.identity.objectID),
                    parent: .graphNode(edit.provenance.id)
                ),
            ],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )

        return try ImageData(
            descriptor: outputDescriptor,
            storage: outputStorage,
            metadata: base.metadata,
            provenance: provenance,
            identity: outputIdentity
        )
    }

    private static func outputAxis(
        _ name: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: name) else {
            throw MaskEditError.invalidOutputAxis
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
