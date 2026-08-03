// SPDX-License-Identifier: MIT

import CryptoKit
import Foundation

// Isolated Swift 6 evidence for proposed ADR-0039. These declarations are not
// Voxelia product API, a canonical storage wire, unsafe-buffer code, a
// production storage implementation, or production resource limits.

enum ProbeStorageError: Error, Sendable, Equatable {
    case invalidLimits
    case invalidText
    case invalidCapabilityWire
    case unknownCapabilityBits
    case missingReadPath
    case missingCapabilityWitness
    case unexpectedCapabilityWitness
    case capabilityConflict
    case invalidShape
    case invalidScalar
    case invalidComponents
    case rankMismatch
    case invalidLayout
    case overlappingLayout
    case arithmeticOverflow
    case byteLengthRequired
    case byteLengthInsufficient
    case invalidAlignment
    case invalidBacking
    case invalidOrganization
    case invalidResolution
    case invalidIntegrityClaim
    case unstableByteOrder
    case unsupportedAccess
    case regionOutOfBounds
    case destinationMismatch
    case partialRead
    case failedRead
    case cancelled
    case staleGeneration
    case integrityDenied
    case duplicateWrite
    case unknownWrite
    case failedWrite
    case invalidWritePartition
    case incompleteBuilder
    case alreadyCommitted
}

enum ProbePlatformByteCeiling {
    // The evidence intentionally chooses a conservative materialization ceiling
    // below Int.max. A product value must be platform-derived and versioned.
    static let maximumMaterializedByteCount = min(UInt64(Int.max), 1 << 30)
    static let maximumDescribedByteCount = min(UInt64(Int.max), 1 << 40)
}

protocol ProbeRedactedDiagnostic:
    CustomStringConvertible,
    CustomDebugStringConvertible,
    CustomReflectable
{}

extension ProbeRedactedDiagnostic {
    var description: String { "<redacted-storage-probe>" }
    var debugDescription: String { description }
    var customMirror: Mirror {
        Mirror(self, children: ["value": "<redacted-storage-probe>"])
    }
}

extension ProbeStorageError: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String { "storage probe rejected input" }
    var debugDescription: String { description }
}

struct ProbeBoundedBytes: Sendable, Hashable, ProbeRedactedDiagnostic {
    private let bytes: ContiguousArray<UInt8>

    let count: UInt64

    init(
        _ source: some Sequence<UInt8>,
        maximumByteCount: UInt64
    ) throws {
        guard
            maximumByteCount > 0,
            maximumByteCount <= ProbePlatformByteCeiling.maximumMaterializedByteCount
        else {
            throw ProbeStorageError.invalidLimits
        }
        var accepted: ContiguousArray<UInt8> = []
        accepted.reserveCapacity(Int(min(maximumByteCount, 4_096)))
        for byte in source {
            guard UInt64(accepted.count) < maximumByteCount else {
                throw ProbeStorageError.byteLengthInsufficient
            }
            accepted.append(byte)
        }
        bytes = accepted
        count = UInt64(accepted.count)
    }

    fileprivate var exactData: Data { Data(bytes) }

    fileprivate func prefix(count requestedCount: UInt64) throws -> Self {
        guard requestedCount > 0, requestedCount <= count else {
            throw ProbeStorageError.partialRead
        }
        return try Self(
            bytes.prefix(Int(requestedCount)),
            maximumByteCount: requestedCount
        )
    }

    fileprivate var exactBytes: ContiguousArray<UInt8> { bytes }
}

struct ProbeExactText: Sendable, Hashable, Comparable, ProbeRedactedDiagnostic {
    private static let hardMaximumUTF8Bytes = 256
    private let bytes: ContiguousArray<UInt8>

    init(_ value: String, maximumUTF8Bytes: Int = 64) throws {
        guard
            maximumUTF8Bytes > 0,
            maximumUTF8Bytes <= Self.hardMaximumUTF8Bytes
        else {
            throw ProbeStorageError.invalidLimits
        }
        var accepted: ContiguousArray<UInt8> = []
        accepted.reserveCapacity(maximumUTF8Bytes)
        for byte in value.utf8 {
            guard accepted.count < maximumUTF8Bytes else {
                throw ProbeStorageError.invalidText
            }
            accepted.append(byte)
        }
        guard value.contains(where: { !$0.isWhitespace }) else {
            throw ProbeStorageError.invalidText
        }
        bytes = accepted
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes.lexicographicallyPrecedes(rhs.bytes)
    }
}

enum ProbeStorageCapability: UInt64, Sendable, Hashable, CaseIterable {
    // These probe-only positions demonstrate the proposed closed access subset.
    case scopedContiguousByteAccess = 0x0000_0000_0000_0001
    case mappedRepresentationAccess = 0x0000_0000_0000_0002
    case builderAcquisition = 0x0000_0000_0000_0004
    case regionEnumeration = 0x0000_0000_0000_0008
    case nativeTileAccess = 0x0000_0000_0000_0010
    case nativeBrickAccess = 0x0000_0000_0000_0020
    case compressedRepresentationAccess = 0x0000_0000_0000_0040
    case resolutionLevelAccess = 0x0000_0000_0000_0080
    case prefetchHints = 0x0000_0000_0000_0100
    case scopedDigestAccess = 0x0000_0000_0000_0200
}

struct ProbeCapabilityClaim: Sendable, Hashable, ProbeRedactedDiagnostic {
    static let knownMask = ProbeStorageCapability.allCases.reduce(UInt64(0)) {
        $0 | $1.rawValue
    }

    let rawValue: UInt64

    var unknownBits: UInt64 { rawValue & ~Self.knownMask }

    func contains(_ capability: ProbeStorageCapability) -> Bool {
        rawValue & capability.rawValue == capability.rawValue
    }

    var knownCapabilities: Set<ProbeStorageCapability> {
        Set(ProbeStorageCapability.allCases.filter(contains))
    }
}

