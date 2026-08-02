// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("LookupTableDescriptor")
struct LookupTableDescriptorTests {
    @Test("[Unit][VOX-API-003] preserves order, mapping origin, and optional unit")
    func preservesDeclaredMetadata() throws {
        let unit = try MeasurementUnit(
            namespace: "UCUM",
            code: "HU",
            dimension: .dimensionless
        )
        let minimumOrigin = try LookupTableDescriptor(
            firstMappedValue: Int64.min,
            values: [3.0, 1.0, 2.0].lazy,
            outputUnit: unit
        )
        let maximumOrigin = try LookupTableDescriptor(
            firstMappedValue: Int64.max,
            values: [4.0],
            outputUnit: nil
        )

        #expect(minimumOrigin.firstMappedValue == Int64.min)
        #expect(minimumOrigin.values == [3, 1, 2])
        #expect(minimumOrigin.outputUnit == unit)
        #expect(maximumOrigin.firstMappedValue == Int64.max)
        #expect(maximumOrigin.values == [4])
        #expect(maximumOrigin.outputUnit == nil)
    }

    @Test("[Unit] accepts an empty table without inventing application semantics")
    func acceptsEmptyValues() throws {
        let descriptor = try LookupTableDescriptor(
            firstMappedValue: 0,
            values: [Double]()
        )

        #expect(descriptor.values.isEmpty)
        #expect(descriptor.outputUnit == nil)
    }

    @Test("[Unit][VOX-API-004] preserves finite values and canonicalizes signed zero")
    func preservesFiniteValuesAndCanonicalizesZero() throws {
        let descriptor = try LookupTableDescriptor(
            firstMappedValue: 0,
            values: [
                -Double.greatestFiniteMagnitude,
                -0.0,
                Double.leastNonzeroMagnitude,
                Double.greatestFiniteMagnitude,
            ]
        )

        #expect(
            descriptor.values[0].bitPattern
                == (-Double.greatestFiniteMagnitude).bitPattern
        )
        #expect(descriptor.values[1].bitPattern == Double(0).bitPattern)
        #expect(
            descriptor.values[2].bitPattern
                == Double.leastNonzeroMagnitude.bitPattern
        )
        #expect(
            descriptor.values[3].bitPattern
                == Double.greatestFiniteMagnitude.bitPattern
        )
        let positiveZero = try LookupTableDescriptor(
            firstMappedValue: 0,
            values: [0.0]
        )
        let negativeZero = try LookupTableDescriptor(
            firstMappedValue: 0,
            values: [-0.0]
        )
        #expect(positiveZero == negativeZero)
        #expect(Set([positiveZero, negativeZero]).count == 1)
    }

    @Test("[Unit][VOX-ERR-001] rejects every non-finite table value")
    func rejectsNonFiniteValues() {
        for invalidValue in [Double.nan, Double.infinity, -Double.infinity] {
            for index in 0..<3 {
                var values = [1.0, 2.0, 3.0]
                values[index] = invalidValue
                #expect(throws: DataModelError.invalidValueTransform) {
                    try LookupTableDescriptor(
                        firstMappedValue: 0,
                        values: values
                    )
                }
            }
        }
    }

    @Test("[Unit][VOX-API-004] Codable uses the exact explicit-null schema")
    func codableRoundTripAndShape() throws {
        let unit = try MeasurementUnit(namespace: "UCUM", code: "1")
        let withUnit = try LookupTableDescriptor(
            firstMappedValue: -2,
            values: [0, 0.5, 1],
            outputUnit: unit
        )
        let withoutUnit = try LookupTableDescriptor(
            firstMappedValue: 0,
            values: [1]
        )

        for descriptor in [withUnit, withoutUnit] {
            let data = try JSONEncoder().encode(descriptor)
            #expect(
                try JSONDecoder().decode(LookupTableDescriptor.self, from: data)
                    == descriptor
            )
            let object = try #require(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            #expect(Set(object.keys) == ["firstMappedValue", "values", "outputUnit"])
            if descriptor.outputUnit == nil {
                #expect(object["outputUnit"] is NSNull)
            } else {
                #expect(object["outputUnit"] is [String: Any])
            }
        }
    }

    @Test("[Unit][VOX-API-004] decoding is strict and revalidates nested values")
    func decodingIsStrictAndRevalidates() {
        let malformedValues = [
            #"{"firstMappedValue":0,"values":[]}"#,
            #"{"firstMappedValue":0,"values":[],"outputUnit":null,"extra":true}"#,
            #"[]"#,
        ]
        for malformedValue in malformedValues {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    LookupTableDescriptor.self,
                    from: Data(malformedValue.utf8)
                )
            }
        }

        let nonFinite =
            #"{"firstMappedValue":0,"values":[1,"NaN",3],"outputUnit":null}"#
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        do {
            _ = try decoder.decode(
                LookupTableDescriptor.self,
                from: Data(nonFinite.utf8)
            )
            #expect(Bool(false), "Expected non-finite lookup value to fail.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.last?.stringValue == "values")
            #expect(context.underlyingError as? DataModelError == .invalidValueTransform)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        let invalidUnit =
            #"{"firstMappedValue":0,"values":[1],"outputUnit":{"namespace":" ","code":"1","displayName":null,"dimension":null,"scaleToCanonical":null,"offsetToCanonical":null}}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                LookupTableDescriptor.self,
                from: Data(invalidUnit.utf8)
            )
        }
    }
}
