// SPDX-License-Identifier: MIT

import Foundation
import Synchronization

// Isolated Swift 6 evidence for proposed ADR-0041. These Probe* declarations
// use toy identities, owners, byte layouts and resource ceilings. They are not
// Voxelia product API, a production storage implementation, an actual file/VM
// mapping, a no-copy proof, persistent identity, or source authorisation.

private enum ProbeReadError:
    Error,
    Sendable,
    Equatable,
    CaseIterable,
    CustomStringConvertible,
    CustomDebugStringConvertible,
    CustomReflectable
{
    case invalidLimit
    case platformIntegerRange
    case invalidRequest
    case arithmeticOverflow
    case resourceLimit
    case allocationFailure
    case unsupportedOperation
    case cancelled
    case staleSnapshot
    case incompleteRead
    case providerFailure
    case providerContractViolation
    case externallyMutableMapping

    var description: String { "storage read probe rejected input" }
    var debugDescription: String { description }
    var customMirror: Mirror {
        Mirror(self, children: ["value": ProbeDiagnostic.redactionMarker])
    }
}

private enum ProbeDiagnostic {
    static let redactionMarker = "<redacted-storage-read-lifetime-probe>"
}

private protocol ProbeRedactedDiagnostic:
    CustomStringConvertible,
    CustomDebugStringConvertible,
    CustomReflectable
{}

extension ProbeRedactedDiagnostic {
    var description: String { ProbeDiagnostic.redactionMarker }
    var debugDescription: String { description }
    var customMirror: Mirror {
        Mirror(self, children: ["value": ProbeDiagnostic.redactionMarker])
    }
}

private func probeRequire(
    _ condition: @autoclosure () -> Bool,
    _ message: String = "storage read lifetime probe assertion failed"
) {
    precondition(condition(), message)
}

private func probeRequireThrows<R>(
    _ expected: ProbeReadError,
    _ body: () throws -> R
) {
    do {
        _ = try body()
        preconditionFailure("storage read lifetime probe unexpectedly succeeded")
    } catch let error as ProbeReadError {
        precondition(error == expected, "probe returned a different typed failure")
    } catch {
        preconditionFailure("probe returned an unexpected error type")
    }
}

private func probeRequireAsyncThrows<R>(
    _ expected: ProbeReadError,
    _ body: () async throws -> R
) async {
    do {
        _ = try await body()
        preconditionFailure("storage read lifetime probe unexpectedly succeeded")
    } catch let error as ProbeReadError {
        precondition(error == expected, "probe returned a different typed failure")
    } catch {
        preconditionFailure("probe returned an unexpected error type")
    }
}

private func probeCheckedAdd(_ lhs: Int, _ rhs: Int) throws -> Int {
    guard lhs >= 0, rhs >= 0 else { throw ProbeReadError.arithmeticOverflow }
    let (result, overflow) = lhs.addingReportingOverflow(rhs)
    guard !overflow else { throw ProbeReadError.arithmeticOverflow }
    return result
}

private func probeCheckedMultiply(_ lhs: Int, _ rhs: Int) throws -> Int {
    guard lhs >= 0, rhs >= 0 else { throw ProbeReadError.arithmeticOverflow }
    let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
    guard !overflow else { throw ProbeReadError.arithmeticOverflow }
    return result
}

private func probeCheckedPlatformInt(
    _ value: UInt64,
    maximum: Int
) throws -> Int {
    guard maximum >= 0 else { throw ProbeReadError.invalidLimit }
    guard value <= UInt64(Int.max) else {
        throw ProbeReadError.platformIntegerRange
    }
    guard value <= UInt64(maximum) else { throw ProbeReadError.resourceLimit }
    return Int(value)
}

private struct ProbeLimits: Sendable, Hashable, ProbeRedactedDiagnostic {
    let maximumRank: Int
    let maximumExtent: Int
    let maximumRequestBytes: Int
    let maximumConcurrentReads: Int
    let maximumResidentReadBytes: Int
    let maximumLeaseBytes: Int
    let maximumConcurrentLeases: Int
    let maximumTombstones: Int

    init(
        maximumRank: Int,
        maximumExtent: Int,
        maximumRequestBytes: Int,
        maximumConcurrentReads: Int,
        maximumResidentReadBytes: Int,
        maximumLeaseBytes: Int,
        maximumConcurrentLeases: Int,
        maximumTombstones: Int
    ) throws {
        guard maximumRank > 0,
            maximumRank <= 64,
            maximumExtent > 0,
            maximumRequestBytes > 0,
            maximumConcurrentReads > 0,
            maximumResidentReadBytes > 0,
            maximumLeaseBytes > 0,
            maximumConcurrentLeases > 0,
            maximumTombstones >= maximumConcurrentReads
        else {
            throw ProbeReadError.invalidLimit
        }
        self.maximumRank = maximumRank
        self.maximumExtent = maximumExtent
        self.maximumRequestBytes = maximumRequestBytes
        self.maximumConcurrentReads = maximumConcurrentReads
        self.maximumResidentReadBytes = maximumResidentReadBytes
        self.maximumLeaseBytes = maximumLeaseBytes
        self.maximumConcurrentLeases = maximumConcurrentLeases
        self.maximumTombstones = maximumTombstones
    }

    static func fixture(
        maximumConcurrentReads: Int = 4,
        maximumResidentReadBytes: Int = 64
    ) throws -> Self {
        try Self(
            maximumRank: 4,
            maximumExtent: 64,
            maximumRequestBytes: 32,
            maximumConcurrentReads: maximumConcurrentReads,
            maximumResidentReadBytes: maximumResidentReadBytes,
            maximumLeaseBytes: 64,
            maximumConcurrentLeases: 4,
            maximumTombstones: 64
        )
    }
}

private struct ProbeShape: Sendable, Hashable, ProbeRedactedDiagnostic {
    let extents: ContiguousArray<Int>
    let elementCount: Int

    init(
        rawExtents: some Collection<UInt64>,
        limits: ProbeLimits
    ) throws {
        guard !rawExtents.isEmpty, rawExtents.count <= limits.maximumRank else {
            throw ProbeReadError.invalidRequest
        }
        var accepted: ContiguousArray<Int> = []
        accepted.reserveCapacity(rawExtents.count)
        var count = 1
        for rawExtent in rawExtents {
            let extent = try probeCheckedPlatformInt(
                rawExtent,
                maximum: limits.maximumExtent
            )
            guard extent > 0 else { throw ProbeReadError.invalidRequest }
            count = try probeCheckedMultiply(count, extent)
            accepted.append(extent)
        }
        extents = accepted
        elementCount = count
    }

    var rank: Int { extents.count }
}

private struct ProbeDescriptor: Sendable, Hashable, ProbeRedactedDiagnostic {
    let shape: ProbeShape
    let scalarByteCount: Int
    let componentCount: Int
    let representationProfile: UInt8
    let fullByteCount: Int

    init(
        shape: ProbeShape,
        scalarByteCount: Int,
        componentCount: Int,
        representationProfile: UInt8,
        limits: ProbeLimits
    ) throws {
        guard scalarByteCount > 0, componentCount > 0 else {
            throw ProbeReadError.invalidRequest
        }
        let bytesPerSample = try probeCheckedMultiply(
            scalarByteCount,
            componentCount
        )
        let fullByteCount = try probeCheckedMultiply(
            shape.elementCount,
            bytesPerSample
        )
        guard fullByteCount <= limits.maximumLeaseBytes else {
            throw ProbeReadError.resourceLimit
        }
        self.shape = shape
        self.scalarByteCount = scalarByteCount
        self.componentCount = componentCount
        self.representationProfile = representationProfile
        self.fullByteCount = fullByteCount
    }

    var bytesPerSample: Int { scalarByteCount * componentCount }
}

private struct ProbeRegion: Sendable, Hashable, ProbeRedactedDiagnostic {
    let lowerBounds: ContiguousArray<Int>
    let extents: ContiguousArray<Int>
    let elementCount: Int
    let expectedByteCount: Int
    let descriptor: ProbeDescriptor

    init(
        rawLowerBounds: some Collection<UInt64>,
        rawExtents: some Collection<UInt64>,
        descriptor: ProbeDescriptor,
        limits: ProbeLimits
    ) throws {
        guard rawLowerBounds.count == descriptor.shape.rank,
            rawExtents.count == descriptor.shape.rank
        else {
            throw ProbeReadError.invalidRequest
        }
        var lowerBounds: ContiguousArray<Int> = []
        var extents: ContiguousArray<Int> = []
        lowerBounds.reserveCapacity(descriptor.shape.rank)
        extents.reserveCapacity(descriptor.shape.rank)
        var elementCount = 1
        for axis in 0..<descriptor.shape.rank {
            let rawLower = rawLowerBounds[
                rawLowerBounds.index(rawLowerBounds.startIndex, offsetBy: axis)
            ]
            let rawExtent = rawExtents[
                rawExtents.index(rawExtents.startIndex, offsetBy: axis)
            ]
            let lower = try probeCheckedPlatformInt(
                rawLower,
                maximum: descriptor.shape.extents[axis]
            )
            let extent = try probeCheckedPlatformInt(
                rawExtent,
                maximum: limits.maximumExtent
            )
            guard extent > 0 else { throw ProbeReadError.invalidRequest }
            let upper = try probeCheckedAdd(lower, extent)
            guard upper <= descriptor.shape.extents[axis] else {
                throw ProbeReadError.invalidRequest
            }
            elementCount = try probeCheckedMultiply(elementCount, extent)
            lowerBounds.append(lower)
            extents.append(extent)
        }
        let expectedByteCount = try probeCheckedMultiply(
            elementCount,
            descriptor.bytesPerSample
        )
        guard expectedByteCount <= limits.maximumRequestBytes else {
            throw ProbeReadError.resourceLimit
        }
        self.lowerBounds = lowerBounds
        self.extents = extents
        self.elementCount = elementCount
        self.expectedByteCount = expectedByteCount
        self.descriptor = descriptor
    }
}

private final class ProbeOpaqueIdentity: Sendable {
    private init() {}
    static func mint() -> ProbeOpaqueIdentity { ProbeOpaqueIdentity() }
}

private final class ProbeLifetimeCounter: Sendable {
    private let countState = Mutex(0)

    var value: Int { countState.withLock { $0 } }

    fileprivate func increment() {
        countState.withLock { count in
            count += 1
        }
    }
}

private final class ProbeSnapshotOwner: Sendable, ProbeRedactedDiagnostic {
    let identity = ProbeOpaqueIdentity.mint()
    private let contents: Data
    private let lifetimeCounter: ProbeLifetimeCounter

    init(
        bytes: ContiguousArray<UInt8>,
        lifetimeCounter: ProbeLifetimeCounter
    ) {
        contents = Data(bytes)
        self.lifetimeCounter = lifetimeCounter
    }

    fileprivate var byteCount: Int { contents.count }
    fileprivate var exactBytes: ContiguousArray<UInt8> {
        ContiguousArray(contents)
    }

    fileprivate func withContents<R>(
        _ body: (borrowing Data) throws -> R
    ) rethrows -> R {
        try body(contents)
    }

    deinit {
        lifetimeCounter.increment()
    }
}

private struct ProbeBindingKey: Sendable, ProbeRedactedDiagnostic {
    let providerIdentity: ProbeOpaqueIdentity
    let descriptor: ProbeDescriptor
    let ownerIdentity: ProbeOpaqueIdentity
    let snapshotIdentity: ProbeOpaqueIdentity
    let generation: UInt64

    func exactlyMatches(_ other: Self) -> Bool {
        providerIdentity === other.providerIdentity
            && descriptor == other.descriptor
            && ownerIdentity === other.ownerIdentity
            && snapshotIdentity === other.snapshotIdentity
            && generation == other.generation
    }
}

