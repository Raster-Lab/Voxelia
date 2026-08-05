// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaGeometry

/// The closed source facts admitted before scalar-surface storage access.
///
/// This internal value copies only bounded descriptor leaves. It does not own
/// storage, samples, publication authority or a second authoritative lattice.
struct ScalarSurfaceSourceAdmission: Sendable {
    let extents: ContiguousArray<Int>
    let scalarType: ScalarType
    let byteOrder: ByteOrder
    let spatialImageAxes: ContiguousArray<Int>
    let matrixElements: ContiguousArray<Double>
    let reversesWinding: Bool
    let sampleCount: Int
    let cellCount: Int

    init(request: ScalarSurfaceExtractionRequest) throws {
        let descriptor = request.source.descriptor
        let extents = descriptor.shape.extents
        guard extents.count == 3 else {
            throw ScalarSurfaceExtractionError.unsupportedSource
        }
        guard
            descriptor.components.count == 1,
            descriptor.components.interpretation == .scalar
        else {
            throw ScalarSurfaceExtractionError.unsupportedSource
        }
        switch descriptor.semantic {
        case .intensity, .probability, .parametric:
            break
        default:
            throw ScalarSurfaceExtractionError.unsupportedSource
        }

        let scalarType = descriptor.scalarFormat.type
        switch scalarType {
        case .int8, .uint8, .int16, .uint16, .int32, .uint32,
            .float16, .float32, .float64:
            break
        case .int64, .uint64:
            throw ScalarSurfaceExtractionError.unsupportedSource
        }

        guard case .affine(let geometry) = descriptor.spatialGeometry else {
            throw ScalarSurfaceExtractionError.unsupportedSource
        }
        let spatialImageAxes = geometry.spatialAxes.imageAxes
        guard
            spatialImageAxes.count == 3,
            spatialImageAxes.sorted() == [0, 1, 2]
        else {
            throw ScalarSurfaceExtractionError.unsupportedSource
        }

        let maximumExactlyRepresentableIndex = 9_007_199_254_740_992
        for extent in extents {
            guard extent - 1 <= maximumExactlyRepresentableIndex else {
                throw ScalarSurfaceExtractionError.unsupportedSource
            }
        }

        let matrix = geometry.indexToWorld.elements
        let determinant =
            matrix[0] * (matrix[5] * matrix[10] - matrix[6] * matrix[9])
            - matrix[1] * (matrix[4] * matrix[10] - matrix[6] * matrix[8])
            + matrix[2] * (matrix[4] * matrix[9] - matrix[5] * matrix[8])
        guard determinant.isFinite, determinant != 0 else {
            throw ScalarSurfaceExtractionError.unsupportedSource
        }

        let sampleCount: Int
        do {
            sampleCount = try descriptor.shape.elementCount()
        } catch {
            throw ScalarSurfaceExtractionError.unsupportedSource
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
            let cellExtent = extent - 1
            let product = count.multipliedReportingOverflow(by: cellExtent)
            guard !product.overflow else {
                throw ScalarSurfaceExtractionError.resourceLimitExceeded
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

/// One admitted, owned packed-byte adapter used by both validation and cells.
///
/// The adapter decodes on demand and repeats the pure transform for cell
/// corners. It deliberately never retains a full binary64 source lattice.
struct ScalarSurfaceSourceAdapter: Sendable {
    private enum TransformStage: Sendable {
        case linear(LinearValueTransformDescriptor)
        case table(LookupTableDescriptor)
    }

    private struct DecodedScalar: Sendable {
        let value: Double
        let integer: Int64?
    }

    let admission: ScalarSurfaceSourceAdmission
    private let bytes: [UInt8]
    private let stages: ContiguousArray<TransformStage>

    init(
        request: ScalarSurfaceExtractionRequest,
        admission: ScalarSurfaceSourceAdmission,
        bytes: [UInt8]
    ) throws {
        let expectedByteCount = admission.sampleCount.multipliedReportingOverflow(
            by: admission.scalarType.byteCount
        )
        guard
            !expectedByteCount.overflow,
            expectedByteCount.partialValue == bytes.count
        else {
            throw ScalarSurfaceExtractionError.sourceReadFailed
        }

        self.admission = admission
        self.bytes = bytes
        self.stages = try Self.admitTransform(
            request.source.descriptor.valueTransform,
            scalarType: admission.scalarType
        )
    }

    func validateFiniteSamples(
        cancellation: CPUScalarSurfaceCancellationProbe
    ) throws {
        for ordinal in 0..<admission.sampleCount {
            if ordinal.isMultiple(of: 4_096),
                cancellation(.sampleValidation(UInt64(ordinal)))
            {
                throw ScalarSurfaceExtractionError.cancelled
            }
            let value = try authoritativeValue(at: ordinal)
            guard value.isFinite else {
                throw ScalarSurfaceExtractionError.nonFiniteSample
            }
        }
    }

    func authoritativeValue(at ordinal: Int) throws -> Double {
        let decoded = try decode(at: ordinal)
        var value = decoded.value
        for stage in stages {
            switch stage {
            case .linear(let transform):
                let product = value * transform.scale
                value = product + transform.offset
            case .table(let table):
                guard let integer = decoded.integer else {
                    throw ScalarSurfaceExtractionError.sourceReadFailed
                }
                value = Self.tableOutput(table, storedInteger: integer)
            }
        }
        return value
    }

    private static func admitTransform(
        _ transform: ValueTransform?,
        scalarType: ScalarType
    ) throws -> ContiguousArray<TransformStage> {
        switch transform {
        case nil, .identity:
            return []
        case .linear(let linear):
            return [.linear(linear)]
        case .lookupTable(let table):
            guard scalarType.isInteger, !table.values.isEmpty else {
                throw ScalarSurfaceExtractionError.sourceReadFailed
            }
            return [.table(table)]
        case .composed(let composition):
            guard composition.transforms.count <= 8 else {
                throw ScalarSurfaceExtractionError.sourceReadFailed
            }
            var admitted = ContiguousArray<TransformStage>()
            var hasNonIdentityStage = false
            for stage in composition.transforms {
                switch stage {
                case .identity:
                    continue
                case .linear(let linear):
                    admitted.append(.linear(linear))
                    hasNonIdentityStage = true
                case .lookupTable(let table):
                    guard
                        scalarType.isInteger,
                        !hasNonIdentityStage,
                        !table.values.isEmpty
                    else {
                        throw ScalarSurfaceExtractionError.sourceReadFailed
                    }
                    admitted.append(.table(table))
                    hasNonIdentityStage = true
                case .composed:
                    throw ScalarSurfaceExtractionError.sourceReadFailed
                }
            }
            return admitted
        }
    }

    private static func tableOutput(
        _ table: LookupTableDescriptor,
        storedInteger: Int64
    ) -> Double {
        let difference = storedInteger.subtractingReportingOverflow(
            table.firstMappedValue
        )
        let index: Int
        if difference.overflow {
            index = table.firstMappedValue < 0 ? table.values.count - 1 : 0
        } else {
            let upper = Int64(table.values.count - 1)
            index = Int(min(max(difference.partialValue, 0), upper))
        }
        return table.values[index]
    }

    private func decode(at ordinal: Int) throws -> DecodedScalar {
        guard ordinal >= 0, ordinal < admission.sampleCount else {
            throw ScalarSurfaceExtractionError.sourceReadFailed
        }
        let byteCount = admission.scalarType.byteCount
        let offset = ordinal.multipliedReportingOverflow(by: byteCount)
        let upperBound = offset.partialValue.addingReportingOverflow(byteCount)
        guard
            !offset.overflow,
            !upperBound.overflow,
            upperBound.partialValue <= bytes.count
        else {
            throw ScalarSurfaceExtractionError.sourceReadFailed
        }

        let bits = word(at: offset.partialValue, byteCount: byteCount)
        switch admission.scalarType {
        case .int8:
            let integer = Int64(Int8(bitPattern: UInt8(bits)))
            return DecodedScalar(value: Double(integer), integer: integer)
        case .uint8:
            let integer = Int64(UInt8(bits))
            return DecodedScalar(value: Double(integer), integer: integer)
        case .int16:
            let integer = Int64(Int16(bitPattern: UInt16(bits)))
            return DecodedScalar(value: Double(integer), integer: integer)
        case .uint16:
            let integer = Int64(UInt16(bits))
            return DecodedScalar(value: Double(integer), integer: integer)
        case .int32:
            let integer = Int64(Int32(bitPattern: UInt32(bits)))
            return DecodedScalar(value: Double(integer), integer: integer)
        case .uint32:
            let integer = Int64(UInt32(bits))
            return DecodedScalar(value: Double(integer), integer: integer)
        case .float16:
            return DecodedScalar(
                value: Double(Float16(bitPattern: UInt16(bits))),
                integer: nil
            )
        case .float32:
            return DecodedScalar(
                value: Double(Float(bitPattern: UInt32(bits))),
                integer: nil
            )
        case .float64:
            return DecodedScalar(value: Double(bitPattern: bits), integer: nil)
        case .int64, .uint64:
            throw ScalarSurfaceExtractionError.sourceReadFailed
        }
    }

    private func word(at offset: Int, byteCount: Int) -> UInt64 {
        var value: UInt64 = 0
        if admission.byteOrder == .bigEndian {
            for index in 0..<byteCount {
                value = (value << 8) | UInt64(bytes[offset + index])
            }
        } else {
            for index in 0..<byteCount {
                value |= UInt64(bytes[offset + index]) << UInt64(index * 8)
            }
        }
        return value
    }
}
