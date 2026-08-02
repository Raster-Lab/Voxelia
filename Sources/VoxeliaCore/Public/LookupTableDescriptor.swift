// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// A finite ordered lookup table for authoritative value transformation.
///
/// This descriptor stores table metadata only. It does not define lookup,
/// clamping, extrapolation, or display-window behavior.
public struct LookupTableDescriptor: Sendable, Hashable, Codable {
    /// The stored integer value mapped by the first table entry.
    public let firstMappedValue: Int64

    /// Finite output values in increasing stored-value order.
    public let values: ContiguousArray<Double>

    /// The optional unit of table outputs, without inferred conversion.
    public let outputUnit: MeasurementUnit?

    /// Creates a lookup-table descriptor while preserving value order.
    ///
    /// Empty tables are accepted because their operational meaning belongs to
    /// a consuming operation. Signed zero is canonicalized to positive zero;
    /// every other finite value and the complete `Int64` mapping origin are
    /// preserved exactly.
    ///
    /// - Throws: ``DataModelError/invalidValueTransform`` when any table value
    ///   is NaN or infinity.
    public init<Values: Collection>(
        firstMappedValue: Int64,
        values: Values,
        outputUnit: MeasurementUnit? = nil
    ) throws where Values.Element == Double {
        var validatedValues = ContiguousArray<Double>()
        validatedValues.reserveCapacity(values.count)
        for value in values {
            guard value.isFinite else {
                throw DataModelError.invalidValueTransform
            }
            validatedValues.append(value == 0 ? 0 : value)
        }

        self.firstMappedValue = firstMappedValue
        self.values = validatedValues
        self.outputUnit = outputUnit
    }

    /// Decodes the exact three-field representation and revalidates its table.
    public init(from decoder: any Decoder) throws {
        let firstMappedValueKey = LookupTableCodingKey("firstMappedValue")
        let valuesKey = LookupTableCodingKey("values")
        let outputUnitKey = LookupTableCodingKey("outputUnit")
        let container = try decoder.container(keyedBy: LookupTableCodingKey.self)
        let expectedKeys = Set([
            firstMappedValueKey.stringValue,
            valuesKey.stringValue,
            outputUnitKey.stringValue,
        ])
        guard Set(container.allKeys.map(\.stringValue)) == expectedKeys else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                        "A lookup table requires firstMappedValue, values, and outputUnit."
                )
            )
        }

        let firstMappedValue = try container.decode(
            Int64.self,
            forKey: firstMappedValueKey
        )
        let values = try container.decode(
            ContiguousArray<Double>.self,
            forKey: valuesKey
        )
        let outputUnit = try container.decodeIfPresent(
            MeasurementUnit.self,
            forKey: outputUnitKey
        )

        do {
            try self.init(
                firstMappedValue: firstMappedValue,
                values: values,
                outputUnit: outputUnit
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [valuesKey],
                    debugDescription: "A lookup table contains a non-finite value.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes all three declared fields, including an explicit null unit.
    public func encode(to encoder: any Encoder) throws {
        let firstMappedValueKey = LookupTableCodingKey("firstMappedValue")
        let valuesKey = LookupTableCodingKey("values")
        let outputUnitKey = LookupTableCodingKey("outputUnit")
        var container = encoder.container(keyedBy: LookupTableCodingKey.self)
        try container.encode(firstMappedValue, forKey: firstMappedValueKey)
        try container.encode(values, forKey: valuesKey)
        try container.encode(outputUnit, forKey: outputUnitKey)
    }
}

private struct LookupTableCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
