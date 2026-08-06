// SPDX-License-Identifier: MIT

/// The decoded size a codestream's own header declares it will expand to.
///
/// Read from the `SIZ` marker segment, which the standard requires to be the first
/// marker segment after `SOC`. `depth` comes from the JP3D extension fields that
/// follow the per-component records; it is `1` when they are absent, which is the
/// two-dimensional case.
public struct CodestreamGeometry: Sendable, Hashable {
    /// Declared image width, in samples.
    public let width: Int
    /// Declared image height, in samples.
    public let height: Int
    /// Declared depth in slices, or `1` when the header carries no depth extension.
    public let depth: Int
    /// Declared component count.
    public let componentCount: Int
    /// The **largest** bit depth any component declares.
    ///
    /// The maximum rather than the last, deliberately: a budget must not be
    /// under-estimated, and a codestream may declare components of differing depths.
    public let bitsPerComponent: Int

    /// Bytes needed per sample at ``bitsPerComponent``, rounded up.
    public var bytesPerSample: Int {
        (bitsPerComponent + 7) / 8
    }

    /// The decoded byte count this geometry implies, or `nil` if it is not
    /// representable.
    ///
    /// Every multiplication is checked. That is the whole point of this type: the
    /// values are attacker-controlled 32-bit quantities, and a header declaring
    /// `0x7FFFFFFF` by `0x7FFFFFFF` overflows a 64-bit product. Returning `nil`
    /// rather than trapping is the difference between a refusal and a crash.
    public var impliedDecodedByteCount: Int? {
        var total = width
        for factor in [height, depth, componentCount, bytesPerSample] {
            let (product, overflowed) = total.multipliedReportingOverflow(by: factor)
            guard !overflowed else { return nil }
            total = product
        }
        return total
    }
}

/// What reading a codestream's header established.
public enum CodestreamHeaderReading: Sendable, Equatable {
    /// A well-formed `SIZ` segment was read.
    case geometry(CodestreamGeometry)
    /// The bytes open as a JPEG 2000 codestream but the header is not well formed.
    case malformedJPEG2000Header
    /// The bytes are not a JPEG 2000 codestream, so the question does not arise.
    case notAJPEG2000Codestream
}

/// An error raised while admitting a codestream against a decode budget.
///
/// Payload-free, following `ADR-0258`: the input that provokes a refusal learns
/// nothing from it.
public enum CodestreamBudgetError: Error, Sendable, Equatable {
    /// The bytes claim to be a JPEG 2000 codestream but their header is malformed.
    case headerNotReadable
    /// The geometry the header declares is not representable, so no budget can hold
    /// it.
    case declaredGeometryNotRepresentable
    /// The geometry the header declares exceeds the caller's ceiling.
    case declaredGeometryExceedsCeiling
}