private struct ProbeBinding: Sendable, ProbeRedactedDiagnostic {
    let providerIdentity: ProbeOpaqueIdentity
    let descriptor: ProbeDescriptor
    let owner: ProbeSnapshotOwner
    let snapshotIdentity: ProbeOpaqueIdentity
    let generation: UInt64

    init(
        providerIdentity: ProbeOpaqueIdentity,
        descriptor: ProbeDescriptor,
        owner: ProbeSnapshotOwner,
        snapshotIdentity: ProbeOpaqueIdentity,
        generation: UInt64
    ) throws {
        guard generation > 0, owner.byteCount == descriptor.fullByteCount else {
            throw ProbeReadError.invalidRequest
        }
        self.providerIdentity = providerIdentity
        self.descriptor = descriptor
        self.owner = owner
        self.snapshotIdentity = snapshotIdentity
        self.generation = generation
    }

    var key: ProbeBindingKey {
        ProbeBindingKey(
            providerIdentity: providerIdentity,
            descriptor: descriptor,
            ownerIdentity: owner.identity,
            snapshotIdentity: snapshotIdentity,
            generation: generation
        )
    }

    func exactlyMatches(_ other: Self) -> Bool {
        key.exactlyMatches(other.key)
    }
}

private final class ProbeRequestSeal: Sendable {
    private init() {}
    static func mint() -> ProbeRequestSeal { ProbeRequestSeal() }
}

private final class ProbeBudgetIdentity: Sendable {
    private init() {}
    static func mint() -> ProbeBudgetIdentity { ProbeBudgetIdentity() }
}

private final class ProbeCurrentPermit: Sendable {
    private init() {}
    static func mint() -> ProbeCurrentPermit { ProbeCurrentPermit() }
}

private enum ProbeFreshnessRequirement: Sendable {
    case boundSnapshot
    case requireCurrent
}

private enum ProbeTicketFreshness: Sendable {
    case boundSnapshot
    case requireCurrent(ProbeCurrentPermit)
}

private struct ProbeProviderRequest: Sendable {
    let region: ProbeRegion
}

private struct ProbeReadTicket: Sendable {
    let authorityIdentity: ProbeOpaqueIdentity
    let slot: Int
    let seal: ProbeRequestSeal
    let budgetIdentity: ProbeBudgetIdentity
    let binding: ProbeBinding
    let region: ProbeRegion
    let freshness: ProbeTicketFreshness

    var providerRequest: ProbeProviderRequest {
        ProbeProviderRequest(region: region)
    }
}

private enum ProbeProviderOutput: Sendable {
    case complete
    case cancelled
    case failed
}

private final class ProbeCandidateStamp: Sendable {
    private init() {}
    static func mint() -> ProbeCandidateStamp { ProbeCandidateStamp() }
}

private struct ProbeStampedCandidate: Sendable {
    let authorityIdentity: ProbeOpaqueIdentity
    let seal: ProbeRequestSeal
    let stamp: ProbeCandidateStamp
    let sourceKey: ProbeBindingKey
    let region: ProbeRegion
    let initializedByteCount: Int
}

private struct ProbeFillReport: Sendable, Equatable {
    let initializedByteCount: Int
    let poisoned: Bool
}

private struct ProbeAuthoritySnapshot: Sendable, Equatable {
    let inFlightRequests: Int
    let preparedRequests: Int
    let drainingRequests: Int
    let residentReadBytes: Int
    let activeLeases: Int
    let committedCount: Int
    let liveCommittedResults: Int
    let cancelledCount: Int
    let staleCount: Int
    let incompleteCount: Int
    let failedCount: Int
    let allocationFailureCount: Int
    let abandonedCount: Int
}

private final class ProbeTransactionAuthority: Sendable {
    private enum DrainReason: Sendable {
        case cancelled
        case stale
        case incomplete
        case failed
        case allocationFailed
        case abandoned
    }

    private struct Pending: Sendable {
        let binding: ProbeBindingKey
        let expectedByteCount: Int
        let freshness: ProbeTicketFreshness
    }

    private struct Prepared: Sendable {
        let binding: ProbeBindingKey
        let expectedByteCount: Int
        let freshness: ProbeTicketFreshness
        let stamp: ProbeCandidateStamp
    }

    private struct Draining: Sendable {
        let expectedByteCount: Int
        let reason: DrainReason
    }

    private enum Status: Sendable {
        case pending(Pending)
        case prepared(Prepared)
        case draining(Draining)
        case committed
        case committedReleased
        case cancelled
        case stale
        case incomplete
        case failed
        case allocationFailed
        case abandoned
    }

    private struct Entry: Sendable {
        let seal: ProbeRequestSeal
        let sequence: UInt64
        var status: Status
    }

    private enum BudgetState: Sendable {
        case reserved
        case committed
    }

    private struct BudgetRecord: Sendable {
        let identity: ProbeBudgetIdentity
        let byteCount: Int
        var state: BudgetState
    }

    private struct State: Sendable {
        var currentBinding: ProbeBindingKey
        var knownBindings: [ProbeBindingKey?]
        var entries: [Entry?]
        var budgets: [BudgetRecord?]
        var nextSequence: UInt64 = 1
        var inFlightRequests = 0
        var residentReadBytes = 0
        var activeLeases = 0
        var committedCount = 0
        var liveCommittedResults = 0
        var cancelledCount = 0
        var staleCount = 0
        var incompleteCount = 0
        var failedCount = 0
        var allocationFailureCount = 0
        var abandonedCount = 0
    }

    private let identity = ProbeOpaqueIdentity.mint()
    private let limits: ProbeLimits
    private let state: Mutex<State>

    init(currentBinding: ProbeBinding, limits: ProbeLimits) {
        self.limits = limits
        var knownBindings = [ProbeBindingKey?](
            repeating: nil,
            count: limits.maximumTombstones
        )
        knownBindings[0] = currentBinding.key
        let entries = [Entry?](
            repeating: nil,
            count: limits.maximumTombstones
        )
        let budgets = [BudgetRecord?](
            repeating: nil,
            count: limits.maximumResidentReadBytes
        )
        state = Mutex(
            State(
                currentBinding: currentBinding.key,
                knownBindings: knownBindings,
                entries: entries,
                budgets: budgets
            )
        )
    }

    func admits(_ binding: ProbeBinding) -> Bool {
        state.withLock { state in
            state.knownBindings.contains { known in
                known?.exactlyMatches(binding.key) == true
            }
        }
    }

    func begin(
        binding: ProbeBinding,
        region: ProbeRegion,
        freshness: ProbeFreshnessRequirement
    ) throws -> ProbeReadTicket {
        guard region.descriptor == binding.descriptor,
            region.expectedByteCount > 0,
            region.expectedByteCount <= limits.maximumRequestBytes
        else {
            throw ProbeReadError.invalidRequest
        }

        let seal = ProbeRequestSeal.mint()
        let budgetIdentity = ProbeBudgetIdentity.mint()
        let ticketFreshness: ProbeTicketFreshness
        switch freshness {
        case .boundSnapshot:
            ticketFreshness = .boundSnapshot
        case .requireCurrent:
            ticketFreshness = .requireCurrent(ProbeCurrentPermit.mint())
        }

        let pending = Pending(
            binding: binding.key,
            expectedByteCount: region.expectedByteCount,
            freshness: ticketFreshness
        )
        let slot = try state.withLock { state in
            guard
                state.knownBindings.contains(where: { known in
                    known?.exactlyMatches(binding.key) == true
                })
            else {
                throw ProbeReadError.providerContractViolation
            }
            if case .requireCurrent = ticketFreshness {
                guard state.currentBinding.exactlyMatches(binding.key) else {
                    throw ProbeReadError.staleSnapshot
                }
            }
            guard state.inFlightRequests < limits.maximumConcurrentReads else {
                throw ProbeReadError.resourceLimit
            }
            let nextResident = try probeCheckedAdd(
                state.residentReadBytes,
                region.expectedByteCount
            )
            guard nextResident <= limits.maximumResidentReadBytes else {
                throw ProbeReadError.resourceLimit
            }
            guard let slot = Self.recyclableSlot(in: state.entries),
                let budgetSlot = state.budgets.firstIndex(where: { $0 == nil }),
                state.nextSequence < UInt64.max
            else {
                throw ProbeReadError.resourceLimit
            }
            let sequence = state.nextSequence
            state.nextSequence += 1
            state.entries[slot] = Entry(
                seal: seal,
                sequence: sequence,
                status: .pending(pending)
            )
            state.budgets[budgetSlot] = BudgetRecord(
                identity: budgetIdentity,
                byteCount: region.expectedByteCount,
                state: .reserved
            )
            state.inFlightRequests += 1
            state.residentReadBytes = nextResident
            return slot
        }
        return ProbeReadTicket(
            authorityIdentity: identity,
            slot: slot,
            seal: seal,
            budgetIdentity: budgetIdentity,
            binding: binding,
            region: region,
            freshness: ticketFreshness
        )
    }

    func cancel(_ ticket: ProbeReadTicket) {
        guard ticket.authorityIdentity === identity else { return }
        state.withLock { state in
            guard state.entries.indices.contains(ticket.slot),
                var entry = state.entries[ticket.slot],
                entry.seal === ticket.seal,
                let reservation = Self.reservation(for: entry.status)
            else {
                return
            }
            entry.status = .draining(
                Draining(expectedByteCount: reservation, reason: .cancelled)
            )
            state.entries[ticket.slot] = entry
            state.cancelledCount += 1
        }
    }

    func markTargetAllocationFailure(_ ticket: ProbeReadTicket) {
        guard ticket.authorityIdentity === identity else { return }
        state.withLock { state in
            guard state.entries.indices.contains(ticket.slot),
                var entry = state.entries[ticket.slot],
                entry.seal === ticket.seal,
                case .pending(let pending) = entry.status
            else { return }
            entry.status = .draining(
                Draining(
                    expectedByteCount: pending.expectedByteCount,
                    reason: .allocationFailed
                )
            )
            state.entries[ticket.slot] = entry
            state.allocationFailureCount += 1
        }
    }

    func installCurrent(_ binding: ProbeBinding) throws {
        try state.withLock { state in
            if !state.knownBindings.contains(where: { known in
                known?.exactlyMatches(binding.key) == true
            }) {
                guard
                    let knownSlot = state.knownBindings.firstIndex(where: {
                        $0 == nil
                    })
                else {
                    throw ProbeReadError.resourceLimit
                }
                state.knownBindings[knownSlot] = binding.key
            }
            state.currentBinding = binding.key
            for slot in state.entries.indices {
                guard var entry = state.entries[slot],
                    let reservation = Self.currentReservation(for: entry.status),
                    !reservation.binding.exactlyMatches(binding.key)
                else { continue }
                entry.status = .draining(
                    Draining(
                        expectedByteCount: reservation.expectedByteCount,
                        reason: .stale
                    )
                )
                state.entries[slot] = entry
                state.staleCount += 1
            }
        }
    }

    func markAbandonedIfOpen(_ ticket: ProbeReadTicket) {
        guard ticket.authorityIdentity === identity else { return }
        state.withLock { state in
            guard state.entries.indices.contains(ticket.slot),
                var entry = state.entries[ticket.slot],
                entry.seal === ticket.seal,
                let reservation = Self.reservation(for: entry.status)
            else {
                return
            }
            entry.status = .draining(
                Draining(expectedByteCount: reservation, reason: .abandoned)
            )
            state.entries[ticket.slot] = entry
            state.abandonedCount += 1
        }
    }

