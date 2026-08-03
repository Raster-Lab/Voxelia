// SPDX-License-Identifier: MIT

import CryptoKit
import Foundation

// Isolated Swift 6 evidence for proposed ADR-0040. These Probe* declarations
// use toy tags and toy resource limits. They are not Voxelia product API, a
// canonical descriptor/wire, a persistent image identity, a production source
// decoder, or diagnostic validation. The floating fixtures demonstrate an
// exact-bit sequence only; they do not define full semantic image identity.

private enum ProbeProjectionError:
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
    case invalidShape
    case invalidRegion
    case rankMismatch
    case regionOutOfBounds
    case arithmeticOverflow
    case resourceLimitExceeded
    case invalidLogicalBinding
    case logicalBindingMismatch
    case invalidRepresentation
    case invalidComponentMap
    case overlappingAddress
    case addressOutOfBounds
    case shortInput
    case longInput
    case sourceDecoderRequired
    case unsupportedPacking
    case floatingValidBitsUnsupported
    case invalidSourceInterpretation
    case invalidUnusedBits

    var description: String { "logical projection probe rejected input" }
    var debugDescription: String { description }
    var customMirror: Mirror {
        Mirror(self, children: ["value": ProbeDiagnostic.redactionMarker])
    }
}

private enum ProbeDiagnostic {
    static let redactionMarker = "<redacted-logical-projection-probe>"
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

private struct ProbeLimits: Sendable, Hashable, ProbeRedactedDiagnostic {
    let maximumRank: Int
    let maximumExtent: Int
    let maximumElementCount: Int
    let maximumComponentCount: Int
    let maximumLogicalValueCount: Int
    let maximumCanonicalByteCount: Int
    let maximumRepresentationByteCount: Int
    let maximumFingerprintFrameByteCount: Int

    init(
        maximumRank: Int,
        maximumExtent: Int,
        maximumElementCount: Int,
        maximumComponentCount: Int,
        maximumLogicalValueCount: Int,
        maximumCanonicalByteCount: Int,
        maximumRepresentationByteCount: Int,
        maximumFingerprintFrameByteCount: Int
    ) throws {
        guard maximumRank > 0,
            maximumRank <= 64,
            maximumExtent > 0,
            maximumElementCount > 0,
            maximumComponentCount > 0,
            maximumLogicalValueCount > 0,
            maximumCanonicalByteCount > 0,
            maximumRepresentationByteCount > 0,
            maximumFingerprintFrameByteCount > 0
        else {
            throw ProbeProjectionError.invalidLimit
        }

        self.maximumRank = maximumRank
        self.maximumExtent = maximumExtent
        self.maximumElementCount = maximumElementCount
        self.maximumComponentCount = maximumComponentCount
        self.maximumLogicalValueCount = maximumLogicalValueCount
        self.maximumCanonicalByteCount = maximumCanonicalByteCount
        self.maximumRepresentationByteCount = maximumRepresentationByteCount
        self.maximumFingerprintFrameByteCount = maximumFingerprintFrameByteCount
    }

    static func fixture() throws -> Self {
        try Self(
            maximumRank: 4,
            maximumExtent: 64,
            maximumElementCount: 1_024,
            maximumComponentCount: 8,
            maximumLogicalValueCount: 4_096,
            maximumCanonicalByteCount: 65_536,
            maximumRepresentationByteCount: 65_536,
            maximumFingerprintFrameByteCount: 131_072
        )
    }
}

private func probeCheckedAdd(_ lhs: Int, _ rhs: Int) throws -> Int {
    guard lhs >= 0, rhs >= 0 else {
        throw ProbeProjectionError.arithmeticOverflow
    }
    let (result, overflow) = lhs.addingReportingOverflow(rhs)
    guard !overflow else { throw ProbeProjectionError.arithmeticOverflow }
    return result
}

private func probeCheckedMultiply(_ lhs: Int, _ rhs: Int) throws -> Int {
    guard lhs >= 0, rhs >= 0 else {
        throw ProbeProjectionError.arithmeticOverflow
    }
    let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
    guard !overflow else { throw ProbeProjectionError.arithmeticOverflow }
    return result
}

private func probeCheckedPlatformInt(
    _ value: UInt64,
    maximum: Int? = nil
) throws -> Int {
    guard value <= UInt64(Int.max) else {
        throw ProbeProjectionError.platformIntegerRange
    }
    if let maximum {
        guard maximum >= 0 else { throw ProbeProjectionError.invalidLimit }
        guard value <= UInt64(maximum) else {
            throw ProbeProjectionError.resourceLimitExceeded
        }
    }
    return Int(value)
}

private func probeSampleOrdinal(
    logicalIndex: some Collection<Int>,
    shape: ProbeShape
) throws -> Int {
    guard logicalIndex.count == shape.rank else {
        throw ProbeProjectionError.rankMismatch
    }
    var ordinal = 0
    var axisStride = 1
    for axis in 0..<shape.rank {
        let index = logicalIndex[logicalIndex.index(logicalIndex.startIndex, offsetBy: axis)]
        guard index >= 0, index < shape.extents[axis] else {
            throw ProbeProjectionError.regionOutOfBounds
        }
        let contribution = try probeCheckedMultiply(index, axisStride)
        ordinal = try probeCheckedAdd(ordinal, contribution)
        axisStride = try probeCheckedMultiply(axisStride, shape.extents[axis])
    }
    return ordinal
}

private func probeValueOrdinal(
    logicalIndex: some Collection<Int>,
    component: Int,
    binding: ProbeLogicalBinding
) throws -> Int {
    guard component >= 0, component < binding.componentCount else {
        throw ProbeProjectionError.invalidLogicalBinding
    }
    let sampleOrdinal = try probeSampleOrdinal(
        logicalIndex: logicalIndex,
        shape: binding.shape
    )
    let firstValue = try probeCheckedMultiply(
        binding.componentCount,
        sampleOrdinal
    )
    return try probeCheckedAdd(firstValue, component)
}

private struct ProbeShape: Sendable, Hashable, ProbeRedactedDiagnostic {
    let extents: ContiguousArray<Int>
    let elementCount: Int

    init(
        rawExtents: some Collection<UInt64>,
        limits: ProbeLimits
    ) throws {
        guard !rawExtents.isEmpty, rawExtents.count <= limits.maximumRank else {
            throw ProbeProjectionError.invalidShape
        }

        var extents: ContiguousArray<Int> = []
        extents.reserveCapacity(rawExtents.count)
        var elementCount = 1
        for rawExtent in rawExtents {
            let extent = try probeCheckedPlatformInt(
                rawExtent,
                maximum: limits.maximumExtent
            )
            guard extent > 0 else {
                throw ProbeProjectionError.invalidShape
            }
            elementCount = try probeCheckedMultiply(elementCount, extent)
            guard elementCount <= limits.maximumElementCount else {
                throw ProbeProjectionError.resourceLimitExceeded
            }
            extents.append(extent)
        }

        self.extents = extents
        self.elementCount = elementCount
    }

    var rank: Int { extents.count }
}

private struct ProbeRegion: Sendable, Hashable, ProbeRedactedDiagnostic {
    let origin: ContiguousArray<Int>
    let extents: ContiguousArray<Int>
    let elementCount: Int

    init(
        rawOrigin: some Collection<UInt64>,
        rawExtents: some Collection<UInt64>,
        within shape: ProbeShape,
        limits: ProbeLimits
    ) throws {
        guard rawOrigin.count == shape.rank, rawExtents.count == shape.rank else {
            throw ProbeProjectionError.rankMismatch
        }

        var origin: ContiguousArray<Int> = []
        var extents: ContiguousArray<Int> = []
        origin.reserveCapacity(shape.rank)
        extents.reserveCapacity(shape.rank)
        var elementCount = 1

        for axis in 0..<shape.rank {
            let axisOrigin = try probeCheckedPlatformInt(
                rawOrigin[rawOrigin.index(rawOrigin.startIndex, offsetBy: axis)],
                maximum: limits.maximumExtent
            )
            let axisExtent = try probeCheckedPlatformInt(
                rawExtents[rawExtents.index(rawExtents.startIndex, offsetBy: axis)],
                maximum: limits.maximumExtent
            )
            guard axisExtent > 0 else {
                throw ProbeProjectionError.invalidRegion
            }
            let end = try probeCheckedAdd(axisOrigin, axisExtent)
            guard end <= shape.extents[axis] else {
                throw ProbeProjectionError.regionOutOfBounds
            }
            elementCount = try probeCheckedMultiply(elementCount, axisExtent)
            guard elementCount <= limits.maximumElementCount else {
                throw ProbeProjectionError.resourceLimitExceeded
            }
            origin.append(axisOrigin)
            extents.append(axisExtent)
        }

        self.origin = origin
        self.extents = extents
        self.elementCount = elementCount
    }

    static func whole(_ shape: ProbeShape, limits: ProbeLimits) throws -> Self {
        try Self(
            rawOrigin: repeatElement(UInt64(0), count: shape.rank),
            rawExtents: shape.extents.map(UInt64.init),
            within: shape,
            limits: limits
        )
    }
}

private enum ProbeLogicalScalar: UInt8, Sendable, Hashable {
    case int16 = 1
    case uint16 = 2
    case binary16 = 3
    case binary32 = 4
    case binary64 = 5

    var byteWidth: Int {
        switch self {
        case .int16, .uint16, .binary16:
            2
        case .binary32:
            4
        case .binary64:
            8
        }
    }

    var isBinaryFloatingPoint: Bool {
        switch self {
        case .int16, .uint16:
            false
        case .binary16, .binary32, .binary64:
            true
        }
    }
}

private enum ProbeComponentInterpretation: UInt8, Sendable, Hashable {
    case generic = 1
    case colourComponents = 2
}

private enum ProbeComponentRole: UInt8, Sendable, Hashable {
    case intensity = 1
    case red = 2
    case green = 3
    case blue = 4
}

private struct ProbeToySemanticDescriptor:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    let interpretation: ProbeComponentInterpretation
    let orderedRoles: ContiguousArray<ProbeComponentRole>

    init(
        interpretation: ProbeComponentInterpretation,
        orderedRoles: some Collection<ProbeComponentRole>,
        limits: ProbeLimits
    ) throws {
        guard !orderedRoles.isEmpty,
            orderedRoles.count <= limits.maximumComponentCount,
            Set(orderedRoles).count == orderedRoles.count
        else {
            throw ProbeProjectionError.invalidLogicalBinding
        }

        switch interpretation {
        case .generic:
            guard orderedRoles.allSatisfy({ $0 == .intensity }) else {
                throw ProbeProjectionError.invalidLogicalBinding
            }
        case .colourComponents:
            guard orderedRoles.allSatisfy({ $0 != .intensity }) else {
                throw ProbeProjectionError.invalidLogicalBinding
            }
        }

        self.interpretation = interpretation
        self.orderedRoles = ContiguousArray(orderedRoles)
    }

    var count: Int { orderedRoles.count }
}

private struct ProbeProjectionCounts: Sendable, Hashable {
    let elementCount: Int
    let valueCount: Int
    let canonicalByteCount: Int

    init(
        elementCount: Int,
        componentCount: Int,
        scalarByteWidth: Int,
        limits: ProbeLimits
    ) throws {
        guard elementCount > 0, componentCount > 0, scalarByteWidth > 0 else {
            throw ProbeProjectionError.invalidLogicalBinding
        }
        let valueCount = try probeCheckedMultiply(elementCount, componentCount)
        let canonicalByteCount = try probeCheckedMultiply(valueCount, scalarByteWidth)
        guard valueCount <= limits.maximumLogicalValueCount,
            canonicalByteCount <= limits.maximumCanonicalByteCount
        else {
            throw ProbeProjectionError.resourceLimitExceeded
        }
        self.elementCount = elementCount
        self.valueCount = valueCount
        self.canonicalByteCount = canonicalByteCount
    }
}

