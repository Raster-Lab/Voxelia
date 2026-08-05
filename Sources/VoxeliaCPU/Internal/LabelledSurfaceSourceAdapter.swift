// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaGeometry

/// The closed source facts admitted before labelled-surface storage access.
///
/// This internal value copies only bounded descriptor leaves. It does not own
/// storage, decoded labels, publication authority or a second authoritative
/// lattice.
struct LabelledSurfaceSourceAdmission: Sendable {
    let extents: ContiguousArray<Int>
    let scalarType: ScalarType
    let byteOrder: ByteOrder
    let spatialImageAxes: ContiguousArray<Int>
    let matrixElements: ContiguousArray<Double>
    let reversesWinding: Bool
    let sampleCount: Int
    let cellCount: Int

    init(request: LabelledSurfaceExtractionRequest) throws {
        let descriptor = request.source.descriptor
        let extents = descriptor.shape.extents
        guard extents.count == 3 else {
            throw LabelledSurfaceExtractionError.unsupportedSource
        }
        guard
            descriptor.components.count == 1,
            descriptor.components.interpretation == .scalar,
            descriptor.semantic == .label,
            descriptor.units == nil
        else {
            throw LabelledSurfaceExtractionError.unsupportedSource
        }

        let scalarType = descriptor.scalarFormat.type
        guard scalarType.isInteger else {
            throw LabelledSurfaceExtractionError.unsupportedSource
        }
        if let validBitCount = descriptor.scalarFormat.validBitCount,
            validBitCount != scalarType.bitCount
        {
            throw LabelledSurfaceExtractionError.unsupportedSource
        }
        switch descriptor.valueTransform {
        case nil, .identity:
            break
        case .linear, .lookupTable, .composed:
            throw LabelledSurfaceExtractionError.unsupportedSource
        }

        switch request.selectedLabels {
        case .signed:
            guard scalarType.isSignedInteger else {
                throw LabelledSurfaceExtractionError.unsupportedSource
            }
        case .unsigned:
            guard !scalarType.isSignedInteger else {
                throw LabelledSurfaceExtractionError.unsupportedSource
            }
        }

        guard case .affine(let geometry) = descriptor.spatialGeometry else {
            throw LabelledSurfaceExtractionError.unsupportedSource
        }
        let spatialImageAxes = geometry.spatialAxes.imageAxes
        guard
            spatialImageAxes.count == 3,
            spatialImageAxes.sorted() == [0, 1, 2]
        else {
            throw LabelledSurfaceExtractionError.unsupportedSource
        }

        let maximumExactlyRepresentableIndex = 9_007_199_254_740_992
        for extent in extents {
            guard extent - 1 <= maximumExactlyRepresentableIndex else {
                throw LabelledSurfaceExtractionError.unsupportedSource
            }
        }

        let matrix = geometry.indexToWorld.elements
        let determinant =
            matrix[0] * (matrix[5] * matrix[10] - matrix[6] * matrix[9])
            - matrix[1] * (matrix[4] * matrix[10] - matrix[6] * matrix[8])
            + matrix[2] * (matrix[4] * matrix[9] - matrix[5] * matrix[8])
        guard determinant.isFinite, determinant != 0 else {
            throw LabelledSurfaceExtractionError.unsupportedSource
        }

        let sampleCount: Int
        do {
            sampleCount = try descriptor.shape.elementCount()
        } catch {
            throw LabelledSurfaceExtractionError.unsupportedSource
        }
        let cellCount = try Self.checkedCellCount(extents: extents)
        let permutationIsOdd = Self.permutationIsOdd(spatialImageAxes)

        self.extents = extents
        self.scalarType = scalarType
        self.byteOrder = descriptor.scalarFormat.byteOrder
        self.spatialImageAxes = spatialImageAxes
        self.matrixElements = matrix
        self.reversesWinding = (determinant < 0) != permutationIsOdd
        self.sampleCount = sampleCount
        self.cellCount = cellCount
    }

    private static func checkedCellCount(
        extents: ContiguousArray<Int>
    ) throws -> Int {
        var count = 1
        for extent in extents {
            let product = count.multipliedReportingOverflow(by: extent - 1)
            guard !product.overflow else {
                throw LabelledSurfaceExtractionError.resourceLimitExceeded
            }
            count = product.partialValue
        }
        return count
    }