struct ProbeCapabilityEnvelope: Sendable, Hashable, ProbeRedactedDiagnostic {
    private static let prefix = ContiguousArray(#"{"schemaVersion":1,"bits":""#.utf8)
    private static let suffix = ContiguousArray(#""}"#.utf8)
    private static let hexadecimal = ContiguousArray("0123456789abcdef".utf8)

    let claim: ProbeCapabilityClaim

    init(wire: String) throws {
        let expectedCount = Self.prefix.count + 16 + Self.suffix.count
        var bytes: ContiguousArray<UInt8> = []
        bytes.reserveCapacity(expectedCount)
        for byte in wire.utf8 {
            guard bytes.count < expectedCount else {
                throw ProbeStorageError.invalidCapabilityWire
            }
            bytes.append(byte)
        }
        guard bytes.count == expectedCount,
            bytes.prefix(Self.prefix.count).elementsEqual(Self.prefix),
            bytes.suffix(Self.suffix.count).elementsEqual(Self.suffix)
        else {
            throw ProbeStorageError.invalidCapabilityWire
        }

        var rawValue: UInt64 = 0
        for byte in bytes.dropFirst(Self.prefix.count).dropLast(Self.suffix.count) {
            guard let nibble = Self.hexadecimal.firstIndex(of: byte) else {
                throw ProbeStorageError.invalidCapabilityWire
            }
            let (shifted, overflow) = rawValue.multipliedReportingOverflow(by: 16)
            guard !overflow else { throw ProbeStorageError.arithmeticOverflow }
            rawValue = shifted | UInt64(nibble)
        }

        let claim = ProbeCapabilityClaim(rawValue: rawValue)
        if claim.unknownBits != 0 {
            throw ProbeStorageError.unknownCapabilityBits
        }
        self.claim = claim
    }

    init(claim: ProbeCapabilityClaim) throws {
        guard claim.unknownBits == 0 else {
            throw ProbeStorageError.unknownCapabilityBits
        }
        self.claim = claim
    }

    var wire: String {
        var bytes = Self.prefix
        bytes.reserveCapacity(Self.prefix.count + 16 + Self.suffix.count)
        for shift in stride(from: 60, through: 0, by: -4) {
            let nibble = Int((claim.rawValue >> UInt64(shift)) & 0xF)
            bytes.append(Self.hexadecimal[nibble])
        }
        bytes.append(contentsOf: Self.suffix)
        return String(decoding: bytes, as: UTF8.self)
    }
}

// This deliberately narrow forwarding type preserves only the exact fixed-width
// capability-bits envelope demonstrated here. It is not a general unknown-JSON
// or future-schema container and cannot be admitted operationally.
struct ProbeOpaqueFixedWidthCapabilityEnvelope:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    private static let maximumByteCount = 256
    private static let prefix = ContiguousArray(#"{"schemaVersion":"#.utf8)
    private static let marker = ContiguousArray(#","bits":""#.utf8)
    private static let suffix = ContiguousArray(#""}"#.utf8)
    private static let hexadecimal = ContiguousArray("0123456789abcdef".utf8)
    private let bytes: ContiguousArray<UInt8>

    init(wire: String) throws {
        try self.init(rawUTF8: wire.utf8)
    }

    init(rawUTF8: some Sequence<UInt8>) throws {
        var bytes: ContiguousArray<UInt8> = []
        bytes.reserveCapacity(Self.maximumByteCount)
        for byte in rawUTF8 {
            guard bytes.count < Self.maximumByteCount else {
                throw ProbeStorageError.invalidCapabilityWire
            }
            bytes.append(byte)
        }

        let fixedTailCount = Self.marker.count + 16 + Self.suffix.count
        guard
            bytes.count > Self.prefix.count + fixedTailCount,
            bytes.prefix(Self.prefix.count).elementsEqual(Self.prefix),
            bytes.suffix(Self.suffix.count).elementsEqual(Self.suffix)
        else {
            throw ProbeStorageError.invalidCapabilityWire
        }
        let versionEnd = bytes.count - fixedTailCount
        guard
            bytes[versionEnd..<(versionEnd + Self.marker.count)]
                .elementsEqual(Self.marker)
        else {
            throw ProbeStorageError.invalidCapabilityWire
        }

        let versionBytes = bytes[Self.prefix.count..<versionEnd]
        guard
            !versionBytes.isEmpty,
            versionBytes.count <= 20,
            versionBytes.first != 48
        else {
            throw ProbeStorageError.invalidCapabilityWire
        }
        var version: UInt64 = 0
        for byte in versionBytes {
            guard (48...57).contains(byte) else {
                throw ProbeStorageError.invalidCapabilityWire
            }
            let (shifted, multiplyOverflow) = version.multipliedReportingOverflow(by: 10)
            let (next, addOverflow) = shifted.addingReportingOverflow(UInt64(byte - 48))
            guard !multiplyOverflow, !addOverflow else {
                throw ProbeStorageError.invalidCapabilityWire
            }
            version = next
        }
        guard version > 1 else {
            throw ProbeStorageError.invalidCapabilityWire
        }

        let bitsStart = versionEnd + Self.marker.count
        let bitsEnd = bitsStart + 16
        let validBits = bytes[bitsStart..<bitsEnd].allSatisfy {
            Self.hexadecimal.contains($0)
        }
        guard validBits else {
            throw ProbeStorageError.invalidCapabilityWire
        }
        self.bytes = bytes
    }

    var forwardedWire: String { String(decoding: bytes, as: UTF8.self) }
}

struct ProbeDescriptorLimits: Sendable, Hashable {
    private static let hardMaximumRank: UInt64 = 64
    private static let hardMaximumExtent: UInt64 = 1 << 30
    private static let hardMaximumComponents: UInt64 = 64
    private static let hardMaximumLogicalByteCount =
        ProbePlatformByteCeiling.maximumDescribedByteCount
    private static let hardMaximumRepresentationByteLength =
        ProbePlatformByteCeiling.maximumMaterializedByteCount
    private static let hardMaximumRequestByteLength =
        ProbePlatformByteCeiling.maximumMaterializedByteCount
    private static let hardMaximumAlignment: UInt64 = 1 << 30
    private static let hardMaximumResolutionLevels: UInt64 = 1 << 20
    private static let hardMaximumBuilderSlots: UInt64 = 64

    let maximumRank: UInt64
    let maximumExtent: UInt64
    let maximumComponents: UInt64
    let maximumLogicalByteCount: UInt64
    let maximumRepresentationByteLength: UInt64
    let maximumRequestByteLength: UInt64
    let maximumAlignment: UInt64
    let maximumResolutionLevels: UInt64
    let maximumBuilderSlots: UInt64

    init(
        maximumRank: UInt64,
        maximumExtent: UInt64,
        maximumComponents: UInt64,
        maximumLogicalByteCount: UInt64,
        maximumRepresentationByteLength: UInt64,
        maximumRequestByteLength: UInt64,
        maximumAlignment: UInt64,
        maximumResolutionLevels: UInt64,
        maximumBuilderSlots: UInt64
    ) throws {
        guard maximumRank > 0, maximumRank <= Self.hardMaximumRank,
            maximumExtent > 0, maximumExtent <= Self.hardMaximumExtent,
            maximumComponents > 0,
            maximumComponents <= Self.hardMaximumComponents,
            maximumLogicalByteCount > 0,
            maximumLogicalByteCount <= Self.hardMaximumLogicalByteCount,
            maximumRepresentationByteLength > 0,
            maximumRepresentationByteLength <= Self.hardMaximumRepresentationByteLength,
            maximumRequestByteLength > 0,
            maximumRequestByteLength <= Self.hardMaximumRequestByteLength,
            maximumAlignment > 0,
            maximumAlignment <= Self.hardMaximumAlignment,
            maximumResolutionLevels > 0,
            maximumResolutionLevels <= Self.hardMaximumResolutionLevels,
            maximumBuilderSlots > 0,
            maximumBuilderSlots <= Self.hardMaximumBuilderSlots
        else {
            throw ProbeStorageError.invalidLimits
        }
        self.maximumRank = maximumRank
        self.maximumExtent = maximumExtent
        self.maximumComponents = maximumComponents
        self.maximumLogicalByteCount = maximumLogicalByteCount
        self.maximumRepresentationByteLength = maximumRepresentationByteLength
        self.maximumRequestByteLength = maximumRequestByteLength
        self.maximumAlignment = maximumAlignment
        self.maximumResolutionLevels = maximumResolutionLevels
        self.maximumBuilderSlots = maximumBuilderSlots
    }

    static func probeDefault() throws -> Self {
        try Self(
            maximumRank: 8,
            maximumExtent: 1_024,
            maximumComponents: 8,
            maximumLogicalByteCount: 1 << 40,
            maximumRepresentationByteLength: 64 * 1_024 * 1_024,
            maximumRequestByteLength: 64 * 1_024 * 1_024,
            maximumAlignment: 4_096,
            maximumResolutionLevels: 16,
            maximumBuilderSlots: 16
        )
    }
}

struct ProbeShape: Sendable, Hashable, ProbeRedactedDiagnostic {
    let extents: ContiguousArray<UInt64>

    init(
        extents: some Sequence<UInt64>,
        limits: ProbeDescriptorLimits
    ) throws {
        var accepted: ContiguousArray<UInt64> = []
        for extent in extents {
            guard UInt64(accepted.count) < limits.maximumRank else {
                throw ProbeStorageError.invalidShape
            }
            guard extent > 0, extent <= limits.maximumExtent else {
                throw ProbeStorageError.invalidShape
            }
            accepted.append(extent)
        }
        guard !accepted.isEmpty else { throw ProbeStorageError.invalidShape }
        self.extents = accepted
    }

    var rank: Int { extents.count }
}

enum ProbeByteOrder: UInt8, Sendable, Hashable {
    case native
    case littleEndian
    case bigEndian
}

struct ProbeScalarFormat: Sendable, Hashable, ProbeRedactedDiagnostic {
    let byteWidth: UInt64
    let byteOrder: ProbeByteOrder

    init(byteWidth: UInt64, byteOrder: ProbeByteOrder) throws {
        guard [1, 2, 4, 8].contains(byteWidth) else {
            throw ProbeStorageError.invalidScalar
        }
        self.byteWidth = byteWidth
        self.byteOrder = byteOrder
    }
}

enum ProbeComponentLayout: UInt8, Sendable, Hashable {
    case interleaved
    case planar
    case storageDefined
}

struct ProbeComponents: Sendable, Hashable, ProbeRedactedDiagnostic {
    let count: UInt64
    let layout: ProbeComponentLayout

    init(
        count: UInt64,
        layout: ProbeComponentLayout,
        limits: ProbeDescriptorLimits
    ) throws {
        guard count > 0, count <= limits.maximumComponents else {
            throw ProbeStorageError.invalidComponents
        }
        self.count = count
        self.layout = layout
    }
}

enum ProbeStorageLocality: UInt8, Sendable, Hashable {
    case local
    case remote
}

enum ProbeProviderMechanism: UInt8, Sendable, Hashable {
    case ownedMemory
    case mappedFile
    case callback
}

enum ProbePersistence: UInt8, Sendable, Hashable {
    case transient
    case processLifetime
    case mappedFile
    case persistentCache
    case external
}

enum ProbeOpaqueRepresentation: UInt8, Sendable, Hashable {
    case compressed
    case providerDefined
}

struct ProbeStridedLayout: Sendable, Hashable, ProbeRedactedDiagnostic {
    let baseOffset: UInt64
    let axisByteStrides: ContiguousArray<UInt64>
    let componentByteStride: UInt64
}

enum ProbeRepresentation: Sendable, Hashable, ProbeRedactedDiagnostic {
    case decodedStrided(ProbeStridedLayout)
    case opaque(ProbeOpaqueRepresentation)
}

struct ProbeStorageOwnerID: Sendable, Hashable, ProbeRedactedDiagnostic {
    let value: ProbeExactText
}

struct ProbeStorageSnapshotID: Sendable, Hashable, ProbeRedactedDiagnostic {
    let value: ProbeExactText
}

enum ProbeRepresentationDigestAlgorithm: UInt8, Sendable, Hashable {
    case sha256

    var digestByteCount: Int {
        switch self {
        case .sha256:
            32
        }
    }
}

struct ProbeRepresentationDescriptorBinding:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    let shape: ProbeShape
    let scalar: ProbeScalarFormat
    let components: ProbeComponents
    let organization: ProbeStorageOrganization
    let representation: ProbeRepresentation
    let locality: ProbeStorageLocality
    let providerMechanism: ProbeProviderMechanism
    let persistence: ProbePersistence
    let resolutionLevelCount: UInt64
    let representationByteLength: UInt64?
    let alignment: UInt64?
}

struct ProbeRepresentationIntegrityClaim:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    let projectionID: ProbeExactText
    let projectionVersion: UInt64
    let descriptorBinding: ProbeRepresentationDescriptorBinding
    let snapshotID: ProbeStorageSnapshotID
    let generation: UInt64
    let algorithm: ProbeRepresentationDigestAlgorithm
    let digest: ContiguousArray<UInt8>
    let representationByteLength: UInt64

    init(
        projectionID: ProbeExactText,
        projectionVersion: UInt64,
        descriptorBinding: ProbeRepresentationDescriptorBinding,
        snapshotID: ProbeStorageSnapshotID,
        generation: UInt64,
        algorithm: ProbeRepresentationDigestAlgorithm,
        digest: some Sequence<UInt8>,
        representationByteLength: UInt64
    ) throws {
        var acceptedDigest: ContiguousArray<UInt8> = []
        acceptedDigest.reserveCapacity(algorithm.digestByteCount)
        for byte in digest {
            guard acceptedDigest.count < algorithm.digestByteCount else {
                throw ProbeStorageError.invalidIntegrityClaim
            }
            acceptedDigest.append(byte)
        }
        guard
            projectionVersion > 0,
            acceptedDigest.count == algorithm.digestByteCount,
            representationByteLength > 0
        else {
            throw ProbeStorageError.invalidIntegrityClaim
        }
        self.projectionID = projectionID
        self.projectionVersion = projectionVersion
        self.descriptorBinding = descriptorBinding
        self.snapshotID = snapshotID
        self.generation = generation
        self.algorithm = algorithm
        self.digest = acceptedDigest
        self.representationByteLength = representationByteLength
    }
}

private func probeCheckedAdd(_ lhs: UInt64, _ rhs: UInt64) throws -> UInt64 {
    let (value, overflow) = lhs.addingReportingOverflow(rhs)
    guard !overflow else { throw ProbeStorageError.arithmeticOverflow }
    return value
}

private func probeCheckedMultiply(_ lhs: UInt64, _ rhs: UInt64) throws -> UInt64 {
    let (value, overflow) = lhs.multipliedReportingOverflow(by: rhs)
    guard !overflow else { throw ProbeStorageError.arithmeticOverflow }
    return value
}

private func probeLogicalByteCount(
    shape: ProbeShape,
    scalar: ProbeScalarFormat,
    components: ProbeComponents,
    limits: ProbeDescriptorLimits
) throws -> UInt64 {
    var count: UInt64 = 1
    for extent in shape.extents {
        count = try probeCheckedMultiply(count, extent)
    }
    count = try probeCheckedMultiply(count, components.count)
    count = try probeCheckedMultiply(count, scalar.byteWidth)
    guard count <= limits.maximumLogicalByteCount else {
        throw ProbeStorageError.byteLengthInsufficient
    }
    return count
}

enum ProbeStorageOrganization: UInt8, Sendable, Hashable {
    case linear
    case tiled
    case bricked
    case providerDefined
}

struct ProbeStorageDescriptor: Sendable, Hashable, ProbeRedactedDiagnostic {
    let shape: ProbeShape
    let scalar: ProbeScalarFormat
    let components: ProbeComponents
    let organization: ProbeStorageOrganization
    let representation: ProbeRepresentation
    let locality: ProbeStorageLocality
    let providerMechanism: ProbeProviderMechanism
    let persistence: ProbePersistence
    let resolutionLevelCount: UInt64
    let representationByteLength: UInt64?
    let alignment: UInt64?
    let integrityClaim: ProbeRepresentationIntegrityClaim?
    let representationBinding: ProbeRepresentationDescriptorBinding
    let logicalByteCount: UInt64
    let requiredRepresentationByteLength: UInt64?

    init(
        shape: ProbeShape,
        scalar: ProbeScalarFormat,
        components: ProbeComponents,
        organization: ProbeStorageOrganization,
        representation: ProbeRepresentation,
        providerMechanism: ProbeProviderMechanism,
        locality: ProbeStorageLocality = .local,
        persistence: ProbePersistence,
        resolutionLevelCount: UInt64,
        representationByteLength: UInt64?,
        alignment: UInt64?,
        integrityClaim: ProbeRepresentationIntegrityClaim?,
        limits: ProbeDescriptorLimits
    ) throws {
        guard
            resolutionLevelCount > 0,
            resolutionLevelCount <= limits.maximumResolutionLevels
        else {
            throw ProbeStorageError.invalidResolution
        }
        if let representationByteLength {
            guard
                representationByteLength > 0,
                representationByteLength <= limits.maximumRepresentationByteLength
            else {
                throw ProbeStorageError.byteLengthInsufficient
            }
        }
        if let alignment {
            guard
                alignment > 0,
                alignment <= limits.maximumAlignment,
                alignment & (alignment - 1) == 0
            else {
                throw ProbeStorageError.invalidAlignment
            }
        }
        if persistence == .mappedFile, providerMechanism != .mappedFile {
            throw ProbeStorageError.invalidBacking
        }
        let requiredRepresentationByteLength: UInt64?
        switch representation {
        case .decodedStrided(let layout):
            guard components.layout != .storageDefined else {
                throw ProbeStorageError.invalidLayout
            }
            guard let representationByteLength else {
                throw ProbeStorageError.byteLengthRequired
            }
            let required = try Self.validate(
                layout: layout,
                shape: shape,
                scalar: scalar,
                components: components,
                alignment: alignment
            )
            guard required <= representationByteLength else {
                throw ProbeStorageError.byteLengthInsufficient
            }
            if scalar.byteWidth > 1, scalar.byteOrder == .native {
                guard
                    providerMechanism == .ownedMemory,
                    persistence == .transient || persistence == .processLifetime
                else {
                    throw ProbeStorageError.unstableByteOrder
                }
            }
            requiredRepresentationByteLength = required
        case .opaque:
            guard alignment == nil else {
                throw ProbeStorageError.invalidAlignment
            }
            requiredRepresentationByteLength = nil
        }

        let representationBinding = ProbeRepresentationDescriptorBinding(
            shape: shape,
            scalar: scalar,
            components: components,
            organization: organization,
            representation: representation,
            locality: locality,
            providerMechanism: providerMechanism,
            persistence: persistence,
            resolutionLevelCount: resolutionLevelCount,
            representationByteLength: representationByteLength,
            alignment: alignment
        )
        if let integrityClaim {
            guard
                let representationByteLength,
                integrityClaim.representationByteLength == representationByteLength,
                integrityClaim.descriptorBinding == representationBinding
            else {
                throw ProbeStorageError.invalidIntegrityClaim
            }
        }

        self.shape = shape
        self.scalar = scalar
        self.components = components
        self.organization = organization
        self.representation = representation
        self.locality = locality
        self.providerMechanism = providerMechanism
        self.persistence = persistence
        self.resolutionLevelCount = resolutionLevelCount
        self.representationByteLength = representationByteLength
        self.alignment = alignment
        self.integrityClaim = integrityClaim
        self.representationBinding = representationBinding
        logicalByteCount = try probeLogicalByteCount(
            shape: shape,
            scalar: scalar,
            components: components,
            limits: limits
        )
        self.requiredRepresentationByteLength = requiredRepresentationByteLength
    }

    private static func validate(
        layout: ProbeStridedLayout,
        shape: ProbeShape,
        scalar: ProbeScalarFormat,
        components: ProbeComponents,
        alignment: UInt64?
    ) throws -> UInt64 {
        guard layout.axisByteStrides.count == shape.rank else {
            throw ProbeStorageError.rankMismatch
        }
        guard layout.axisByteStrides.allSatisfy({ $0 > 0 }) else {
            throw ProbeStorageError.invalidLayout
        }
        guard layout.componentByteStride > 0 else {
            throw ProbeStorageError.invalidLayout
        }
        if let alignment, !layout.baseOffset.isMultiple(of: alignment) {
            throw ProbeStorageError.invalidAlignment
        }

        let axisDimensions = Array(zip(shape.extents, layout.axisByteStrides))
        let axisSpan = try nonoverlappingSpan(
            dimensions: axisDimensions,
            scalarByteWidth: scalar.byteWidth
        )

        switch components.layout {
        case .interleaved:
            guard layout.componentByteStride == scalar.byteWidth else {
                throw ProbeStorageError.invalidLayout
            }
        case .planar:
            guard layout.componentByteStride >= axisSpan else {
                throw ProbeStorageError.overlappingLayout
            }
        case .storageDefined:
            throw ProbeStorageError.invalidLayout
        }

        var dimensions = axisDimensions
        dimensions.append((components.count, layout.componentByteStride))
        let span = try nonoverlappingSpan(
            dimensions: dimensions,
            scalarByteWidth: scalar.byteWidth
        )
        return try probeCheckedAdd(layout.baseOffset, span)
    }

    private static func nonoverlappingSpan(
        dimensions: [(UInt64, UInt64)],
        scalarByteWidth: UInt64
    ) throws -> UInt64 {
        let active =
            dimensions
            .filter { $0.0 > 1 }
            .sorted { lhs, rhs in lhs.1 < rhs.1 }
        var span = scalarByteWidth
        for (count, stride) in active {
            guard stride >= span else {
                throw ProbeStorageError.overlappingLayout
            }
            let tail = try probeCheckedMultiply(count - 1, stride)
            span = try probeCheckedAdd(span, tail)
        }
        return span
    }
}

final class ProbeProviderInstanceIdentity:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    fileprivate init() {}

    static func == (
        lhs: ProbeProviderInstanceIdentity,
        rhs: ProbeProviderInstanceIdentity
    ) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

struct ProbeWitnessBinding: Sendable, Hashable, ProbeRedactedDiagnostic {
    let providerIdentity: ProbeProviderInstanceIdentity
    let ownerID: ProbeStorageOwnerID
    let descriptor: ProbeStorageDescriptor
    let snapshotID: ProbeStorageSnapshotID
    let generation: UInt64
}

struct ProbeUnpublishedTargetBinding:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    let ownerID: ProbeStorageOwnerID
    let descriptor: ProbeStorageDescriptor
    let snapshotID: ProbeStorageSnapshotID
    let generation: UInt64
    let sourceAuthority: ProbeWitnessBinding

    fileprivate init(
        ownerID: ProbeStorageOwnerID,
        descriptor: ProbeStorageDescriptor,
        snapshotID: ProbeStorageSnapshotID,
        generation: UInt64,
        sourceAuthority: ProbeWitnessBinding
    ) {
        self.ownerID = ownerID
        self.descriptor = descriptor
        self.snapshotID = snapshotID
        self.generation = generation
        self.sourceAuthority = sourceAuthority
    }
}

struct ProbeOperationReceipt: Sendable, Hashable, ProbeRedactedDiagnostic {
    let capability: ProbeStorageCapability
    let binding: ProbeWitnessBinding

    fileprivate init(
        capability: ProbeStorageCapability,
        binding: ProbeWitnessBinding
    ) {
        self.capability = capability
        self.binding = binding
    }
}

struct ProbeCallableOperationWitness: Sendable, ProbeRedactedDiagnostic {
    let capability: ProbeStorageCapability
    let binding: ProbeWitnessBinding
    private let provider: ProbeStorageProvider
    private let authoritySeal: ProbeStorageProvider.AuthoritySeal

    fileprivate init(
        capability: ProbeStorageCapability,
        binding: ProbeWitnessBinding,
        provider: ProbeStorageProvider,
        authoritySeal: ProbeStorageProvider.AuthoritySeal
    ) {
        self.capability = capability
        self.binding = binding
        self.provider = provider
        self.authoritySeal = authoritySeal
    }

    func invoke() async throws -> ProbeOperationReceipt {
        try await provider.invoke(
            capability: capability,
            binding: binding,
            authoritySeal: authoritySeal
        )
    }

    func acquireBuilder(
        requiredSlots: some Sequence<ProbeWriteSlot> & Sendable,
        limits: ProbeDescriptorLimits
    ) async throws -> ProbeStorageBuilder {
        guard capability == .builderAcquisition else {
            throw ProbeStorageError.unsupportedAccess
        }
        return try await provider.acquireBuilder(
            binding: binding,
            authoritySeal: authoritySeal,
            requiredSlots: requiredSlots,
            limits: limits
        )
    }
}

struct ProbeRegionReadWitness: Sendable, ProbeRedactedDiagnostic {
    let binding: ProbeWitnessBinding
    private let provider: ProbeStorageProvider
    private let authoritySeal: ProbeStorageProvider.AuthoritySeal

    fileprivate init(
        binding: ProbeWitnessBinding,
        provider: ProbeStorageProvider,
        authoritySeal: ProbeStorageProvider.AuthoritySeal
    ) {
        self.binding = binding
        self.provider = provider
        self.authoritySeal = authoritySeal
    }

    func read(
        _ request: ProbeReadDestination.ReadRequest
    ) async throws -> ProbeStorageProvider.ReadCompletion {
        try await provider.read(
            request,
            binding: binding,
            authoritySeal: authoritySeal,
            fixtureMode: .complete
        )
    }

    fileprivate func readShortNegativeFixture(
        _ request: ProbeReadDestination.ReadRequest
    ) async throws -> ProbeStorageProvider.ReadCompletion {
        try await provider.read(
            request,
            binding: binding,
            authoritySeal: authoritySeal,
            fixtureMode: .short
        )
    }

    fileprivate func readCancellationNegativeFixture(
        _ request: ProbeReadDestination.ReadRequest
    ) async throws -> ProbeStorageProvider.ReadCompletion {
        try await provider.read(
            request,
            binding: binding,
            authoritySeal: authoritySeal,
            fixtureMode: .cancelled
        )
    }

    fileprivate func readFailureNegativeFixture(
        _ request: ProbeReadDestination.ReadRequest
    ) async throws -> ProbeStorageProvider.ReadCompletion {
        try await provider.read(
            request,
            binding: binding,
            authoritySeal: authoritySeal,
            fixtureMode: .failed
        )
    }
}

struct ProbeStorageWitnesses: Sendable, ProbeRedactedDiagnostic {
    let regionRead: ProbeRegionReadWitness
    let operations: ContiguousArray<ProbeCallableOperationWitness>
}

struct ProbeStorageAdmission: Sendable, ProbeRedactedDiagnostic {
    let descriptor: ProbeStorageDescriptor
    let capabilities: ProbeCapabilityClaim
    let witnesses: ProbeStorageWitnesses