private struct ProbeLogicalBinding:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    let shape: ProbeShape
    let scalar: ProbeLogicalScalar
    let componentCount: Int

    init(
        shape: ProbeShape,
        scalar: ProbeLogicalScalar,
        componentCount: Int,
        limits: ProbeLimits
    ) throws {
        guard componentCount > 0,
            componentCount <= limits.maximumComponentCount
        else {
            throw ProbeProjectionError.invalidLogicalBinding
        }
        _ = try ProbeProjectionCounts(
            elementCount: shape.elementCount,
            componentCount: componentCount,
            scalarByteWidth: scalar.byteWidth,
            limits: limits
        )
        self.shape = shape
        self.scalar = scalar
        self.componentCount = componentCount
    }
}

private enum ProbeByteOrder: UInt8, Sendable, Hashable {
    case littleEndian = 1
    case bigEndian = 2
}

private enum ProbePhysicalLayout: UInt8, Sendable, Hashable {
    case interleaved = 1
    case planar = 2
    case paddedStrided = 3
}

private enum ProbeValueEncoding: Sendable, Hashable {
    case decodedFullWidth
    case integerValidBitCountOnly(storedBitCount: Int)
    case packed(storedBitCount: Int)
    case floatingValidBitCountOnly(storedBitCount: Int)

    var tag: UInt8 {
        switch self {
        case .decodedFullWidth:
            1
        case .integerValidBitCountOnly:
            2
        case .packed:
            3
        case .floatingValidBitCountOnly:
            4
        }
    }

    var storedBitCount: Int? {
        switch self {
        case .decodedFullWidth:
            nil
        case .integerValidBitCountOnly(let storedBitCount),
            .packed(let storedBitCount),
            .floatingValidBitCountOnly(let storedBitCount):
            storedBitCount
        }
    }
}

private struct ProbeRepresentationDescriptor:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    let shape: ProbeShape
    let decodedScalar: ProbeLogicalScalar
    let byteOrder: ProbeByteOrder
    let layout: ProbePhysicalLayout
    let valueEncoding: ProbeValueEncoding
    let baseOffset: Int
    let axisByteStrides: ContiguousArray<Int>
    let componentByteStride: Int
    let physicalLogicalOrdinals: ContiguousArray<Int>
    let physicalSlotForLogicalComponent: ContiguousArray<Int>
    let initializedByteLength: Int

    init(
        shape: ProbeShape,
        decodedScalar: ProbeLogicalScalar,
        byteOrder: ProbeByteOrder,
        layout: ProbePhysicalLayout,
        valueEncoding: ProbeValueEncoding,
        rawBaseOffset: UInt64,
        rawAxisByteStrides: some Collection<UInt64>,
        rawComponentByteStride: UInt64,
        rawPhysicalLogicalOrdinals: some Collection<UInt64>,
        rawPhysicalSlotForLogicalComponent: some Collection<UInt64>,
        rawInitializedByteLength: UInt64,
        limits: ProbeLimits
    ) throws {
        guard rawAxisByteStrides.count <= limits.maximumRank,
            rawPhysicalLogicalOrdinals.count <= limits.maximumComponentCount,
            rawPhysicalSlotForLogicalComponent.count <= limits.maximumComponentCount
        else {
            throw ProbeProjectionError.resourceLimitExceeded
        }
        if let storedBitCount = valueEncoding.storedBitCount,
            storedBitCount <= 0
        {
            throw ProbeProjectionError.invalidSourceInterpretation
        }

        var axisByteStrides: ContiguousArray<Int> = []
        axisByteStrides.reserveCapacity(rawAxisByteStrides.count)
        for rawStride in rawAxisByteStrides {
            axisByteStrides.append(
                try probeCheckedPlatformInt(
                    rawStride,
                    maximum: limits.maximumRepresentationByteCount
                )
            )
        }
        var componentMap: ContiguousArray<Int> = []
        componentMap.reserveCapacity(rawPhysicalSlotForLogicalComponent.count)
        for rawSlot in rawPhysicalSlotForLogicalComponent {
            componentMap.append(
                try probeCheckedPlatformInt(
                    rawSlot,
                    maximum: limits.maximumComponentCount - 1
                )
            )
        }
        var physicalLogicalOrdinals: ContiguousArray<Int> = []
        physicalLogicalOrdinals.reserveCapacity(rawPhysicalLogicalOrdinals.count)
        for rawOrdinal in rawPhysicalLogicalOrdinals {
            physicalLogicalOrdinals.append(
                try probeCheckedPlatformInt(
                    rawOrdinal,
                    maximum: limits.maximumComponentCount - 1
                )
            )
        }

        let initializedByteLength = try probeCheckedPlatformInt(
            rawInitializedByteLength,
            maximum: limits.maximumRepresentationByteCount
        )
        guard initializedByteLength > 0 else {
            throw ProbeProjectionError.invalidRepresentation
        }

        self.shape = shape
        self.decodedScalar = decodedScalar
        self.byteOrder = byteOrder
        self.layout = layout
        self.valueEncoding = valueEncoding
        baseOffset = try probeCheckedPlatformInt(
            rawBaseOffset,
            maximum: limits.maximumRepresentationByteCount
        )
        self.axisByteStrides = axisByteStrides
        componentByteStride = try probeCheckedPlatformInt(
            rawComponentByteStride,
            maximum: limits.maximumRepresentationByteCount
        )
        self.physicalLogicalOrdinals = physicalLogicalOrdinals
        physicalSlotForLogicalComponent = componentMap
        self.initializedByteLength = initializedByteLength
    }
}

private struct ProbeRepresentation:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    let descriptor: ProbeRepresentationDescriptor
    private let byteStorage: ContiguousArray<UInt8>

    init(
        descriptor: ProbeRepresentationDescriptor,
        bytes: some Sequence<UInt8>,
        limits: ProbeLimits
    ) throws {
        var accepted: ContiguousArray<UInt8> = []
        accepted.reserveCapacity(min(descriptor.initializedByteLength, 4_096))
        for byte in bytes {
            guard accepted.count < limits.maximumRepresentationByteCount else {
                throw ProbeProjectionError.resourceLimitExceeded
            }
            accepted.append(byte)
        }
        self.descriptor = descriptor
        byteStorage = accepted
    }

    fileprivate var exactBytes: ContiguousArray<UInt8> { byteStorage }
}

private struct ProbeLogicalProjection:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    let binding: ProbeLogicalBinding
    let region: ProbeRegion
    private let canonicalByteStorage: ContiguousArray<UInt8>

    fileprivate init(
        binding: ProbeLogicalBinding,
        region: ProbeRegion,
        canonicalBytes: ContiguousArray<UInt8>
    ) {
        self.binding = binding
        self.region = region
        canonicalByteStorage = canonicalBytes
    }

    fileprivate var canonicalBytes: ContiguousArray<UInt8> {
        canonicalByteStorage
    }
}

private enum ProbeNormalizer {
    static func normalize(
        binding: ProbeLogicalBinding,
        representation: ProbeRepresentation,
        region: ProbeRegion,
        limits: ProbeLimits
    ) throws -> ProbeLogicalProjection {
        switch representation.descriptor.valueEncoding {
        case .decodedFullWidth:
            break
        case .integerValidBitCountOnly:
            throw ProbeProjectionError.sourceDecoderRequired
        case .packed:
            throw ProbeProjectionError.unsupportedPacking
        case .floatingValidBitCountOnly:
            throw ProbeProjectionError.floatingValidBitsUnsupported
        }

        guard representation.descriptor.shape == binding.shape,
            representation.descriptor.decodedScalar == binding.scalar,
            region.origin.count == binding.shape.rank,
            region.extents.count == binding.shape.rank
        else {
            throw ProbeProjectionError.logicalBindingMismatch
        }
        for axis in 0..<binding.shape.rank {
            guard region.extents[axis] > 0 else {
                throw ProbeProjectionError.invalidRegion
            }
            let end = try probeCheckedAdd(region.origin[axis], region.extents[axis])
            guard end <= binding.shape.extents[axis] else {
                throw ProbeProjectionError.regionOutOfBounds
            }
        }
        guard representation.descriptor.axisByteStrides.count == binding.shape.rank else {
            throw ProbeProjectionError.invalidRepresentation
        }

        try validateComponentMap(
            descriptor: representation.descriptor,
            logicalComponentCount: binding.componentCount
        )

        if representation.exactBytes.count < representation.descriptor.initializedByteLength {
            throw ProbeProjectionError.shortInput
        }
        if representation.exactBytes.count > representation.descriptor.initializedByteLength {
            throw ProbeProjectionError.longInput
        }

        let counts = try ProbeProjectionCounts(
            elementCount: region.elementCount,
            componentCount: binding.componentCount,
            scalarByteWidth: binding.scalar.byteWidth,
            limits: limits
        )
        try validateCompleteAddressing(
            binding: binding,
            descriptor: representation.descriptor,
            limits: limits
        )

        var output: ContiguousArray<UInt8> = []
        output.reserveCapacity(counts.canonicalByteCount)
        try forEachIndex(in: region) { logicalIndex in
            for logicalComponent in 0..<binding.componentCount {
                let address = try valueAddress(
                    descriptor: representation.descriptor,
                    logicalIndex: logicalIndex,
                    logicalComponent: logicalComponent
                )
                let end = try probeCheckedAdd(address, binding.scalar.byteWidth)
                guard end <= representation.exactBytes.count else {
                    throw ProbeProjectionError.addressOutOfBounds
                }
                let source = representation.exactBytes[address..<end]
                switch representation.descriptor.byteOrder {
                case .bigEndian:
                    output.append(contentsOf: source)
                case .littleEndian:
                    output.append(contentsOf: source.reversed())
                }
            }
        }
        guard output.count == counts.canonicalByteCount else {
            throw ProbeProjectionError.invalidRepresentation
        }
        return ProbeLogicalProjection(
            binding: binding,
            region: region,
            canonicalBytes: output
        )
    }

    private static func validateComponentMap(
        descriptor: ProbeRepresentationDescriptor,
        logicalComponentCount: Int
    ) throws {
        // This proves consistency of the retained logical-ordinal claims and
        // map. Raw sample bytes cannot authenticate those claims; a production
        // adapter would need separately admitted authority for the mapping.
        let count = logicalComponentCount
        guard descriptor.physicalLogicalOrdinals.count == count,
            descriptor.physicalSlotForLogicalComponent.count == count,
            Set(descriptor.physicalLogicalOrdinals).count == count,
            descriptor.physicalLogicalOrdinals.allSatisfy({
                $0 >= 0 && $0 < count
            })
        else {
            throw ProbeProjectionError.invalidComponentMap
        }

        var usedSlots: Set<Int> = []
        usedSlots.reserveCapacity(count)
        for logicalOrdinal in 0..<count {
            let physicalSlot = descriptor.physicalSlotForLogicalComponent[logicalOrdinal]
            guard physicalSlot >= 0,
                physicalSlot < count,
                usedSlots.insert(physicalSlot).inserted,
                descriptor.physicalLogicalOrdinals[physicalSlot]
                    == logicalOrdinal
            else {
                throw ProbeProjectionError.invalidComponentMap
            }
        }
    }