    func retire(_ ticket: ProbeReadTicket) {
        guard ticket.authorityIdentity === identity else { return }
        state.withLock { state in
            guard state.entries.indices.contains(ticket.slot),
                var entry = state.entries[ticket.slot],
                entry.seal === ticket.seal,
                case .draining(let draining) = entry.status
            else { return }
            switch draining.reason {
            case .cancelled:
                entry.status = .cancelled
            case .stale:
                entry.status = .stale
            case .incomplete:
                entry.status = .incomplete
            case .failed:
                entry.status = .failed
            case .allocationFailed:
                entry.status = .allocationFailed
            case .abandoned:
                entry.status = .abandoned
            }
            state.entries[ticket.slot] = entry
            Self.releaseReservation(
                draining.expectedByteCount,
                budgetIdentity: ticket.budgetIdentity,
                from: &state
            )
        }
    }

    func prepare(
        _ ticket: ProbeReadTicket,
        output: ProbeProviderOutput,
        report: ProbeFillReport
    ) throws -> ProbeStampedCandidate {
        let stamp = ProbeCandidateStamp.mint()

        switch output {
        case .cancelled:
            try finishProviderOutcome(
                ticket,
                terminal: .cancelled,
                error: .cancelled
            )
        case .failed:
            try finishProviderOutcome(
                ticket,
                terminal: .failed,
                error: .providerFailure
            )
        case .complete:
            try state.withLock { state in
                guard ticket.authorityIdentity === identity,
                    state.entries.indices.contains(ticket.slot),
                    var entry = state.entries[ticket.slot],
                    entry.seal === ticket.seal
                else {
                    throw ProbeReadError.providerContractViolation
                }
                guard case .pending(let pending) = entry.status else {
                    throw Self.error(for: entry.status)
                }
                if case .requireCurrent = pending.freshness,
                    !state.currentBinding.exactlyMatches(pending.binding)
                {
                    entry.status = .draining(
                        Draining(
                            expectedByteCount: pending.expectedByteCount,
                            reason: .stale
                        )
                    )
                    state.entries[ticket.slot] = entry
                    state.staleCount += 1
                    throw ProbeReadError.staleSnapshot
                }
                guard report.initializedByteCount == pending.expectedByteCount,
                    !report.poisoned
                else {
                    entry.status = .draining(
                        Draining(
                            expectedByteCount: pending.expectedByteCount,
                            reason: .incomplete
                        )
                    )
                    state.entries[ticket.slot] = entry
                    state.incompleteCount += 1
                    throw ProbeReadError.incompleteRead
                }
                entry.status = .prepared(
                    Prepared(
                        binding: pending.binding,
                        expectedByteCount: pending.expectedByteCount,
                        freshness: pending.freshness,
                        stamp: stamp
                    )
                )
                state.entries[ticket.slot] = entry
            }
            return ProbeStampedCandidate(
                authorityIdentity: identity,
                seal: ticket.seal,
                stamp: stamp,
                sourceKey: ticket.binding.key,
                region: ticket.region,
                initializedByteCount: report.initializedByteCount
            )
        }
        preconditionFailure("provider terminal outcome unexpectedly returned")
    }

    func commit(
        _ ticket: ProbeReadTicket,
        candidate: ProbeStampedCandidate,
        package: ProbePreparedResultPackage
    ) throws -> ProbeReadResult {
        try state.withLock { state in
            guard ticket.authorityIdentity === identity,
                state.entries.indices.contains(ticket.slot),
                var entry = state.entries[ticket.slot],
                entry.seal === ticket.seal
            else {
                throw ProbeReadError.providerContractViolation
            }
            guard case .prepared(let prepared) = entry.status else {
                throw Self.error(for: entry.status)
            }
            guard candidate.authorityIdentity === identity,
                candidate.seal === ticket.seal
            else {
                // A candidate stamped for another authority/request cannot
                // consume this exact prepared transaction.
                throw ProbeReadError.providerContractViolation
            }
            guard candidate.stamp === prepared.stamp,
                package.stamp === candidate.stamp,
                candidate.sourceKey.exactlyMatches(prepared.binding),
                package.buffer.sourceKey.exactlyMatches(prepared.binding),
                candidate.region == ticket.region,
                candidate.initializedByteCount == prepared.expectedByteCount,
                package.report
                    == ProbeFillReport(
                        initializedByteCount: prepared.expectedByteCount,
                        poisoned: false
                    )
            else {
                entry.status = .draining(
                    Draining(
                        expectedByteCount: prepared.expectedByteCount,
                        reason: .abandoned
                    )
                )
                state.entries[ticket.slot] = entry
                state.abandonedCount += 1
                throw ProbeReadError.providerContractViolation
            }
            if case .requireCurrent = prepared.freshness,
                !state.currentBinding.exactlyMatches(prepared.binding)
            {
                entry.status = .draining(
                    Draining(
                        expectedByteCount: prepared.expectedByteCount,
                        reason: .stale
                    )
                )
                state.entries[ticket.slot] = entry
                state.staleCount += 1
                throw ProbeReadError.staleSnapshot
            }
            entry.status = .committed
            state.entries[ticket.slot] = entry
            guard
                let budgetSlot = state.budgets.firstIndex(where: { record in
                    record?.identity === ticket.budgetIdentity
                }), var budget = state.budgets[budgetSlot],
                case .reserved = budget.state
            else {
                preconditionFailure("missing exact reserved budget")
            }
            budget.state = .committed
            state.budgets[budgetSlot] = budget
            state.inFlightRequests -= 1
            state.committedCount += 1
            state.liveCommittedResults += 1
        }
        return ProbeReadResult(
            region: candidate.region,
            buffer: package.buffer
        )
    }

    func makePrivateBuffer(
        for ticket: ProbeReadTicket
    ) -> ProbePrivateBufferOwner {
        let tokenKey = ProbeBudgetTokenKey(
            authorityIdentity: identity,
            budgetIdentity: ticket.budgetIdentity
        )
        return ProbePrivateBufferOwner(
            capacity: ticket.region.expectedByteCount,
            sourceKey: ticket.binding.key,
            budgetLease: ProbeCommittedBudgetLease(
                authority: self,
                key: tokenKey
            )
        )
    }

    func prepareResultPackage(
        candidate: ProbeStampedCandidate,
        buffer: ProbePrivateBufferOwner
    ) -> ProbePreparedResultPackage {
        return ProbePreparedResultPackage(
            stamp: candidate.stamp,
            buffer: buffer,
            report: buffer.frozenReport
        )
    }

    private func finishProviderOutcome(
        _ ticket: ProbeReadTicket,
        terminal: Status,
        error: ProbeReadError
    ) throws -> Never {
        try state.withLock { state in
            guard ticket.authorityIdentity === identity,
                state.entries.indices.contains(ticket.slot),
                var entry = state.entries[ticket.slot],
                entry.seal === ticket.seal
            else {
                throw ProbeReadError.providerContractViolation
            }
            guard case .pending(let pending) = entry.status else {
                throw Self.error(for: entry.status)
            }
            if case .requireCurrent = pending.freshness,
                !state.currentBinding.exactlyMatches(pending.binding)
            {
                entry.status = .draining(
                    Draining(
                        expectedByteCount: pending.expectedByteCount,
                        reason: .stale
                    )
                )
                state.entries[ticket.slot] = entry
                state.staleCount += 1
                throw ProbeReadError.staleSnapshot
            }
            let reason: DrainReason
            switch terminal {
            case .cancelled:
                reason = .cancelled
            case .failed:
                reason = .failed
            case .allocationFailed:
                reason = .allocationFailed
            default:
                preconditionFailure("invalid provider terminal status")
            }
            entry.status = .draining(
                Draining(
                    expectedByteCount: pending.expectedByteCount,
                    reason: reason
                )
            )
            state.entries[ticket.slot] = entry
            switch terminal {
            case .cancelled:
                state.cancelledCount += 1
            case .failed:
                state.failedCount += 1
            case .allocationFailed:
                state.allocationFailureCount += 1
            default:
                preconditionFailure("invalid provider terminal status")
            }
            throw error
        }
    }

    func reserveLease(byteCount: Int) throws {
        guard byteCount > 0, byteCount <= limits.maximumLeaseBytes else {
            throw ProbeReadError.resourceLimit
        }
        try state.withLock { state in
            guard state.activeLeases < limits.maximumConcurrentLeases else {
                throw ProbeReadError.resourceLimit
            }
            state.activeLeases += 1
        }
    }

    func releaseLease() {
        state.withLock { state in
            precondition(state.activeLeases > 0)
            state.activeLeases -= 1
        }
    }

    fileprivate func releaseThroughToken(_ key: ProbeBudgetTokenKey) {
        guard key.authorityIdentity === identity else { return }
        state.withLock { state in
            guard
                let budgetSlot = state.budgets.firstIndex(where: { record in
                    record?.identity === key.budgetIdentity
                }), let budget = state.budgets[budgetSlot]
            else { return }
            precondition(state.residentReadBytes >= budget.byteCount)
            state.residentReadBytes -= budget.byteCount
            state.budgets[budgetSlot] = nil
            if case .committed = budget.state {
                precondition(state.liveCommittedResults > 0)
                state.liveCommittedResults -= 1
            }
        }
    }

    var snapshot: ProbeAuthoritySnapshot {
        state.withLock { state in
            var preparedRequests = 0
            var drainingRequests = 0
            for entry in state.entries {
                if case .prepared? = entry?.status {
                    preparedRequests += 1
                }
                if case .draining? = entry?.status {
                    drainingRequests += 1
                }
            }
            return ProbeAuthoritySnapshot(
                inFlightRequests: state.inFlightRequests,
                preparedRequests: preparedRequests,
                drainingRequests: drainingRequests,
                residentReadBytes: state.residentReadBytes,
                activeLeases: state.activeLeases,
                committedCount: state.committedCount,
                liveCommittedResults: state.liveCommittedResults,
                cancelledCount: state.cancelledCount,
                staleCount: state.staleCount,
                incompleteCount: state.incompleteCount,
                failedCount: state.failedCount,
                allocationFailureCount: state.allocationFailureCount,
                abandonedCount: state.abandonedCount
            )
        }
    }

    private static func releaseReservation(
        _ byteCount: Int,
        budgetIdentity: ProbeBudgetIdentity,
        from state: inout State
    ) {
        precondition(state.inFlightRequests > 0)
        state.inFlightRequests -= 1
        if let budgetSlot = state.budgets.firstIndex(where: { record in
            record?.identity === budgetIdentity
        }) {
            precondition(state.residentReadBytes >= byteCount)
            state.residentReadBytes -= byteCount
            state.budgets[budgetSlot] = nil
        }
    }

    private static func reservation(for status: Status) -> Int? {
        switch status {
        case .pending(let pending):
            return pending.expectedByteCount
        case .prepared(let prepared):
            return prepared.expectedByteCount
        default:
            return nil
        }
    }

    private static func currentReservation(
        for status: Status
    ) -> (binding: ProbeBindingKey, expectedByteCount: Int)? {
        switch status {
        case .pending(let pending):
            guard case .requireCurrent = pending.freshness else { return nil }
            return (pending.binding, pending.expectedByteCount)
        case .prepared(let prepared):
            guard case .requireCurrent = prepared.freshness else { return nil }
            return (prepared.binding, prepared.expectedByteCount)
        default:
            return nil
        }
    }

    private static func error(for status: Status) -> ProbeReadError {
        switch status {
        case .pending, .prepared:
            preconditionFailure("open status passed to terminal error mapping")
        case .draining(let draining):
            switch draining.reason {
            case .cancelled:
                return .cancelled
            case .stale:
                return .staleSnapshot
            case .incomplete:
                return .incompleteRead
            case .failed:
                return .providerFailure
            case .allocationFailed:
                return .allocationFailure
            case .abandoned:
                return .providerContractViolation
            }
        case .cancelled:
            return .cancelled
        case .stale:
            return .staleSnapshot
        case .committed, .committedReleased, .incomplete, .failed,
            .allocationFailed, .abandoned:
            return .providerContractViolation
        }
    }

    private static func terminalStatus(for reason: DrainReason) -> Status {
        switch reason {
        case .cancelled: return .cancelled
        case .stale: return .stale
        case .incomplete: return .incomplete
        case .failed: return .failed
        case .allocationFailed: return .allocationFailed
        case .abandoned: return .abandoned
        }
    }