    fileprivate init(
        descriptor: ProbeStorageDescriptor,
        capabilities: ProbeCapabilityClaim,
        witnesses: ProbeStorageWitnesses
    ) throws {
        guard capabilities.unknownBits == 0 else {
            throw ProbeStorageError.unknownCapabilityBits
        }
        let claimed = capabilities.knownCapabilities
        let witnessed = Set(witnesses.operations.map(\.capability))
        guard claimed == witnessed else {
            throw claimed.isSubset(of: witnessed)
                ? ProbeStorageError.unexpectedCapabilityWitness
                : ProbeStorageError.missingCapabilityWitness
        }
        guard
            witnesses.regionRead.binding.descriptor == descriptor,
            witnesses.operations.allSatisfy({
                $0.binding == witnesses.regionRead.binding
            })
        else {
            throw ProbeStorageError.unexpectedCapabilityWitness
        }
        self.descriptor = descriptor
        self.capabilities = capabilities
        self.witnesses = witnesses
    }
}

actor ProbeStorageProvider: ProbeRedactedDiagnostic {
    fileprivate final class AuthoritySeal: Sendable {
        fileprivate init() {}
    }

    enum ReadFixtureMode: Sendable {
        case complete
        case short
        case cancelled
        case failed
    }

    struct ReadCompletion: Sendable, ProbeRedactedDiagnostic {
        fileprivate enum Outcome: Sendable, Hashable {
            case bytes(ProbeBoundedBytes)
            case cancelled
            case failed
        }

        fileprivate let requestSeal: ProbeReadDestination.RequestSeal
        fileprivate let binding: ProbeWitnessBinding
        fileprivate let outcome: Outcome

        fileprivate init(
            requestSeal: ProbeReadDestination.RequestSeal,
            binding: ProbeWitnessBinding,
            outcome: Outcome
        ) {
            self.requestSeal = requestSeal
            self.binding = binding
            self.outcome = outcome
        }
    }

    private let ownerID: ProbeStorageOwnerID
    private let descriptor: ProbeStorageDescriptor
    private var snapshotID: ProbeStorageSnapshotID
    private var generation: UInt64
    private let representationBytes: ProbeBoundedBytes
    private let canonicalLogicalReadBytes: ProbeBoundedBytes?
    private let supportedCapabilities: Set<ProbeStorageCapability>
    private let integrityPolicyAuthority: ProbeIntegrityPolicyAuthority?
    private let providerIdentity = ProbeProviderInstanceIdentity()
    private let authoritySeal = AuthoritySeal()
    private var nextUnpublishedTargetOrdinal: UInt64 = 1

    init(
        ownerID: ProbeStorageOwnerID,
        descriptor: ProbeStorageDescriptor,
        snapshotID: ProbeStorageSnapshotID,
        generation: UInt64,
        representationBytes: ProbeBoundedBytes,
        canonicalLogicalReadBytes: ProbeBoundedBytes? = nil,
        supportedCapabilities: some Sequence<ProbeStorageCapability>,
        integrityPolicyAuthority: ProbeIntegrityPolicyAuthority? = nil
    ) throws {
        if let byteLength = descriptor.representationByteLength {
            guard representationBytes.count == byteLength else {
                throw ProbeStorageError.byteLengthInsufficient
            }
        }
        if let canonicalLogicalReadBytes {
            guard
                canonicalLogicalReadBytes.count == descriptor.logicalByteCount,
                canonicalLogicalReadBytes.count
                    <= ProbePlatformByteCeiling.maximumMaterializedByteCount
            else {
                throw ProbeStorageError.byteLengthInsufficient
            }
        }
        var accepted: ContiguousArray<ProbeStorageCapability> = []
        for capability in supportedCapabilities {
            guard accepted.count < ProbeStorageCapability.allCases.count else {
                throw ProbeStorageError.unexpectedCapabilityWitness
            }
            accepted.append(capability)
        }
        let supported = Set(accepted)
        guard supported.count == accepted.count else {
            throw ProbeStorageError.unexpectedCapabilityWitness
        }
        try Self.validate(capabilities: supported, descriptor: descriptor)
        self.ownerID = ownerID
        self.descriptor = descriptor
        self.snapshotID = snapshotID
        self.generation = generation
        self.representationBytes = representationBytes
        self.canonicalLogicalReadBytes = canonicalLogicalReadBytes
        self.supportedCapabilities = supported
        self.integrityPolicyAuthority = integrityPolicyAuthority
    }

    func admission() throws -> ProbeStorageAdmission {
        guard canServeRegionRead else {
            throw ProbeStorageError.missingReadPath
        }
        let binding = currentBinding
        let witnesses = ProbeStorageWitnesses(
            regionRead: ProbeRegionReadWitness(
                binding: binding,
                provider: self,
                authoritySeal: authoritySeal
            ),
            operations: ContiguousArray(
                supportedCapabilities.sorted { $0.rawValue < $1.rawValue }.map {
                    ProbeCallableOperationWitness(
                        capability: $0,
                        binding: binding,
                        provider: self,
                        authoritySeal: authoritySeal
                    )
                }
            )
        )
        return try ProbeStorageAdmission(
            descriptor: descriptor,
            capabilities: ProbeCapabilityClaim(
                rawValue: supportedCapabilities.reduce(UInt64(0)) {
                    $0 | $1.rawValue
                }
            ),
            witnesses: witnesses
        )
    }

    fileprivate func invoke(
        capability: ProbeStorageCapability,
        binding: ProbeWitnessBinding,
        authoritySeal presentedSeal: AuthoritySeal
    ) throws -> ProbeOperationReceipt {
        guard
            presentedSeal === authoritySeal,
            binding == currentBinding,
            capability != .resolutionLevelAccess,
            supportedCapabilities.contains(capability)
        else {
            throw ProbeStorageError.staleGeneration
        }
        return ProbeOperationReceipt(capability: capability, binding: binding)
    }

    fileprivate func acquireBuilder(
        binding: ProbeWitnessBinding,
        authoritySeal presentedSeal: AuthoritySeal,
        requiredSlots: some Sequence<ProbeWriteSlot> & Sendable,
        limits: ProbeDescriptorLimits
    ) throws -> ProbeStorageBuilder {
        guard
            presentedSeal === authoritySeal,
            binding == currentBinding,
            supportedCapabilities.contains(.builderAcquisition)
        else {
            throw ProbeStorageError.staleGeneration
        }
        return try ProbeStorageBuilder(
            provider: self,
            authoritySeal: authoritySeal,
            binding: binding,
            requiredSlots: requiredSlots,
            limits: limits
        )
    }

    fileprivate func freezeBuilder(
        binding: ProbeWitnessBinding,
        authoritySeal presentedSeal: AuthoritySeal,
        stagedBytesBySlot: [ProbeWriteSlot: ContiguousArray<UInt8>]
    ) throws -> ProbeFrozenStorage {
        guard
            presentedSeal === authoritySeal,
            binding == currentBinding,
            supportedCapabilities.contains(.builderAcquisition)
        else {
            throw ProbeStorageError.staleGeneration
        }
        var stagedByteCount: UInt64 = 0
        for (slot, bytes) in stagedBytesBySlot {
            guard
                slot.descriptor == descriptor,
                slot.region.storageShape == descriptor.shape,
                UInt64(bytes.count) == slot.expectedByteLength
            else {
                throw ProbeStorageError.failedWrite
            }
            stagedByteCount = try probeCheckedAdd(
                stagedByteCount,
                UInt64(bytes.count)
            )
        }
        guard stagedByteCount == descriptor.logicalByteCount else {
            throw ProbeStorageError.incompleteBuilder
        }
        return ProbeFrozenStorage(
            binding: try mintUnpublishedTargetBinding(
                sourceAuthority: binding
            ),
            stagedBytesBySlot: stagedBytesBySlot
        )
    }

    private func mintUnpublishedTargetBinding(
        sourceAuthority: ProbeWitnessBinding
    ) throws -> ProbeUnpublishedTargetBinding {
        while true {
            let ordinal = nextUnpublishedTargetOrdinal
            let (next, overflow) = ordinal.addingReportingOverflow(1)
            guard !overflow else {
                throw ProbeStorageError.arithmeticOverflow
            }
            nextUnpublishedTargetOrdinal = next
            let targetSnapshotID = ProbeStorageSnapshotID(
                value: try ProbeExactText(
                    "provider-unpublished-target.\(ordinal)"
                )
            )
            guard targetSnapshotID != sourceAuthority.snapshotID else {
                continue
            }
            return ProbeUnpublishedTargetBinding(
                ownerID: ownerID,
                descriptor: descriptor,
                snapshotID: targetSnapshotID,
                generation: ordinal,
                sourceAuthority: sourceAuthority
            )
        }
    }

    fileprivate func read(
        _ request: ProbeReadDestination.ReadRequest,
        binding: ProbeWitnessBinding,
        authoritySeal presentedSeal: AuthoritySeal,
        fixtureMode: ReadFixtureMode
    ) throws -> ReadCompletion {
        guard
            presentedSeal === authoritySeal,
            binding == currentBinding,
            request.binding == binding,
            request.storageDescriptor == descriptor
        else {
            throw ProbeStorageError.staleGeneration
        }
        let completeBytes = try collectReadBytes(for: request)
        let outcome: ReadCompletion.Outcome
        switch fixtureMode {
        case .complete:
            outcome = .bytes(completeBytes)
        case .short:
            guard request.expectedByteLength > 1 else {
                throw ProbeStorageError.partialRead
            }
            outcome = .bytes(
                try completeBytes.prefix(
                    count: request.expectedByteLength - 1
                )
            )
        case .cancelled:
            outcome = .cancelled
        case .failed:
            outcome = .failed
        }
        return ReadCompletion(
            requestSeal: request.requestSeal,
            binding: binding,
            outcome: outcome
        )
    }

    func verifyRepresentationIntegrity() async throws
        -> ProbeRepresentationIntegrityEvidence
    {
        let verifiedBinding = currentBinding
        guard
            let integrityPolicyAuthority,
            let claim = descriptor.integrityClaim,
            claim.descriptorBinding == descriptor.representationBinding,
            claim.snapshotID == verifiedBinding.snapshotID,
            claim.generation == verifiedBinding.generation,
            claim.representationByteLength == representationBytes.count
        else {
            throw ProbeStorageError.integrityDenied
        }
        let policyAuthorization =
            try await integrityPolicyAuthority
            .issueAuthorization()
        guard currentBinding == verifiedBinding else {
            throw ProbeStorageError.integrityDenied
        }
        let observedDigest = ContiguousArray(
            SHA256.hash(data: representationBytes.exactData)
        )
        guard claim.digest == observedDigest else {
            throw ProbeStorageError.integrityDenied
        }
        return ProbeRepresentationIntegrityEvidence(
            provider: self,
            authoritySeal: authoritySeal,
            descriptor: descriptor,
            claim: claim,
            binding: verifiedBinding,
            observedDigest: observedDigest,
            policyAuthorization: policyAuthorization
        )
    }

    fileprivate func validate(
        evidenceBinding: ProbeWitnessBinding,
        authoritySeal presentedSeal: AuthoritySeal
    ) throws {
        guard presentedSeal === authoritySeal,
            evidenceBinding == currentBinding
        else {
            throw ProbeStorageError.integrityDenied
        }
    }

    func advanceGeneration() throws {
        let (next, overflow) = generation.addingReportingOverflow(1)
        guard !overflow else { throw ProbeStorageError.arithmeticOverflow }
        generation = next
    }

    private var currentBinding: ProbeWitnessBinding {
        ProbeWitnessBinding(
            providerIdentity: providerIdentity,
            ownerID: ownerID,
            descriptor: descriptor,
            snapshotID: snapshotID,
            generation: generation
        )
    }

    private var canServeRegionRead: Bool {
        if case .decodedStrided = descriptor.representation {
            return true
        }
        return canonicalLogicalReadBytes != nil
    }

    private func collectReadBytes(
        for request: ProbeReadDestination.ReadRequest
    ) throws -> ProbeBoundedBytes {
        switch descriptor.representation {
        case .decodedStrided(let layout):
            return try Self.gatherDecodedStrided(
                source: representationBytes,
                descriptor: descriptor,
                layout: layout,
                region: request.region,
                expectedByteLength: request.expectedByteLength
            )
        case .opaque:
            guard let canonicalLogicalReadBytes else {
                throw ProbeStorageError.missingReadPath
            }
            return try Self.gatherCanonicalLogical(
                source: canonicalLogicalReadBytes,
                descriptor: descriptor,
                region: request.region,
                expectedByteLength: request.expectedByteLength
            )
        }
    }

    private static func gatherDecodedStrided(
        source: ProbeBoundedBytes,
        descriptor: ProbeStorageDescriptor,
        layout: ProbeStridedLayout,
        region: ProbeRegion,
        expectedByteLength: UInt64
    ) throws -> ProbeBoundedBytes {
        try gather(
            source: source,
            descriptor: descriptor,
            region: region,
            expectedByteLength: expectedByteLength,
            baseOffset: layout.baseOffset,
            axisByteStrides: layout.axisByteStrides,
            componentByteStride: layout.componentByteStride
        )
    }

    private static func gatherCanonicalLogical(
        source: ProbeBoundedBytes,
        descriptor: ProbeStorageDescriptor,
        region: ProbeRegion,
        expectedByteLength: UInt64
    ) throws -> ProbeBoundedBytes {
        var axisByteStrides: ContiguousArray<UInt64> = []
        var stride = try probeCheckedMultiply(
            descriptor.scalar.byteWidth,
            descriptor.components.count
        )
        for extent in descriptor.shape.extents {
            axisByteStrides.append(stride)
            stride = try probeCheckedMultiply(stride, extent)
        }
        return try gather(
            source: source,
            descriptor: descriptor,
            region: region,
            expectedByteLength: expectedByteLength,
            baseOffset: 0,
            axisByteStrides: axisByteStrides,
            componentByteStride: descriptor.scalar.byteWidth
        )
    }

    private static func gather(
        source: ProbeBoundedBytes,
        descriptor: ProbeStorageDescriptor,
        region: ProbeRegion,
        expectedByteLength: UInt64,
        baseOffset: UInt64,
        axisByteStrides: ContiguousArray<UInt64>,
        componentByteStride: UInt64
    ) throws -> ProbeBoundedBytes {
        guard
            region.storageShape == descriptor.shape,
            axisByteStrides.count == descriptor.shape.rank,
            expectedByteLength
                <= ProbePlatformByteCeiling.maximumMaterializedByteCount
        else {
            throw ProbeStorageError.destinationMismatch
        }
        var voxelCount: UInt64 = 1
        for extent in region.extents {
            voxelCount = try probeCheckedMultiply(voxelCount, extent)
        }
        var gathered: ContiguousArray<UInt8> = []
        gathered.reserveCapacity(Int(expectedByteLength))
        let sourceBytes = source.exactBytes
        var voxel: UInt64 = 0
        while voxel < voxelCount {
            var remaining = voxel
            var voxelOffset = baseOffset
            for axis in region.extents.indices {
                let localCoordinate = remaining % region.extents[axis]
                remaining /= region.extents[axis]
                let coordinate = try probeCheckedAdd(
                    region.origin[axis],
                    localCoordinate
                )
                voxelOffset = try probeCheckedAdd(
                    voxelOffset,
                    probeCheckedMultiply(
                        coordinate,
                        axisByteStrides[axis]
                    )
                )
            }
            var component: UInt64 = 0
            while component < descriptor.components.count {
                let componentOffset = try probeCheckedAdd(
                    voxelOffset,
                    probeCheckedMultiply(component, componentByteStride)
                )
                let upper = try probeCheckedAdd(
                    componentOffset,
                    descriptor.scalar.byteWidth
                )
                guard upper <= source.count else {
                    throw ProbeStorageError.partialRead
                }
                gathered.append(
                    contentsOf: sourceBytes[
                        Int(componentOffset)..<Int(upper)
                    ]
                )
                component += 1
            }
            voxel += 1
        }
        guard UInt64(gathered.count) == expectedByteLength else {
            throw ProbeStorageError.partialRead
        }
        return try ProbeBoundedBytes(
            gathered,
            maximumByteCount: expectedByteLength
        )
    }

    private static func validate(
        capabilities: Set<ProbeStorageCapability>,
        descriptor: ProbeStorageDescriptor
    ) throws {
        for capability in capabilities {
            switch capability {
            case .scopedContiguousByteAccess:
                guard case .decodedStrided = descriptor.representation,
                    descriptor.representationByteLength != nil
                else {
                    throw ProbeStorageError.capabilityConflict
                }
            case .mappedRepresentationAccess:
                guard
                    descriptor.providerMechanism == .mappedFile,
                    descriptor.representationByteLength != nil
                else {
                    throw ProbeStorageError.capabilityConflict
                }
            case .nativeTileAccess:
                guard descriptor.organization == .tiled else {
                    throw ProbeStorageError.capabilityConflict
                }
            case .nativeBrickAccess:
                guard descriptor.organization == .bricked else {
                    throw ProbeStorageError.capabilityConflict
                }
            case .compressedRepresentationAccess:
                guard case .opaque(.compressed) = descriptor.representation else {
                    throw ProbeStorageError.capabilityConflict
                }
            case .resolutionLevelAccess:
                // M1 keeps the bit reserved in the closed wire registry, but
                // source-gates operational admission until M5 defines callable
                // per-level descriptors and spatial correspondence.
                throw ProbeStorageError.unsupportedAccess
            case .builderAcquisition, .regionEnumeration, .prefetchHints,
                .scopedDigestAccess:
                break
            }
        }
    }
}

struct ProbeRegion: Sendable, Hashable, ProbeRedactedDiagnostic {
    let origin: ContiguousArray<UInt64>
    let extents: ContiguousArray<UInt64>
    let storageShape: ProbeShape

