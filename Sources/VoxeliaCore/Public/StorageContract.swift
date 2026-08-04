// SPDX-License-Identifier: MIT

/// The closed, payload-free storage-contract failure family frozen by
/// `ADR-0042`.
///
/// Cases deliberately carry no region, count, offset, path, provider
/// message or underlying error; privileged operational detail belongs to
/// host-governed channels. Error precedence follows the `ADR-0041` state
/// machine: pre-admission rejections invoke no provider.
public enum StorageContractError: Error, Sendable, Equatable {
    case invalidRegion
    case incompatibleBinding
    case unsupportedOperation
    case resourceLimitExceeded
    case allocationFailed
    case cancelled
    case staleSnapshot
    case providerFailure
    case contractViolation
}

/// The storage-independent logical sample binding frozen by `ADR-0042`
/// and selected by accepted `ADR-0040`.
///
/// The binding states the validated shape, the exact decoded scalar type
/// and the logical component count whose ordinals run `0..<componentCount`.
/// It carries no physical byte order, stride, source-bit or padding field:
/// those belong to the representation and interpretation layers, and no
/// layer acquires another's authority because byte counts or labels match.
public struct LogicalSampleBinding: Sendable, Hashable {
    /// The validated dynamic-rank shape.
    public let shape: ImageShape
    /// The exact decoded scalar type of every logical value.
    public let scalarType: ScalarType
    /// The logical component count; ordinals are `0..<componentCount`.
    public let componentCount: Int
    /// The checked total logical value count (`elements * components`).
    public let logicalValueCount: Int

    /// Creates a validated binding with checked value accounting.
    ///
    /// - Throws: ``StorageContractError/incompatibleBinding`` for a
    ///   non-positive component count, or
    ///   ``StorageContractError/resourceLimitExceeded`` when the checked
    ///   value or byte count overflows `Int`.
    public init(shape: ImageShape, scalarType: ScalarType, componentCount: Int) throws {
        guard componentCount >= 1 else {
            throw StorageContractError.incompatibleBinding
        }
        let elementCount: Int
        do {
            elementCount = try shape.elementCount()
        } catch {
            throw StorageContractError.resourceLimitExceeded
        }
        let (values, valueOverflow) = elementCount.multipliedReportingOverflow(
            by: componentCount
        )
        guard !valueOverflow else {
            throw StorageContractError.resourceLimitExceeded
        }
        let (_, byteOverflow) = values.multipliedReportingOverflow(
            by: scalarType.byteCount
        )
        guard !byteOverflow else {
            throw StorageContractError.resourceLimitExceeded
        }
        self.shape = shape
        self.scalarType = scalarType
        self.componentCount = componentCount
        self.logicalValueCount = values
    }

    /// The exact packed decoded byte count of the complete binding.
    public var logicalByteCount: Int {
        logicalValueCount * scalarType.byteCount
    }

    /// The lossless `RFC-0001` step-5 compatibility projection from the
    /// existing controlled descriptor leaves.
    ///
    /// The projection consumes only representation-independent fields:
    /// the scalar format contributes its exact decoded type (its byte
    /// order and any packed-layout hints are representation-layer facts),
    /// and the component descriptor contributes its component count (its
    /// interpretation, layout and names are semantic-layer facts). No
    /// information a logical binding may legally hold is dropped.
    public init(
        shape: ImageShape,
        scalarFormat: ScalarFormat,
        components: ComponentDescriptor
    ) throws {
        try self.init(
            shape: shape,
            scalarType: scalarFormat.type,
            componentCount: components.count
        )
    }
}