    private static func validateCompleteAddressing(
        binding: ProbeLogicalBinding,
        descriptor: ProbeRepresentationDescriptor,
        limits: ProbeLimits
    ) throws {
        let wholeRegion = try ProbeRegion.whole(binding.shape, limits: limits)
        var usedByteOffsets: Set<Int> = []
        let counts = try ProbeProjectionCounts(
            elementCount: binding.shape.elementCount,
            componentCount: binding.componentCount,
            scalarByteWidth: binding.scalar.byteWidth,
            limits: limits
        )
        usedByteOffsets.reserveCapacity(counts.canonicalByteCount)

        try forEachIndex(in: wholeRegion) { logicalIndex in
            for logicalComponent in 0..<binding.componentCount {
                let address = try valueAddress(
                    descriptor: descriptor,
                    logicalIndex: logicalIndex,
                    logicalComponent: logicalComponent
                )
                let end = try probeCheckedAdd(address, binding.scalar.byteWidth)
                guard end <= descriptor.initializedByteLength else {
                    throw ProbeProjectionError.addressOutOfBounds
                }
                for byteOffset in address..<end {
                    guard usedByteOffsets.insert(byteOffset).inserted else {
                        throw ProbeProjectionError.overlappingAddress
                    }
                }
            }
        }
    }

    private static func valueAddress(
        descriptor: ProbeRepresentationDescriptor,
        logicalIndex: ContiguousArray<Int>,
        logicalComponent: Int
    ) throws -> Int {
        var address = descriptor.baseOffset
        for axis in logicalIndex.indices {
            let displacement = try probeCheckedMultiply(
                logicalIndex[axis],
                descriptor.axisByteStrides[axis]
            )
            address = try probeCheckedAdd(address, displacement)
        }
        let physicalSlot = descriptor.physicalSlotForLogicalComponent[logicalComponent]
        let componentDisplacement = try probeCheckedMultiply(
            physicalSlot,
            descriptor.componentByteStride
        )
        return try probeCheckedAdd(address, componentDisplacement)
    }

    private static func forEachIndex(
        in region: ProbeRegion,
        _ body: (ContiguousArray<Int>) throws -> Void
    ) throws {
        var index = region.origin
        while true {
            try body(index)

            var axis = 0
            while axis < index.count {
                index[axis] += 1
                let end = try probeCheckedAdd(
                    region.origin[axis],
                    region.extents[axis]
                )
                if index[axis] < end {
                    break
                }
                index[axis] = region.origin[axis]
                axis += 1
            }
            if axis == index.count {
                return
            }
        }
    }
}

private struct ProbeByteEncoder {
    private(set) var bytes: ContiguousArray<UInt8> = []

    mutating func append(_ value: UInt8) {
        bytes.append(value)
    }

    mutating func appendBigEndian(_ value: UInt16) {
        bytes.append(UInt8(truncatingIfNeeded: value >> 8))
        bytes.append(UInt8(truncatingIfNeeded: value))
    }

    mutating func appendBigEndian(_ value: UInt32) {
        bytes.append(UInt8(truncatingIfNeeded: value >> 24))
        bytes.append(UInt8(truncatingIfNeeded: value >> 16))
        bytes.append(UInt8(truncatingIfNeeded: value >> 8))
        bytes.append(UInt8(truncatingIfNeeded: value))
    }

    mutating func appendBigEndian(_ value: UInt64) {
        bytes.append(UInt8(truncatingIfNeeded: value >> 56))
        bytes.append(UInt8(truncatingIfNeeded: value >> 48))
        bytes.append(UInt8(truncatingIfNeeded: value >> 40))
        bytes.append(UInt8(truncatingIfNeeded: value >> 32))
        bytes.append(UInt8(truncatingIfNeeded: value >> 24))
        bytes.append(UInt8(truncatingIfNeeded: value >> 16))
        bytes.append(UInt8(truncatingIfNeeded: value >> 8))
        bytes.append(UInt8(truncatingIfNeeded: value))
    }

    mutating func appendNonnegativeInt(_ value: Int) throws {
        guard let converted = UInt64(exactly: value) else {
            throw ProbeProjectionError.invalidRepresentation
        }
        appendBigEndian(converted)
    }
}

private struct ProbeToyFrame {
    private(set) var bytes: ContiguousArray<UInt8> = []
    let maximumByteCount: Int

    mutating func appendField(
        tag: UInt8,
        payload: some Collection<UInt8>
    ) throws {
        let headerByteCount = 9
        let withHeader = try probeCheckedAdd(bytes.count, headerByteCount)
        let total = try probeCheckedAdd(withHeader, payload.count)
        guard total <= maximumByteCount,
            let payloadByteCount = UInt64(exactly: payload.count)
        else {
            throw ProbeProjectionError.resourceLimitExceeded
        }
        bytes.append(tag)
        var length = ProbeByteEncoder()
        length.appendBigEndian(payloadByteCount)
        bytes.append(contentsOf: length.bytes)
        bytes.append(contentsOf: payload)
    }
}

private struct ProbeFingerprint:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    private let digestStorage: ContiguousArray<UInt8>

    init(frame: some Collection<UInt8>) {
        digestStorage = ContiguousArray(SHA256.hash(data: Data(frame)))
    }

    var hexadecimal: String {
        var result = ""
        result.reserveCapacity(digestStorage.count * 2)
        for byte in digestStorage {
            result.append(String(format: "%02x", byte))
        }
        return result
    }
}

private enum ProbeFingerprinting {
    private static let sampleLayoutDomain = ContiguousArray(
        "VOXELIA-SAMPLE-LAYOUT-PROBE\0".utf8
    )
    private static let representationDomain = ContiguousArray(
        "VOXELIA-REPRESENTATION-PROBE\0".utf8
    )
    private static let descriptorBearingDomain = ContiguousArray(
        "VOXELIA-DESCRIPTOR-BEARING-PROBE\0".utf8
    )
    private static let sampleLayoutProjection = ContiguousArray(
        "org.voxelia.logical-sample-sequence".utf8
    )
    private static let descriptorBearingProjection = ContiguousArray(
        "org.voxelia.toy-descriptor-bearing-sequence".utf8
    )

    static func sampleLayout(
        _ projection: ProbeLogicalProjection,
        limits: ProbeLimits
    ) throws -> ProbeFingerprint {
        var frame = ProbeToyFrame(
            maximumByteCount: limits.maximumFingerprintFrameByteCount
        )
        try frame.appendField(tag: 1, payload: sampleLayoutDomain)
        try frame.appendField(tag: 2, payload: [0, 0, 0, 1])
        try frame.appendField(tag: 3, payload: sampleLayoutProjection)
        try frame.appendField(
            tag: 4,
            payload: try encode(binding: projection.binding)
        )
        try frame.appendField(
            tag: 5,
            payload: try encode(region: projection.region)
        )
        try frame.appendField(tag: 6, payload: projection.canonicalBytes)
        return ProbeFingerprint(frame: frame.bytes)
    }

    static func descriptorBearing(
        _ projection: ProbeLogicalProjection,
        semantics: ProbeToySemanticDescriptor,
        limits: ProbeLimits
    ) throws -> ProbeFingerprint {
        guard semantics.count == projection.binding.componentCount else {
            throw ProbeProjectionError.logicalBindingMismatch
        }
        var frame = ProbeToyFrame(
            maximumByteCount: limits.maximumFingerprintFrameByteCount
        )
        try frame.appendField(tag: 1, payload: descriptorBearingDomain)
        try frame.appendField(tag: 2, payload: [0, 0, 0, 1])
        try frame.appendField(tag: 3, payload: descriptorBearingProjection)
        try frame.appendField(
            tag: 4,
            payload: try encode(binding: projection.binding)
        )
        try frame.appendField(tag: 5, payload: encode(semantics: semantics))
        try frame.appendField(
            tag: 6,
            payload: try encode(region: projection.region)
        )
        try frame.appendField(tag: 7, payload: projection.canonicalBytes)
        return ProbeFingerprint(frame: frame.bytes)
    }

    static func representation(
        _ representation: ProbeRepresentation,
        limits: ProbeLimits
    ) throws -> ProbeFingerprint {
        var frame = ProbeToyFrame(
            maximumByteCount: limits.maximumFingerprintFrameByteCount
        )
        try frame.appendField(tag: 1, payload: representationDomain)
        try frame.appendField(tag: 2, payload: [0, 0, 0, 1])
        try frame.appendField(
            tag: 3,
            payload: try encode(descriptor: representation.descriptor)
        )
        try frame.appendField(tag: 4, payload: representation.exactBytes)
        return ProbeFingerprint(frame: frame.bytes)
    }

    private static func encode(
        binding: ProbeLogicalBinding
    ) throws -> ContiguousArray<UInt8> {
        var encoder = ProbeByteEncoder()
        try encoder.appendNonnegativeInt(binding.shape.rank)
        for extent in binding.shape.extents {
            try encoder.appendNonnegativeInt(extent)
        }
        encoder.append(binding.scalar.rawValue)
        try encoder.appendNonnegativeInt(binding.componentCount)
        return encoder.bytes
    }

    private static func encode(
        semantics: ProbeToySemanticDescriptor
    ) -> ContiguousArray<UInt8> {
        var encoder = ProbeByteEncoder()
        encoder.append(semantics.interpretation.rawValue)
        for role in semantics.orderedRoles {
            encoder.append(role.rawValue)
        }
        return encoder.bytes
    }

    private static func encode(
        region: ProbeRegion
    ) throws -> ContiguousArray<UInt8> {
        var encoder = ProbeByteEncoder()
        try encoder.appendNonnegativeInt(region.origin.count)
        for origin in region.origin {
            try encoder.appendNonnegativeInt(origin)
        }
        for extent in region.extents {
            try encoder.appendNonnegativeInt(extent)
        }
        return encoder.bytes
    }

    private static func encode(
        descriptor: ProbeRepresentationDescriptor
    ) throws -> ContiguousArray<UInt8> {
        var encoder = ProbeByteEncoder()
        try encoder.appendNonnegativeInt(descriptor.shape.rank)
        for extent in descriptor.shape.extents {
            try encoder.appendNonnegativeInt(extent)
        }
        encoder.append(descriptor.decodedScalar.rawValue)
        encoder.append(descriptor.byteOrder.rawValue)
        encoder.append(descriptor.layout.rawValue)
        encoder.append(descriptor.valueEncoding.tag)
        try encoder.appendNonnegativeInt(descriptor.valueEncoding.storedBitCount ?? 0)
        try encoder.appendNonnegativeInt(descriptor.baseOffset)
        try encoder.appendNonnegativeInt(descriptor.axisByteStrides.count)
        for stride in descriptor.axisByteStrides {
            try encoder.appendNonnegativeInt(stride)
        }
        try encoder.appendNonnegativeInt(descriptor.componentByteStride)
        try encoder.appendNonnegativeInt(descriptor.physicalLogicalOrdinals.count)
        for ordinal in descriptor.physicalLogicalOrdinals {
            try encoder.appendNonnegativeInt(ordinal)
        }
        try encoder.appendNonnegativeInt(
            descriptor.physicalSlotForLogicalComponent.count
        )
        for slot in descriptor.physicalSlotForLogicalComponent {
            try encoder.appendNonnegativeInt(slot)
        }
        try encoder.appendNonnegativeInt(descriptor.initializedByteLength)
        return encoder.bytes
    }
}

private enum ProbeIntegerSignedness: UInt8, Sendable, Hashable {
    case signed = 1
    case unsigned = 2
}

private enum ProbeUnusedBitPolicy: UInt8, Sendable, Hashable {
    case requireZero = 1
    case ignoreButRetainInSourceRepresentation = 2
}