    init(
        origin: some Sequence<UInt64>,
        extents: some Sequence<UInt64>,
        within shape: ProbeShape
    ) throws {
        var acceptedOrigin: ContiguousArray<UInt64> = []
        acceptedOrigin.reserveCapacity(shape.rank)
        for coordinate in origin {
            guard acceptedOrigin.count < shape.rank else {
                throw ProbeStorageError.rankMismatch
            }
            acceptedOrigin.append(coordinate)
        }
        var acceptedExtents: ContiguousArray<UInt64> = []
        acceptedExtents.reserveCapacity(shape.rank)
        for extent in extents {
            guard acceptedExtents.count < shape.rank else {
                throw ProbeStorageError.rankMismatch
            }
            acceptedExtents.append(extent)
        }
        guard
            acceptedOrigin.count == shape.rank,
            acceptedExtents.count == shape.rank
        else {
            throw ProbeStorageError.rankMismatch
        }
        for axis in shape.extents.indices {
            guard acceptedExtents[axis] > 0 else {
                throw ProbeStorageError.regionOutOfBounds
            }
            let upper = try probeCheckedAdd(
                acceptedOrigin[axis],
                acceptedExtents[axis]
            )
            guard upper <= shape.extents[axis] else {
                throw ProbeStorageError.regionOutOfBounds
            }
        }
        self.origin = acceptedOrigin
        self.extents = acceptedExtents
        storageShape = shape
    }
}

enum ProbeDestinationLayout: UInt8, Sendable, Hashable {
    case canonicalPackedInterleaved
}

struct ProbeDestinationDescriptor: Sendable, Hashable, ProbeRedactedDiagnostic {
    let shape: ProbeShape
    let scalar: ProbeScalarFormat
    let componentCount: UInt64
    let layout: ProbeDestinationLayout
    let logicalByteLength: UInt64

    init(
        shape: ProbeShape,
        scalar: ProbeScalarFormat,
        components: ProbeComponents,
        declaredByteLength: UInt64,
        limits: ProbeDescriptorLimits
    ) throws {
        guard components.layout == .interleaved else {
            throw ProbeStorageError.destinationMismatch
        }
        let expected = try probeLogicalByteCount(
            shape: shape,
            scalar: scalar,
            components: components,
            limits: limits
        )
        guard
            declaredByteLength == expected,
            declaredByteLength <= limits.maximumRequestByteLength
        else {
            throw ProbeStorageError.destinationMismatch
        }
        self.shape = shape
        self.scalar = scalar
        componentCount = components.count
        layout = .canonicalPackedInterleaved
        logicalByteLength = declaredByteLength
    }
}

enum ProbeDestinationState: Sendable, Hashable, ProbeRedactedDiagnostic {
    case empty
    case published(ProbeBoundedBytes)
}

actor ProbeReadDestination: ProbeRedactedDiagnostic {
    fileprivate final class RequestSeal: Sendable {
        fileprivate init() {}
    }

    struct ReadRequest: Sendable, ProbeRedactedDiagnostic {
        fileprivate let requestSeal: RequestSeal
        fileprivate let binding: ProbeWitnessBinding
        fileprivate let region: ProbeRegion
        fileprivate let storageDescriptor: ProbeStorageDescriptor
        fileprivate let expectedByteLength: UInt64

        fileprivate init(
            requestSeal: RequestSeal,
            binding: ProbeWitnessBinding,
            region: ProbeRegion,
            storageDescriptor: ProbeStorageDescriptor,
            expectedByteLength: UInt64
        ) {
            self.requestSeal = requestSeal
            self.binding = binding
            self.region = region
            self.storageDescriptor = storageDescriptor
            self.expectedByteLength = expectedByteLength
        }
    }

    private let descriptor: ProbeDestinationDescriptor
    private var currentGeneration: UInt64
    private var state: ProbeDestinationState = .empty
    private var pendingRequest: ReadRequest?

    init(descriptor: ProbeDestinationDescriptor, currentGeneration: UInt64) {
        self.descriptor = descriptor
        self.currentGeneration = currentGeneration
    }

    func begin(
        region: ProbeRegion,
        storage: ProbeStorageDescriptor,
        witness: ProbeRegionReadWitness,
        limits: ProbeDescriptorLimits
    ) throws -> ReadRequest {
        guard state == .empty else { throw ProbeStorageError.alreadyCommitted }
        guard pendingRequest == nil else {
            throw ProbeStorageError.alreadyCommitted
        }
        guard
            witness.binding.descriptor == storage,
            witness.binding.generation == currentGeneration
        else {
            throw ProbeStorageError.staleGeneration
        }
        let regionShape = try ProbeShape(extents: region.extents, limits: limits)
        let expectedByteLength = try probeLogicalByteCount(
            shape: regionShape,
            scalar: storage.scalar,
            components: storage.components,
            limits: limits
        )
        guard
            region.storageShape == storage.shape,
            descriptor.shape == regionShape,
            descriptor.scalar == storage.scalar,
            descriptor.componentCount == storage.components.count,
            descriptor.layout == .canonicalPackedInterleaved,
            expectedByteLength <= limits.maximumRequestByteLength,
            descriptor.logicalByteLength == expectedByteLength
        else {
            throw ProbeStorageError.destinationMismatch
        }
        let request = ReadRequest(
            requestSeal: RequestSeal(),
            binding: witness.binding,
            region: region,
            storageDescriptor: storage,
            expectedByteLength: expectedByteLength
        )
        pendingRequest = request
        return request
    }

    func publish(_ completion: ProbeStorageProvider.ReadCompletion) throws {
        guard state == .empty else { throw ProbeStorageError.alreadyCommitted }
        guard let request = pendingRequest else {
            throw ProbeStorageError.staleGeneration
        }
        guard
            completion.requestSeal === request.requestSeal,
            completion.binding == request.binding,
            completion.binding.generation == currentGeneration
        else {
            throw ProbeStorageError.staleGeneration
        }

        switch completion.outcome {
        case .bytes(let stagedBytes):
            pendingRequest = nil
            guard stagedBytes.count == request.expectedByteLength else {
                throw ProbeStorageError.partialRead
            }
            state = .published(stagedBytes)
        case .cancelled:
            pendingRequest = nil
            throw ProbeStorageError.cancelled
        case .failed:
            pendingRequest = nil
            throw ProbeStorageError.failedRead
        }
    }

    func advanceGeneration() throws {
        let (next, overflow) = currentGeneration.addingReportingOverflow(1)
        guard !overflow else { throw ProbeStorageError.arithmeticOverflow }
        currentGeneration = next
        pendingRequest = nil
    }

    func snapshot() -> ProbeDestinationState { state }
}

struct ProbeIntegrityPolicyID: Sendable, Hashable, ProbeRedactedDiagnostic {
    let value: ProbeExactText
}

struct ProbeRepresentationIntegrityEvidence:
    Sendable,
    ProbeRedactedDiagnostic
{
    private let provider: ProbeStorageProvider
    private let authoritySeal: ProbeStorageProvider.AuthoritySeal
    let descriptor: ProbeStorageDescriptor
    let claim: ProbeRepresentationIntegrityClaim
    let binding: ProbeWitnessBinding
    let observedDigest: ContiguousArray<UInt8>
    fileprivate let policyAuthorization: ProbeIntegrityPolicyAuthorization

    fileprivate init(
        provider: ProbeStorageProvider,
        authoritySeal: ProbeStorageProvider.AuthoritySeal,
        descriptor: ProbeStorageDescriptor,
        claim: ProbeRepresentationIntegrityClaim,
        binding: ProbeWitnessBinding,
        observedDigest: ContiguousArray<UInt8>,
        policyAuthorization: ProbeIntegrityPolicyAuthorization
    ) {
        self.provider = provider
        self.authoritySeal = authoritySeal
        self.descriptor = descriptor
        self.claim = claim
        self.binding = binding
        self.observedDigest = observedDigest
        self.policyAuthorization = policyAuthorization
    }

    fileprivate func validateCurrent() async throws {
        try await provider.validate(
            evidenceBinding: binding,
            authoritySeal: authoritySeal
        )
    }
}

struct ProbeIntegrityPolicySnapshot:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    let policyID: ProbeIntegrityPolicyID
    let revision: UInt64
}

struct ProbeIntegrityPolicyAuthorization: Sendable, ProbeRedactedDiagnostic {
    fileprivate let authority: ProbeIntegrityPolicyAuthority
    fileprivate let authoritySeal: ProbeIntegrityPolicyAuthority.AuthoritySeal
    let snapshot: ProbeIntegrityPolicySnapshot

    fileprivate init(
        authority: ProbeIntegrityPolicyAuthority,
        authoritySeal: ProbeIntegrityPolicyAuthority.AuthoritySeal,
        snapshot: ProbeIntegrityPolicySnapshot
    ) {
        self.authority = authority
        self.authoritySeal = authoritySeal
        self.snapshot = snapshot
    }
}

struct ProbeRepresentationIntegrityAssurance:
    Sendable,
    ProbeRedactedDiagnostic
{
    let descriptor: ProbeStorageDescriptor
    let claim: ProbeRepresentationIntegrityClaim
    let binding: ProbeWitnessBinding
    let policySnapshot: ProbeIntegrityPolicySnapshot

    fileprivate init(
        descriptor: ProbeStorageDescriptor,
        claim: ProbeRepresentationIntegrityClaim,
        binding: ProbeWitnessBinding,
        policySnapshot: ProbeIntegrityPolicySnapshot
    ) {
        self.descriptor = descriptor
        self.claim = claim
        self.binding = binding
        self.policySnapshot = policySnapshot
    }
}

actor ProbeIntegrityPolicyAuthority {
    fileprivate final class AuthoritySeal: Sendable {
        fileprivate init() {}
    }

    private enum Status: Sendable {
        case active
        case expired
        case revoked
    }

    private let policyID: ProbeIntegrityPolicyID
    private var revision: UInt64
    private var status: Status = .active
    private let authoritySeal = AuthoritySeal()

    init(policyID: ProbeIntegrityPolicyID, revision: UInt64) throws {
        guard revision > 0 else { throw ProbeStorageError.integrityDenied }
        self.policyID = policyID
        self.revision = revision
    }

    fileprivate func issueAuthorization() throws
        -> ProbeIntegrityPolicyAuthorization
    {
        guard status == .active else {
            throw ProbeStorageError.integrityDenied
        }
        return ProbeIntegrityPolicyAuthorization(
            authority: self,
            authoritySeal: authoritySeal,
            snapshot: ProbeIntegrityPolicySnapshot(
                policyID: policyID,
                revision: revision
            )
        )
    }

    func evaluate(
        descriptor: ProbeStorageDescriptor,
        evidence: ProbeRepresentationIntegrityEvidence
    ) async throws -> ProbeRepresentationIntegrityAssurance {
        try await evidence.validateCurrent()
        let authorization = evidence.policyAuthorization
        guard
            let claim = descriptor.integrityClaim,
            evidence.descriptor == descriptor,
            evidence.claim == claim,
            evidence.binding.descriptor == descriptor,
            evidence.binding.snapshotID == claim.snapshotID,
            evidence.binding.generation == claim.generation,
            evidence.observedDigest == claim.digest,
            authorization.authority === self,
            authorization.authoritySeal === authoritySeal,
            authorization.snapshot.policyID == policyID,
            authorization.snapshot.revision == revision,
            status == .active
        else {
            throw ProbeStorageError.integrityDenied
        }
        return ProbeRepresentationIntegrityAssurance(
            descriptor: descriptor,
            claim: claim,
            binding: evidence.binding,
            policySnapshot: authorization.snapshot
        )
    }

    func expire() throws {
        try advanceRevision()
        status = .expired
    }

    func revoke() throws {
        try advanceRevision()
        status = .revoked
    }

    private func advanceRevision() throws {
        let (next, overflow) = revision.addingReportingOverflow(1)
        guard !overflow else { throw ProbeStorageError.arithmeticOverflow }
        revision = next
    }
}

struct ProbeWriteSlot: Sendable, Hashable, ProbeRedactedDiagnostic {
    let value: ProbeExactText
    let region: ProbeRegion
    let descriptor: ProbeStorageDescriptor
    let expectedByteLength: UInt64

    init(
        value: ProbeExactText,
        region: ProbeRegion,
        descriptor: ProbeStorageDescriptor,
        limits: ProbeDescriptorLimits
    ) throws {
        guard region.storageShape == descriptor.shape else {
            throw ProbeStorageError.invalidWritePartition
        }
        let regionShape = try ProbeShape(extents: region.extents, limits: limits)
        let expectedByteLength = try probeLogicalByteCount(
            shape: regionShape,
            scalar: descriptor.scalar,
            components: descriptor.components,
            limits: limits
        )
        guard expectedByteLength <= limits.maximumRequestByteLength else {
            throw ProbeStorageError.byteLengthInsufficient
        }
        self.value = value
        self.region = region
        self.descriptor = descriptor
        self.expectedByteLength = expectedByteLength
    }
}

enum ProbeWriteDelivery: Sendable, Hashable, ProbeRedactedDiagnostic {
    case bytes(ContiguousArray<UInt8>)
    case retryableCancellation
    case transactionCancellation
    case failed
}

enum ProbeBuilderState: Sendable, Hashable {
    case open(completedCount: UInt64)
    case failed(completedCount: UInt64)
    case cancelled(completedCount: UInt64)
    case committed(completedCount: UInt64)
}

struct ProbeFrozenStorage: Sendable, Hashable, ProbeRedactedDiagnostic {
    let binding: ProbeUnpublishedTargetBinding
    let stagedBytesBySlot: [ProbeWriteSlot: ContiguousArray<UInt8>]

    fileprivate init(
        binding: ProbeUnpublishedTargetBinding,
        stagedBytesBySlot: [ProbeWriteSlot: ContiguousArray<UInt8>]
    ) {
        self.binding = binding
        self.stagedBytesBySlot = stagedBytesBySlot
    }

    var descriptor: ProbeStorageDescriptor { binding.descriptor }
    var generation: UInt64 { binding.generation }

    var completedSlotCount: UInt64 { UInt64(stagedBytesBySlot.count) }

    var stagedLogicalByteCount: UInt64 {
        stagedBytesBySlot.values.reduce(UInt64(0)) {
            $0 + UInt64($1.count)
        }
    }
}