    private static func recyclableSlot(in entries: [Entry?]) -> Int? {
        if let empty = entries.firstIndex(where: { $0 == nil }) {
            return empty
        }
        var selected: (slot: Int, sequence: UInt64)?
        for slot in entries.indices {
            guard let entry = entries[slot], isEvictable(entry.status) else {
                continue
            }
            if selected == nil || entry.sequence < selected!.sequence {
                selected = (slot, entry.sequence)
            }
        }
        return selected?.slot
    }

    private static func isEvictable(_ status: Status) -> Bool {
        switch status {
        case .pending, .prepared, .draining:
            return false
        case .committed, .committedReleased, .cancelled, .stale,
            .incomplete, .failed, .allocationFailed, .abandoned:
            return true
        }
    }
}

private struct ProbeBudgetTokenKey: Sendable {
    let authorityIdentity: ProbeOpaqueIdentity
    let budgetIdentity: ProbeBudgetIdentity
}

private final class ProbeCommittedBudgetLease: Sendable {
    private let authority: ProbeTransactionAuthority
    private let key: ProbeBudgetTokenKey
    private let released = Mutex(false)

    init(authority: ProbeTransactionAuthority, key: ProbeBudgetTokenKey) {
        self.authority = authority
        self.key = key
    }

    func release() {
        let shouldRelease = released.withLock { released in
            guard !released else { return false }
            released = true
            return true
        }
        if shouldRelease {
            authority.releaseThroughToken(key)
        }
    }

    deinit {
        release()
    }
}

private final class ProbePrivateBufferOwner: Sendable, ProbeRedactedDiagnostic {
    private struct State: Sendable {
        var bytes: ContiguousArray<UInt8>
        var initializedByteCount = 0
        var poisoned = false
        var frozen = false
    }

    let sourceKey: ProbeBindingKey
    private let state: Mutex<State>
    private let budgetLease: ProbeCommittedBudgetLease

    init(
        capacity: Int,
        sourceKey: ProbeBindingKey,
        budgetLease: ProbeCommittedBudgetLease
    ) {
        precondition(capacity > 0)
        self.sourceKey = sourceKey
        state = Mutex(
            State(bytes: ContiguousArray(repeating: 0, count: capacity))
        )
        self.budgetLease = budgetLease
    }

    func makeFillCapability() -> ProbeBoundedFillCapability {
        ProbeBoundedFillCapability(owner: self)
    }

    fileprivate func write(startOffset: Int, byte: UInt8) -> Bool {
        state.withLock { state in
            guard !state.frozen else { return false }
            let (nextOffset, overflow) = startOffset.addingReportingOverflow(1)
            guard !overflow,
                startOffset == state.initializedByteCount,
                nextOffset <= state.bytes.count
            else {
                state.poisoned = true
                return false
            }
            state.bytes[startOffset] = byte
            state.initializedByteCount = nextOffset
            return true
        }
    }

    func freeze() -> ProbeFillReport {
        state.withLock { state in
            state.frozen = true
            return ProbeFillReport(
                initializedByteCount: state.initializedByteCount,
                poisoned: state.poisoned
            )
        }
    }

    var frozenReport: ProbeFillReport {
        state.withLock { state in
            precondition(state.frozen)
            return ProbeFillReport(
                initializedByteCount: state.initializedByteCount,
                poisoned: state.poisoned
            )
        }
    }

    func deepCopiedBytes() -> ContiguousArray<UInt8> {
        state.withLock { state in
            precondition(state.frozen)
            var copy: ContiguousArray<UInt8> = []
            copy.reserveCapacity(state.initializedByteCount)
            for index in 0..<state.initializedByteCount {
                copy.append(state.bytes[index])
            }
            return copy
        }
    }
}

private final class ProbeBoundedFillCapability: Sendable {
    private struct State: Sendable {
        weak var owner: ProbePrivateBufferOwner?
        var closed = false
    }

    private let state: Mutex<State>

    fileprivate init(owner: ProbePrivateBufferOwner) {
        state = Mutex(State(owner: owner))
    }

    func write(startOffset: Int, byte: UInt8) -> Bool {
        state.withLock { state in
            guard !state.closed, let owner = state.owner else { return false }
            return owner.write(startOffset: startOffset, byte: byte)
        }
    }

    func close() {
        state.withLock { state in
            state.closed = true
            state.owner = nil
        }
    }
}

private struct ProbePreparedResultPackage: Sendable {
    let stamp: ProbeCandidateStamp
    let buffer: ProbePrivateBufferOwner
    let report: ProbeFillReport
}

private struct ProbeReadResult: Sendable, ProbeRedactedDiagnostic {
    let region: ProbeRegion
    private let buffer: ProbePrivateBufferOwner

    init(region: ProbeRegion, buffer: ProbePrivateBufferOwner) {
        self.region = region
        self.buffer = buffer
    }

    var copiedBytes: ContiguousArray<UInt8> {
        // Rebuild element-by-element so the returned ordinary value cannot
        // share the committed buffer after its resident-budget token dies.
        buffer.deepCopiedBytes()
    }
    var sourceKey: ProbeBindingKey { buffer.sourceKey }
}

private actor ProbeSuspensionGate {
    private struct ArrivalWaiter {
        let target: Int
        let continuation: CheckedContinuation<Void, Never>
    }

    private var arrived = 0
    private var open = false
    private var providerWaiters: [CheckedContinuation<Void, Never>] = []
    private var arrivalWaiters: [ArrivalWaiter] = []

    func suspendProvider() async {
        arrived += 1
        let ready = arrivalWaiters.filter { $0.target <= arrived }
        arrivalWaiters.removeAll { $0.target <= arrived }
        for waiter in ready {
            waiter.continuation.resume()
        }
        if open { return }
        await withCheckedContinuation { continuation in
            providerWaiters.append(continuation)
        }
    }

    func waitForArrivals(_ target: Int) async {
        precondition(target > 0)
        if arrived >= target { return }
        await withCheckedContinuation { continuation in
            arrivalWaiters.append(
                ArrivalWaiter(target: target, continuation: continuation)
            )
        }
    }

    func releaseAll() {
        open = true
        let waiters = providerWaiters
        providerWaiters.removeAll(keepingCapacity: true)
        for waiter in waiters {
            waiter.resume()
        }
    }
}

private enum ProbeProviderResponse: Sendable {
    case complete
    case short
    case long
    case failed
    case cancelled
}

private enum ProbeProviderMode: Sendable {
    case immediate(ProbeProviderResponse)
    case suspended(ProbeSuspensionGate, ProbeProviderResponse)
}

private enum ProbeMappedChangePolicy: Sendable, Equatable {
    case absent
    case immutableSnapshot
    case externallyMutable
}

private enum ProbeAccessKind: Sendable, Hashable {
    case contiguousDecoded
    case mappedRepresentation
}

private protocol ProbeStorageWitness: Sendable {
    var binding: ProbeBinding { get }
    var authority: ProbeTransactionAuthority { get }
    var supportedAccess: Set<ProbeAccessKind> { get }
    var postPreparationGate: ProbeSuspensionGate? { get }
    var simulateTargetAllocationFailure: Bool { get }

    func fill(
        _ request: ProbeProviderRequest,
        into destination: ProbeBoundedFillCapability
    ) async -> ProbeProviderOutput

    func withContents<R>(
        for access: ProbeAccessKind,
        _ body: (borrowing Data) throws -> R
    ) throws -> R
}

private final class ProbeStorageProvider: ProbeStorageWitness {
    let binding: ProbeBinding
    let authority: ProbeTransactionAuthority
    let supportedAccess: Set<ProbeAccessKind>
    let postPreparationGate: ProbeSuspensionGate?
    let simulateTargetAllocationFailure: Bool

    private let mode: ProbeProviderMode
    private let mappedChangePolicy: ProbeMappedChangePolicy
    private let invocationState = Mutex(0)

    init(
        binding: ProbeBinding,
        authority: ProbeTransactionAuthority,
        mode: ProbeProviderMode,
        contiguousAccess: Bool = true,
        mappedChangePolicy: ProbeMappedChangePolicy = .immutableSnapshot,
        postPreparationGate: ProbeSuspensionGate? = nil,
        simulateTargetAllocationFailure: Bool = false
    ) {
        self.binding = binding
        self.authority = authority
        self.mode = mode
        self.mappedChangePolicy = mappedChangePolicy
        self.postPreparationGate = postPreparationGate
        self.simulateTargetAllocationFailure = simulateTargetAllocationFailure
        var access: Set<ProbeAccessKind> = []
        if contiguousAccess { access.insert(.contiguousDecoded) }
        if mappedChangePolicy != .absent {
            access.insert(.mappedRepresentation)
        }
        supportedAccess = access
    }

    var invocationCount: Int { invocationState.withLock { $0 } }

    func fill(
        _ request: ProbeProviderRequest,
        into destination: ProbeBoundedFillCapability
    ) async -> ProbeProviderOutput {
        invocationState.withLock { count in
            count += 1
        }

        let response: ProbeProviderResponse
        switch mode {
        case .immediate(let immediate):
            response = immediate
        case .suspended(let gate, let suspended):
            await gate.suspendProvider()
            response = suspended
        }

        switch response {
        case .complete:
            do {
                try fillBytes(
                    for: request,
                    maximumByteCount: request.region.expectedByteCount,
                    into: destination
                )
                return .complete
            } catch {
                return .failed
            }
        case .short:
            do {
                try fillBytes(
                    for: request,
                    maximumByteCount: request.region.expectedByteCount - 1,
                    into: destination
                )
                return .complete
            } catch {
                return .failed
            }
        case .long:
            do {
                try fillBytes(
                    for: request,
                    maximumByteCount: request.region.expectedByteCount,
                    into: destination
                )
                _ = destination.write(
                    startOffset: request.region.expectedByteCount,
                    byte: 0xEE
                )
                return .complete
            } catch {
                return .failed
            }
        case .failed:
            return .failed
        case .cancelled:
            return .cancelled
        }
    }

    func withContents<R>(
        for access: ProbeAccessKind,
        _ body: (borrowing Data) throws -> R
    ) throws -> R {
        guard supportedAccess.contains(access) else {
            throw ProbeReadError.unsupportedOperation
        }
        if access == .mappedRepresentation,
            mappedChangePolicy == .externallyMutable
        {
            throw ProbeReadError.externallyMutableMapping
        }

        let retainedOwner = binding.owner
        try authority.reserveLease(byteCount: retainedOwner.byteCount)
        defer { authority.releaseLease() }
        return try retainedOwner.withContents(body)
    }

    private func fillBytes(
        for request: ProbeProviderRequest,
        maximumByteCount: Int,
        into destination: ProbeBoundedFillCapability
    ) throws {
        let descriptor = binding.descriptor
        let region = request.region
        guard maximumByteCount >= 0,
            maximumByteCount <= region.expectedByteCount
        else {
            throw ProbeReadError.providerFailure
        }
        var emittedByteCount = 0

        try binding.owner.withContents { contents in
            for localOrdinal in 0..<region.elementCount {
                var remaining = localOrdinal
                var sourceOrdinal = 0
                var sourceStride = 1
                for axis in 0..<descriptor.shape.rank {
                    let localIndex = remaining % region.extents[axis]
                    remaining /= region.extents[axis]
                    let sourceIndex = try probeCheckedAdd(
                        region.lowerBounds[axis],
                        localIndex
                    )
                    let contribution = try probeCheckedMultiply(
                        sourceIndex,
                        sourceStride
                    )
                    sourceOrdinal = try probeCheckedAdd(
                        sourceOrdinal,
                        contribution
                    )
                    sourceStride = try probeCheckedMultiply(
                        sourceStride,
                        descriptor.shape.extents[axis]
                    )
                }
                let byteOffset = try probeCheckedMultiply(
                    sourceOrdinal,
                    descriptor.bytesPerSample
                )
                let byteEnd = try probeCheckedAdd(
                    byteOffset,
                    descriptor.bytesPerSample
                )
                guard byteEnd <= contents.count else {
                    throw ProbeReadError.providerFailure
                }
                for index in byteOffset..<byteEnd {
                    if emittedByteCount >= maximumByteCount { return }
                    _ = destination.write(
                        startOffset: emittedByteCount,
                        byte: contents[index]
                    )
                    emittedByteCount += 1
                }
            }
        }
    }
}