private struct ProbeIntegerSourceInterpretation:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    let containerBitWidth: Int
    let storedBitCount: Int
    let leastSignificantStoredBit: Int
    let signedness: ProbeIntegerSignedness
    let byteOrder: ProbeByteOrder
    let unusedBitPolicy: ProbeUnusedBitPolicy
    let resultScalar: ProbeLogicalScalar

    init(
        containerBitWidth: Int,
        storedBitCount: Int,
        leastSignificantStoredBit: Int,
        signedness: ProbeIntegerSignedness,
        byteOrder: ProbeByteOrder,
        unusedBitPolicy: ProbeUnusedBitPolicy,
        resultScalar: ProbeLogicalScalar
    ) throws {
        guard containerBitWidth == 16,
            storedBitCount > 0,
            storedBitCount <= containerBitWidth,
            leastSignificantStoredBit >= 0,
            resultScalar == .int16 || resultScalar == .uint16
        else {
            throw ProbeProjectionError.invalidSourceInterpretation
        }

        self.containerBitWidth = containerBitWidth
        self.storedBitCount = storedBitCount
        self.leastSignificantStoredBit = leastSignificantStoredBit
        self.signedness = signedness
        self.byteOrder = byteOrder
        self.unusedBitPolicy = unusedBitPolicy
        self.resultScalar = resultScalar
    }
}

private struct ProbeDecodedIntegerSource:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    // The raw source spelling remains separate from the decoded full-width
    // bytes so an ignored unused bit is not erased from representation evidence.
    let resultScalar: ProbeLogicalScalar
    let valueCount: Int
    let interpretation: ProbeIntegerSourceInterpretation
    private let sourceByteStorage: ContiguousArray<UInt8>
    private let fullWidthByteStorage: ContiguousArray<UInt8>

    fileprivate init(
        resultScalar: ProbeLogicalScalar,
        valueCount: Int,
        interpretation: ProbeIntegerSourceInterpretation,
        sourceBytes: ContiguousArray<UInt8>,
        fullWidthBytes: ContiguousArray<UInt8>
    ) {
        self.resultScalar = resultScalar
        self.valueCount = valueCount
        self.interpretation = interpretation
        sourceByteStorage = sourceBytes
        fullWidthByteStorage = fullWidthBytes
    }

    fileprivate var sourceBytes: ContiguousArray<UInt8> {
        sourceByteStorage
    }

    fileprivate var fullWidthBytes: ContiguousArray<UInt8> {
        fullWidthByteStorage
    }
}

private enum ProbeIntegerSourceDecoder {
    static func decode(
        sourceBytes: some Sequence<UInt8>,
        expectedValueCount: Int,
        interpretation: ProbeIntegerSourceInterpretation,
        limits: ProbeLimits
    ) throws -> ProbeDecodedIntegerSource {
        guard expectedValueCount > 0,
            expectedValueCount <= limits.maximumLogicalValueCount
        else {
            throw ProbeProjectionError.resourceLimitExceeded
        }
        let expectedSourceByteCount = try probeCheckedMultiply(expectedValueCount, 2)
        guard expectedSourceByteCount <= limits.maximumRepresentationByteCount else {
            throw ProbeProjectionError.resourceLimitExceeded
        }

        var accepted: ContiguousArray<UInt8> = []
        accepted.reserveCapacity(expectedSourceByteCount)
        for byte in sourceBytes {
            guard accepted.count < limits.maximumRepresentationByteCount else {
                throw ProbeProjectionError.resourceLimitExceeded
            }
            accepted.append(byte)
        }
        if accepted.count < expectedSourceByteCount {
            throw ProbeProjectionError.shortInput
        }
        if accepted.count > expectedSourceByteCount {
            throw ProbeProjectionError.longInput
        }

        var output = ProbeByteEncoder()
        for valueIndex in 0..<expectedValueCount {
            let byteIndex = valueIndex * 2
            // 1. Resolve byte order into one unsigned container.
            let word: UInt16
            switch interpretation.byteOrder {
            case .bigEndian:
                word =
                    UInt16(accepted[byteIndex]) << 8
                    | UInt16(accepted[byteIndex + 1])
            case .littleEndian:
                word =
                    UInt16(accepted[byteIndex + 1]) << 8
                    | UInt16(accepted[byteIndex])
            }

            // 2. Prove the stored field fits before any field shift.
            let fieldEnd = try probeCheckedAdd(
                interpretation.leastSignificantStoredBit,
                interpretation.storedBitCount
            )
            guard fieldEnd <= interpretation.containerBitWidth else {
                throw ProbeProjectionError.invalidSourceInterpretation
            }
            let valueMask: UInt16 =
                interpretation.storedBitCount == 16
                ? UInt16.max
                : (UInt16(1) << interpretation.storedBitCount) - 1
            let fieldMask = valueMask << interpretation.leastSignificantStoredBit
            let unusedMask = ~fieldMask

            // 3. Apply the unused-bit rule to the original container.
            if interpretation.unusedBitPolicy == .requireZero,
                word & unusedMask != 0
            {
                throw ProbeProjectionError.invalidUnusedBits
            }

            // 4. Shift first, then mask the extracted field.
            let field =
                (word >> interpretation.leastSignificantStoredBit) & valueMask

            // 5. Extend only the already-extracted field.
            let extended: UInt16
            switch interpretation.signedness {
            case .signed:
                let signBit = UInt16(1) << (interpretation.storedBitCount - 1)
                extended = field & signBit == 0 ? field : field | ~valueMask
            case .unsigned:
                extended = field
            }

            // 6. Admit only the exact bound decoded scalar spelling.
            output.appendBigEndian(
                try exactTargetBitPattern(
                    extended,
                    interpretation: interpretation
                )
            )
        }
        return ProbeDecodedIntegerSource(
            resultScalar: interpretation.resultScalar,
            valueCount: expectedValueCount,
            interpretation: interpretation,
            sourceBytes: accepted,
            fullWidthBytes: output.bytes
        )
    }

    private static func exactTargetBitPattern(
        _ extended: UInt16,
        interpretation: ProbeIntegerSourceInterpretation
    ) throws -> UInt16 {
        switch (interpretation.signedness, interpretation.resultScalar) {
        case (.signed, .int16), (.unsigned, .uint16):
            extended
        default:
            throw ProbeProjectionError.invalidSourceInterpretation
        }
    }
}

private struct ProbeSensitiveFixture:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    private let label: String
    private let bytes: ContiguousArray<UInt8>

    init(label: String, bytes: some Collection<UInt8>) {
        self.label = label
        self.bytes = ContiguousArray(bytes)
    }
}

private struct ProbeHashReport: Sendable, Hashable {
    let sampleLayout: String
    let littleInterleavedRepresentation: String
    let bigPlanarRepresentation: String
    let paddedBGRRepresentation: String
    let mutatedPaddingRepresentation: String
}

private struct ProbeSemanticHashReport: Sendable, Hashable {
    let rgbDescriptorBearing: String
    let bgrDescriptorBearing: String
}

private enum ProbeFixtures {
    static func rgbSemantics(
        limits: ProbeLimits
    ) throws -> ProbeToySemanticDescriptor {
        try ProbeToySemanticDescriptor(
            interpretation: .colourComponents,
            orderedRoles: [.red, .green, .blue],
            limits: limits
        )
    }

    static func rgbBinding(limits: ProbeLimits) throws -> ProbeLogicalBinding {
        let shape = try ProbeShape(rawExtents: [2, 2], limits: limits)
        return try ProbeLogicalBinding(
            shape: shape,
            scalar: .uint16,
            componentCount: 3,
            limits: limits
        )
    }

    static let canonicalRGBBytes: ContiguousArray<UInt8> = [
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06,
        0x11, 0x12, 0x13, 0x14, 0x15, 0x16,
        0x21, 0x22, 0x23, 0x24, 0x25, 0x26,
        0x31, 0x32, 0x33, 0x34, 0x35, 0x36,
    ]

    static let littleInterleavedBytes: ContiguousArray<UInt8> = [
        0x02, 0x01, 0x04, 0x03, 0x06, 0x05,
        0x12, 0x11, 0x14, 0x13, 0x16, 0x15,
        0x22, 0x21, 0x24, 0x23, 0x26, 0x25,
        0x32, 0x31, 0x34, 0x33, 0x36, 0x35,
    ]

    static let bigPlanarBytes: ContiguousArray<UInt8> = [
        0x01, 0x02, 0x11, 0x12, 0x21, 0x22, 0x31, 0x32,
        0x03, 0x04, 0x13, 0x14, 0x23, 0x24, 0x33, 0x34,
        0x05, 0x06, 0x15, 0x16, 0x25, 0x26, 0x35, 0x36,
    ]

    static let paddedBGRBytes: ContiguousArray<UInt8> = [
        0xAA, 0xAA, 0xAA, 0xAA,
        0x05, 0x06, 0x03, 0x04, 0x01, 0x02, 0xAA, 0xAA,
        0x15, 0x16, 0x13, 0x14, 0x11, 0x12,
        0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA,
        0x25, 0x26, 0x23, 0x24, 0x21, 0x22, 0xAA, 0xAA,
        0x35, 0x36, 0x33, 0x34, 0x31, 0x32,
        0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA,
    ]

    static func representation(
        binding: ProbeLogicalBinding,
        byteOrder: ProbeByteOrder,
        layout: ProbePhysicalLayout,
        valueEncoding: ProbeValueEncoding = .decodedFullWidth,
        baseOffset: UInt64,
        axisByteStrides: [UInt64],
        componentByteStride: UInt64,
        physicalLogicalOrdinals: [UInt64],
        physicalSlotForLogicalComponent: [UInt64],
        initializedByteLength: UInt64,
        bytes: some Sequence<UInt8>,
        limits: ProbeLimits
    ) throws -> ProbeRepresentation {
        let descriptor = try ProbeRepresentationDescriptor(
            shape: binding.shape,
            decodedScalar: binding.scalar,
            byteOrder: byteOrder,
            layout: layout,
            valueEncoding: valueEncoding,
            rawBaseOffset: baseOffset,
            rawAxisByteStrides: axisByteStrides,
            rawComponentByteStride: componentByteStride,
            rawPhysicalLogicalOrdinals: physicalLogicalOrdinals,
            rawPhysicalSlotForLogicalComponent: physicalSlotForLogicalComponent,
            rawInitializedByteLength: initializedByteLength,
            limits: limits
        )
        return try ProbeRepresentation(
            descriptor: descriptor,
            bytes: bytes,
            limits: limits
        )
    }

    static func littleInterleaved(
        binding: ProbeLogicalBinding,
        limits: ProbeLimits
    ) throws -> ProbeRepresentation {
        try representation(
            binding: binding,
            byteOrder: .littleEndian,
            layout: .interleaved,
            baseOffset: 0,
            axisByteStrides: [6, 12],
            componentByteStride: 2,
            physicalLogicalOrdinals: [0, 1, 2],
            physicalSlotForLogicalComponent: [0, 1, 2],
            initializedByteLength: 24,
            bytes: littleInterleavedBytes,
            limits: limits
        )
    }

    static func bigPlanar(
        binding: ProbeLogicalBinding,
        limits: ProbeLimits
    ) throws -> ProbeRepresentation {
        try representation(
            binding: binding,
            byteOrder: .bigEndian,
            layout: .planar,
            baseOffset: 0,
            axisByteStrides: [2, 4],
            componentByteStride: 8,
            physicalLogicalOrdinals: [0, 1, 2],
            physicalSlotForLogicalComponent: [0, 1, 2],
            initializedByteLength: 24,
            bytes: bigPlanarBytes,
            limits: limits
        )
    }

    static func paddedBGR(
        binding: ProbeLogicalBinding,
        bytes: some Sequence<UInt8> = paddedBGRBytes,
        limits: ProbeLimits
    ) throws -> ProbeRepresentation {
        try representation(
            binding: binding,
            byteOrder: .bigEndian,
            layout: .paddedStrided,
            baseOffset: 4,
            axisByteStrides: [8, 20],
            componentByteStride: 2,
            physicalLogicalOrdinals: [2, 1, 0],
            physicalSlotForLogicalComponent: [2, 1, 0],
            initializedByteLength: 44,
            bytes: bytes,
            limits: limits
        )
    }

