// SPDX-License-Identifier: MIT

/// The backend-neutral storage contract implemented by concrete providers.
///
/// Conformances live in or behind `VoxeliaStorage`; the contract itself is
/// Core-owned so canonical data handles never require a `Core -> Storage`
/// dependency. A conforming value grants read access to one admitted
/// immutable snapshot only; it carries no integrity, residency or
/// publication authority.
public protocol ImageStorageContract: Sendable {
    /// The admitted immutable snapshot this provider serves.
    var snapshot: StorageSnapshotHandle { get }

    /// Performs one complete owned region read against the snapshot.
    func read(region: ImageRegion) throws -> RegionReadResult
}

/// The checked Core-owned erased storage handle frozen by `ADR-0042`.
///
/// Erasure is one checked witness dispatch: the box forwards to exactly
/// the erased conformance, and un-erasure to a different concrete type is
/// a typed failure, never a fallback or silent bridge.
public struct AnyImageStorage: Sendable {
    private let base: any ImageStorageContract

    /// Erases one concrete provider behind the Core contract.
    public init(erasing base: some ImageStorageContract) {
        self.base = base
    }

    /// The admitted immutable snapshot of the erased provider.
    public var snapshot: StorageSnapshotHandle {
        base.snapshot
    }

    /// Forwards one complete owned region read to the erased provider.
    public func read(region: ImageRegion) throws -> RegionReadResult {
        try base.read(region: region)
    }

    /// Recovers the exact erased concrete type.
    ///
    /// - Throws: ``StorageContractError/incompatibleBinding`` when the
    ///   erased value is not exactly the requested type.
    public func unerased<Concrete: ImageStorageContract>(
        as type: Concrete.Type
    ) throws -> Concrete {
        guard let concrete = base as? Concrete else {
            throw StorageContractError.incompatibleBinding
        }
        return concrete
    }
}