private struct ProbeAnyStorage: Sendable, ProbeRedactedDiagnostic {
    private let witness: any ProbeStorageWitness

    init<W: ProbeStorageWitness>(_ witness: W) throws {
        guard witness.authority.admits(witness.binding) else {
            throw ProbeReadError.staleSnapshot
        }
        self.witness = witness
    }

    var binding: ProbeBinding { witness.binding }
    var supportedAccess: Set<ProbeAccessKind> { witness.supportedAccess }

    func read(
        rawLowerBounds: some Collection<UInt64> & Sendable,
        rawExtents: some Collection<UInt64> & Sendable,
        limits: ProbeLimits,
        freshness: ProbeFreshnessRequirement = .boundSnapshot
    ) async throws -> ProbeReadResult {
        let region = try ProbeRegion(
            rawLowerBounds: rawLowerBounds,
            rawExtents: rawExtents,
            descriptor: witness.binding.descriptor,
            limits: limits
        )
        let ticket = try witness.authority.begin(
            binding: witness.binding,
            region: region,
            freshness: freshness
        )
        if witness.simulateTargetAllocationFailure {
            witness.authority.markTargetAllocationFailure(ticket)
            witness.authority.retire(ticket)
            throw ProbeReadError.allocationFailure
        }
        var privateBuffer: ProbePrivateBufferOwner? =
            witness.authority.makePrivateBuffer(for: ticket)
        return try await withTaskCancellationHandler {
            var fillCapability = privateBuffer?.makeFillCapability()
            guard let retainedFillCapability = fillCapability else {
                witness.authority.markAbandonedIfOpen(ticket)
                witness.authority.retire(ticket)
                throw ProbeReadError.allocationFailure
            }
            var output: ProbeProviderOutput? = await witness.fill(
                ticket.providerRequest,
                into: retainedFillCapability
            )
            fillCapability?.close()
            fillCapability = nil
            var candidate: ProbeStampedCandidate?
            var package: ProbePreparedResultPackage?
            do {
                if Task.isCancelled {
                    witness.authority.cancel(ticket)
                }
                guard let retainedOutput = output else {
                    throw ProbeReadError.providerContractViolation
                }
                guard let retainedBuffer = privateBuffer else {
                    throw ProbeReadError.allocationFailure
                }
                let report = retainedBuffer.freeze()
                candidate = try witness.authority.prepare(
                    ticket,
                    output: retainedOutput,
                    report: report
                )
                output = nil
                if let gate = witness.postPreparationGate {
                    await gate.suspendProvider()
                }
                if Task.isCancelled {
                    witness.authority.cancel(ticket)
                }
                guard let retainedCandidate = candidate else {
                    throw ProbeReadError.providerContractViolation
                }
                package = witness.authority.prepareResultPackage(
                    candidate: retainedCandidate,
                    buffer: retainedBuffer
                )
                guard let retainedPackage = package else {
                    throw ProbeReadError.providerContractViolation
                }
                return try witness.authority.commit(
                    ticket,
                    candidate: retainedCandidate,
                    package: retainedPackage
                )
            } catch {
                // Drop provider-owned output/candidate outside the Mutex, then
                // release the precharged reservation exactly once.
                output = nil
                candidate = nil
                package = nil
                witness.authority.markAbandonedIfOpen(ticket)
                privateBuffer = nil
                witness.authority.retire(ticket)
                throw error
            }
        } onCancel: {
            witness.authority.cancel(ticket)
        }
    }

    func withContents<R>(
        for access: ProbeAccessKind,
        _ body: (borrowing Data) throws -> R
    ) throws -> R {
        try witness.withContents(for: access, body)
    }
}

private struct ProbeFixture: Sendable {
    let storage: ProbeAnyStorage
    let authority: ProbeTransactionAuthority
    let provider: ProbeStorageProvider
    let binding: ProbeBinding
    let lifetimeCounter: ProbeLifetimeCounter
    let limits: ProbeLimits
}

private enum ProbeFixtures {
    static let defaultBytes = ContiguousArray((0..<12).map(UInt8.init))

    static func make(
        mode: ProbeProviderMode = .immediate(.complete),
        bytes: ContiguousArray<UInt8> = defaultBytes,
        limits: ProbeLimits? = nil,
        contiguousAccess: Bool = true,
        mappedChangePolicy: ProbeMappedChangePolicy = .immutableSnapshot,
        postPreparationGate: ProbeSuspensionGate? = nil,
        simulateTargetAllocationFailure: Bool = false,
        lifetimeCounter: ProbeLifetimeCounter = ProbeLifetimeCounter()
    ) throws -> ProbeFixture {
        let acceptedLimits = try limits ?? .fixture()
        let shape = try ProbeShape(rawExtents: [4, 3], limits: acceptedLimits)
        let descriptor = try ProbeDescriptor(
            shape: shape,
            scalarByteCount: 1,
            componentCount: 1,
            representationProfile: 1,
            limits: acceptedLimits
        )
        let providerIdentity = ProbeOpaqueIdentity.mint()
        let owner = ProbeSnapshotOwner(
            bytes: bytes,
            lifetimeCounter: lifetimeCounter
        )
        let binding = try ProbeBinding(
            providerIdentity: providerIdentity,
            descriptor: descriptor,
            owner: owner,
            snapshotIdentity: ProbeOpaqueIdentity.mint(),
            generation: 1
        )
        let authority = ProbeTransactionAuthority(
            currentBinding: binding,
            limits: acceptedLimits
        )
        let provider = ProbeStorageProvider(
            binding: binding,
            authority: authority,
            mode: mode,
            contiguousAccess: contiguousAccess,
            mappedChangePolicy: mappedChangePolicy,
            postPreparationGate: postPreparationGate,
            simulateTargetAllocationFailure: simulateTargetAllocationFailure
        )
        return ProbeFixture(
            storage: try ProbeAnyStorage(provider),
            authority: authority,
            provider: provider,
            binding: binding,
            lifetimeCounter: lifetimeCounter,
            limits: acceptedLimits
        )
    }

    static func nextBinding(
        after binding: ProbeBinding,
        bytes: ContiguousArray<UInt8>? = nil,
        lifetimeCounter: ProbeLifetimeCounter = ProbeLifetimeCounter()
    ) throws -> ProbeBinding {
        let owner = ProbeSnapshotOwner(
            bytes: bytes ?? binding.owner.exactBytes,
            lifetimeCounter: lifetimeCounter
        )
        return try ProbeBinding(
            providerIdentity: binding.providerIdentity,
            descriptor: binding.descriptor,
            owner: owner,
            snapshotIdentity: ProbeOpaqueIdentity.mint(),
            generation: binding.generation + 1
        )
    }
}

private struct ProbeCapturedText: TextOutputStream {
    var value = ""

    mutating func write(_ string: String) {
        value.append(contentsOf: string)
    }
}

private struct ProbeDirectPrepared: Sendable {
    let candidate: ProbeStampedCandidate
    let buffer: ProbePrivateBufferOwner
    let package: ProbePreparedResultPackage
}

#if ADR0041_SPAN_ESCAPE_SHOULD_FAIL
    extension ProbeSnapshotOwner {
        // Full compilation must reject returning this lifetime-dependent view.
        fileprivate func forbiddenReturnedSpan() -> Span<UInt8> {
            contents.span
        }
    }
#endif

#if ADR0041_RAW_SPAN_ESCAPE_SHOULD_FAIL
    extension ProbeSnapshotOwner {
        // Full compilation must reject returning this lifetime-dependent view.
        fileprivate func forbiddenReturnedRawSpan() -> RawSpan {
            contents.bytes
        }
    }
#endif

@main
private enum ADR0041StorageReadLifetimeProbe {
    static func main() async throws {
        try await testCheckedLimitsRegionAndAdmission()
        try await testCheckedErasureAndOperationAvailability()
        try await testCompleteReadHasOneCommitPoint()
        try await testIncompleteFailureAndUnsupported()
        try await testCancellationAndLateCompletion()
        try await testStaleInvalidationAndHistoricalSafety()
        try await testFirstTerminalReplayForeignAndAbandonment()
        try await testConcurrentReadsAndResidentBudgets()
        try await testOwnerRetentionAndExactlyOnceRelease()
        try testScopedSpanAndRawSpanAccess()
        try await testRedactedDiagnostics()
        try testNegativeConfigurationsAreSourceGated()

        print("binding=coreAuthority+descriptor+owner+snapshot+generation exact=true")
        print(
            "transactionGate=pending+prepared+commit+cancel+stale+drain+budget "
                + "firstTerminalWins=true"
        )
        print("readPublication=complete-owned-only residentBudgetTransfer=true")
        print("fill=exact-capacity+monotonic poisonOnInvalidCoverage=true")
        print("tombstones=FIFO-recyclable liveBudgetLedger=independent")
        print("erasure=single-checked-witness fallback=false")
        print("leases=borrowing-Data+Span+RawSpan mappedPolicy=immutable-only")
        print("ownerRetention=read+lease deinitExactlyOnce=true")
        print("diagnostics=payload+path+identity+seal+address-redacted")
        print("focusedTestGroups=12")
    }

    private static func testCheckedLimitsRegionAndAdmission() async throws {
        probeRequireThrows(.invalidLimit) {
            try ProbeLimits(
                maximumRank: 0,
                maximumExtent: 1,
                maximumRequestBytes: 1,
                maximumConcurrentReads: 1,
                maximumResidentReadBytes: 1,
                maximumLeaseBytes: 1,
                maximumConcurrentLeases: 1,
                maximumTombstones: 1
            )
        }
        probeRequireThrows(.platformIntegerRange) {
            try probeCheckedPlatformInt(UInt64(Int.max) + 1, maximum: Int.max)
        }
        probeRequireThrows(.resourceLimit) {
            try probeCheckedPlatformInt(9, maximum: 8)
        }
        probeRequireThrows(.invalidLimit) {
            try probeCheckedPlatformInt(0, maximum: -1)
        }
        probeRequireThrows(.arithmeticOverflow) {
            try probeCheckedAdd(Int.max, 1)
        }
        probeRequireThrows(.arithmeticOverflow) {
            try probeCheckedMultiply(Int.max, 2)
        }

        let fixture = try ProbeFixtures.make()
        await probeRequireAsyncThrows(.invalidRequest) {
            try await fixture.storage.read(
                rawLowerBounds: [0],
                rawExtents: [1],
                limits: fixture.limits
            )
        }
        await probeRequireAsyncThrows(.invalidRequest) {
            try await fixture.storage.read(
                rawLowerBounds: [3, 2],
                rawExtents: [2, 1],
                limits: fixture.limits
            )
        }
        await probeRequireAsyncThrows(.invalidRequest) {
            try await fixture.storage.read(
                rawLowerBounds: [0, 0],
                rawExtents: [0, 1],
                limits: fixture.limits
            )
        }
        probeRequire(fixture.provider.invocationCount == 0)
        probeRequire(fixture.authority.snapshot.inFlightRequests == 0)
        probeRequire(fixture.authority.snapshot.residentReadBytes == 0)

        let narrowLimits = try ProbeLimits(
            maximumRank: 2,
            maximumExtent: 64,
            maximumRequestBytes: 1,
            maximumConcurrentReads: 1,
            maximumResidentReadBytes: 1,
            maximumLeaseBytes: 64,
            maximumConcurrentLeases: 1,
            maximumTombstones: 4
        )
        let narrow = try ProbeFixtures.make(limits: narrowLimits)
        await probeRequireAsyncThrows(.resourceLimit) {
            try await narrow.storage.read(
                rawLowerBounds: [1, 1],
                rawExtents: [2, 1],
                limits: narrow.limits
            )
        }
        probeRequire(narrow.provider.invocationCount == 0)

        let exact = try await fixture.storage.read(
            rawLowerBounds: [1, 1],
            rawExtents: [2, 1],
            limits: fixture.limits
        )
        probeRequire(exact.copiedBytes == [5, 6])
    }

