// SPDX-License-Identifier: MIT

/// One complete owned immutable region-read result, frozen by `ADR-0042`.
///
/// The result's decoded bytes are packed interleaved at base offset zero
/// with exactly the checked expected length. They are not automatically
/// canonical logical identity bytes, and the result carries no integrity,
/// provenance or publication authority. There is no public initializer:
/// only a committed transaction mints a result.
public struct RegionReadResult: Sendable {
    /// The admitted binding the read was validated against.
    public let binding: LogicalSampleBinding
    /// The half-open region the result covers.
    public let region: ImageRegion
    /// The complete packed interleaved bytes, exactly the expected length.
    public let bytes: [UInt8]

    fileprivate init(binding: LogicalSampleBinding, region: ImageRegion, bytes: [UInt8]) {
        self.binding = binding
        self.region = region
        self.bytes = bytes
    }
}

/// The weak bounded monotonic fill capability a provider receives.
///
/// Every write begins at the exact current cursor and remains within
/// capacity; overrun or after-close writes poison the private fill and
/// fail typed. The provider never receives the backing, budget token,
/// request seal or commit capability.
public final class RegionFillCapability {
    fileprivate var buffer: [UInt8]
    fileprivate let capacity: Int
    fileprivate var poisoned = false
    fileprivate var closed = false

    fileprivate init(capacity: Int) {
        self.capacity = capacity
        var storage = [UInt8]()
        storage.reserveCapacity(capacity)
        self.buffer = storage
    }

    /// Appends bytes at the exact current cursor.
    ///
    /// - Throws: ``StorageContractError/contractViolation`` for a write
    ///   after close or beyond capacity; the fill is poisoned either way.
    public func write(_ bytes: some Sequence<UInt8>) throws {
        guard !closed, !poisoned else {
            poisoned = true
            throw StorageContractError.contractViolation
        }
        for byte in bytes {
            guard buffer.count < capacity else {
                poisoned = true
                throw StorageContractError.contractViolation
            }
            buffer.append(byte)
        }
    }
}

/// One single-owner synchronous region-read transaction implementing the
/// `ADR-0041` state machine's safe first profile.
///
/// Pre-admission rejections (invalid region, unsupported representation,
/// checked-count overflow) throw from construction and create no
/// transaction. After admission the first terminal event wins:
/// cancellation blocks commit, a poisoned or incomplete fill fails
/// closed, and a committed transaction is a tombstone that can never
/// commit again. The asynchronous coordinator, budget ledger and
/// provider-drain accounting arrive with the Execution-facing increments;
/// this profile is deliberately single-owner and synchronous.
public final class RegionReadTransaction {
    private enum State {
        case pending
        case committed
        case cancelled
        case failed
    }

    /// The admitted handle the transaction reads from.
    public let handle: StorageSnapshotHandle
    /// The validated half-open region.
    public let region: ImageRegion
    /// The checked expected packed byte count.
    public let expectedByteCount: Int

    private var state = State.pending
    private var fill: RegionFillCapability

    /// Admits one read against a decoded snapshot handle.
    ///
    /// - Throws: ``StorageContractError/unsupportedOperation`` for an
    ///   opaque representation; ``StorageContractError/invalidRegion``
    ///   for a rank mismatch, an empty region or a region not contained
    ///   by the admitted shape; and
    ///   ``StorageContractError/resourceLimitExceeded`` when the checked
    ///   expected byte count overflows.
    public init(handle: StorageSnapshotHandle, region: ImageRegion) throws {
        guard case .decodedStrided = handle.representation else {
            throw StorageContractError.unsupportedOperation
        }
        let extents = handle.binding.shape.extents
        guard region.rank == extents.count else {
            throw StorageContractError.invalidRegion
        }
        var regionElementCount = 1
        for axis in extents.indices {
            let lower = region.lowerBounds[axis]
            let upper = region.upperBounds[axis]
            guard lower >= 0, upper <= extents[axis], upper > lower else {
                throw StorageContractError.invalidRegion
            }
            let (product, overflow) = regionElementCount.multipliedReportingOverflow(
                by: upper - lower
            )
            guard !overflow else {
                throw StorageContractError.resourceLimitExceeded
            }
            regionElementCount = product
        }
        let (values, valueOverflow) = regionElementCount.multipliedReportingOverflow(
            by: handle.binding.componentCount
        )
        guard !valueOverflow else {
            throw StorageContractError.resourceLimitExceeded
        }
        let (bytes, byteOverflow) = values.multipliedReportingOverflow(
            by: handle.binding.scalarType.byteCount
        )
        guard !byteOverflow else {
            throw StorageContractError.resourceLimitExceeded
        }

        self.handle = handle
        self.region = region
        self.expectedByteCount = bytes
        self.fill = RegionFillCapability(capacity: bytes)
    }

    /// Runs the provider with only the weak bounded fill capability.
    ///
    /// A throwing provider terminalises the transaction as failed; the
    /// typed provider cause is not retained.
    public func fill(with provider: (RegionFillCapability) throws -> Void) throws {
        guard case .pending = state else {
            throw StorageContractError.contractViolation
        }
        do {
            try provider(fill)
        } catch let error as StorageContractError {
            state = .failed
            throw error
        } catch {
            state = .failed
            throw StorageContractError.providerFailure
        }
    }

    /// Requests cancellation: blocks commit immediately and permanently.
    public func cancel() {
        if case .pending = state {
            state = .cancelled
        }
    }

    /// Commits exactly once after complete coverage, minting the owned
    /// immutable result and closing the fill.
    ///
    /// - Throws: ``StorageContractError/cancelled`` after cancellation;
    ///   ``StorageContractError/contractViolation`` for a poisoned or
    ///   incomplete fill or a second terminal transition.
    public func commit() throws -> RegionReadResult {
        switch state {
        case .cancelled:
            throw StorageContractError.cancelled
        case .committed, .failed:
            throw StorageContractError.contractViolation
        case .pending:
            break
        }
        guard !fill.poisoned, fill.buffer.count == expectedByteCount else {
            state = .failed
            throw StorageContractError.contractViolation
        }
        fill.closed = true
        state = .committed
        let regionBinding: LogicalSampleBinding
        do {
            var extents = ContiguousArray<Int>()
            for axis in region.lowerBounds.indices {
                extents.append(region.upperBounds[axis] - region.lowerBounds[axis])
            }
            regionBinding = try LogicalSampleBinding(
                shape: try ImageShape(extents: extents),
                scalarType: handle.binding.scalarType,
                componentCount: handle.binding.componentCount
            )
        } catch {
            state = .failed
            throw StorageContractError.contractViolation
        }
        return RegionReadResult(
            binding: regionBinding,
            region: region,
            bytes: fill.buffer
        )
    }
}