    static func oneComponentBinding(
        shape: ProbeShape,
        scalar: ProbeLogicalScalar,
        limits: ProbeLimits
    ) throws -> ProbeLogicalBinding {
        return try ProbeLogicalBinding(
            shape: shape,
            scalar: scalar,
            componentCount: 1,
            limits: limits
        )
    }

    static func contiguousBigEndian(
        binding: ProbeLogicalBinding,
        bytes: some Sequence<UInt8>,
        valueEncoding: ProbeValueEncoding = .decodedFullWidth,
        declaredByteLength: UInt64? = nil,
        limits: ProbeLimits
    ) throws -> ProbeRepresentation {
        let counts = try ProbeProjectionCounts(
            elementCount: binding.shape.elementCount,
            componentCount: binding.componentCount,
            scalarByteWidth: binding.scalar.byteWidth,
            limits: limits
        )
        guard let calculatedByteLength = UInt64(exactly: counts.canonicalByteCount) else {
            throw ProbeProjectionError.arithmeticOverflow
        }
        let byteLength = declaredByteLength ?? calculatedByteLength
        let axisStrides = try contiguousAxisStrides(binding: binding)
        return try representation(
            binding: binding,
            byteOrder: .bigEndian,
            layout: .interleaved,
            valueEncoding: valueEncoding,
            baseOffset: 0,
            axisByteStrides: axisStrides,
            componentByteStride: UInt64(binding.scalar.byteWidth),
            physicalLogicalOrdinals: (0..<binding.componentCount).map(UInt64.init),
            physicalSlotForLogicalComponent: (0..<binding.componentCount).map(UInt64.init),
            initializedByteLength: byteLength,
            bytes: bytes,
            limits: limits
        )
    }

    private static func contiguousAxisStrides(
        binding: ProbeLogicalBinding
    ) throws -> [UInt64] {
        var strides: [UInt64] = []
        strides.reserveCapacity(binding.shape.rank)
        var stride = try probeCheckedMultiply(
            binding.scalar.byteWidth,
            binding.componentCount
        )
        for extent in binding.shape.extents {
            guard let rawStride = UInt64(exactly: stride) else {
                throw ProbeProjectionError.arithmeticOverflow
            }
            strides.append(rawStride)
            stride = try probeCheckedMultiply(stride, extent)
        }
        return strides
    }
}

private func probeRequire(
    _ condition: @autoclosure () -> Bool,
    _ message: String = "logical projection probe invariant failed"
) {
    precondition(condition(), message)
}

private func probeRequireThrows<R>(
    _ expected: ProbeProjectionError,
    _ body: () throws -> R
) {
    do {
        _ = try body()
        preconditionFailure("logical projection probe unexpectedly succeeded")
    } catch let error as ProbeProjectionError {
        precondition(
            error == expected,
            "logical projection probe returned a different typed failure"
        )
    } catch {
        preconditionFailure("logical projection probe returned an unexpected error type")
    }
}

@main
private enum ADR0040LogicalSampleProjectionProbe {
    static func main() async throws {
        let limits = try ProbeLimits.fixture()
        try testCheckedShapeRegionAndCounts(limits: limits)
        try testRankThreeAxisZeroFastestGolden(limits: limits)
        try testSHA256KnownAnswer()
        let report = try await testCanonicalLayoutsAndConcurrentEquality(limits: limits)
        try testComponentMapFailures(limits: limits)
        let semanticReport = try testBindingAndRegionFingerprintSensitivity(
            limits: limits
        )
        try testDirectEncodingRejectionsAndSourceDecoder(limits: limits)
        try testExactFloatingBitSequences(limits: limits)
        try testRepresentationFailures(limits: limits)
        try testRedactedDiagnostics(limits: limits)

        print("sampleLayoutFingerprintSHA256=\(report.sampleLayout)")
        print(
            "littleInterleavedRepresentationSHA256="
                + report.littleInterleavedRepresentation
        )
        print("bigPlanarRepresentationSHA256=\(report.bigPlanarRepresentation)")
        print("paddedBGRRepresentationSHA256=\(report.paddedBGRRepresentation)")
        print(
            "mutatedPaddingRepresentationSHA256="
                + report.mutatedPaddingRepresentation
        )
        print(
            "rgbDescriptorBearingSHA256="
                + semanticReport.rgbDescriptorBearing
        )
        print(
            "bgrDescriptorBearingSHA256="
                + semanticReport.bgrDescriptorBearing
        )
        print("focusedTestGroups=10")
    }