actor ProbeStorageBuilder: ProbeRedactedDiagnostic {
    private let provider: ProbeStorageProvider
    private let authoritySeal: ProbeStorageProvider.AuthoritySeal
    private let binding: ProbeWitnessBinding
    private let requiredSlots: Set<ProbeWriteSlot>
    private var stagedBytesBySlot: [ProbeWriteSlot: ContiguousArray<UInt8>] = [:]
    private var failed = false
    private var transactionCancelled = false
    private var commitInProgress = false
    private var committed = false

    fileprivate init(
        provider: ProbeStorageProvider,
        authoritySeal: ProbeStorageProvider.AuthoritySeal,
        binding: ProbeWitnessBinding,
        requiredSlots: some Sequence<ProbeWriteSlot> & Sendable,
        limits: ProbeDescriptorLimits
    ) throws {
        let descriptor = binding.descriptor
        var slots: ContiguousArray<ProbeWriteSlot> = []
        slots.reserveCapacity(Int(limits.maximumBuilderSlots))
        for slot in requiredSlots {
            guard UInt64(slots.count) < limits.maximumBuilderSlots else {
                throw ProbeStorageError.invalidWritePartition
            }
            slots.append(slot)
        }
        let required = Set(slots)
        guard !required.isEmpty, required.count == slots.count else {
            throw ProbeStorageError.duplicateWrite
        }
        var coveredByteCount: UInt64 = 0
        for index in slots.indices {
            let slot = slots[index]
            guard
                slot.descriptor == descriptor,
                slot.region.storageShape == descriptor.shape
            else {
                throw ProbeStorageError.invalidWritePartition
            }
            coveredByteCount = try probeCheckedAdd(
                coveredByteCount,
                slot.expectedByteLength
            )
            for otherIndex in slots.indices where otherIndex < index {
                guard !Self.overlaps(slots[otherIndex].region, slot.region) else {
                    throw ProbeStorageError.invalidWritePartition
                }
            }
        }
        guard coveredByteCount == descriptor.logicalByteCount else {
            throw ProbeStorageError.invalidWritePartition
        }
        self.provider = provider
        self.authoritySeal = authoritySeal
        self.binding = binding
        self.requiredSlots = required
    }

    private static func overlaps(_ lhs: ProbeRegion, _ rhs: ProbeRegion) -> Bool {
        for axis in lhs.origin.indices {
            let lhsUpper = lhs.origin[axis] + lhs.extents[axis]
            let rhsUpper = rhs.origin[axis] + rhs.extents[axis]
            if lhsUpper <= rhs.origin[axis] || rhsUpper <= lhs.origin[axis] {
                return false
            }
        }
        return true
    }

    func write(_ slot: ProbeWriteSlot, delivery: ProbeWriteDelivery) throws {
        guard !committed else { throw ProbeStorageError.alreadyCommitted }
        guard !commitInProgress else { throw ProbeStorageError.alreadyCommitted }
        guard !transactionCancelled else { throw ProbeStorageError.cancelled }
        guard !failed else { throw ProbeStorageError.failedWrite }
        guard requiredSlots.contains(slot) else {
            throw ProbeStorageError.unknownWrite
        }
        guard stagedBytesBySlot[slot] == nil else {
            throw ProbeStorageError.duplicateWrite
        }
        switch delivery {
        case .bytes(let stagedBytes):
            guard UInt64(stagedBytes.count) == slot.expectedByteLength else {
                failed = true
                throw ProbeStorageError.failedWrite
            }
            stagedBytesBySlot[slot] = stagedBytes
        case .retryableCancellation:
            throw ProbeStorageError.cancelled
        case .transactionCancellation:
            transactionCancelled = true
            throw ProbeStorageError.cancelled
        case .failed:
            failed = true
            throw ProbeStorageError.failedWrite
        }
    }

    func commit() async throws -> ProbeFrozenStorage {
        guard !committed else { throw ProbeStorageError.alreadyCommitted }
        guard !commitInProgress else { throw ProbeStorageError.alreadyCommitted }
        guard !transactionCancelled else { throw ProbeStorageError.cancelled }
        guard !failed else { throw ProbeStorageError.failedWrite }
        guard Set(stagedBytesBySlot.keys) == requiredSlots else {
            throw ProbeStorageError.incompleteBuilder
        }
        commitInProgress = true
        do {
            let frozen = try await provider.freezeBuilder(
                binding: binding,
                authoritySeal: authoritySeal,
                stagedBytesBySlot: stagedBytesBySlot
            )
            committed = true
            commitInProgress = false
            return frozen
        } catch {
            commitInProgress = false
            throw error
        }
    }

    func snapshot() -> ProbeBuilderState {
        let count = UInt64(stagedBytesBySlot.count)
        if committed { return .committed(completedCount: count) }
        if transactionCancelled { return .cancelled(completedCount: count) }
        if failed { return .failed(completedCount: count) }
        return .open(completedCount: count)
    }
}

struct ProbeOwnedView: Sendable, ProbeRedactedDiagnostic {
    private let owner: ProbeBackingOwner
    let generation: UInt64
    let offset: UInt64
    let count: UInt64

    fileprivate init(
        owner: ProbeBackingOwner,
        generation: UInt64,
        offset: UInt64,
        count: UInt64
    ) {
        self.owner = owner
        self.generation = generation
        self.offset = offset
        self.count = count
    }

    func readOwnedSnapshot() async throws -> ContiguousArray<UInt8> {
        try await owner.readOwnedSnapshot(
            generation: generation,
            offset: offset,
            count: count
        )
    }
}

actor ProbeBackingOwner: ProbeRedactedDiagnostic {
    private let maximumByteLength: UInt64
    private var generation: UInt64 = 0
    private var bytes: ContiguousArray<UInt8>

    init(
        bytes: some Sequence<UInt8>,
        maximumByteLength: UInt64
    ) throws {
        guard
            maximumByteLength > 0,
            maximumByteLength
                <= ProbePlatformByteCeiling.maximumMaterializedByteCount
        else {
            throw ProbeStorageError.invalidLimits
        }
        self.maximumByteLength = maximumByteLength
        self.bytes = try Self.collect(
            bytes,
            maximumByteLength: maximumByteLength
        )
    }

    func makeView(offset: UInt64, count: UInt64) throws -> ProbeOwnedView {
        let upper = try probeCheckedAdd(offset, count)
        guard count > 0, upper <= UInt64(bytes.count) else {
            throw ProbeStorageError.regionOutOfBounds
        }
        return ProbeOwnedView(
            owner: self,
            generation: generation,
            offset: offset,
            count: count
        )
    }

    fileprivate func readOwnedSnapshot(
        generation requestedGeneration: UInt64,
        offset: UInt64,
        count: UInt64
    ) throws -> ContiguousArray<UInt8> {
        guard requestedGeneration == generation else {
            throw ProbeStorageError.staleGeneration
        }
        let upper = try probeCheckedAdd(offset, count)
        guard upper <= UInt64(bytes.count) else {
            throw ProbeStorageError.regionOutOfBounds
        }
        return ContiguousArray(bytes[Int(offset)..<Int(upper)])
    }

    func replace(with bytes: some Sequence<UInt8> & Sendable) throws {
        let (nextGeneration, overflow) = generation.addingReportingOverflow(1)
        guard !overflow else { throw ProbeStorageError.arithmeticOverflow }
        let replacement = try Self.collect(
            bytes,
            maximumByteLength: maximumByteLength
        )
        self.bytes = replacement
        generation = nextGeneration
    }

    private static func collect(
        _ bytes: some Sequence<UInt8>,
        maximumByteLength: UInt64
    ) throws -> ContiguousArray<UInt8> {
        var accepted: ContiguousArray<UInt8> = []
        for byte in bytes {
            guard UInt64(accepted.count) < maximumByteLength else {
                throw ProbeStorageError.byteLengthInsufficient
            }
            accepted.append(byte)
        }
        return accepted
    }
}

private enum ProbeFixtures {
    static func exact(_ value: String) throws -> ProbeExactText {
        try ProbeExactText(value)
    }

    static func claim(
        _ capabilities: some Sequence<ProbeStorageCapability>
    ) -> ProbeCapabilityClaim {
        ProbeCapabilityClaim(
            rawValue: capabilities.reduce(UInt64(0)) {
                $0 | $1.rawValue
            }
        )
    }

    static func canonicalDescriptor(
        limits: ProbeDescriptorLimits,
        byteOrder: ProbeByteOrder = .littleEndian,
        providerMechanism: ProbeProviderMechanism = .ownedMemory,
        locality: ProbeStorageLocality = .local,
        persistence: ProbePersistence = .transient
    ) throws -> ProbeStorageDescriptor {
        let shape = try ProbeShape(extents: [2, 3], limits: limits)
        let scalar = try ProbeScalarFormat(byteWidth: 2, byteOrder: byteOrder)
        let components = try ProbeComponents(
            count: 2,
            layout: .interleaved,
            limits: limits
        )
        return try ProbeStorageDescriptor(
            shape: shape,
            scalar: scalar,
            components: components,
            organization: .linear,
            representation: .decodedStrided(
                ProbeStridedLayout(
                    baseOffset: 0,
                    axisByteStrides: [4, 8],
                    componentByteStride: 2
                )
            ),
            providerMechanism: providerMechanism,
            locality: locality,
            persistence: persistence,
            resolutionLevelCount: 1,
            representationByteLength: 24,
            alignment: 2,
            integrityClaim: nil,
            limits: limits
        )
    }

    static func opaqueDescriptor(
        limits: ProbeDescriptorLimits,
        organization: ProbeStorageOrganization = .linear,
        opaque: ProbeOpaqueRepresentation = .compressed,
        providerMechanism: ProbeProviderMechanism = .callback,
        locality: ProbeStorageLocality = .remote,
        persistence: ProbePersistence = .external,
        resolutionLevelCount: UInt64 = 1,
        representationByteLength: UInt64? = nil
    ) throws -> ProbeStorageDescriptor {
        let shape = try ProbeShape(extents: [2, 3], limits: limits)
        let scalar = try ProbeScalarFormat(byteWidth: 2, byteOrder: .littleEndian)
        let components = try ProbeComponents(
            count: 2,
            layout: .interleaved,
            limits: limits
        )
        return try ProbeStorageDescriptor(
            shape: shape,
            scalar: scalar,
            components: components,
            organization: organization,
            representation: .opaque(opaque),
            providerMechanism: providerMechanism,
            locality: locality,
            persistence: persistence,
            resolutionLevelCount: resolutionLevelCount,
            representationByteLength: representationByteLength,
            alignment: nil,
            integrityClaim: nil,
            limits: limits
        )
    }
}

private func probeRequire(
    _ condition: @autoclosure () -> Bool,
    _ message: String = "storage probe failed"
) {
    precondition(condition(), message)
}

private func probeRequireThrows<T: Error & Equatable, R>(
    _ expected: T,
    _ operation: () throws -> R
) {
    do {
        _ = try operation()
        preconditionFailure("storage probe unexpectedly succeeded")
    } catch let error as T {
        precondition(error == expected, "storage probe returned a different typed failure")
    } catch {
        preconditionFailure("storage probe returned an unexpected error type")
    }
}

private func probeRequireAsyncThrows<T: Error & Equatable, R>(
    _ expected: T,
    _ operation: () async throws -> R
) async {
    do {
        _ = try await operation()
        preconditionFailure("storage probe unexpectedly succeeded")
    } catch let error as T {
        precondition(error == expected, "storage probe returned a different typed failure")
    } catch {
        preconditionFailure("storage probe returned an unexpected error type")
    }
}

@main
struct ADR0039StorageCapabilityDescriptorAdmissionProbe {
    static func main() async throws {
        try testClosedCapabilityWire()
        try testDescriptorAndLayoutAdmission()
        try await testCapabilityWitnessAdmission()
        try await testAtomicRegionReadPublication()
        try await testRepresentationIntegrityEvidence()
        try await testBuilderPublication()
        try await testActorOwnedViewLifetime()
        try testRedactedDiagnostics()
    }