/// Bounds what a codestream's own header may ask a decoder to allocate, per
/// `ADR-0273` (`VOX-CMP-011`).
///
/// ## Why this exists, measured rather than assumed
///
/// An adversarial-input sweep against the pinned codec found the slice-stack container
/// well hardened — every attack on its slice count, tile dimensions, component count,
/// bit depth, per-slice lengths and magic threw a clean, specific error. The weakness
/// is one layer out, in the standards-shaped `SIZ` envelope, whose declared dimensions
/// are read as 32-bit quantities and used without an upper bound:
///
/// - `Xsiz` and `Ysiz` set to `0xFFFF` implies roughly 32 GiB. The process allocated
///   past 2 GiB and was killed.
/// - `Xsiz` and `Ysiz` set to `0x7FFFFFFF` overflows the product. The process trapped
///   immediately, before allocating anything.
/// - A **single bit flip** at one `Ysiz` byte turned a 988-byte codestream into a
///   self-consistent 31.9 MiB decode — a thousandfold amplification that reports
///   success and that a caller cannot detect by checking the result against itself.
///
/// `ADR-0273` records the sweep. None of those is a bounded failure, and
/// `VOX-CMP-011` requires one.
///
/// ## Where the bound is applied
///
/// ``CompressedDecodeValidator/admitDestination(for:maximumDecodedByteCount:)`` calls
/// this, so every decode routed through Voxelia is bounded before the codec sees the
/// bytes. That placement is the point: a rule a caller must remember to invoke is a
/// rule that will eventually be forgotten, and the existing post-decode extents
/// comparison — a real second layer — can only fire once the allocation has happened.
///
/// ## Bytes that are not JPEG 2000 are not refused
///
/// A ``CompressedPayload`` may carry JPEG-LS, RLE or an uncompressed transfer syntax.
/// This gate has no opinion on those, exactly as `ADR-0272`'s labelling rule has none:
/// treating everything unparseable as hostile would refuse legitimate objects. A
/// codestream that *does* open as JPEG 2000 and then fails to parse is refused, because
/// handing precisely that to the codec is what crashed.
public enum CodestreamHeaderBudget {
    /// `SOC`, which opens every JPEG 2000 codestream.
    private static let startOfCodestream: [UInt8] = [0xFF, 0x4F]
    /// `SIZ`, which the standard requires to be the first marker segment after `SOC`.
    private static let sizeMarker: [UInt8] = [0xFF, 0x51]

    /// The smallest well-formed `SIZ` segment length, counting the length field.
    ///
    /// Thirty-eight bytes cover everything up to and including the component count;
    /// the per-component records follow.
    private static let minimumSizeSegmentLength = 38
    /// Each per-component record is `Ssiz`, `XRsiz`, `YRsiz`.
    private static let bytesPerComponentRecord = 3
    /// `Ssiz`'s low seven bits hold the bit depth, less one.
    private static let bitDepthMask: UInt8 = 0x7F

    /// The bit depths a conformant `Ssiz` may declare.
    ///
    /// `Ssiz` encodes depth less one in seven bits, so the *encodable* range reaches
    /// 128 while the standard permits only 1 to 38. The difference is not academic: a
    /// single bit flip on this byte was measured turning a 16-bit declaration into 113
    /// bits, which the pinned decoder ignored and which the budget alone would refuse
    /// only when the ceiling happened to be tight. Bounding the field itself refuses it
    /// under any ceiling.
    private static let permittedBitDepths = 1...38