    private static func permutationIsOdd(
        _ axes: ContiguousArray<Int>
    ) -> Bool {
        var inversionCount = 0
        for lhs in axes.indices {
            for rhs in axes.indices where rhs > lhs && axes[lhs] > axes[rhs] {
                inversionCount += 1
            }
        }
        return !inversionCount.isMultiple(of: 2)
    }
}

/// One admitted, owned packed-byte adapter shared by validation and cells.
///
/// Decoding retains the source integer domain and never passes labels through
/// binary64. Membership searches the caller's canonical sorted array directly;
/// no execution hash set or decoded label lattice is created.
struct LabelledSurfaceSourceAdapter: Sendable {
    let admission: LabelledSurfaceSourceAdmission
    private let bytes: [UInt8]
    private let selectedLabels: LabelledSurfaceLabelSet

    init(
        request: LabelledSurfaceExtractionRequest,
        admission: LabelledSurfaceSourceAdmission,
        bytes: [UInt8]
    ) throws {
        let expectedByteCount = admission.sampleCount.multipliedReportingOverflow(
            by: admission.scalarType.byteCount
        )
        guard
            !expectedByteCount.overflow,
            expectedByteCount.partialValue == bytes.count
        else {
            throw LabelledSurfaceExtractionError.sourceReadFailed
        }
        self.admission = admission
        self.bytes = bytes
        self.selectedLabels = request.selectedLabels
    }

    func validateSamples(
        cancellation: CPULabelledSurfaceCancellationProbe
    ) throws {
        for ordinal in 0..<admission.sampleCount {
            if ordinal.isMultiple(of: 4_096),
                cancellation(.sampleValidation(UInt64(ordinal)))
            {
                throw LabelledSurfaceExtractionError.cancelled
            }
            _ = try isSelected(at: ordinal)
        }
    }

    func isSelected(at ordinal: Int) throws -> Bool {
        let bits = try decodedBits(at: ordinal)
        switch selectedLabels {
        case .signed(let labels):
            let value: Int64
            switch admission.scalarType {
            case .int8:
                value = Int64(Int8(bitPattern: UInt8(bits)))
            case .int16:
                value = Int64(Int16(bitPattern: UInt16(bits)))
            case .int32:
                value = Int64(Int32(bitPattern: UInt32(bits)))
            case .int64:
                value = Int64(bitPattern: bits)
            default:
                throw LabelledSurfaceExtractionError.sourceReadFailed
            }
            return Self.contains(value, in: labels)
        case .unsigned(let labels):
            let value: UInt64
            switch admission.scalarType {
            case .uint8:
                value = UInt64(UInt8(bits))
            case .uint16:
                value = UInt64(UInt16(bits))
            case .uint32:
                value = UInt64(UInt32(bits))
            case .uint64:
                value = bits
            default:
                throw LabelledSurfaceExtractionError.sourceReadFailed
            }
            return Self.contains(value, in: labels)
        }
    }

    private static func contains<Value: Comparable>(
        _ value: Value,
        in sortedValues: ContiguousArray<Value>
    ) -> Bool {
        var lower = sortedValues.startIndex
        var upper = sortedValues.endIndex
        while lower < upper {
            let midpoint = lower + (upper - lower) / 2
            if sortedValues[midpoint] < value {
                lower = midpoint + 1
            } else {
                upper = midpoint
            }
        }
        return lower < sortedValues.endIndex && sortedValues[lower] == value
    }

    private func decodedBits(at ordinal: Int) throws -> UInt64 {
        guard ordinal >= 0, ordinal < admission.sampleCount else {
            throw LabelledSurfaceExtractionError.sourceReadFailed
        }
        let byteCount = admission.scalarType.byteCount
        let offset = ordinal.multipliedReportingOverflow(by: byteCount)
        let upperBound = offset.partialValue.addingReportingOverflow(byteCount)
        guard
            !offset.overflow,
            !upperBound.overflow,
            upperBound.partialValue <= bytes.count
        else {
            throw LabelledSurfaceExtractionError.sourceReadFailed
        }

        var value: UInt64 = 0
        if admission.byteOrder == .bigEndian {
            for index in 0..<byteCount {
                value = (value << 8) | UInt64(bytes[offset.partialValue + index])
            }
        } else {
            for index in 0..<byteCount {
                value |=
                    UInt64(bytes[offset.partialValue + index])
                    << UInt64(index * 8)
            }
        }
        return value
    }
}