    private static func testClosedCapabilityWire() throws {
        let cases = ProbeStorageCapability.allCases
        probeRequire(cases.count == 10)
        probeRequire(Set(cases.map(\.rawValue)).count == cases.count)
        for capability in cases {
            let rawValue = capability.rawValue
            probeRequire(rawValue.nonzeroBitCount == 1)
            probeRequire(rawValue & ~ProbeCapabilityClaim.knownMask == 0)
        }
        probeRequire(ProbeCapabilityClaim.knownMask == 0x0000_0000_0000_03FF)

        let empty = try ProbeCapabilityEnvelope(
            claim: ProbeCapabilityClaim(rawValue: 0)
        )
        probeRequire(empty.wire == #"{"schemaVersion":1,"bits":"0000000000000000"}"#)

        let fullClaim = ProbeFixtures.claim(cases)
        let full = try ProbeCapabilityEnvelope(claim: fullClaim)
        probeRequire(full.wire == #"{"schemaVersion":1,"bits":"00000000000003ff"}"#)
        let decodedFull = try ProbeCapabilityEnvelope(wire: full.wire)
        probeRequire(decodedFull.claim == fullClaim)

        probeRequireThrows(ProbeStorageError.invalidCapabilityWire) {
            try ProbeCapabilityEnvelope(
                wire: #"{"schemaVersion":1,"bits":"00000000000003FF"}"#
            )
        }
        probeRequireThrows(ProbeStorageError.invalidCapabilityWire) {
            try ProbeCapabilityEnvelope(
                wire: #"{"bits":"0000000000000000","schemaVersion":1}"#
            )
        }
        probeRequireThrows(ProbeStorageError.invalidCapabilityWire) {
            try ProbeCapabilityEnvelope(
                wire: #"{"schemaVersion":2,"bits":"0000000000000000"}"#
            )
        }
        probeRequireThrows(ProbeStorageError.unknownCapabilityBits) {
            try ProbeCapabilityEnvelope(
                wire: #"{"schemaVersion":1,"bits":"0000000000000400"}"#
            )
        }
        probeRequireThrows(ProbeStorageError.unknownCapabilityBits) {
            try ProbeCapabilityEnvelope(
                claim: ProbeCapabilityClaim(rawValue: 1 << 63)
            )
        }

        let futureWire = #"{"schemaVersion":2,"bits":"0000000000000400"}"#
        let opaque = try ProbeOpaqueFixedWidthCapabilityEnvelope(wire: futureWire)
        probeRequire(opaque.forwardedWire == futureWire)
        probeRequireThrows(ProbeStorageError.invalidCapabilityWire) {
            try ProbeOpaqueFixedWidthCapabilityEnvelope(wire: full.wire)
        }
        probeRequireThrows(ProbeStorageError.invalidCapabilityWire) {
            try ProbeOpaqueFixedWidthCapabilityEnvelope(wire: "not-an-envelope")
        }
        probeRequireThrows(ProbeStorageError.invalidCapabilityWire) {
            try ProbeCapabilityEnvelope(wire: String(repeating: "x", count: 1_000))
        }
        probeRequireThrows(ProbeStorageError.invalidCapabilityWire) {
            try ProbeOpaqueFixedWidthCapabilityEnvelope(
                rawUTF8: repeatElement(UInt8(0x78), count: 257)
            )
        }
    }

    private static func testDescriptorAndLayoutAdmission() throws {
        let limits = try ProbeDescriptorLimits.probeDefault()
        let canonical = try ProbeFixtures.canonicalDescriptor(limits: limits)
        probeRequire(canonical.logicalByteCount == 24)
        probeRequire(canonical.requiredRepresentationByteLength == 24)

        let shape = canonical.shape
        let scalar = canonical.scalar
        let interleaved = canonical.components
        let planar = try ProbeComponents(count: 2, layout: .planar, limits: limits)
        let planarDescriptor = try ProbeStorageDescriptor(
            shape: shape,
            scalar: scalar,
            components: planar,
            organization: .linear,
            representation: .decodedStrided(
                ProbeStridedLayout(
                    baseOffset: 0,
                    axisByteStrides: [2, 4],
                    componentByteStride: 12
                )
            ),
            providerMechanism: .ownedMemory,
            persistence: .transient,
            resolutionLevelCount: 1,
            representationByteLength: 24,
            alignment: 2,
            integrityClaim: nil,
            limits: limits
        )
        probeRequire(planarDescriptor.requiredRepresentationByteLength == 24)

        let paddedRepresentation = ProbeRepresentation.decodedStrided(
            ProbeStridedLayout(
                baseOffset: 8,
                axisByteStrides: [4, 16],
                componentByteStride: 2
            )
        )
        let paddedBinding = ProbeRepresentationDescriptorBinding(
            shape: shape,
            scalar: scalar,
            components: interleaved,
            organization: .linear,
            representation: paddedRepresentation,
            locality: .local,
            providerMechanism: .ownedMemory,
            persistence: .transient,
            resolutionLevelCount: 1,
            representationByteLength: 64,
            alignment: 8
        )
        let paddedClaim = try ProbeRepresentationIntegrityClaim(
            projectionID: try ProbeFixtures.exact("voxelia.storage-representation"),
            projectionVersion: 1,
            descriptorBinding: paddedBinding,
            snapshotID: ProbeStorageSnapshotID(
                value: try ProbeFixtures.exact("snapshot.padded")
            ),
            generation: 1,
            algorithm: .sha256,
            digest: repeatElement(UInt8(101), count: 32),
            representationByteLength: 64
        )
        let paddedDescriptor = try ProbeStorageDescriptor(
            shape: shape,
            scalar: scalar,
            components: interleaved,
            organization: .linear,
            representation: paddedRepresentation,
            providerMechanism: .ownedMemory,
            persistence: .transient,
            resolutionLevelCount: 1,
            representationByteLength: 64,
            alignment: 8,
            integrityClaim: paddedClaim,
            limits: limits
        )
        probeRequire(paddedDescriptor.logicalByteCount == 24)
        probeRequire(paddedDescriptor.requiredRepresentationByteLength == 48)
        probeRequire(paddedDescriptor.representationByteLength == 64)

        probeRequireThrows(ProbeStorageError.rankMismatch) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: interleaved,
                organization: .linear,
                representation: .decodedStrided(
                    ProbeStridedLayout(
                        baseOffset: 0,
                        axisByteStrides: [4],
                        componentByteStride: 2
                    )
                ),
                providerMechanism: .ownedMemory,
                persistence: .transient,
                resolutionLevelCount: 1,
                representationByteLength: 24,
                alignment: 2,
                integrityClaim: nil,
                limits: limits
            )
        }
        probeRequireThrows(ProbeStorageError.overlappingLayout) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: interleaved,
                organization: .linear,
                representation: .decodedStrided(
                    ProbeStridedLayout(
                        baseOffset: 0,
                        axisByteStrides: [2, 4],
                        componentByteStride: 2
                    )
                ),
                providerMechanism: .ownedMemory,
                persistence: .transient,
                resolutionLevelCount: 1,
                representationByteLength: 24,
                alignment: 2,
                integrityClaim: nil,
                limits: limits
            )
        }
        probeRequireThrows(ProbeStorageError.overlappingLayout) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: planar,
                organization: .linear,
                representation: .decodedStrided(
                    ProbeStridedLayout(
                        baseOffset: 0,
                        axisByteStrides: [2, 4],
                        componentByteStride: 10
                    )
                ),
                providerMechanism: .ownedMemory,
                persistence: .transient,
                resolutionLevelCount: 1,
                representationByteLength: 24,
                alignment: 2,
                integrityClaim: nil,
                limits: limits
            )
        }
        probeRequireThrows(ProbeStorageError.byteLengthRequired) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: interleaved,
                organization: .linear,
                representation: canonical.representation,
                providerMechanism: .ownedMemory,
                persistence: .transient,
                resolutionLevelCount: 1,
                representationByteLength: nil,
                alignment: 2,
                integrityClaim: nil,
                limits: limits
            )
        }
        probeRequireThrows(ProbeStorageError.byteLengthInsufficient) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: interleaved,
                organization: .linear,
                representation: canonical.representation,
                providerMechanism: .ownedMemory,
                persistence: .transient,
                resolutionLevelCount: 1,
                representationByteLength: 23,
                alignment: 2,
                integrityClaim: nil,
                limits: limits
            )
        }
        probeRequireThrows(ProbeStorageError.invalidAlignment) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: interleaved,
                organization: .linear,
                representation: canonical.representation,
                providerMechanism: .ownedMemory,
                persistence: .transient,
                resolutionLevelCount: 1,
                representationByteLength: 24,
                alignment: 3,
                integrityClaim: nil,
                limits: limits
            )
        }
        probeRequireThrows(ProbeStorageError.invalidAlignment) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: interleaved,
                organization: .linear,
                representation: .decodedStrided(
                    ProbeStridedLayout(
                        baseOffset: 2,
                        axisByteStrides: [4, 8],
                        componentByteStride: 2
                    )
                ),
                providerMechanism: .ownedMemory,
                persistence: .transient,
                resolutionLevelCount: 1,
                representationByteLength: 26,
                alignment: 4,
                integrityClaim: nil,
                limits: limits
            )
        }

        let nativeScalar = try ProbeScalarFormat(byteWidth: 2, byteOrder: .native)
        probeRequireThrows(ProbeStorageError.unstableByteOrder) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: nativeScalar,
                components: interleaved,
                organization: .linear,
                representation: canonical.representation,
                providerMechanism: .mappedFile,
                persistence: .mappedFile,
                resolutionLevelCount: 1,
                representationByteLength: 24,
                alignment: 2,
                integrityClaim: nil,
                limits: limits
            )
        }
        _ = try ProbeFixtures.canonicalDescriptor(
            limits: limits,
            byteOrder: .native,
            providerMechanism: .ownedMemory,
            locality: .remote,
            persistence: .processLifetime
        )

        let storageDefined = try ProbeComponents(
            count: 2,
            layout: .storageDefined,
            limits: limits
        )
        probeRequireThrows(ProbeStorageError.invalidLayout) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: storageDefined,
                organization: .providerDefined,
                representation: canonical.representation,
                providerMechanism: .callback,
                persistence: .external,
                resolutionLevelCount: 1,
                representationByteLength: 24,
                alignment: nil,
                integrityClaim: nil,
                limits: limits
            )
        }

        let unknownLengthOpaque = try ProbeFixtures.opaqueDescriptor(limits: limits)
        probeRequire(unknownLengthOpaque.representationByteLength == nil)
        probeRequire(unknownLengthOpaque.logicalByteCount == 24)
        let remoteProcessLifetimeSession = try ProbeFixtures.opaqueDescriptor(
            limits: limits,
            providerMechanism: .callback,
            locality: .remote,
            persistence: .processLifetime
        )
        probeRequire(remoteProcessLifetimeSession.locality == .remote)
        probeRequire(
            remoteProcessLifetimeSession.providerMechanism == .callback
        )
        probeRequire(
            remoteProcessLifetimeSession.persistence == .processLifetime
        )
        let remoteOriginMappedCache = try ProbeFixtures.opaqueDescriptor(
            limits: limits,
            providerMechanism: .mappedFile,
            locality: .remote,
            persistence: .mappedFile,
            representationByteLength: 24
        )
        probeRequire(remoteOriginMappedCache.locality == .remote)
        probeRequire(remoteOriginMappedCache.providerMechanism == .mappedFile)
        probeRequire(remoteOriginMappedCache.persistence == .mappedFile)
        probeRequireThrows(ProbeStorageError.invalidIntegrityClaim) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: interleaved,
                organization: .linear,
                representation: .opaque(.compressed),
                providerMechanism: .callback,
                locality: .remote,
                persistence: .external,
                resolutionLevelCount: 1,
                representationByteLength: nil,
                alignment: nil,
                integrityClaim: paddedClaim,
                limits: limits
            )
        }
        probeRequireThrows(ProbeStorageError.arithmeticOverflow) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: interleaved,
                organization: .linear,
                representation: .decodedStrided(
                    ProbeStridedLayout(
                        baseOffset: 0,
                        axisByteStrides: [UInt64.max, 8],
                        componentByteStride: 2
                    )
                ),
                providerMechanism: .ownedMemory,
                persistence: .transient,
                resolutionLevelCount: 1,
                representationByteLength: limits.maximumRepresentationByteLength,
                alignment: 2,
                integrityClaim: nil,
                limits: limits
            )
        }
        probeRequireThrows(ProbeStorageError.invalidAlignment) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: interleaved,
                organization: .linear,
                representation: canonical.representation,
                providerMechanism: .ownedMemory,
                persistence: .transient,
                resolutionLevelCount: 1,
                representationByteLength: 24,
                alignment: limits.maximumAlignment * 2,
                integrityClaim: nil,
                limits: limits
            )
        }
        probeRequireThrows(ProbeStorageError.invalidAlignment) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: interleaved,
                organization: .linear,
                representation: .opaque(.compressed),
                providerMechanism: .mappedFile,
                persistence: .mappedFile,
                resolutionLevelCount: 1,
                representationByteLength: 24,
                alignment: 2,
                integrityClaim: nil,
                limits: limits
            )
        }
        probeRequireThrows(ProbeStorageError.invalidResolution) {
            try ProbeStorageDescriptor(
                shape: shape,
                scalar: scalar,
                components: interleaved,
                organization: .linear,
                representation: .opaque(.compressed),
                providerMechanism: .callback,
                locality: .remote,
                persistence: .external,
                resolutionLevelCount: limits.maximumResolutionLevels + 1,
                representationByteLength: nil,
                alignment: nil,
                integrityClaim: nil,
                limits: limits
            )
        }

        let largeShape = try ProbeShape(
            extents: [1_024, 1_024, 2],
            limits: limits
        )
        let largeScalar = try ProbeScalarFormat(
            byteWidth: 8,
            byteOrder: .littleEndian
        )
        let largeComponents = try ProbeComponents(
            count: 8,
            layout: .interleaved,
            limits: limits
        )
        let largeOpaque = try ProbeStorageDescriptor(
            shape: largeShape,
            scalar: largeScalar,
            components: largeComponents,
            organization: .bricked,
            representation: .opaque(.compressed),
            providerMechanism: .callback,
            locality: .remote,
            persistence: .external,
            resolutionLevelCount: 1,
            representationByteLength: nil,
            alignment: nil,
            integrityClaim: nil,
            limits: limits
        )
        probeRequire(largeOpaque.logicalByteCount > limits.maximumRequestByteLength)
    }

    private static func testCapabilityWitnessAdmission() async throws {
        let limits = try ProbeDescriptorLimits.probeDefault()
        let canonical = try ProbeFixtures.canonicalDescriptor(limits: limits)
        let ownerID = ProbeStorageOwnerID(
            value: try ProbeFixtures.exact("provider.owner")
        )
        let snapshotID = ProbeStorageSnapshotID(
            value: try ProbeFixtures.exact("provider.snapshot")
        )
        let canonicalBytes = try ProbeBoundedBytes(
            (0..<24).map { UInt8($0) },
            maximumByteCount: 24
        )
        let baseCapabilities: Set<ProbeStorageCapability> = [
            .scopedContiguousByteAccess,
            .builderAcquisition,
            .regionEnumeration,
            .prefetchHints,
            .scopedDigestAccess,
        ]
        var retainedProvider: ProbeStorageProvider? = try ProbeStorageProvider(
            ownerID: ownerID,
            descriptor: canonical,
            snapshotID: snapshotID,
            generation: 7,
            representationBytes: canonicalBytes,
            supportedCapabilities: baseCapabilities
        )
        requireExactActorRedaction(retainedProvider!)
        let baseAdmission = try await retainedProvider!.admission()
        retainedProvider = nil
        let admitted = baseAdmission
        probeRequire(admitted.descriptor == canonical)
        probeRequire(admitted.witnesses.regionRead.binding.ownerID == ownerID)
        probeRequire(admitted.witnesses.regionRead.binding.descriptor == canonical)
        probeRequire(admitted.witnesses.regionRead.binding.snapshotID == snapshotID)
        probeRequire(admitted.witnesses.regionRead.binding.generation == 7)
        probeRequire(admitted.witnesses.operations.count == baseCapabilities.count)
        for witness in admitted.witnesses.operations {
            let receipt = try await witness.invoke()
            probeRequire(receipt.capability == witness.capability)
            probeRequire(receipt.binding == witness.binding)
        }

        let staleProvider = try ProbeStorageProvider(
            ownerID: ownerID,
            descriptor: canonical,
            snapshotID: snapshotID,
            generation: 7,
            representationBytes: canonicalBytes,
            supportedCapabilities: [.prefetchHints]
        )
        let staleWitness = try await staleProvider.admission().witnesses.operations[0]
        try await staleProvider.advanceGeneration()
        await probeRequireAsyncThrows(ProbeStorageError.staleGeneration) {
            try await staleWitness.invoke()
        }

        let mappedCompressed = try ProbeFixtures.opaqueDescriptor(
            limits: limits,
            providerMechanism: .mappedFile,
            locality: .local,
            persistence: .mappedFile,
            representationByteLength: 128
        )
        let mappedBytes = try ProbeBoundedBytes(
            repeatElement(UInt8(1), count: 128),
            maximumByteCount: 128
        )
        let mappedProviderWithoutLogicalRead = try ProbeStorageProvider(
            ownerID: ownerID,
            descriptor: mappedCompressed,
            snapshotID: snapshotID,
            generation: 1,
            representationBytes: mappedBytes,
            supportedCapabilities: [
                .mappedRepresentationAccess,
                .compressedRepresentationAccess,
            ]
        )
        await probeRequireAsyncThrows(ProbeStorageError.missingReadPath) {
            try await mappedProviderWithoutLogicalRead.admission()
        }
        probeRequireThrows(ProbeStorageError.capabilityConflict) {
            try ProbeStorageProvider(
                ownerID: ownerID,
                descriptor: mappedCompressed,
                snapshotID: snapshotID,
                generation: 1,
                representationBytes: mappedBytes,
                supportedCapabilities: [.scopedContiguousByteAccess]
            )
        }

        let remoteCompressed = try ProbeFixtures.opaqueDescriptor(
            limits: limits,
            representationByteLength: 128
        )
        probeRequireThrows(ProbeStorageError.capabilityConflict) {
            try ProbeStorageProvider(
                ownerID: ownerID,
                descriptor: remoteCompressed,
                snapshotID: snapshotID,
                generation: 1,
                representationBytes: mappedBytes,
                supportedCapabilities: [.mappedRepresentationAccess]
            )
        }
        probeRequireThrows(ProbeStorageError.capabilityConflict) {
            try ProbeStorageProvider(
                ownerID: ownerID,
                descriptor: canonical,
                snapshotID: snapshotID,
                generation: 1,
                representationBytes: canonicalBytes,
                supportedCapabilities: [.nativeTileAccess]
            )
        }
        probeRequireThrows(ProbeStorageError.unsupportedAccess) {
            try ProbeStorageProvider(
                ownerID: ownerID,
                descriptor: canonical,
                snapshotID: snapshotID,
                generation: 1,
                representationBytes: canonicalBytes,
                supportedCapabilities: [.resolutionLevelAccess]
            )
        }

        let brick = try ProbeFixtures.opaqueDescriptor(
            limits: limits,
            organization: .bricked,
            resolutionLevelCount: 3,
            representationByteLength: 256
        )
        let brickBytes = try ProbeBoundedBytes(
            repeatElement(UInt8(2), count: 256),
            maximumByteCount: 256
        )
        probeRequireThrows(ProbeStorageError.unsupportedAccess) {
            try ProbeStorageProvider(
                ownerID: ownerID,
                descriptor: brick,
                snapshotID: snapshotID,
                generation: 3,
                representationBytes: brickBytes,
                canonicalLogicalReadBytes: canonicalBytes,
                supportedCapabilities: [.resolutionLevelAccess]
            )
        }
        let brickProvider = try ProbeStorageProvider(
            ownerID: ownerID,
            descriptor: brick,
            snapshotID: snapshotID,
            generation: 3,
            representationBytes: brickBytes,
            canonicalLogicalReadBytes: canonicalBytes,
            supportedCapabilities: [
                .nativeBrickAccess,
                .compressedRepresentationAccess,
                .prefetchHints,
            ]
        )
        let brickAdmission = try await brickProvider.admission()
        probeRequire(
            !brickAdmission.witnesses.operations.contains {
                $0.capability == .resolutionLevelAccess
            }
        )
        let fullBrickRegion = try ProbeRegion(
            origin: [0, 0],
            extents: brick.shape.extents,
            within: brick.shape
        )
        let brickDestinationDescriptor = try ProbeDestinationDescriptor(
            shape: brick.shape,
            scalar: brick.scalar,
            components: brick.components,
            declaredByteLength: brick.logicalByteCount,
            limits: limits
        )
        let brickDestination = ProbeReadDestination(
            descriptor: brickDestinationDescriptor,
            currentGeneration: 3
        )
        let brickRequest = try await brickDestination.begin(
            region: fullBrickRegion,
            storage: brick,
            witness: brickAdmission.witnesses.regionRead,
            limits: limits
        )
        let brickCompletion = try await brickAdmission.witnesses.regionRead.read(
            brickRequest
        )
        try await brickDestination.publish(brickCompletion)
        let brickDestinationState = await brickDestination.snapshot()
        probeRequire(brickDestinationState == .published(canonicalBytes))
    }

    private static func testAtomicRegionReadPublication() async throws {
        let limits = try ProbeDescriptorLimits.probeDefault()
        let storage = try ProbeFixtures.canonicalDescriptor(limits: limits)
        let region = try ProbeRegion(
            origin: [1, 0],
            extents: [1, 3],
            within: storage.shape
        )
        let destinationShape = try ProbeShape(extents: region.extents, limits: limits)
        let destinationDescriptor = try ProbeDestinationDescriptor(
            shape: destinationShape,
            scalar: storage.scalar,
            components: storage.components,
            declaredByteLength: 12,
            limits: limits
        )
        let representationBytes = try ProbeBoundedBytes(
            (0..<24).map { UInt8($0) },
            maximumByteCount: 24
        )
        let expectedPackedRegionBytes = try ProbeBoundedBytes(
            [4, 5, 6, 7, 12, 13, 14, 15, 20, 21, 22, 23],
            maximumByteCount: 12
        )
        let provider = try ProbeStorageProvider(
            ownerID: ProbeStorageOwnerID(
                value: try ProbeFixtures.exact("read.provider")
            ),
            descriptor: storage,
            snapshotID: ProbeStorageSnapshotID(
                value: try ProbeFixtures.exact("read.snapshot")
            ),
            generation: 7,
            representationBytes: representationBytes,
            supportedCapabilities: [] as [ProbeStorageCapability]
        )
        let readWitness = try await provider.admission().witnesses.regionRead
        let substitutingProvider = try ProbeStorageProvider(
            ownerID: ProbeStorageOwnerID(
                value: try ProbeFixtures.exact("read.provider")
            ),
            descriptor: storage,
            snapshotID: ProbeStorageSnapshotID(
                value: try ProbeFixtures.exact("read.snapshot")
            ),
            generation: 7,
            representationBytes: try ProbeBoundedBytes(
                repeatElement(UInt8(0xEE), count: 24),
                maximumByteCount: 24
            ),
            supportedCapabilities: [] as [ProbeStorageCapability]
        )
        let substitutingWitness =
            try await substitutingProvider.admission().witnesses.regionRead
        probeRequire(readWitness.binding.ownerID == substitutingWitness.binding.ownerID)
        probeRequire(
            readWitness.binding.snapshotID == substitutingWitness.binding.snapshotID
        )
        probeRequire(readWitness.binding.generation == substitutingWitness.binding.generation)
        probeRequire(readWitness.binding.descriptor == substitutingWitness.binding.descriptor)
        probeRequire(
            readWitness.binding.providerIdentity
                !== substitutingWitness.binding.providerIdentity
        )
        probeRequire(readWitness.binding != substitutingWitness.binding)

        let crossProviderDestination = ProbeReadDestination(
            descriptor: destinationDescriptor,
            currentGeneration: 7
        )
        let crossProviderRequest = try await crossProviderDestination.begin(
            region: region,
            storage: storage,
            witness: readWitness,
            limits: limits
        )
        await probeRequireAsyncThrows(ProbeStorageError.staleGeneration) {
            try await substitutingWitness.read(crossProviderRequest)
        }
        let authorizedCrossProviderCompletion = try await readWitness.read(
            crossProviderRequest
        )
        try await crossProviderDestination.publish(
            authorizedCrossProviderCompletion
        )
        let authorizedCrossProviderState = await crossProviderDestination.snapshot()
        probeRequire(
            authorizedCrossProviderState == .published(expectedPackedRegionBytes)
        )

        let success = ProbeReadDestination(
            descriptor: destinationDescriptor,
            currentGeneration: 7
        )
        let successRequest = try await success.begin(
            region: region,
            storage: storage,
            witness: readWitness,
            limits: limits
        )
        let successCompletion = try await readWitness.read(successRequest)
        try await success.publish(successCompletion)
        requireExactActorRedaction(success)
        let successState = await success.snapshot()
        probeRequire(
            successState == .published(expectedPackedRegionBytes)
        )

        let partial = ProbeReadDestination(
            descriptor: destinationDescriptor,
            currentGeneration: 7
        )
        let partialRequest = try await partial.begin(
            region: region,
            storage: storage,
            witness: readWitness,
            limits: limits
        )
        let partialCompletion = try await readWitness.readShortNegativeFixture(
            partialRequest
        )
        await probeRequireAsyncThrows(ProbeStorageError.partialRead) {
            try await partial.publish(partialCompletion)
        }
        let fullCompletionAfterPartial = try await readWitness.read(
            partialRequest
        )
        await probeRequireAsyncThrows(ProbeStorageError.staleGeneration) {
            try await partial.publish(fullCompletionAfterPartial)
        }
        let partialState = await partial.snapshot()
        probeRequire(partialState == .empty)

        let cancelled = ProbeReadDestination(
            descriptor: destinationDescriptor,
            currentGeneration: 7
        )
        let cancelledRequest = try await cancelled.begin(
            region: region,
            storage: storage,
            witness: readWitness,
            limits: limits
        )
        let cancelledCompletion =
            try await readWitness.readCancellationNegativeFixture(
                cancelledRequest
            )
        await probeRequireAsyncThrows(ProbeStorageError.cancelled) {
            try await cancelled.publish(cancelledCompletion)
        }
        let cancelledState = await cancelled.snapshot()
        probeRequire(cancelledState == .empty)

        let failed = ProbeReadDestination(
            descriptor: destinationDescriptor,
            currentGeneration: 7
        )
        let failedRequest = try await failed.begin(
            region: region,
            storage: storage,
            witness: readWitness,
            limits: limits
        )
        let failedCompletion = try await readWitness.readFailureNegativeFixture(
            failedRequest
        )
        await probeRequireAsyncThrows(ProbeStorageError.failedRead) {
            try await failed.publish(failedCompletion)
        }
        let failedState = await failed.snapshot()
        probeRequire(failedState == .empty)

        let sameLengthDifferentStorage = try ProbeFixtures.canonicalDescriptor(
            limits: limits,
            byteOrder: .bigEndian
        )
        let substitutedDescriptorDestination = ProbeReadDestination(
            descriptor: try ProbeDestinationDescriptor(
                shape: destinationShape,
                scalar: sameLengthDifferentStorage.scalar,
                components: sameLengthDifferentStorage.components,
                declaredByteLength: 12,
                limits: limits
            ),
            currentGeneration: 7
        )
        await probeRequireAsyncThrows(ProbeStorageError.staleGeneration) {
            try await substitutedDescriptorDestination.begin(
                region: region,
                storage: sameLengthDifferentStorage,
                witness: readWitness,
                limits: limits
            )
        }

        let retaggingTarget = ProbeReadDestination(
            descriptor: destinationDescriptor,
            currentGeneration: 7
        )
        let oldRequest = try await retaggingTarget.begin(
            region: region,
            storage: storage,
            witness: readWitness,
            limits: limits
        )
        let oldCompletion = try await readWitness.read(oldRequest)
        try await retaggingTarget.advanceGeneration()
        try await provider.advanceGeneration()
        let currentReadWitness = try await provider.admission().witnesses.regionRead
        let currentRequest = try await retaggingTarget.begin(
            region: region,
            storage: storage,
            witness: currentReadWitness,
            limits: limits
        )
        await probeRequireAsyncThrows(ProbeStorageError.staleGeneration) {
            try await retaggingTarget.publish(oldCompletion)
        }
        let currentCompletion = try await currentReadWitness.read(currentRequest)
        try await retaggingTarget.publish(currentCompletion)

        let oneComponent = try ProbeComponents(
            count: 1,
            layout: .interleaved,
            limits: limits
        )
        let wrongDescriptor = try ProbeDestinationDescriptor(
            shape: destinationShape,
            scalar: storage.scalar,
            components: oneComponent,
            declaredByteLength: 6,
            limits: limits
        )
        let mismatch = ProbeReadDestination(
            descriptor: wrongDescriptor,
            currentGeneration: 7
        )
        await probeRequireAsyncThrows(ProbeStorageError.destinationMismatch) {
            try await mismatch.begin(
                region: region,
                storage: storage,
                witness: readWitness,
                limits: limits
            )
        }
        let mismatchState = await mismatch.snapshot()
        probeRequire(mismatchState == .empty)

        let otherShape = try ProbeShape(extents: [3, 2], limits: limits)
        let crossShapeRegion = try ProbeRegion(
            origin: [0, 0],
            extents: [1, 2],
            within: otherShape
        )
        let crossShapeDestination = try ProbeDestinationDescriptor(
            shape: ProbeShape(extents: crossShapeRegion.extents, limits: limits),
            scalar: storage.scalar,
            components: storage.components,
            declaredByteLength: 8,
            limits: limits
        )
        let substituted = ProbeReadDestination(
            descriptor: crossShapeDestination,
            currentGeneration: 7
        )
        await probeRequireAsyncThrows(ProbeStorageError.destinationMismatch) {
            try await substituted.begin(
                region: crossShapeRegion,
                storage: storage,
                witness: readWitness,
                limits: limits
            )
        }
        let substitutedState = await substituted.snapshot()
        probeRequire(substitutedState == .empty)

        probeRequireThrows(ProbeStorageError.regionOutOfBounds) {
            try ProbeRegion(
                origin: [2, 0],
                extents: [1, 3],
                within: storage.shape
            )
        }
        probeRequireThrows(ProbeStorageError.rankMismatch) {
            try ProbeRegion(
                origin: repeatElement(UInt64(0), count: 3),
                extents: [1, 1],
                within: storage.shape
            )
        }
    }

    private static func testRepresentationIntegrityEvidence() async throws {
        let limits = try ProbeDescriptorLimits.probeDefault()
        let canonical = try ProbeFixtures.canonicalDescriptor(limits: limits)
        let snapshotID = ProbeStorageSnapshotID(
            value: try ProbeFixtures.exact("snapshot.1")
        )
        let representationBytes = try ProbeBoundedBytes(
            (0..<24).map { UInt8($0) },
            maximumByteCount: 24
        )
        let digest = ContiguousArray(
            SHA256.hash(data: representationBytes.exactData)
        )
        probeRequire(
            digest == [
                0x1D, 0x64, 0xAD, 0xD2, 0xA6, 0x38, 0x83, 0x67,
                0xC9, 0xBC, 0x2D, 0x1F, 0x1B, 0x38, 0x4B, 0x06,
                0x9A, 0x6E, 0xF3, 0x82, 0xCD, 0xAA, 0xA8, 0x97,
                0x71, 0xDD, 0x10, 0x3E, 0x28, 0x61, 0x3A, 0x25,
            ]
        )
        let claim = try ProbeRepresentationIntegrityClaim(
            projectionID: try ProbeFixtures.exact(
                "voxelia.storage-representation"
            ),
            projectionVersion: 1,
            descriptorBinding: canonical.representationBinding,
            snapshotID: snapshotID,
            generation: 5,
            algorithm: .sha256,
            digest: digest,
            representationByteLength: 24
        )
        let descriptor = try ProbeStorageDescriptor(
            shape: canonical.shape,
            scalar: canonical.scalar,
            components: canonical.components,
            organization: canonical.organization,
            representation: canonical.representation,
            providerMechanism: canonical.providerMechanism,
            locality: canonical.locality,
            persistence: canonical.persistence,
            resolutionLevelCount: canonical.resolutionLevelCount,
            representationByteLength: canonical.representationByteLength,
            alignment: canonical.alignment,
            integrityClaim: claim,
            limits: limits
        )
        let policyID = ProbeIntegrityPolicyID(
            value: try ProbeFixtures.exact("policy.representation-integrity")
        )
        let policyAuthority = try ProbeIntegrityPolicyAuthority(
            policyID: policyID,
            revision: 1
        )
        let provider = try ProbeStorageProvider(
            ownerID: ProbeStorageOwnerID(
                value: try ProbeFixtures.exact("integrity.provider")
            ),
            descriptor: descriptor,
            snapshotID: snapshotID,
            generation: 5,
            representationBytes: representationBytes,
            supportedCapabilities: [.scopedDigestAccess],
            integrityPolicyAuthority: policyAuthority
        )
        let evidence = try await provider.verifyRepresentationIntegrity()
        let assurance = try await policyAuthority.evaluate(
            descriptor: descriptor,
            evidence: evidence
        )
        probeRequire(assurance.claim == claim)
        probeRequire(assurance.descriptor == descriptor)
        probeRequire(assurance.binding.generation == 5)
        probeRequire(assurance.policySnapshot.policyID == policyID)
        probeRequire(assurance.policySnapshot.revision == 1)

        let otherAuthority = try ProbeIntegrityPolicyAuthority(
            policyID: policyID,
            revision: 1
        )
        await probeRequireAsyncThrows(ProbeStorageError.integrityDenied) {
            try await otherAuthority.evaluate(
                descriptor: descriptor,
                evidence: evidence
            )
        }

        let badClaim = try ProbeRepresentationIntegrityClaim(
            projectionID: claim.projectionID,
            projectionVersion: claim.projectionVersion,
            descriptorBinding: canonical.representationBinding,
            snapshotID: snapshotID,
            generation: 5,
            algorithm: .sha256,
            digest: repeatElement(UInt8(0xA5), count: 32),
            representationByteLength: 24
        )
        let badDescriptor = try ProbeStorageDescriptor(
            shape: canonical.shape,
            scalar: canonical.scalar,
            components: canonical.components,
            organization: canonical.organization,
            representation: canonical.representation,
            providerMechanism: canonical.providerMechanism,
            locality: canonical.locality,
            persistence: canonical.persistence,
            resolutionLevelCount: canonical.resolutionLevelCount,
            representationByteLength: canonical.representationByteLength,
            alignment: canonical.alignment,
            integrityClaim: badClaim,
            limits: limits
        )
        let badProvider = try ProbeStorageProvider(
            ownerID: ProbeStorageOwnerID(
                value: try ProbeFixtures.exact("integrity.bad-provider")
            ),
            descriptor: badDescriptor,
            snapshotID: snapshotID,
            generation: 5,
            representationBytes: representationBytes,
            supportedCapabilities: [.scopedDigestAccess],
            integrityPolicyAuthority: policyAuthority
        )
        await probeRequireAsyncThrows(ProbeStorageError.integrityDenied) {
            try await badProvider.verifyRepresentationIntegrity()
        }

        let transplantedScalar = try ProbeScalarFormat(
            byteWidth: canonical.scalar.byteWidth,
            byteOrder: .bigEndian
        )
        probeRequireThrows(ProbeStorageError.invalidIntegrityClaim) {
            try ProbeStorageDescriptor(
                shape: canonical.shape,
                scalar: transplantedScalar,
                components: canonical.components,
                organization: canonical.organization,
                representation: canonical.representation,
                providerMechanism: canonical.providerMechanism,
                locality: canonical.locality,
                persistence: canonical.persistence,
                resolutionLevelCount: canonical.resolutionLevelCount,
                representationByteLength: canonical.representationByteLength,
                alignment: canonical.alignment,
                integrityClaim: claim,
                limits: limits
            )
        }

        try await policyAuthority.revoke()
        await probeRequireAsyncThrows(ProbeStorageError.integrityDenied) {
            try await policyAuthority.evaluate(
                descriptor: descriptor,
                evidence: evidence
            )
        }

        let expiryAuthority = try ProbeIntegrityPolicyAuthority(
            policyID: policyID,
            revision: 7
        )
        let expiryProvider = try ProbeStorageProvider(
            ownerID: ProbeStorageOwnerID(
                value: try ProbeFixtures.exact("integrity.expiry-provider")
            ),
            descriptor: descriptor,
            snapshotID: snapshotID,
            generation: 5,
            representationBytes: representationBytes,
            supportedCapabilities: [.scopedDigestAccess],
            integrityPolicyAuthority: expiryAuthority
        )
        let expiryEvidence =
            try await expiryProvider
            .verifyRepresentationIntegrity()
        try await expiryAuthority.expire()
        await probeRequireAsyncThrows(ProbeStorageError.integrityDenied) {
            try await expiryAuthority.evaluate(
                descriptor: descriptor,
                evidence: expiryEvidence
            )
        }

        try await expiryProvider.advanceGeneration()
        await probeRequireAsyncThrows(ProbeStorageError.integrityDenied) {
            try await expiryEvidence.validateCurrent()
        }

        probeRequireThrows(ProbeStorageError.invalidIntegrityClaim) {
            try ProbeRepresentationIntegrityClaim(
                projectionID: try ProbeFixtures.exact(
                    "voxelia.storage-representation"
                ),
                projectionVersion: 1,
                descriptorBinding: canonical.representationBinding,
                snapshotID: snapshotID,
                generation: 5,
                algorithm: .sha256,
                digest: repeatElement(UInt8(0), count: 31),
                representationByteLength: 24
            )
        }

        let noPolicyProvider = try ProbeStorageProvider(
            ownerID: ProbeStorageOwnerID(
                value: try ProbeFixtures.exact("integrity.no-policy")
            ),
            descriptor: descriptor,
            snapshotID: snapshotID,
            generation: 5,
            representationBytes: representationBytes,
            supportedCapabilities: [.scopedDigestAccess]
        )
        await probeRequireAsyncThrows(ProbeStorageError.integrityDenied) {
            try await noPolicyProvider.verifyRepresentationIntegrity()
        }
    }

    private static func testBuilderPublication() async throws {
        let limits = try ProbeDescriptorLimits.probeDefault()
        let descriptor = try ProbeFixtures.canonicalDescriptor(limits: limits)
        let firstRegion = try ProbeRegion(
            origin: [0, 0],
            extents: [2, 1],
            within: descriptor.shape
        )
        let secondRegion = try ProbeRegion(
            origin: [0, 1],
            extents: [2, 2],
            within: descriptor.shape
        )
        let first = try ProbeWriteSlot(
            value: ProbeFixtures.exact("region.first"),
            region: firstRegion,
            descriptor: descriptor,
            limits: limits
        )
        let second = try ProbeWriteSlot(
            value: ProbeFixtures.exact("region.second"),
            region: secondRegion,
            descriptor: descriptor,
            limits: limits
        )
        let unknown = try ProbeWriteSlot(
            value: ProbeFixtures.exact("region.unknown"),
            region: firstRegion,
            descriptor: descriptor,
            limits: limits
        )
        let overlapping = try ProbeWriteSlot(
            value: ProbeFixtures.exact("region.overlap"),
            region: ProbeRegion(
                origin: [1, 0],
                extents: [1, 3],
                within: descriptor.shape
            ),
            descriptor: descriptor,
            limits: limits
        )
        let firstBytes = ContiguousArray(repeating: UInt8(1), count: 8)
        let secondBytes = ContiguousArray(repeating: UInt8(2), count: 16)
        let representationBytes = try ProbeBoundedBytes(
            (0..<24).map { UInt8($0) },
            maximumByteCount: 24
        )
        let ownerID = ProbeStorageOwnerID(
            value: try ProbeFixtures.exact("builder.provider")
        )
        let snapshotID = ProbeStorageSnapshotID(
            value: try ProbeFixtures.exact("builder.snapshot")
        )
        let provider = try ProbeStorageProvider(
            ownerID: ownerID,
            descriptor: descriptor,
            snapshotID: snapshotID,
            generation: 11,
            representationBytes: representationBytes,
            supportedCapabilities: [.builderAcquisition]
        )
        let builderWitness = try await provider.admission().witnesses.operations[0]

        await probeRequireAsyncThrows(ProbeStorageError.duplicateWrite) {
            try await builderWitness.acquireBuilder(
                requiredSlots: [first, first],
                limits: limits
            )
        }
        await probeRequireAsyncThrows(ProbeStorageError.invalidWritePartition) {
            try await builderWitness.acquireBuilder(
                requiredSlots: [first],
                limits: limits
            )
        }
        await probeRequireAsyncThrows(ProbeStorageError.invalidWritePartition) {
            try await builderWitness.acquireBuilder(
                requiredSlots: [first, second, overlapping],
                limits: limits
            )
        }
        await probeRequireAsyncThrows(ProbeStorageError.invalidWritePartition) {
            try await builderWitness.acquireBuilder(
                requiredSlots: repeatElement(
                    first,
                    count: Int(limits.maximumBuilderSlots + 1)
                ),
                limits: limits
            )
        }
        let sameLengthDifferentDescriptor =
            try ProbeFixtures.canonicalDescriptor(
                limits: limits,
                byteOrder: .bigEndian
            )
        let substitutedFirst = try ProbeWriteSlot(
            value: ProbeFixtures.exact("region.substituted"),
            region: firstRegion,
            descriptor: sameLengthDifferentDescriptor,
            limits: limits
        )
        await probeRequireAsyncThrows(ProbeStorageError.invalidWritePartition) {
            try await builderWitness.acquireBuilder(
                requiredSlots: [substitutedFirst, second],
                limits: limits
            )
        }

        let builder = try await builderWitness.acquireBuilder(
            requiredSlots: [first, second],
            limits: limits
        )
        await probeRequireAsyncThrows(ProbeStorageError.unknownWrite) {
            try await builder.write(unknown, delivery: .bytes(firstBytes))
        }
        try await builder.write(first, delivery: .bytes(firstBytes))
        await probeRequireAsyncThrows(ProbeStorageError.duplicateWrite) {
            try await builder.write(first, delivery: .bytes(firstBytes))
        }
        await probeRequireAsyncThrows(ProbeStorageError.incompleteBuilder) {
            try await builder.commit()
        }
        let incompleteState = await builder.snapshot()
        probeRequire(incompleteState == .open(completedCount: 1))

        await probeRequireAsyncThrows(ProbeStorageError.cancelled) {
            try await builder.write(second, delivery: .retryableCancellation)
        }
        let cancelledState = await builder.snapshot()
        probeRequire(cancelledState == .open(completedCount: 1))
        try await builder.write(second, delivery: .bytes(secondBytes))
        requireExactActorRedaction(builder)
        let frozen = try await builder.commit()
        probeRequire(frozen.descriptor == descriptor)
        probeRequire(frozen.binding.ownerID == ownerID)
        probeRequire(frozen.binding.snapshotID != snapshotID)
        probeRequire(frozen.binding.generation == 1)
        probeRequire(frozen.binding.sourceAuthority == builderWitness.binding)
        probeRequire(frozen.completedSlotCount == 2)
        probeRequire(frozen.stagedLogicalByteCount == descriptor.logicalByteCount)
        probeRequire(frozen.stagedBytesBySlot[first] == firstBytes)
        probeRequire(frozen.stagedBytesBySlot[second] == secondBytes)
        let committedState = await builder.snapshot()
        probeRequire(committedState == .committed(completedCount: 2))
        await probeRequireAsyncThrows(ProbeStorageError.alreadyCommitted) {
            try await builder.commit()
        }

        let sameValuePeerProvider = try ProbeStorageProvider(
            ownerID: ownerID,
            descriptor: descriptor,
            snapshotID: snapshotID,
            generation: 11,
            representationBytes: representationBytes,
            supportedCapabilities: [.builderAcquisition]
        )
        let sameValuePeerWitness =
            try await sameValuePeerProvider.admission().witnesses.operations[0]
        probeRequire(sameValuePeerWitness.binding != builderWitness.binding)
        probeRequire(
            sameValuePeerWitness.binding.providerIdentity
                !== builderWitness.binding.providerIdentity
        )
        let sameValuePeerBuilder =
            try await sameValuePeerWitness.acquireBuilder(
                requiredSlots: [first, second],
                limits: limits
            )
        let peerFirstBytes = ContiguousArray(repeating: UInt8(3), count: 8)
        let peerSecondBytes = ContiguousArray(repeating: UInt8(4), count: 16)
        try await sameValuePeerBuilder.write(
            first,
            delivery: .bytes(peerFirstBytes)
        )
        try await sameValuePeerBuilder.write(
            second,
            delivery: .bytes(peerSecondBytes)
        )
        let sameValuePeerFrozen = try await sameValuePeerBuilder.commit()
        probeRequire(
            sameValuePeerFrozen.binding.snapshotID == frozen.binding.snapshotID
        )
        probeRequire(
            sameValuePeerFrozen.binding.generation == frozen.binding.generation
        )
        probeRequire(sameValuePeerFrozen.binding != frozen.binding)
        probeRequire(
            sameValuePeerFrozen.binding.sourceAuthority
                == sameValuePeerWitness.binding
        )
        probeRequire(
            sameValuePeerFrozen.binding.sourceAuthority
                != frozen.binding.sourceAuthority
        )
        probeRequire(
            sameValuePeerFrozen.stagedBytesBySlot != frozen.stagedBytesBySlot
        )
        probeRequire(
            sameValuePeerFrozen.stagedBytesBySlot[first] == peerFirstBytes
        )
        probeRequire(
            sameValuePeerFrozen.stagedBytesBySlot[second] == peerSecondBytes
        )

        let uniqueTargetBuilder = try await builderWitness.acquireBuilder(
            requiredSlots: [first, second],
            limits: limits
        )
        try await uniqueTargetBuilder.write(first, delivery: .bytes(firstBytes))
        try await uniqueTargetBuilder.write(second, delivery: .bytes(secondBytes))
        let uniqueTargetFrozen = try await uniqueTargetBuilder.commit()
        probeRequire(uniqueTargetFrozen.binding != frozen.binding)
        probeRequire(
            uniqueTargetFrozen.binding.snapshotID != frozen.binding.snapshotID
        )
        probeRequire(uniqueTargetFrozen.binding.generation == 2)
        probeRequire(
            uniqueTargetFrozen.binding.sourceAuthority == builderWitness.binding
        )

        let staleProvider = try ProbeStorageProvider(
            ownerID: ownerID,
            descriptor: descriptor,
            snapshotID: snapshotID,
            generation: 11,
            representationBytes: representationBytes,
            supportedCapabilities: [.builderAcquisition]
        )
        let staleBuilderWitness =
            try await staleProvider.admission().witnesses.operations[0]
        let staleBuilder = try await staleBuilderWitness.acquireBuilder(
            requiredSlots: [first, second],
            limits: limits
        )
        try await staleBuilder.write(first, delivery: .bytes(firstBytes))
        try await staleBuilder.write(second, delivery: .bytes(secondBytes))
        try await staleProvider.advanceGeneration()
        await probeRequireAsyncThrows(ProbeStorageError.staleGeneration) {
            try await staleBuilder.commit()
        }
        await probeRequireAsyncThrows(ProbeStorageError.staleGeneration) {
            try await staleBuilder.commit()
        }
        let staleState = await staleBuilder.snapshot()
        probeRequire(staleState == .open(completedCount: 2))
        await probeRequireAsyncThrows(ProbeStorageError.staleGeneration) {
            try await staleBuilderWitness.acquireBuilder(
                requiredSlots: [first, second],
                limits: limits
            )
        }

        let failedBuilder = try await builderWitness.acquireBuilder(
            requiredSlots: [first, second],
            limits: limits
        )
        try await failedBuilder.write(first, delivery: .bytes(firstBytes))
        await probeRequireAsyncThrows(ProbeStorageError.failedWrite) {
            try await failedBuilder.write(second, delivery: .failed)
        }
        let failedState = await failedBuilder.snapshot()
        probeRequire(failedState == .failed(completedCount: 1))
        await probeRequireAsyncThrows(ProbeStorageError.failedWrite) {
            try await failedBuilder.commit()
        }

        let shortBuilder = try await builderWitness.acquireBuilder(
            requiredSlots: [first, second],
            limits: limits
        )
        await probeRequireAsyncThrows(ProbeStorageError.failedWrite) {
            try await shortBuilder.write(
                first,
                delivery: .bytes(
                    ContiguousArray(repeating: UInt8(1), count: 7)
                )
            )
        }
        let shortState = await shortBuilder.snapshot()
        probeRequire(shortState == .failed(completedCount: 0))

        let cancelledBuilder = try await builderWitness.acquireBuilder(
            requiredSlots: [first, second],
            limits: limits
        )
        try await cancelledBuilder.write(first, delivery: .bytes(firstBytes))
        await probeRequireAsyncThrows(ProbeStorageError.cancelled) {
            try await cancelledBuilder.write(
                second,
                delivery: .transactionCancellation
            )
        }
        let terminalCancellationState = await cancelledBuilder.snapshot()
        probeRequire(terminalCancellationState == .cancelled(completedCount: 1))
        await probeRequireAsyncThrows(ProbeStorageError.cancelled) {
            try await cancelledBuilder.write(second, delivery: .bytes(secondBytes))
        }
        await probeRequireAsyncThrows(ProbeStorageError.cancelled) {
            try await cancelledBuilder.commit()
        }
    }

    private static func testActorOwnedViewLifetime() async throws {
        var retainedOwner: ProbeBackingOwner? = try ProbeBackingOwner(
            bytes: [0, 1, 2],
            maximumByteLength: 8
        )
        let retainedView = try await retainedOwner?.makeView(offset: 0, count: 3)
        retainedOwner = nil
        let retainedSnapshot = try await retainedView?.readOwnedSnapshot()
        probeRequire(retainedSnapshot == [0, 1, 2])

        let owner = try ProbeBackingOwner(
            bytes: [0, 1, 2, 3, 4, 5],
            maximumByteLength: 8
        )
        requireExactActorRedaction(owner)
        let view = try await owner.makeView(offset: 1, count: 3)
        let firstSnapshot = try await view.readOwnedSnapshot()
        probeRequire(firstSnapshot == [1, 2, 3])

        try await owner.replace(with: [9, 8, 7, 6])
        await probeRequireAsyncThrows(ProbeStorageError.staleGeneration) {
            try await view.readOwnedSnapshot()
        }

        let current = try await owner.makeView(offset: 0, count: 4)
        let currentSnapshot = try await current.readOwnedSnapshot()
        probeRequire(currentSnapshot == [9, 8, 7, 6])
        await probeRequireAsyncThrows(ProbeStorageError.byteLengthInsufficient) {
            try await owner.replace(with: repeatElement(UInt8(1), count: 9))
        }
        let unchangedSnapshot = try await current.readOwnedSnapshot()
        probeRequire(unchangedSnapshot == [9, 8, 7, 6])

        probeRequireThrows(ProbeStorageError.byteLengthInsufficient) {
            try ProbeBackingOwner(
                bytes: repeatElement(UInt8(0), count: 9),
                maximumByteLength: 8
            )
        }
    }

    private static func requireExactActorRedaction(
        _ value: some AnyObject & ProbeRedactedDiagnostic
    ) {
        probeRequire(String(describing: value) == "<redacted-storage-probe>")
        probeRequire(String(reflecting: value) == "<redacted-storage-probe>")
        let mirror = Mirror(reflecting: value)
        probeRequire(mirror.children.count == 1)
        let child = mirror.children.first
        probeRequire(child?.label == "value")
        probeRequire(
            child.map { String(describing: $0.value) }
                == "<redacted-storage-probe>"
        )
        var dumped = ""
        dump(value, to: &dumped)
        probeRequire(
            dumped
                == "▿ <redacted-storage-probe> #0\n"
                + "  - value: \"<redacted-storage-probe>\"\n"
        )
    }

    private static func requireExactRedaction(
        _ value: some ProbeRedactedDiagnostic
    ) {
        probeRequire(String(describing: value) == "<redacted-storage-probe>")
        probeRequire(String(reflecting: value) == "<redacted-storage-probe>")
        let mirror = Mirror(reflecting: value)
        probeRequire(mirror.children.count == 1)
        let child = mirror.children.first
        probeRequire(child?.label == "value")
        probeRequire(
            child.map { String(describing: $0.value) }
                == "<redacted-storage-probe>"
        )
        var dumped = ""
        dump(value, to: &dumped)
        probeRequire(
            dumped
                == "▿ <redacted-storage-probe>\n"
                + "  - value: \"<redacted-storage-probe>\"\n"
        )
    }

    private static func testRedactedDiagnostics() throws {
        let patientSentinel = "Patient Jane Doe / SOP 1.2.840.113619"
        let sensitive = try ProbeExactText(patientSentinel)
        let sensitiveOwner = ProbeStorageOwnerID(value: sensitive)
        let sensitiveBytes = try ProbeBoundedBytes(
            patientSentinel.utf8,
            maximumByteCount: UInt64(patientSentinel.utf8.count)
        )
        requireExactRedaction(sensitiveBytes)
        requireExactRedaction(ProbeDestinationState.published(sensitiveBytes))
        requireExactRedaction(
            ProbeWriteDelivery.bytes(sensitiveBytes.exactBytes)
        )
        probeRequire(
            String(describing: sensitiveBytes) == "<redacted-storage-probe>"
        )
        probeRequire(
            String(reflecting: sensitiveBytes) == "<redacted-storage-probe>"
        )
        let byteMirror = Mirror(reflecting: sensitiveBytes)
        probeRequire(byteMirror.children.count == 1)
        let byteChild = byteMirror.children.first
        probeRequire(byteChild?.label == "value")
        probeRequire(
            byteChild.map { String(describing: $0.value) }
                == "<redacted-storage-probe>"
        )
        var byteDump = ""
        dump(sensitiveBytes, to: &byteDump)
        probeRequire(
            byteDump
                == "▿ <redacted-storage-probe>\n"
                + "  - value: \"<redacted-storage-probe>\"\n"
        )
        var values = [
            String(describing: sensitive),
            String(reflecting: sensitive),
            String(describing: sensitiveOwner),
            String(reflecting: sensitiveOwner),
            String(describing: ProbeStorageError.invalidIntegrityClaim),
            String(reflecting: ProbeStorageError.staleGeneration),
        ]
        values.append(
            contentsOf: Mirror(reflecting: sensitive).children.map {
                String(reflecting: $0.value)
            }
        )
        var dumped = ""
        dump(sensitiveOwner, to: &dumped)
        values.append(dumped)
        for value in values {
            probeRequire(!value.contains(patientSentinel))
            probeRequire(!value.contains("Jane Doe"))
            probeRequire(!value.contains("1.2.840"))
        }

        probeRequireThrows(ProbeStorageError.invalidLimits) {
            try ProbeBoundedBytes(
                [] as [UInt8],
                maximumByteCount:
                    ProbePlatformByteCeiling.maximumMaterializedByteCount + 1
            )
        }
        probeRequireThrows(ProbeStorageError.invalidLimits) {
            try ProbeBackingOwner(
                bytes: [] as [UInt8],
                maximumByteLength:
                    ProbePlatformByteCeiling.maximumMaterializedByteCount + 1
            )
        }
        let limits = try ProbeDescriptorLimits.probeDefault()
        probeRequireThrows(ProbeStorageError.invalidLimits) {
            try ProbeDescriptorLimits(
                maximumRank: limits.maximumRank,
                maximumExtent: limits.maximumExtent,
                maximumComponents: limits.maximumComponents,
                maximumLogicalByteCount: limits.maximumLogicalByteCount,
                maximumRepresentationByteLength:
                    ProbePlatformByteCeiling.maximumMaterializedByteCount + 1,
                maximumRequestByteLength: limits.maximumRequestByteLength,
                maximumAlignment: limits.maximumAlignment,
                maximumResolutionLevels: limits.maximumResolutionLevels,
                maximumBuilderSlots: limits.maximumBuilderSlots
            )
        }
    }
}