    /// Reads the geometry a codestream's header declares.
    ///
    /// Every read is bounds-checked and the parse visits a fixed set of offsets plus
    /// one loop bounded by the declared component count, itself bounded by the segment
    /// length. No allocation depends on any declared value.
    public static func read<C: RandomAccessCollection<UInt8>>(
        _ codestream: C
    ) -> CodestreamHeaderReading where C.Index == Int {
        let base = codestream.startIndex
        let count = codestream.count

        func byte(_ offset: Int) -> UInt8? {
            guard offset >= 0, offset < count else { return nil }
            return codestream[base + offset]
        }
        func matches(_ pattern: [UInt8], at offset: Int) -> Bool {
            for (index, expected) in pattern.enumerated() {
                guard byte(offset + index) == expected else { return false }
            }
            return true
        }
        func unsigned16(_ offset: Int) -> Int? {
            guard let high = byte(offset), let low = byte(offset + 1) else { return nil }
            return Int(high) << 8 | Int(low)
        }
        func unsigned32(_ offset: Int) -> Int? {
            var value = 0
            for index in 0..<4 {
                guard let next = byte(offset + index) else { return nil }
                value = value << 8 | Int(next)
            }
            return value
        }

        guard matches(startOfCodestream, at: 0) else {
            return .notAJPEG2000Codestream
        }

        // The standard mandates `SIZ` immediately after `SOC`. A codestream that puts
        // something else there is malformed rather than merely unusual, and every
        // codestream measured in this project has `SIZ` at this offset.
        let marker = startOfCodestream.count
        guard matches(sizeMarker, at: marker) else {
            return .malformedJPEG2000Header
        }

        let segment = marker + sizeMarker.count
        guard let segmentLength = unsigned16(segment),
            segmentLength >= minimumSizeSegmentLength
        else {
            return .malformedJPEG2000Header
        }
        // The segment must lie wholly within the codestream. Without this a declared
        // length alone could send the component walk past the end.
        let segmentEnd = segment + segmentLength
        guard segmentEnd <= count else {
            return .malformedJPEG2000Header
        }

        // Offsets are counted from `segment`, which addresses the length field itself
        // because `Lsiz` counts itself:
        //
        //     +0  Lsiz(2)   +2  Rsiz(2)    +4  Xsiz(4)    +8  Ysiz(4)
        //     +12 XOsiz(4)  +16 YOsiz(4)   +20 XTsiz(4)   +24 YTsiz(4)
        //     +28 XTOsiz(4) +32 YTOsiz(4)  +36 Csiz(2)    +38 per-component records
        //
        // The first version of this parser used offsets counted from the *marker*
        // instead, two bytes earlier, and read `Ysiz` where `Xsiz` sits. It refused
        // every valid codestream, which is how the slip was found — the adversarial
        // cases were all refused too, for entirely the wrong reason.
        guard let width = unsigned32(segment + 4),
            let height = unsigned32(segment + 8),
            let componentCount = unsigned16(segment + 36),
            width >= 1, height >= 1, componentCount >= 1
        else {
            return .malformedJPEG2000Header
        }

        // The component records must fit inside the declared segment. That is the real
        // bound on the loop below, so no separate cap on the component count is
        // imposed — the segment length already supplies one. Note that this start
        // offset equals the minimum segment length, which is not a coincidence: the
        // minimum covers exactly the fixed fields above.
        let componentsStart = segment + 38
        let componentsLength = componentCount * bytesPerComponentRecord
        guard componentsStart + componentsLength <= segmentEnd else {
            return .malformedJPEG2000Header
        }

        var bitsPerComponent = 0
        for index in 0..<componentCount {
            guard let ssiz = byte(componentsStart + index * bytesPerComponentRecord)
            else {
                return .malformedJPEG2000Header
            }
            let declared = Int(ssiz & bitDepthMask) + 1
            guard permittedBitDepths.contains(declared) else {
                return .malformedJPEG2000Header
            }
            bitsPerComponent = max(bitsPerComponent, declared)
        }

        // The JP3D extension follows the component records: depth(4), then tileSizeZ(4).
        // Absent means two-dimensional, so depth is one.
        var depth = 1
        let depthOffset = componentsStart + componentsLength
        if depthOffset + 4 <= segmentEnd, let declared = unsigned32(depthOffset) {
            guard declared >= 1 else { return .malformedJPEG2000Header }
            depth = declared
        }

        return .geometry(
            CodestreamGeometry(
                width: width,
                height: height,
                depth: depth,
                componentCount: componentCount,
                bitsPerComponent: bitsPerComponent
            )
        )
    }

    /// Admits `codestream` against a decode ceiling.
    ///
    /// - Parameters:
    ///   - codestream: the bytes about to be handed to a decoder.
    ///   - maximumDecodedByteCount: the largest destination the caller will hold.
    /// - Throws: ``CodestreamBudgetError``.
    public static func admit<C: RandomAccessCollection<UInt8>>(
        codestream: C,
        maximumDecodedByteCount: Int
    ) throws where C.Index == Int {
        switch read(codestream) {
        case .notAJPEG2000Codestream:
            // No opinion; see the type's documentation.
            return
        case .malformedJPEG2000Header:
            throw CodestreamBudgetError.headerNotReadable
        case .geometry(let geometry):
            guard let implied = geometry.impliedDecodedByteCount else {
                throw CodestreamBudgetError.declaredGeometryNotRepresentable
            }
            guard implied <= maximumDecodedByteCount else {
                throw CodestreamBudgetError.declaredGeometryExceedsCeiling
            }
        }
    }
}