    private static func testCheckedErasureAndOperationAvailability() async throws {
        let first = try ProbeFixtures.make()
        let second = try ProbeFixtures.make(
            bytes: ContiguousArray((100..<112).map(UInt8.init))
        )
        let firstResult = try await first.storage.read(
            rawLowerBounds: [0, 0],
            rawExtents: [2, 1],
            limits: first.limits
        )
        let secondResult = try await second.storage.read(
            rawLowerBounds: [0, 0],
            rawExtents: [2, 1],
            limits: second.limits
        )
        probeRequire(firstResult.copiedBytes == [0, 1])
        probeRequire(secondResult.copiedBytes == [100, 101])
        probeRequire(first.storage.supportedAccess == Set(ProbeAccessKind.allCases))

        let noMapped = try ProbeFixtures.make(mappedChangePolicy: .absent)
        probeRequire(noMapped.storage.supportedAccess == [.contiguousDecoded])
        probeRequireThrows(.unsupportedOperation) {
            try noMapped.storage.withContents(for: .mappedRepresentation) { _ in 0 }
        }
        probeRequire(noMapped.provider.invocationCount == 0)

        let alternate = try ProbeFixtures.nextBinding(after: first.binding)
        probeRequire(!first.binding.exactlyMatches(alternate))
        probeRequireThrows(.staleSnapshot) {
            let mismatchedProvider = ProbeStorageProvider(
                binding: alternate,
                authority: first.authority,
                mode: .immediate(.complete)
            )
            return try ProbeAnyStorage(mismatchedProvider)
        }
    }

    private static func testCompleteReadHasOneCommitPoint() async throws {
        let gate = ProbeSuspensionGate()
        let fixture = try ProbeFixtures.make(
            mode: .suspended(gate, .complete)
        )
        let result = try await withThrowingTaskGroup(
            of: ProbeReadResult.self
        ) { group in
            group.addTask {
                try await fixture.storage.read(
                    rawLowerBounds: [1, 1],
                    rawExtents: [2, 1],
                    limits: fixture.limits
                )
            }
            await gate.waitForArrivals(1)
            let pending = fixture.authority.snapshot
            probeRequire(pending.inFlightRequests == 1)
            probeRequire(pending.residentReadBytes == 2)
            probeRequire(pending.committedCount == 0)
            probeRequire(pending.liveCommittedResults == 0)
            await gate.releaseAll()
            guard let result = try await group.next() else {
                preconditionFailure("missing structured read result")
            }
            return result
        }
        probeRequire(result.copiedBytes == [5, 6])
        let committed = fixture.authority.snapshot
        probeRequire(committed.inFlightRequests == 0)
        probeRequire(committed.residentReadBytes == 2)
        probeRequire(committed.committedCount == 1)
        probeRequire(committed.liveCommittedResults == 1)

        let copiedResult = result
        probeRequire(copiedResult.copiedBytes == result.copiedBytes)
        probeRequire(fixture.authority.snapshot.liveCommittedResults == 1)
    }

    private static func testIncompleteFailureAndUnsupported() async throws {
        for response in [ProbeProviderResponse.short, .long] {
            let fixture = try ProbeFixtures.make(mode: .immediate(response))
            await probeRequireAsyncThrows(.incompleteRead) {
                try await fixture.storage.read(
                    rawLowerBounds: [1, 1],
                    rawExtents: [2, 1],
                    limits: fixture.limits
                )
            }
            probeRequire(fixture.authority.snapshot.incompleteCount == 1)
            probeRequire(fixture.authority.snapshot.residentReadBytes == 0)
        }

        let failed = try ProbeFixtures.make(mode: .immediate(.failed))
        await probeRequireAsyncThrows(.providerFailure) {
            try await failed.storage.read(
                rawLowerBounds: [1, 1],
                rawExtents: [2, 1],
                limits: failed.limits
            )
        }
        probeRequire(failed.authority.snapshot.failedCount == 1)
        probeRequire(failed.authority.snapshot.residentReadBytes == 0)

        let providerCancelled = try ProbeFixtures.make(
            mode: .immediate(.cancelled)
        )
        await probeRequireAsyncThrows(.cancelled) {
            try await providerCancelled.storage.read(
                rawLowerBounds: [1, 1],
                rawExtents: [2, 1],
                limits: providerCancelled.limits
            )
        }
        probeRequire(providerCancelled.authority.snapshot.cancelledCount == 1)
        probeRequire(providerCancelled.authority.snapshot.residentReadBytes == 0)

        let allocationFailed = try ProbeFixtures.make(
            simulateTargetAllocationFailure: true
        )
        await probeRequireAsyncThrows(.allocationFailure) {
            try await allocationFailed.storage.read(
                rawLowerBounds: [1, 1],
                rawExtents: [2, 1],
                limits: allocationFailed.limits
            )
        }
        probeRequire(
            allocationFailed.authority.snapshot.allocationFailureCount == 1
        )
        probeRequire(allocationFailed.provider.invocationCount == 0)
        probeRequire(allocationFailed.authority.snapshot.residentReadBytes == 0)

        let noContiguous = try ProbeFixtures.make(contiguousAccess: false)
        probeRequireThrows(.unsupportedOperation) {
            try noContiguous.storage.withContents(for: .contiguousDecoded) { _ in 0 }
        }
        try await testBoundedFillCoverage()
    }

    private static func testCancellationAndLateCompletion() async throws {
        let gate = ProbeSuspensionGate()
        let limits = try ProbeLimits.fixture(maximumConcurrentReads: 1)
        let fixture = try ProbeFixtures.make(
            mode: .immediate(.complete),
            limits: limits,
            postPreparationGate: gate
        )
        let outcome = await withTaskGroup(of: ProbeReadError.self) { group in
            group.addTask {
                do {
                    _ = try await fixture.storage.read(
                        rawLowerBounds: [1, 1],
                        rawExtents: [2, 1],
                        limits: fixture.limits
                    )
                    return .providerContractViolation
                } catch let error as ProbeReadError {
                    return error
                } catch {
                    return .providerContractViolation
                }
            }
            await gate.waitForArrivals(1)
            probeRequire(fixture.authority.snapshot.preparedRequests == 1)
            group.cancelAll()
            let cancelled = fixture.authority.snapshot
            probeRequire(cancelled.cancelledCount == 1)
            probeRequire(cancelled.committedCount == 0)
            probeRequire(cancelled.inFlightRequests == 1)
            probeRequire(cancelled.drainingRequests == 1)
            probeRequire(cancelled.residentReadBytes == 2)
            await probeRequireAsyncThrows(.resourceLimit) {
                try await fixture.storage.read(
                    rawLowerBounds: [2, 0],
                    rawExtents: [2, 1],
                    limits: fixture.limits
                )
            }
            probeRequire(fixture.provider.invocationCount == 1)
            await gate.releaseAll()
            guard let outcome = await group.next() else {
                preconditionFailure("missing cancellation outcome")
            }
            return outcome
        }
        probeRequire(outcome == .cancelled)
        let late = fixture.authority.snapshot
        probeRequire(late.cancelledCount == 1)
        probeRequire(late.committedCount == 0)
        probeRequire(late.residentReadBytes == 0)
    }

    private static func testStaleInvalidationAndHistoricalSafety() async throws {
        let gate = ProbeSuspensionGate()
        let fixture = try ProbeFixtures.make(
            mode: .immediate(.complete),
            postPreparationGate: gate
        )
        let replacement = try ProbeFixtures.nextBinding(after: fixture.binding)
        let outcome = await withTaskGroup(of: ProbeReadError.self) { group in
            group.addTask {
                do {
                    _ = try await fixture.storage.read(
                        rawLowerBounds: [1, 1],
                        rawExtents: [2, 1],
                        limits: fixture.limits,
                        freshness: .requireCurrent
                    )
                    return .providerContractViolation
                } catch let error as ProbeReadError {
                    return error
                } catch {
                    return .providerContractViolation
                }
            }
            await gate.waitForArrivals(1)
            probeRequire(fixture.authority.snapshot.preparedRequests == 1)
            do {
                try fixture.authority.installCurrent(replacement)
            } catch {
                preconditionFailure("generation installation unexpectedly failed")
            }
            let stale = fixture.authority.snapshot
            probeRequire(stale.staleCount == 1)
            probeRequire(stale.committedCount == 0)
            probeRequire(stale.inFlightRequests == 1)
            probeRequire(stale.drainingRequests == 1)
            probeRequire(stale.residentReadBytes == 2)
            await gate.releaseAll()
            guard let outcome = await group.next() else {
                preconditionFailure("missing stale outcome")
            }
            return outcome
        }
        probeRequire(outcome == .staleSnapshot)
        probeRequire(fixture.authority.snapshot.committedCount == 0)

        let historicalBytes = try fixture.storage.withContents(
            for: .contiguousDecoded
        ) { contents in
            ContiguousArray(contents)
        }
        probeRequire(historicalBytes == ProbeFixtures.defaultBytes)
        let historicalResult = try await fixture.storage.read(
            rawLowerBounds: [0, 0],
            rawExtents: [1, 1],
            limits: fixture.limits,
            freshness: .boundSnapshot
        )
        probeRequire(historicalResult.copiedBytes == [0])
        await probeRequireAsyncThrows(.staleSnapshot) {
            try await fixture.storage.read(
                rawLowerBounds: [0, 0],
                rawExtents: [1, 1],
                limits: fixture.limits,
                freshness: .requireCurrent
            )
        }
    }

