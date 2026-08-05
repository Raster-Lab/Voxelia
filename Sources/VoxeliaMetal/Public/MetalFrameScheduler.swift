// SPDX-License-Identifier: MIT

/// An error raised by frame scheduling.
///
/// Cases deliberately carry no payload; the bound and the token are
/// the whole story.
public enum MetalFrameError: Error, Sendable, Equatable {
    case invalidInFlightLimit
    case inFlightLimitExceeded
    case invalidRelease
}

/// One in-flight frame token per `ADR-0110`.
///
/// The token is identity and ordering evidence only: the monotonic
/// frame index proves acquisition order, and the scheduler frees a
/// slot exactly once per token. Per-frame resource slots arrive with
/// their consumers through their own decisions.
public final class MetalFrameToken: Sendable {
    /// The monotonic acquisition index, as ordering evidence.
    public let frameIndex: UInt64

    init(frameIndex: UInt64) {
        self.frameIndex = frameIndex
    }
}

/// The bounded in-flight frame scheduler per `ADR-0110`
/// (`VOX-MTL-006`).
///
/// Construction takes the explicit inclusive in-flight ceiling — no
/// permissive default — and acquisition at the bound is a typed
/// rejection per the budget-ledger precedent: pacing is the
/// interactive loop's own future decision, and the caller owns the
/// cadence. Release-once reuse mirrors the retention-token
/// discipline.
public actor MetalFrameScheduler {
    /// The inclusive in-flight frame ceiling.
    public let maximumInFlightFrameCount: Int

    private var inFlightTokens = Set<ObjectIdentifier>()
    private var nextFrameIndex: UInt64 = 0

    /// Creates a scheduler with an explicit bound of at least one.
    ///
    /// - Throws: ``MetalFrameError/invalidInFlightLimit``.
    public init(maximumInFlightFrameCount: Int) throws {
        guard maximumInFlightFrameCount >= 1 else {
            throw MetalFrameError.invalidInFlightLimit
        }
        self.maximumInFlightFrameCount = maximumInFlightFrameCount
    }

    /// The currently in-flight frame count.
    public var inFlightFrameCount: Int {
        inFlightTokens.count
    }

    /// Acquires one frame slot.
    ///
    /// - Throws: ``MetalFrameError/inFlightLimitExceeded`` at the
    ///   bound.
    public func acquireFrame() throws -> MetalFrameToken {
        guard inFlightTokens.count < maximumInFlightFrameCount else {
            throw MetalFrameError.inFlightLimitExceeded
        }
        let token = MetalFrameToken(frameIndex: nextFrameIndex)
        nextFrameIndex += 1
        inFlightTokens.insert(ObjectIdentifier(token))
        return token
    }

    /// Releases one frame slot exactly once.
    ///
    /// - Throws: ``MetalFrameError/invalidRelease`` for a foreign or
    ///   already-released token.
    public func releaseFrame(_ token: MetalFrameToken) throws {
        guard inFlightTokens.remove(ObjectIdentifier(token)) != nil else {
            throw MetalFrameError.invalidRelease
        }
    }
}