    private static func testCheckedShapeRegionAndCounts(
        limits: ProbeLimits
    ) throws {
        let exactPlatformMaximum = try probeCheckedPlatformInt(UInt64(Int.max))
        probeRequire(exactPlatformMaximum == Int.max)
        probeRequireThrows(.platformIntegerRange) {
            try probeCheckedPlatformInt(UInt64(Int.max) + 1)
        }
        probeRequireThrows(.resourceLimitExceeded) {
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

        let exactBoundaryLimits = try ProbeLimits(
            maximumRank: 2,
            maximumExtent: 3,
            maximumElementCount: 6,
            maximumComponentCount: 2,
            maximumLogicalValueCount: 12,
            maximumCanonicalByteCount: 24,
            maximumRepresentationByteCount: 24,
            maximumFingerprintFrameByteCount: 256
        )
        let boundaryShape = try ProbeShape(
            rawExtents: [2, 3],
            limits: exactBoundaryLimits
        )
        probeRequire(boundaryShape.elementCount == 6)
        let boundaryCounts = try ProbeProjectionCounts(
            elementCount: boundaryShape.elementCount,
            componentCount: 2,
            scalarByteWidth: 2,
            limits: exactBoundaryLimits
        )
        probeRequire(boundaryCounts.valueCount == 12)
        probeRequire(boundaryCounts.canonicalByteCount == 24)
        probeRequireThrows(.resourceLimitExceeded) {
            _ = try ProbeShape(rawExtents: [3, 3], limits: exactBoundaryLimits)
        }
        probeRequireThrows(.resourceLimitExceeded) {
            _ = try ProbeProjectionCounts(
                elementCount: 6,
                componentCount: 3,
                scalarByteWidth: 1,
                limits: exactBoundaryLimits
            )
        }

        let overflowLimits = try ProbeLimits(
            maximumRank: 2,
            maximumExtent: Int.max,
            maximumElementCount: Int.max,
            maximumComponentCount: Int.max,
            maximumLogicalValueCount: Int.max,
            maximumCanonicalByteCount: Int.max,
            maximumRepresentationByteCount: Int.max,
            maximumFingerprintFrameByteCount: Int.max
        )
        probeRequireThrows(.arithmeticOverflow) {
            _ = try ProbeShape(
                rawExtents: [UInt64(Int.max), 2],
                limits: overflowLimits
            )
        }
        probeRequireThrows(.arithmeticOverflow) {
            _ = try ProbeProjectionCounts(
                elementCount: Int.max,
                componentCount: 2,
                scalarByteWidth: 1,
                limits: overflowLimits
            )
        }
        probeRequireThrows(.arithmeticOverflow) {
            _ = try ProbeProjectionCounts(
                elementCount: Int.max / 2 + 1,
                componentCount: 1,
                scalarByteWidth: 2,
                limits: overflowLimits
            )
        }

        let shape = try ProbeShape(rawExtents: [2, 2], limits: limits)
        let region = try ProbeRegion(
            rawOrigin: [1, 0],
            rawExtents: [1, 2],
            within: shape,
            limits: limits
        )
        probeRequire(region.elementCount == 2)
        probeRequireThrows(.rankMismatch) {
            _ = try ProbeRegion(
                rawOrigin: [0],
                rawExtents: [1],
                within: shape,
                limits: limits
            )
        }
        probeRequireThrows(.invalidRegion) {
            _ = try ProbeRegion(
                rawOrigin: [0, 0],
                rawExtents: [0, 1],
                within: shape,
                limits: limits
            )
        }
        probeRequireThrows(.regionOutOfBounds) {
            _ = try ProbeRegion(
                rawOrigin: [1, 1],
                rawExtents: [2, 1],
                within: shape,
                limits: limits
            )
        }
        probeRequireThrows(.platformIntegerRange) {
            _ = try ProbeRegion(
                rawOrigin: [UInt64(Int.max) + 1, 0],
                rawExtents: [1, 1],
                within: shape,
                limits: limits
            )
        }
        probeRequireThrows(.invalidLimit) {
            _ = try ProbeLimits(
                maximumRank: 0,
                maximumExtent: 1,
                maximumElementCount: 1,
                maximumComponentCount: 1,
                maximumLogicalValueCount: 1,
                maximumCanonicalByteCount: 1,
                maximumRepresentationByteCount: 1,
                maximumFingerprintFrameByteCount: 1
            )
        }
    }

    private static func testRankThreeAxisZeroFastestGolden(
        limits: ProbeLimits
    ) throws {
        let shape = try ProbeShape(rawExtents: [2, 2, 2], limits: limits)
        let binding = try ProbeLogicalBinding(
            shape: shape,
            scalar: .uint16,
            componentCount: 2,
            limits: limits
        )
        let indexGoldens: [([Int], Int)] = [
            ([0, 0, 0], 0),
            ([1, 0, 0], 1),
            ([0, 1, 0], 2),
            ([1, 1, 0], 3),
            ([0, 0, 1], 4),
            ([1, 0, 1], 5),
            ([0, 1, 1], 6),
            ([1, 1, 1], 7),
        ]
        for (index, expectedSampleOrdinal) in indexGoldens {
            let sampleOrdinal = try probeSampleOrdinal(
                logicalIndex: index,
                shape: shape
            )
            probeRequire(sampleOrdinal == expectedSampleOrdinal)
            let firstValue = try probeValueOrdinal(
                logicalIndex: index,
                component: 0,
                binding: binding
            )
            let secondValue = try probeValueOrdinal(
                logicalIndex: index,
                component: 1,
                binding: binding
            )
            probeRequire(firstValue == 2 * expectedSampleOrdinal)
            probeRequire(secondValue == 2 * expectedSampleOrdinal + 1)
        }

        let canonicalOrdinalBytes: ContiguousArray<UInt8> = [
            0x00, 0x00, 0x00, 0x01,
            0x00, 0x02, 0x00, 0x03,
            0x00, 0x04, 0x00, 0x05,
            0x00, 0x06, 0x00, 0x07,
            0x00, 0x08, 0x00, 0x09,
            0x00, 0x0A, 0x00, 0x0B,
            0x00, 0x0C, 0x00, 0x0D,
            0x00, 0x0E, 0x00, 0x0F,
        ]
        let representation = try ProbeFixtures.contiguousBigEndian(
            binding: binding,
            bytes: canonicalOrdinalBytes,
            limits: limits
        )
        probeRequire(representation.descriptor.axisByteStrides == [4, 8, 16])
        let projection = try ProbeNormalizer.normalize(
            binding: binding,
            representation: representation,
            region: ProbeRegion.whole(shape, limits: limits),
            limits: limits
        )
        probeRequire(projection.canonicalBytes == canonicalOrdinalBytes)
    }

    private static func testSHA256KnownAnswer() throws {
        let digest = ProbeFingerprint(frame: ContiguousArray("abc".utf8))
        probeRequire(
            digest.hexadecimal
                == "ba7816bf8f01cfea414140de5dae2223"
                + "b00361a396177a9cb410ff61f20015ad"
        )
    }

    private static func testCanonicalLayoutsAndConcurrentEquality(
        limits: ProbeLimits
    ) async throws -> ProbeHashReport {
        let binding = try ProbeFixtures.rgbBinding(limits: limits)
        let rgbSemantics = try ProbeFixtures.rgbSemantics(limits: limits)
        probeRequire(rgbSemantics.orderedRoles == [.red, .green, .blue])
        probeRequire(rgbSemantics.count == binding.componentCount)
        let whole = try ProbeRegion.whole(binding.shape, limits: limits)
        let little = try ProbeFixtures.littleInterleaved(
            binding: binding,
            limits: limits
        )
        let planar = try ProbeFixtures.bigPlanar(
            binding: binding,
            limits: limits
        )
        let padded = try ProbeFixtures.paddedBGR(
            binding: binding,
            limits: limits
        )
        let mutatedPaddingBytes = ProbeFixtures.paddedBGRBytes.map {
            $0 == 0xAA ? UInt8(0xBB) : $0
        }
        let mutatedPadding = try ProbeFixtures.paddedBGR(
            binding: binding,
            bytes: mutatedPaddingBytes,
            limits: limits
        )

        probeRequire(little.descriptor.byteOrder != planar.descriptor.byteOrder)
        probeRequire(little.descriptor.layout != planar.descriptor.layout)
        probeRequire(planar.descriptor.layout != padded.descriptor.layout)
        probeRequire(
            padded.descriptor.physicalLogicalOrdinals == [2, 1, 0]
        )
        probeRequire(
            padded.descriptor.physicalSlotForLogicalComponent == [2, 1, 0]
        )

        async let littleProjection = ProbeNormalizer.normalize(
            binding: binding,
            representation: little,
            region: whole,
            limits: limits
        )
        async let planarProjection = ProbeNormalizer.normalize(
            binding: binding,
            representation: planar,
            region: whole,
            limits: limits
        )
        async let paddedProjection = ProbeNormalizer.normalize(
            binding: binding,
            representation: padded,
            region: whole,
            limits: limits
        )
        async let mutatedProjection = ProbeNormalizer.normalize(
            binding: binding,
            representation: mutatedPadding,
            region: whole,
            limits: limits
        )
        let (fromLittle, fromPlanar, fromPadded, fromMutatedPadding) = try await (
            littleProjection,
            planarProjection,
            paddedProjection,
            mutatedProjection
        )

        probeRequire(fromLittle.canonicalBytes == ProbeFixtures.canonicalRGBBytes)
        probeRequire(fromPlanar == fromLittle)
        probeRequire(fromPadded == fromLittle)
        probeRequire(fromMutatedPadding == fromLittle)

        let region = try ProbeRegion(
            rawOrigin: [1, 1],
            rawExtents: [1, 1],
            within: binding.shape,
            limits: limits
        )
        let regionProjection = try ProbeNormalizer.normalize(
            binding: binding,
            representation: padded,
            region: region,
            limits: limits
        )
        probeRequire(
            regionProjection.canonicalBytes
                == [0x31, 0x32, 0x33, 0x34, 0x35, 0x36]
        )

        let sampleLayout = try ProbeFingerprinting.sampleLayout(
            fromLittle,
            limits: limits
        )
        let planarSampleLayout = try ProbeFingerprinting.sampleLayout(
            fromPlanar,
            limits: limits
        )
        let paddedSampleLayout = try ProbeFingerprinting.sampleLayout(
            fromPadded,
            limits: limits
        )
        let mutatedPaddingSampleLayout = try ProbeFingerprinting.sampleLayout(
            fromMutatedPadding,
            limits: limits
        )
        probeRequire(planarSampleLayout == sampleLayout)
        probeRequire(paddedSampleLayout == sampleLayout)
        probeRequire(mutatedPaddingSampleLayout == sampleLayout)

        let littleRepresentation = try ProbeFingerprinting.representation(
            little,
            limits: limits
        )
        let planarRepresentation = try ProbeFingerprinting.representation(
            planar,
            limits: limits
        )
        let paddedRepresentation = try ProbeFingerprinting.representation(
            padded,
            limits: limits
        )
        let mutatedRepresentation = try ProbeFingerprinting.representation(
            mutatedPadding,
            limits: limits
        )
        probeRequire(littleRepresentation != planarRepresentation)
        probeRequire(planarRepresentation != paddedRepresentation)
        probeRequire(paddedRepresentation != mutatedRepresentation)
        probeRequire(sampleLayout != littleRepresentation)
        probeRequire(
            sampleLayout.hexadecimal
                == "813b6376bf98f5dc74bac7e0fa902297"
                + "364ceacd7b730eb6ec28875fcba3f254"
        )
        probeRequire(
            littleRepresentation.hexadecimal
                == "6b52f3fdb256e9eb94b0a0766363ce11"
                + "fbc4acb046c1f7f8ed2ecbd72cbf925d"
        )
        probeRequire(
            planarRepresentation.hexadecimal
                == "2c1dc10f36e5664ebc88fbec871d0fe9"
                + "d03eb7c22bdc82860045b5073d7abb5e"
        )
        probeRequire(
            paddedRepresentation.hexadecimal
                == "d5b55f56ac4fa28a075a230822a00aa5"
                + "3c74bb43b7a00088ef6ab87c28e0c267"
        )
        probeRequire(
            mutatedRepresentation.hexadecimal
                == "dd667e6dcba64df60ffd827f0c1fb6f9"
                + "6f4d8a16b7cdb78ec9a342ddfc56d8c7"
        )

        return ProbeHashReport(
            sampleLayout: sampleLayout.hexadecimal,
            littleInterleavedRepresentation: littleRepresentation.hexadecimal,
            bigPlanarRepresentation: planarRepresentation.hexadecimal,
            paddedBGRRepresentation: paddedRepresentation.hexadecimal,
            mutatedPaddingRepresentation: mutatedRepresentation.hexadecimal
        )
    }

    private static func testComponentMapFailures(limits: ProbeLimits) throws {
        let binding = try ProbeFixtures.rgbBinding(limits: limits)
        let whole = try ProbeRegion.whole(binding.shape, limits: limits)

        func make(_ map: [UInt64]) throws -> ProbeRepresentation {
            try ProbeFixtures.representation(
                binding: binding,
                byteOrder: .bigEndian,
                layout: .paddedStrided,
                baseOffset: 4,
                axisByteStrides: [8, 20],
                componentByteStride: 2,
                physicalLogicalOrdinals: [2, 1, 0],
                physicalSlotForLogicalComponent: map,
                initializedByteLength: 44,
                bytes: ProbeFixtures.paddedBGRBytes,
                limits: limits
            )
        }

        let wrongButComplete = try make([0, 1, 2])
        probeRequireThrows(.invalidComponentMap) {
            try ProbeNormalizer.normalize(
                binding: binding,
                representation: wrongButComplete,
                region: whole,
                limits: limits
            )
        }
        let duplicate = try make([2, 2, 0])
        probeRequireThrows(.invalidComponentMap) {
            try ProbeNormalizer.normalize(
                binding: binding,
                representation: duplicate,
                region: whole,
                limits: limits
            )
        }
        let outOfRange = try make([2, 1, 3])
        probeRequireThrows(.invalidComponentMap) {
            try ProbeNormalizer.normalize(
                binding: binding,
                representation: outOfRange,
                region: whole,
                limits: limits
            )
        }
        let incomplete = try make([2, 1])
        probeRequireThrows(.invalidComponentMap) {
            try ProbeNormalizer.normalize(
                binding: binding,
                representation: incomplete,
                region: whole,
                limits: limits
            )
        }
    }

    private static func testBindingAndRegionFingerprintSensitivity(
        limits: ProbeLimits
    ) throws -> ProbeSemanticHashReport {
        let singleton = try ProbeShape(rawExtents: [1], limits: limits)
        let intBinding = try ProbeFixtures.oneComponentBinding(
            shape: singleton,
            scalar: .int16,
            limits: limits
        )
        let uintBinding = try ProbeFixtures.oneComponentBinding(
            shape: singleton,
            scalar: .uint16,
            limits: limits
        )
        let intRegion = try ProbeRegion.whole(intBinding.shape, limits: limits)
        let uintRegion = try ProbeRegion.whole(uintBinding.shape, limits: limits)
        let intRepresentation = try ProbeFixtures.contiguousBigEndian(
            binding: intBinding,
            bytes: [0xFF, 0xFF],
            limits: limits
        )
        let uintRepresentation = try ProbeFixtures.contiguousBigEndian(
            binding: uintBinding,
            bytes: [0xFF, 0xFF],
            limits: limits
        )
        let intProjection = try ProbeNormalizer.normalize(
            binding: intBinding,
            representation: intRepresentation,
            region: intRegion,
            limits: limits
        )
        let uintProjection = try ProbeNormalizer.normalize(
            binding: uintBinding,
            representation: uintRepresentation,
            region: uintRegion,
            limits: limits
        )
        probeRequire(intProjection.canonicalBytes == uintProjection.canonicalBytes)
        let intFingerprint = try ProbeFingerprinting.sampleLayout(
            intProjection,
            limits: limits
        )
        let uintFingerprint = try ProbeFingerprinting.sampleLayout(
            uintProjection,
            limits: limits
        )
        probeRequire(intFingerprint != uintFingerprint)

        let rgbSemantics = try ProbeToySemanticDescriptor(
            interpretation: .colourComponents,
            orderedRoles: [.red, .green, .blue],
            limits: limits
        )
        let bgrSemantics = try ProbeToySemanticDescriptor(
            interpretation: .colourComponents,
            orderedRoles: [.blue, .green, .red],
            limits: limits
        )
        let semanticBinding = try ProbeLogicalBinding(
            shape: singleton,
            scalar: .uint16,
            componentCount: 3,
            limits: limits
        )
        let sameBytes: ContiguousArray<UInt8> = [
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06,
        ]
        let semanticRepresentation = try ProbeFixtures.contiguousBigEndian(
            binding: semanticBinding,
            bytes: sameBytes,
            limits: limits
        )
        let semanticProjection = try ProbeNormalizer.normalize(
            binding: semanticBinding,
            representation: semanticRepresentation,
            region: ProbeRegion.whole(semanticBinding.shape, limits: limits),
            limits: limits
        )
        probeRequire(semanticProjection.canonicalBytes == sameBytes)
        let sampleLayoutBeforeSemanticMutation =
            try ProbeFingerprinting.sampleLayout(
                semanticProjection,
                limits: limits
            )
        let sampleLayoutAfterSemanticMutation =
            try ProbeFingerprinting.sampleLayout(
                semanticProjection,
                limits: limits
            )
        probeRequire(
            sampleLayoutBeforeSemanticMutation == sampleLayoutAfterSemanticMutation
        )
        let rgbDescriptorBearing = try ProbeFingerprinting.descriptorBearing(
            semanticProjection,
            semantics: rgbSemantics,
            limits: limits
        )
        let bgrDescriptorBearing = try ProbeFingerprinting.descriptorBearing(
            semanticProjection,
            semantics: bgrSemantics,
            limits: limits
        )
        probeRequire(rgbDescriptorBearing != bgrDescriptorBearing)
        probeRequire(sampleLayoutBeforeSemanticMutation != rgbDescriptorBearing)
        probeRequire(
            rgbDescriptorBearing.hexadecimal
                == "fc72975ee02dfed43e2fed3a1f9d3249"
                + "e6a189ac2b199ff058e46ae6f8c1a4bc"
        )
        probeRequire(
            bgrDescriptorBearing.hexadecimal
                == "6d9683fb97f0394ea6d1c14b68b88887"
                + "bf14581e8337f30012d2f085b1a7e65e"
        )

        let repeatedShape = try ProbeShape(rawExtents: [2], limits: limits)
        let repeatedBinding = try ProbeFixtures.oneComponentBinding(
            shape: repeatedShape,
            scalar: .uint16,
            limits: limits
        )
        let repeatedRepresentation = try ProbeFixtures.contiguousBigEndian(
            binding: repeatedBinding,
            bytes: [0xAB, 0xCD, 0xAB, 0xCD],
            limits: limits
        )
        let firstRegion = try ProbeRegion(
            rawOrigin: [0],
            rawExtents: [1],
            within: repeatedShape,
            limits: limits
        )
        let secondRegion = try ProbeRegion(
            rawOrigin: [1],
            rawExtents: [1],
            within: repeatedShape,
            limits: limits
        )
        let firstProjection = try ProbeNormalizer.normalize(
            binding: repeatedBinding,
            representation: repeatedRepresentation,
            region: firstRegion,
            limits: limits
        )
        let secondProjection = try ProbeNormalizer.normalize(
            binding: repeatedBinding,
            representation: repeatedRepresentation,
            region: secondRegion,
            limits: limits
        )
        probeRequire(firstProjection.canonicalBytes == secondProjection.canonicalBytes)
        let firstFingerprint = try ProbeFingerprinting.sampleLayout(
            firstProjection,
            limits: limits
        )
        let secondFingerprint = try ProbeFingerprinting.sampleLayout(
            secondProjection,
            limits: limits
        )
        probeRequire(firstFingerprint != secondFingerprint)
        return ProbeSemanticHashReport(
            rgbDescriptorBearing: rgbDescriptorBearing.hexadecimal,
            bgrDescriptorBearing: bgrDescriptorBearing.hexadecimal
        )
    }

    private static func testDirectEncodingRejectionsAndSourceDecoder(
        limits: ProbeLimits
    ) throws {
        let singleton = try ProbeShape(rawExtents: [1], limits: limits)
        let uintBinding = try ProbeFixtures.oneComponentBinding(
            shape: singleton,
            scalar: .uint16,
            limits: limits
        )
        let region = try ProbeRegion.whole(uintBinding.shape, limits: limits)

        let validBitsOnly = try ProbeFixtures.contiguousBigEndian(
            binding: uintBinding,
            bytes: [0x0F, 0xFF],
            valueEncoding: .integerValidBitCountOnly(storedBitCount: 12),
            limits: limits
        )
        probeRequireThrows(.sourceDecoderRequired) {
            try ProbeNormalizer.normalize(
                binding: uintBinding,
                representation: validBitsOnly,
                region: region,
                limits: limits
            )
        }
        let packed = try ProbeFixtures.contiguousBigEndian(
            binding: uintBinding,
            bytes: [0x0F, 0xFF],
            valueEncoding: .packed(storedBitCount: 12),
            limits: limits
        )
        probeRequireThrows(.unsupportedPacking) {
            try ProbeNormalizer.normalize(
                binding: uintBinding,
                representation: packed,
                region: region,
                limits: limits
            )
        }

        let floatBinding = try ProbeFixtures.oneComponentBinding(
            shape: singleton,
            scalar: .binary32,
            limits: limits
        )
        let floatValidBits = try ProbeFixtures.contiguousBigEndian(
            binding: floatBinding,
            bytes: [0x3F, 0x80, 0x00, 0x00],
            valueEncoding: .floatingValidBitCountOnly(storedBitCount: 24),
            limits: limits
        )
        probeRequireThrows(.floatingValidBitsUnsupported) {
            try ProbeNormalizer.normalize(
                binding: floatBinding,
                representation: floatValidBits,
                region: ProbeRegion.whole(floatBinding.shape, limits: limits),
                limits: limits
            )
        }

        let signedInterpretation = try ProbeIntegerSourceInterpretation(
            containerBitWidth: 16,
            storedBitCount: 12,
            leastSignificantStoredBit: 0,
            signedness: .signed,
            byteOrder: .littleEndian,
            unusedBitPolicy: .requireZero,
            resultScalar: .int16
        )
        let signedDecoded = try ProbeIntegerSourceDecoder.decode(
            sourceBytes: [0xFF, 0x07, 0x00, 0x08, 0xFF, 0x0F],
            expectedValueCount: 3,
            interpretation: signedInterpretation,
            limits: limits
        )
        probeRequire(
            signedDecoded.fullWidthBytes
                == [0x07, 0xFF, 0xF8, 0x00, 0xFF, 0xFF]
        )
        let signedShape = try ProbeShape(rawExtents: [3], limits: limits)
        let signedBinding = try ProbeFixtures.oneComponentBinding(
            shape: signedShape,
            scalar: .int16,
            limits: limits
        )
        let signedFullWidthRepresentation = try ProbeFixtures.contiguousBigEndian(
            binding: signedBinding,
            bytes: signedDecoded.fullWidthBytes,
            limits: limits
        )
        let signedProjection = try ProbeNormalizer.normalize(
            binding: signedBinding,
            representation: signedFullWidthRepresentation,
            region: ProbeRegion.whole(signedBinding.shape, limits: limits),
            limits: limits
        )
        probeRequire(signedProjection.canonicalBytes == signedDecoded.fullWidthBytes)

        let unsignedInterpretation = try ProbeIntegerSourceInterpretation(
            containerBitWidth: 16,
            storedBitCount: 12,
            leastSignificantStoredBit: 0,
            signedness: .unsigned,
            byteOrder: .bigEndian,
            unusedBitPolicy: .requireZero,
            resultScalar: .uint16
        )
        let unsignedDecoded = try ProbeIntegerSourceDecoder.decode(
            sourceBytes: [0x07, 0xFF, 0x08, 0x00, 0x0F, 0xFF],
            expectedValueCount: 3,
            interpretation: unsignedInterpretation,
            limits: limits
        )
        probeRequire(
            unsignedDecoded.fullWidthBytes
                == [0x07, 0xFF, 0x08, 0x00, 0x0F, 0xFF]
        )
        let unsignedBinding = try ProbeFixtures.oneComponentBinding(
            shape: signedShape,
            scalar: .uint16,
            limits: limits
        )
        let unsignedFullWidthRepresentation = try ProbeFixtures.contiguousBigEndian(
            binding: unsignedBinding,
            bytes: unsignedDecoded.fullWidthBytes,
            limits: limits
        )
        let unsignedProjection = try ProbeNormalizer.normalize(
            binding: unsignedBinding,
            representation: unsignedFullWidthRepresentation,
            region: ProbeRegion.whole(unsignedBinding.shape, limits: limits),
            limits: limits
        )
        probeRequire(unsignedProjection.canonicalBytes == unsignedDecoded.fullWidthBytes)

        probeRequireThrows(.invalidUnusedBits) {
            try ProbeIntegerSourceDecoder.decode(
                sourceBytes: [0xAF, 0xFF],
                expectedValueCount: 1,
                interpretation: unsignedInterpretation,
                limits: limits
            )
        }
        let ignoredUnusedInterpretation = try ProbeIntegerSourceInterpretation(
            containerBitWidth: 16,
            storedBitCount: 12,
            leastSignificantStoredBit: 0,
            signedness: .unsigned,
            byteOrder: .bigEndian,
            unusedBitPolicy: .ignoreButRetainInSourceRepresentation,
            resultScalar: .uint16
        )
        let ignoredUnused = try ProbeIntegerSourceDecoder.decode(
            sourceBytes: [0xAF, 0xFF],
            expectedValueCount: 1,
            interpretation: ignoredUnusedInterpretation,
            limits: limits
        )
        let cleanUnused = try ProbeIntegerSourceDecoder.decode(
            sourceBytes: [0x0F, 0xFF],
            expectedValueCount: 1,
            interpretation: unsignedInterpretation,
            limits: limits
        )
        probeRequire(ignoredUnused.fullWidthBytes == [0x0F, 0xFF])
        probeRequire(ignoredUnused.fullWidthBytes == cleanUnused.fullWidthBytes)
        probeRequire(ignoredUnused.sourceBytes == [0xAF, 0xFF])
        probeRequire(cleanUnused.sourceBytes == [0x0F, 0xFF])
        probeRequire(ignoredUnused.sourceBytes != cleanUnused.sourceBytes)
        let ignoredFullWidthRepresentation = try ProbeFixtures.contiguousBigEndian(
            binding: uintBinding,
            bytes: ignoredUnused.fullWidthBytes,
            limits: limits
        )
        let cleanFullWidthRepresentation = try ProbeFixtures.contiguousBigEndian(
            binding: uintBinding,
            bytes: cleanUnused.fullWidthBytes,
            limits: limits
        )
        let ignoredProjection = try ProbeNormalizer.normalize(
            binding: uintBinding,
            representation: ignoredFullWidthRepresentation,
            region: region,
            limits: limits
        )
        let cleanProjection = try ProbeNormalizer.normalize(
            binding: uintBinding,
            representation: cleanFullWidthRepresentation,
            region: region,
            limits: limits
        )
        probeRequire(ignoredProjection == cleanProjection)

        let offsetSignedInterpretation = try ProbeIntegerSourceInterpretation(
            containerBitWidth: 16,
            storedBitCount: 12,
            leastSignificantStoredBit: 4,
            signedness: .signed,
            byteOrder: .bigEndian,
            unusedBitPolicy: .requireZero,
            resultScalar: .int16
        )
        let offsetSigned = try ProbeIntegerSourceDecoder.decode(
            sourceBytes: [0xFF, 0xF0],
            expectedValueCount: 1,
            interpretation: offsetSignedInterpretation,
            limits: limits
        )
        probeRequire(offsetSigned.fullWidthBytes == [0xFF, 0xFF])

        let offsetUnsignedInterpretation = try ProbeIntegerSourceInterpretation(
            containerBitWidth: 16,
            storedBitCount: 12,
            leastSignificantStoredBit: 4,
            signedness: .unsigned,
            byteOrder: .bigEndian,
            unusedBitPolicy: .requireZero,
            resultScalar: .uint16
        )
        let offsetUnsigned = try ProbeIntegerSourceDecoder.decode(
            sourceBytes: [0xAB, 0xC0],
            expectedValueCount: 1,
            interpretation: offsetUnsignedInterpretation,
            limits: limits
        )
        probeRequire(offsetUnsigned.fullWidthBytes == [0x0A, 0xBC])
        probeRequireThrows(.invalidUnusedBits) {
            try ProbeIntegerSourceDecoder.decode(
                sourceBytes: [0xAB, 0xC1],
                expectedValueCount: 1,
                interpretation: offsetUnsignedInterpretation,
                limits: limits
            )
        }

        let outOfBoundsInterpretation = try ProbeIntegerSourceInterpretation(
            containerBitWidth: 16,
            storedBitCount: 12,
            leastSignificantStoredBit: 5,
            signedness: .unsigned,
            byteOrder: .bigEndian,
            unusedBitPolicy: .requireZero,
            resultScalar: .uint16
        )
        probeRequireThrows(.invalidSourceInterpretation) {
            try ProbeIntegerSourceDecoder.decode(
                sourceBytes: [0x00, 0x00],
                expectedValueCount: 1,
                interpretation: outOfBoundsInterpretation,
                limits: limits
            )
        }

        let mismatchedTarget = try ProbeIntegerSourceInterpretation(
            containerBitWidth: 16,
            storedBitCount: 12,
            leastSignificantStoredBit: 0,
            signedness: .signed,
            byteOrder: .bigEndian,
            unusedBitPolicy: .requireZero,
            resultScalar: .uint16
        )
        probeRequireThrows(.invalidSourceInterpretation) {
            try ProbeIntegerSourceDecoder.decode(
                sourceBytes: [0x07, 0xFF],
                expectedValueCount: 1,
                interpretation: mismatchedTarget,
                limits: limits
            )
        }
    }

    private static func testExactFloatingBitSequences(
        limits: ProbeLimits
    ) throws {
        // Each list is +0, -0, the minimum subnormal, two distinct quiet-NaN
        // payloads, +infinity and -infinity. Only integer bit containers and
        // indexed byte copies are used; the probe performs no arithmetic value
        // conversion or special-value rewriting.
        try requireExactFloatingSequence(
            scalar: .binary16,
            patterns: [
                0x0000, 0x8000, 0x0001, 0x7E01, 0x7E02, 0x7C00, 0xFC00,
            ].map(UInt64.init),
            limits: limits
        )
        try requireExactFloatingSequence(
            scalar: .binary32,
            patterns: [
                0x0000_0000,
                0x8000_0000,
                0x0000_0001,
                0x7FC0_0001,
                0x7FC0_0002,
                0x7F80_0000,
                0xFF80_0000,
            ].map(UInt64.init),
            limits: limits
        )
        try requireExactFloatingSequence(
            scalar: .binary64,
            patterns: [
                0x0000_0000_0000_0000,
                0x8000_0000_0000_0000,
                0x0000_0000_0000_0001,
                0x7FF8_0000_0000_0001,
                0x7FF8_0000_0000_0002,
                0x7FF0_0000_0000_0000,
                0xFFF0_0000_0000_0000,
            ],
            limits: limits
        )
    }

    private static func requireExactFloatingSequence(
        scalar: ProbeLogicalScalar,
        patterns: [UInt64],
        limits: ProbeLimits
    ) throws {
        probeRequire(scalar.isBinaryFloatingPoint)
        var bytes = ProbeByteEncoder()
        for pattern in patterns {
            switch scalar {
            case .binary16:
                guard let narrowed = UInt16(exactly: pattern) else {
                    throw ProbeProjectionError.invalidLogicalBinding
                }
                bytes.appendBigEndian(narrowed)
            case .binary32:
                guard let narrowed = UInt32(exactly: pattern) else {
                    throw ProbeProjectionError.invalidLogicalBinding
                }
                bytes.appendBigEndian(narrowed)
            case .binary64:
                bytes.appendBigEndian(pattern)
            case .int16, .uint16:
                throw ProbeProjectionError.invalidLogicalBinding
            }
        }

        let shape = try ProbeShape(
            rawExtents: [UInt64(patterns.count)],
            limits: limits
        )
        let binding = try ProbeFixtures.oneComponentBinding(
            shape: shape,
            scalar: scalar,
            limits: limits
        )
        let representation = try ProbeFixtures.contiguousBigEndian(
            binding: binding,
            bytes: bytes.bytes,
            limits: limits
        )
        let projection = try ProbeNormalizer.normalize(
            binding: binding,
            representation: representation,
            region: ProbeRegion.whole(binding.shape, limits: limits),
            limits: limits
        )
        probeRequire(projection.canonicalBytes == bytes.bytes)

        let width = scalar.byteWidth
        probeRequire(
            ContiguousArray(projection.canonicalBytes[0..<width])
                != ContiguousArray(projection.canonicalBytes[width..<(2 * width)])
        )
        probeRequire(
            ContiguousArray(projection.canonicalBytes[(3 * width)..<(4 * width)])
                != ContiguousArray(projection.canonicalBytes[(4 * width)..<(5 * width)])
        )
        probeRequire(
            ContiguousArray(projection.canonicalBytes[(5 * width)..<(6 * width)])
                != ContiguousArray(projection.canonicalBytes[(6 * width)..<(7 * width)])
        )
    }

    private static func testRepresentationFailures(limits: ProbeLimits) throws {
        let singleton = try ProbeShape(rawExtents: [1], limits: limits)
        let binding = try ProbeFixtures.oneComponentBinding(
            shape: singleton,
            scalar: .uint16,
            limits: limits
        )
        let whole = try ProbeRegion.whole(singleton, limits: limits)

        let short = try ProbeFixtures.contiguousBigEndian(
            binding: binding,
            bytes: [0x01],
            declaredByteLength: 2,
            limits: limits
        )
        probeRequireThrows(.shortInput) {
            try ProbeNormalizer.normalize(
                binding: binding,
                representation: short,
                region: whole,
                limits: limits
            )
        }
        let long = try ProbeFixtures.contiguousBigEndian(
            binding: binding,
            bytes: [0x01, 0x02, 0x03],
            declaredByteLength: 2,
            limits: limits
        )
        probeRequireThrows(.longInput) {
            try ProbeNormalizer.normalize(
                binding: binding,
                representation: long,
                region: whole,
                limits: limits
            )
        }

        let outOfBoundsDescriptor = try ProbeRepresentationDescriptor(
            shape: binding.shape,
            decodedScalar: binding.scalar,
            byteOrder: .bigEndian,
            layout: .interleaved,
            valueEncoding: .decodedFullWidth,
            rawBaseOffset: 1,
            rawAxisByteStrides: [2],
            rawComponentByteStride: 2,
            rawPhysicalLogicalOrdinals: [0],
            rawPhysicalSlotForLogicalComponent: [0],
            rawInitializedByteLength: 2,
            limits: limits
        )
        let outOfBounds = try ProbeRepresentation(
            descriptor: outOfBoundsDescriptor,
            bytes: [0x01, 0x02],
            limits: limits
        )
        probeRequireThrows(.addressOutOfBounds) {
            try ProbeNormalizer.normalize(
                binding: binding,
                representation: outOfBounds,
                region: whole,
                limits: limits
            )
        }

        let pairShape = try ProbeShape(rawExtents: [2], limits: limits)
        let pairBinding = try ProbeFixtures.oneComponentBinding(
            shape: pairShape,
            scalar: .uint16,
            limits: limits
        )
        probeRequireThrows(.resourceLimitExceeded) {
            _ = try ProbeRepresentationDescriptor(
                shape: pairBinding.shape,
                decodedScalar: pairBinding.scalar,
                byteOrder: .bigEndian,
                layout: .interleaved,
                valueEncoding: .decodedFullWidth,
                rawBaseOffset: UInt64(Int.max),
                rawAxisByteStrides: [1],
                rawComponentByteStride: 2,
                rawPhysicalLogicalOrdinals: [0],
                rawPhysicalSlotForLogicalComponent: [0],
                rawInitializedByteLength: 4,
                limits: limits
            )
        }

        let overlapDescriptor = try ProbeRepresentationDescriptor(
            shape: pairBinding.shape,
            decodedScalar: pairBinding.scalar,
            byteOrder: .bigEndian,
            layout: .interleaved,
            valueEncoding: .decodedFullWidth,
            rawBaseOffset: 0,
            rawAxisByteStrides: [0],
            rawComponentByteStride: 2,
            rawPhysicalLogicalOrdinals: [0],
            rawPhysicalSlotForLogicalComponent: [0],
            rawInitializedByteLength: 2,
            limits: limits
        )
        let overlapRepresentation = try ProbeRepresentation(
            descriptor: overlapDescriptor,
            bytes: [0, 0],
            limits: limits
        )
        probeRequireThrows(.overlappingAddress) {
            try ProbeNormalizer.normalize(
                binding: pairBinding,
                representation: overlapRepresentation,
                region: ProbeRegion.whole(pairShape, limits: limits),
                limits: limits
            )
        }

        let otherShape = try ProbeShape(rawExtents: [1, 1], limits: limits)
        let otherBinding = try ProbeFixtures.oneComponentBinding(
            shape: otherShape,
            scalar: .uint16,
            limits: limits
        )
        probeRequireThrows(.logicalBindingMismatch) {
            try ProbeNormalizer.normalize(
                binding: otherBinding,
                representation: try ProbeFixtures.contiguousBigEndian(
                    binding: binding,
                    bytes: [0, 0],
                    limits: limits
                ),
                region: ProbeRegion.whole(otherShape, limits: limits),
                limits: limits
            )
        }

        let largerShape = try ProbeShape(rawExtents: [3], limits: limits)
        let foreignRegion = try ProbeRegion(
            rawOrigin: [2],
            rawExtents: [1],
            within: largerShape,
            limits: limits
        )
        probeRequireThrows(.regionOutOfBounds) {
            try ProbeNormalizer.normalize(
                binding: binding,
                representation: try ProbeFixtures.contiguousBigEndian(
                    binding: binding,
                    bytes: [0, 0],
                    limits: limits
                ),
                region: foreignRegion,
                limits: limits
            )
        }

        let tinyLimits = try ProbeLimits(
            maximumRank: 1,
            maximumExtent: 2,
            maximumElementCount: 2,
            maximumComponentCount: 1,
            maximumLogicalValueCount: 2,
            maximumCanonicalByteCount: 4,
            maximumRepresentationByteCount: 2,
            maximumFingerprintFrameByteCount: 128
        )
        probeRequireThrows(.resourceLimitExceeded) {
            _ = try ProbeRepresentation(
                descriptor: ProbeRepresentationDescriptor(
                    shape: try ProbeShape(rawExtents: [1], limits: tinyLimits),
                    decodedScalar: .uint16,
                    byteOrder: .bigEndian,
                    layout: .interleaved,
                    valueEncoding: .decodedFullWidth,
                    rawBaseOffset: 0,
                    rawAxisByteStrides: [2],
                    rawComponentByteStride: 2,
                    rawPhysicalLogicalOrdinals: [0],
                    rawPhysicalSlotForLogicalComponent: [0],
                    rawInitializedByteLength: 2,
                    limits: tinyLimits
                ),
                bytes: [0, 0, 0],
                limits: tinyLimits
            )
        }
    }

    private static func testRedactedDiagnostics(limits: ProbeLimits) throws {
        let sentinel = "Patient Jane Doe / SOP 1.2.840.113619"
        let sensitive = ProbeSensitiveFixture(
            label: sentinel,
            bytes: sentinel.utf8
        )
        probeRequire(String(describing: sensitive) == ProbeDiagnostic.redactionMarker)
        probeRequire(String(reflecting: sensitive) == ProbeDiagnostic.redactionMarker)
        probeRequire(sensitive.debugDescription == ProbeDiagnostic.redactionMarker)
        let mirror = Mirror(reflecting: sensitive)
        probeRequire(mirror.children.count == 1)
        let child = mirror.children.first
        probeRequire(child?.label == "value")
        probeRequire(
            child.map { String(describing: $0.value) }
                == ProbeDiagnostic.redactionMarker
        )
        var dumped = ""
        dump(sensitive, to: &dumped)
        probeRequire(
            dumped
                == "▿ <redacted-logical-projection-probe>\n"
                + "  - value: \"<redacted-logical-projection-probe>\"\n"
        )
        probeRequire(!dumped.contains(sentinel))

        for error in ProbeProjectionError.allCases {
            probeRequire(
                String(describing: error)
                    == "logical projection probe rejected input"
            )
            probeRequire(
                String(reflecting: error)
                    == "logical projection probe rejected input"
            )
            probeRequire(error.debugDescription == error.description)
            let errorMirror = Mirror(reflecting: error)
            probeRequire(errorMirror.children.count == 1)
            probeRequire(errorMirror.children.first?.label == "value")
        }

        let binding = try ProbeFixtures.rgbBinding(limits: limits)
        let representation = try ProbeFixtures.littleInterleaved(
            binding: binding,
            limits: limits
        )
        let projection = try ProbeNormalizer.normalize(
            binding: binding,
            representation: representation,
            region: ProbeRegion.whole(binding.shape, limits: limits),
            limits: limits
        )
        let fingerprint = try ProbeFingerprinting.sampleLayout(
            projection,
            limits: limits
        )
        probeRequire(String(describing: projection) == ProbeDiagnostic.redactionMarker)
        probeRequire(String(reflecting: representation) == ProbeDiagnostic.redactionMarker)
        probeRequire(String(describing: fingerprint) == ProbeDiagnostic.redactionMarker)
        probeRequire(!String(reflecting: fingerprint).contains(fingerprint.hexadecimal))
    }
}