    private static func testFirstTerminalReplayForeignAndAbandonment() async throws {
        let fixture = try ProbeFixtures.make()
        let region = try ProbeRegion(
            rawLowerBounds: [1, 1],
            rawExtents: [2, 1],
            descriptor: fixture.binding.descriptor,
            limits: fixture.limits
        )
        let ticket = try fixture.authority.begin(
            binding: fixture.binding,
            region: region,
            freshness: .requireCurrent
        )
        var prepared: ProbeDirectPrepared? = try await prepareDirect(
            fixture: fixture,
            ticket: ticket
        )
        probeRequire(
            fixture.authority.snapshot.preparedRequests == 1,
            "direct candidate was not prepared"
        )
        var committed: ProbeReadResult?
        do {
            guard let preparedValue = prepared else {
                preconditionFailure("missing direct prepared result")
            }
            committed = try fixture.authority.commit(
                ticket,
                candidate: preparedValue.candidate,
                package: preparedValue.package
            )
        }
        probeRequire(committed?.copiedBytes == [5, 6], "direct commit bytes differ")
        fixture.authority.cancel(ticket)
        let replacement = try ProbeFixtures.nextBinding(after: fixture.binding)
        try fixture.authority.installCurrent(replacement)
        probeRequire(
            fixture.authority.snapshot.committedCount == 1,
            "commit did not remain first terminal"
        )
        probeRequire(
            fixture.authority.snapshot.cancelledCount == 0,
            "late cancellation displaced commit"
        )
        probeRequireThrows(.providerContractViolation) {
            guard let prepared else {
                preconditionFailure("missing replay package")
            }
            _ = try fixture.authority.commit(
                ticket,
                candidate: prepared.candidate,
                package: prepared.package
            )
        }
        committed = nil
        prepared = nil
        probeRequire(
            fixture.authority.snapshot.residentReadBytes == 0,
            "direct result budget did not release"
        )

        let paired = try ProbeFixtures.make()
        let pairedRegion = try ProbeRegion(
            rawLowerBounds: [0, 0],
            rawExtents: [1, 1],
            descriptor: paired.binding.descriptor,
            limits: paired.limits
        )
        let first = try paired.authority.begin(
            binding: paired.binding,
            region: pairedRegion,
            freshness: .boundSnapshot
        )
        let second = try paired.authority.begin(
            binding: paired.binding,
            region: pairedRegion,
            freshness: .boundSnapshot
        )
        var firstPrepared: ProbeDirectPrepared? = try await prepareDirect(
            fixture: paired,
            ticket: first
        )
        var secondPrepared: ProbeDirectPrepared? = try await prepareDirect(
            fixture: paired,
            ticket: second
        )
        probeRequireThrows(.providerContractViolation) {
            guard let secondPrepared else {
                preconditionFailure("missing foreign prepared candidate")
            }
            _ = try paired.authority.commit(
                first,
                candidate: secondPrepared.candidate,
                package: secondPrepared.package
            )
        }
        probeRequire(
            paired.authority.snapshot.inFlightRequests == 2,
            "foreign candidate consumed a request"
        )
        probeRequire(
            paired.authority.snapshot.preparedRequests == 2,
            "foreign candidate consumed prepared state"
        )
        var firstResult: ProbeReadResult?
        var secondResult: ProbeReadResult?
        do {
            guard let firstPreparedValue = firstPrepared,
                let secondPreparedValue = secondPrepared
            else {
                preconditionFailure("missing paired prepared results")
            }
            firstResult = try paired.authority.commit(
                first,
                candidate: firstPreparedValue.candidate,
                package: firstPreparedValue.package
            )
            secondResult = try paired.authority.commit(
                second,
                candidate: secondPreparedValue.candidate,
                package: secondPreparedValue.package
            )
        }
        probeRequire(firstResult?.copiedBytes == [0])
        probeRequire(secondResult?.copiedBytes == [0])
        firstResult = nil
        secondResult = nil
        firstPrepared = nil
        secondPrepared = nil
        probeRequire(paired.authority.snapshot.residentReadBytes == 0)

        let mismatched = try ProbeFixtures.make()
        let mismatchedRegion = try ProbeRegion(
            rawLowerBounds: [0, 0],
            rawExtents: [1, 1],
            descriptor: mismatched.binding.descriptor,
            limits: mismatched.limits
        )
        let mismatchedTicket = try mismatched.authority.begin(
            binding: mismatched.binding,
            region: mismatchedRegion,
            freshness: .boundSnapshot
        )
        var correctPrepared: ProbeDirectPrepared? = try await prepareDirect(
            fixture: mismatched,
            ticket: mismatchedTicket
        )
        guard let correctCandidate = correctPrepared?.candidate else {
            preconditionFailure("missing exact candidate")
        }
        let impossibleExactSealMismatch = ProbeStampedCandidate(
            authorityIdentity: correctCandidate.authorityIdentity,
            seal: correctCandidate.seal,
            stamp: ProbeCandidateStamp.mint(),
            sourceKey: correctCandidate.sourceKey,
            region: correctCandidate.region,
            initializedByteCount: correctCandidate.initializedByteCount
        )
        probeRequireThrows(.providerContractViolation) {
            guard let correctPrepared else {
                preconditionFailure("missing mismatched result package")
            }
            _ = try mismatched.authority.commit(
                mismatchedTicket,
                candidate: impossibleExactSealMismatch,
                package: correctPrepared.package
            )
        }
        probeRequire(mismatched.authority.snapshot.abandonedCount == 1)
        correctPrepared = nil
        mismatched.authority.retire(mismatchedTicket)
        probeRequire(mismatched.authority.snapshot.residentReadBytes == 0)

        let abandoned = try ProbeFixtures.make()
        let abandonedRegion = try ProbeRegion(
            rawLowerBounds: [0, 0],
            rawExtents: [1, 1],
            descriptor: abandoned.binding.descriptor,
            limits: abandoned.limits
        )
        let abandonedTicket = try abandoned.authority.begin(
            binding: abandoned.binding,
            region: abandonedRegion,
            freshness: .boundSnapshot
        )
        abandoned.authority.markAbandonedIfOpen(abandonedTicket)
        abandoned.authority.markAbandonedIfOpen(abandonedTicket)
        abandoned.authority.retire(abandonedTicket)
        probeRequire(abandoned.authority.snapshot.abandonedCount == 1)
        probeRequire(abandoned.authority.snapshot.residentReadBytes == 0)
    }

    private static func testConcurrentReadsAndResidentBudgets() async throws {
        let gate = ProbeSuspensionGate()
        let fixture = try ProbeFixtures.make(
            mode: .suspended(gate, .complete)
        )
        var results: ContiguousArray<ProbeReadResult> = []
        try await withThrowingTaskGroup(of: ProbeReadResult.self) { group in
            group.addTask {
                try await fixture.storage.read(
                    rawLowerBounds: [0, 0],
                    rawExtents: [2, 1],
                    limits: fixture.limits
                )
            }
            group.addTask {
                try await fixture.storage.read(
                    rawLowerBounds: [2, 1],
                    rawExtents: [2, 1],
                    limits: fixture.limits
                )
            }
            await gate.waitForArrivals(2)
            probeRequire(fixture.authority.snapshot.inFlightRequests == 2)
            probeRequire(fixture.authority.snapshot.residentReadBytes == 4)
            await gate.releaseAll()
            for try await result in group {
                results.append(result)
            }
        }
        probeRequire(Set(results.map(\.copiedBytes)) == Set([[0, 1], [6, 7]]))
        probeRequire(fixture.authority.snapshot.committedCount == 2)
        probeRequire(fixture.authority.snapshot.liveCommittedResults == 2)
        results.removeAll()
        probeRequire(fixture.authority.snapshot.residentReadBytes == 0)

        let capacityGate = ProbeSuspensionGate()
        let capacityLimits = try ProbeLimits.fixture(maximumConcurrentReads: 1)
        let capacity = try ProbeFixtures.make(
            mode: .suspended(capacityGate, .complete),
            limits: capacityLimits
        )
        let capacityOutcome = await withTaskGroup(of: ProbeReadError.self) { group in
            group.addTask {
                do {
                    _ = try await capacity.storage.read(
                        rawLowerBounds: [0, 0],
                        rawExtents: [2, 1],
                        limits: capacity.limits
                    )
                    return .providerContractViolation
                } catch let error as ProbeReadError {
                    return error
                } catch {
                    return .providerContractViolation
                }
            }
            await capacityGate.waitForArrivals(1)
            await probeRequireAsyncThrows(.resourceLimit) {
                try await capacity.storage.read(
                    rawLowerBounds: [2, 0],
                    rawExtents: [2, 1],
                    limits: capacity.limits
                )
            }
            probeRequire(capacity.provider.invocationCount == 1)
            group.cancelAll()
            await capacityGate.releaseAll()
            guard let outcome = await group.next() else {
                preconditionFailure("missing capacity cancellation outcome")
            }
            return outcome
        }
        probeRequire(capacityOutcome == .cancelled)

        let residentLimits = try ProbeLimits.fixture(
            maximumConcurrentReads: 2,
            maximumResidentReadBytes: 2
        )
        let resident = try ProbeFixtures.make(limits: residentLimits)
        var held: ProbeReadResult? = try await resident.storage.read(
            rawLowerBounds: [0, 0],
            rawExtents: [2, 1],
            limits: resident.limits
        )
        probeRequire(held?.copiedBytes == [0, 1])
        probeRequire(resident.authority.snapshot.inFlightRequests == 0)
        probeRequire(resident.authority.snapshot.residentReadBytes == 2)
        await probeRequireAsyncThrows(.resourceLimit) {
            try await resident.storage.read(
                rawLowerBounds: [2, 0],
                rawExtents: [2, 1],
                limits: resident.limits
            )
        }
        probeRequire(resident.provider.invocationCount == 1)
        let independentOwnedCopy = held?.copiedBytes
        held = nil
        probeRequire(resident.authority.snapshot.residentReadBytes == 0)
        probeRequire(independentOwnedCopy == [0, 1])
        var admittedAfterRelease: ProbeReadResult? = try await resident.storage.read(
            rawLowerBounds: [2, 0],
            rawExtents: [2, 1],
            limits: resident.limits
        )
        probeRequire(admittedAfterRelease?.copiedBytes == [2, 3])
        admittedAfterRelease = nil
        probeRequire(resident.authority.snapshot.residentReadBytes == 0)

        try await testTombstoneReuseAndIndependentBudgetLedger()
    }

