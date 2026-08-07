// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by headless-output admission.
public enum HeadlessOutputError: Error, Sendable, Equatable {
    /// The requested dynamic range is not in the backend's declared
    /// support — refused typed, never silently downgraded.
    case unsupportedDynamicRange
    /// A requested auxiliary output is not in the backend's declared
    /// support — refused typed, never silently omitted.
    case unsupportedAuxiliaryOutput
}

/// The closed dynamic-range vocabulary of `VOX-HLS-006`.
public enum OutputDynamicRange: String, Sendable, Hashable, Codable {
    case sdr
    case hdr
}

/// The closed auxiliary-output vocabulary of `VOX-HLS-007`.
public enum AuxiliaryOutput: String, Sendable, Hashable, Codable {
    case depth
    case objectIdentifier
}

/// What one backend declares it can produce, per `ADR-0400`.
public struct HeadlessOutputCapabilities: Sendable, Hashable {
    public let supportedRanges: Set<OutputDynamicRange>
    public let supportedAuxiliaries: Set<AuxiliaryOutput>

    public init(
        supportedRanges: Set<OutputDynamicRange>,
        supportedAuxiliaries: Set<AuxiliaryOutput>
    ) {
        self.supportedRanges = supportedRanges
        self.supportedAuxiliaries = supportedAuxiliaries
    }
}

/// One explicit headless output request: a dynamic range and an
/// optional auxiliary selection — the empty selection is valid,
/// because optional means optional.
public struct HeadlessOutputDescriptor: Sendable, Hashable {
    public let dynamicRange: OutputDynamicRange
    public let auxiliaries: Set<AuxiliaryOutput>

    public init(
        dynamicRange: OutputDynamicRange,
        auxiliaries: Set<AuxiliaryOutput>
    ) {
        self.dynamicRange = dynamicRange
        self.auxiliaries = auxiliaries
    }

    /// Admits this request against a backend's declared capabilities.
    ///
    /// - Throws: ``HeadlessOutputError``.
    public func validate(
        against capabilities: HeadlessOutputCapabilities
    ) throws {
        guard capabilities.supportedRanges.contains(dynamicRange) else {
            throw HeadlessOutputError.unsupportedDynamicRange
        }
        guard auxiliaries.isSubset(of: capabilities.supportedAuxiliaries) else {
            throw HeadlessOutputError.unsupportedAuxiliaryOutput
        }
    }
}

/// The optional media-buffer seam of `VOX-HLS-005`, in the `ADR-0378`
/// shape: core modules never name `CVPixelBuffer` — a CoreVideo-backed
/// conformance lives in an adapter package when a host wants one.
public protocol MediaBufferAdapter: Sendable {
    associatedtype Buffer

    /// The adapter's stable identity, for provenance.
    var adapterIdentity: String { get }

    /// Wraps raw pixel bytes and their descriptor in the adapter's
    /// buffer representation.
    func buffer(
        rawPixels: ContiguousArray<UInt8>,
        descriptor: HeadlessOutputDescriptor,
        width: Int,
        height: Int
    ) throws -> Buffer
}