    private static func testBoundedFillCoverage() async throws {
        try expectPoisonedFill { capability in
            probeRequire(capability.write(startOffset: 0, byte: 0x01))
            probeRequire(!capability.write(startOffset: 0, byte: 0x02))
            probeRequire(capability.write(startOffset: 1, byte: 0x03))
        }
        try expectPoisonedFill { capability in
            probeRequire(!capability.write(startOffset: 1, byte: 0x01))
        }
        try expectPoisonedFill { capability in
            probeRequire(capability.write(startOffset: 0, byte: 0x01))
            probeRequire(capability.write(startOffset: 1, byte: 0x02))
            probeRequire(!capability.write(startOffset: 2, byte: 0x03))
        }

        let concurrent = try ProbeFixtures.make()
        let concurrentRegion = try ProbeRegion(
            rawLowerBounds: [0, 0],
            rawExtents: [2, 1],
            descriptor: concurrent.binding.descriptor,
            limits: concurrent.limits
        )
        let concurrentTicket = try concurrent.authority.begin(
            binding: concurrent.binding,
            region: concurrentRegion,
            freshness: .boundSnapshot
        )
        var concurrentBuffer: ProbePrivateBufferOwner? =
            concurrent.authority.makePrivateBuffer(for: concurrentTicket)
        let concurrentReport: ProbeFillReport
        do {
            guard let concurrentTarget = concurrentBuffer else {
                preconditionFailure("missing concurrent fill target")
            }
            let concurrentCapability = concurrentTarget.makeFillCapability()
            let orderGate = ProbeSuspensionGate()
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    _ = concurrentCapability.write(startOffset: 1, byte: 0x01)
                    await orderGate.releaseAll()
                }
                group.addTask {
                    await orderGate.suspendProvider()
                    _ = concurrentCapability.write(startOffset: 0, byte: 0x02)
                }
            }
            concurrentCapability.close()
            concurrentReport = concurrentTarget.freeze()
        }
        probeRequire(concurrentReport.poisoned)
        probeRequireThrows(.incompleteRead) {
            try concurrent.authority.prepare(
                concurrentTicket,
                output: .complete,
                report: concurrentReport
            )
        }
        concurrentBuffer = nil
        concurrent.authority.retire(concurrentTicket)
        probeRequire(concurrent.authority.snapshot.residentReadBytes == 0)

        let closed = try ProbeFixtures.make()
        let closedRegion = try ProbeRegion(
            rawLowerBounds: [0, 0],
            rawExtents: [2, 1],
            descriptor: closed.binding.descriptor,
            limits: closed.limits
        )
        let closedTicket = try closed.authority.begin(
            binding: closed.binding,
            region: closedRegion,
            freshness: .boundSnapshot
        )
        var closedBuffer: ProbePrivateBufferOwner? =
            closed.authority.makePrivateBuffer(for: closedTicket)
        let closedReport: ProbeFillReport
        do {
            guard let closedTarget = closedBuffer else {
                preconditionFailure("missing closed fill target")
            }
            let closedCapability = closedTarget.makeFillCapability()
            probeRequire(closedCapability.write(startOffset: 0, byte: 0x01))
            probeRequire(closedCapability.write(startOffset: 1, byte: 0x02))
            closedCapability.close()
            probeRequire(!closedCapability.write(startOffset: 2, byte: 0x03))
            closedReport = closedTarget.freeze()
        }
        probeRequire(
            closedReport
                == ProbeFillReport(initializedByteCount: 2, poisoned: false)
        )
        closed.authority.markAbandonedIfOpen(closedTicket)
        closedBuffer = nil
        closed.authority.retire(closedTicket)
        probeRequire(closed.authority.snapshot.residentReadBytes == 0)
    }

    private static func expectPoisonedFill(
        _ writes: (ProbeBoundedFillCapability) -> Void
    ) throws {
        let fixture = try ProbeFixtures.make()
        let region = try ProbeRegion(
            rawLowerBounds: [0, 0],
            rawExtents: [2, 1],
            descriptor: fixture.binding.descriptor,
            limits: fixture.limits
        )
        let ticket = try fixture.authority.begin(
            binding: fixture.binding,
            region: region,
            freshness: .boundSnapshot
        )
        var buffer: ProbePrivateBufferOwner? =
            fixture.authority.makePrivateBuffer(for: ticket)
        let report: ProbeFillReport
        do {
            guard let target = buffer else {
                preconditionFailure("missing poisoned fill target")
            }
            let capability = target.makeFillCapability()
            writes(capability)
            capability.close()
            report = target.freeze()
        }
        probeRequire(report.poisoned)
        probeRequireThrows(.incompleteRead) {
            try fixture.authority.prepare(
                ticket,
                output: .complete,
                report: report
            )
        }
        buffer = nil
        fixture.authority.retire(ticket)
        probeRequire(fixture.authority.snapshot.residentReadBytes == 0)
    }

    private static func testTombstoneReuseAndIndependentBudgetLedger() async throws {
        let limits = try ProbeLimits(
            maximumRank: 2,
            maximumExtent: 64,
            maximumRequestBytes: 32,
            maximumConcurrentReads: 2,
            maximumResidentReadBytes: 16,
            maximumLeaseBytes: 64,
            maximumConcurrentLeases: 2,
            maximumTombstones: 2
        )
        let fixture = try ProbeFixtures.make(limits: limits)
        let region = try ProbeRegion(
            rawLowerBounds: [0, 0],
            rawExtents: [1, 1],
            descriptor: fixture.binding.descriptor,
            limits: fixture.limits
        )
        let oldTicket = try fixture.authority.begin(
            binding: fixture.binding,
            region: region,
            freshness: .boundSnapshot
        )
        var oldPrepared: ProbeDirectPrepared? = try await prepareDirect(
            fixture: fixture,
            ticket: oldTicket
        )
        var retainedOldResult: ProbeReadResult?
        do {
            guard let oldPrepared else {
                preconditionFailure("missing retained old result package")
            }
            retainedOldResult = try fixture.authority.commit(
                oldTicket,
                candidate: oldPrepared.candidate,
                package: oldPrepared.package
            )
        }

        for _ in 0..<6 {
            var ephemeral: ProbeReadResult? = try await fixture.storage.read(
                rawLowerBounds: [1, 0],
                rawExtents: [1, 1],
                limits: fixture.limits
            )
            probeRequire(ephemeral?.copiedBytes == [1])
            ephemeral = nil
        }
        probeRequire(fixture.authority.snapshot.residentReadBytes == 1)
        probeRequire(fixture.authority.snapshot.liveCommittedResults == 1)

        let activeTicket = try fixture.authority.begin(
            binding: fixture.binding,
            region: region,
            freshness: .boundSnapshot
        )
        probeRequireThrows(.providerContractViolation) {
            guard let oldPrepared else {
                preconditionFailure("missing evicted replay candidate")
            }
            _ = try fixture.authority.commit(
                oldTicket,
                candidate: oldPrepared.candidate,
                package: oldPrepared.package
            )
        }
        probeRequire(fixture.authority.snapshot.inFlightRequests == 1)
        probeRequire(fixture.authority.snapshot.abandonedCount == 0)
        fixture.authority.markAbandonedIfOpen(activeTicket)
        fixture.authority.retire(activeTicket)

        probeRequire(retainedOldResult?.copiedBytes == [0])
        retainedOldResult = nil
        oldPrepared = nil
        probeRequire(fixture.authority.snapshot.residentReadBytes == 0)
        probeRequire(fixture.authority.snapshot.liveCommittedResults == 0)
    }

    private static func testOwnerRetentionAndExactlyOnceRelease() async throws {
        let successfulCounter = ProbeLifetimeCounter()
        var result: ProbeReadResult? = try await makeLifetimeRead(
            counter: successfulCounter
        )
        probeRequire(successfulCounter.value == 1)
        probeRequire(result?.copiedBytes == [5, 6])
        result = nil
        probeRequire(successfulCounter.value == 1)

        let cancelledCounter = ProbeLifetimeCounter()
        let returnedCancelledCounter = try await makeTerminalLifetimeRead(
            response: .cancelled,
            counter: cancelledCounter,
            expected: .cancelled
        )
        probeRequire(returnedCancelledCounter === cancelledCounter)
        probeRequire(cancelledCounter.value == 1)

        let failedCounter = ProbeLifetimeCounter()
        _ = try await makeTerminalLifetimeRead(
            response: .failed,
            counter: failedCounter,
            expected: .providerFailure
        )
        probeRequire(failedCounter.value == 1)

        let violationCounter = ProbeLifetimeCounter()
        _ = try await makeTerminalLifetimeRead(
            response: .long,
            counter: violationCounter,
            expected: .incompleteRead
        )
        probeRequire(violationCounter.value == 1)
    }

    private static func makeLifetimeRead(
        counter: ProbeLifetimeCounter
    ) async throws -> ProbeReadResult {
        let gate = ProbeSuspensionGate()
        let fixture = try ProbeFixtures.make(
            mode: .suspended(gate, .complete),
            lifetimeCounter: counter
        )
        return try await withThrowingTaskGroup(of: ProbeReadResult.self) { group in
            group.addTask {
                try await fixture.storage.read(
                    rawLowerBounds: [1, 1],
                    rawExtents: [2, 1],
                    limits: fixture.limits
                )
            }
            await gate.waitForArrivals(1)
            probeRequire(counter.value == 0)
            await gate.releaseAll()
            guard let result = try await group.next() else {
                preconditionFailure("missing lifetime result")
            }
            return result
        }
    }

    private static func makeTerminalLifetimeRead(
        response: ProbeProviderResponse,
        counter: ProbeLifetimeCounter,
        expected: ProbeReadError
    ) async throws -> ProbeLifetimeCounter {
        do {
            let fixture = try ProbeFixtures.make(
                mode: .immediate(response),
                lifetimeCounter: counter
            )
            _ = try await fixture.storage.read(
                rawLowerBounds: [1, 1],
                rawExtents: [2, 1],
                limits: fixture.limits
            )
            preconditionFailure("terminal lifetime read unexpectedly succeeded")
        } catch let error as ProbeReadError {
            probeRequire(error == expected)
        }
        return counter
    }

    private static func testScopedSpanAndRawSpanAccess() throws {
        let counter = ProbeLifetimeCounter()
        try exerciseScopedAccess(counter: counter)
        probeRequire(counter.value == 1)

        let mutableMapped = try ProbeFixtures.make(
            mappedChangePolicy: .externallyMutable
        )
        probeRequireThrows(.externallyMutableMapping) {
            try mutableMapped.storage.withContents(
                for: .mappedRepresentation
            ) { contents in
                contents.count
            }
        }
        probeRequire(mutableMapped.authority.snapshot.activeLeases == 0)
    }

    private static func exerciseScopedAccess(
        counter: ProbeLifetimeCounter
    ) throws {
        let fixture = try ProbeFixtures.make(lifetimeCounter: counter)
        let typedBytes = try fixture.storage.withContents(
            for: .contiguousDecoded
        ) { contents in
            let typed: Span<UInt8> = contents.span
            probeRequire(typed.count == 12)
            probeRequire(counter.value == 0)
            var copied: ContiguousArray<UInt8> = []
            copied.reserveCapacity(typed.count)
            for index in typed.indices {
                copied.append(typed[index])
            }
            return copied
        }
        probeRequire(typedBytes == ProbeFixtures.defaultBytes)
        probeRequire(fixture.authority.snapshot.activeLeases == 0)

        let rawBytes = try fixture.storage.withContents(
            for: .mappedRepresentation
        ) { contents in
            let raw: RawSpan = contents.bytes
            probeRequire(raw.byteCount == 12)
            probeRequire(counter.value == 0)
            let copied = ContiguousArray(contents)
            probeRequire(copied.count == raw.byteCount)
            return copied
        }
        probeRequire(rawBytes == ProbeFixtures.defaultBytes)
        probeRequire(fixture.authority.snapshot.activeLeases == 0)
    }

    private static func testRedactedDiagnostics() async throws {
        let sensitiveBytes = ContiguousArray(
            "patient-name-sentinel/private/input.nii".utf8.prefix(12)
        )
        let fixture = try ProbeFixtures.make(bytes: sensitiveBytes)
        let result = try await fixture.storage.read(
            rawLowerBounds: [0, 0],
            rawExtents: [2, 1],
            limits: fixture.limits
        )
        let error = ProbeReadError.providerContractViolation

        probeRequire(String(describing: error) == "storage read probe rejected input")
        probeRequire(String(reflecting: error) == "storage read probe rejected input")
        probeRequire(String(describing: fixture.storage) == ProbeDiagnostic.redactionMarker)
        probeRequire(String(reflecting: fixture.binding) == ProbeDiagnostic.redactionMarker)
        probeRequire(String(describing: result) == ProbeDiagnostic.redactionMarker)

        var captured = ProbeCapturedText()
        dump(error, to: &captured)
        dump(fixture.storage, to: &captured)
        dump(fixture.binding, to: &captured)
        dump(result, to: &captured)
        for forbidden in [
            "patient-name-sentinel",
            "/private/input.nii",
            "snapshotIdentity",
            "providerIdentity",
            "ownerIdentity",
            "RequestSeal",
            "0x",
        ] {
            probeRequire(!captured.value.contains(forbidden))
        }
        probeRequire(captured.value.contains(ProbeDiagnostic.redactionMarker))
    }

    private static func prepareDirect(
        fixture: ProbeFixture,
        ticket: ProbeReadTicket
    ) async throws -> ProbeDirectPrepared {
        var buffer: ProbePrivateBufferOwner? =
            fixture.authority.makePrivateBuffer(for: ticket)
        do {
            guard let retainedBuffer = buffer else {
                throw ProbeReadError.allocationFailure
            }
            let capability = retainedBuffer.makeFillCapability()
            let output = await fixture.provider.fill(
                ticket.providerRequest,
                into: capability
            )
            capability.close()
            let report = retainedBuffer.freeze()
            let candidate = try fixture.authority.prepare(
                ticket,
                output: output,
                report: report
            )
            return ProbeDirectPrepared(
                candidate: candidate,
                buffer: retainedBuffer,
                package: fixture.authority.prepareResultPackage(
                    candidate: candidate,
                    buffer: retainedBuffer
                )
            )
        } catch {
            fixture.authority.markAbandonedIfOpen(ticket)
            buffer = nil
            fixture.authority.retire(ticket)
            throw error
        }
    }

    private static func testNegativeConfigurationsAreSourceGated() throws {
        let sourceGateNames = [
            "ADR0041_SPAN_ESCAPE_SHOULD_FAIL",
            "ADR0041_RAW_SPAN_ESCAPE_SHOULD_FAIL",
        ]
        probeRequire(sourceGateNames.count == 2)
        probeRequire(Set(sourceGateNames).count == 2)
    }
}

extension ProbeAccessKind {
    fileprivate static var allCases: [Self] {
        [.contiguousDecoded, .mappedRepresentation]
    }
}
