// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("MeasurementUnit")
struct MeasurementUnitTests {
    @Test("[Unit][VOX-ARC-002] exposes every initial dimension as a stable string")
    func exposesInitialDimensions() throws {
        let dimensions: [(UnitDimension, String)] = [
            (.length, "length"),
            (.time, "time"),
            (.angle, "angle"),
            (.frequency, "frequency"),
            (.mass, "mass"),
            (.temperature, "temperature"),
            (.electricPotential, "electricPotential"),
            (.concentration, "concentration"),
            (.activity, "activity"),
            (.dimensionless, "dimensionless"),
            (.custom, "custom"),
        ]

        for (dimension, rawValue) in dimensions {
            #expect(dimension.rawValue == rawValue)
            let encoded = try JSONEncoder().encode(dimension)
            #expect(try JSONDecoder().decode(UnitDimension.self, from: encoded) == dimension)
        }
    }

    @Test("[Unit][VOX-ARC-002] preserves namespaced unit and conversion metadata")
    func preservesUnitMetadata() throws {
        let unit = try MeasurementUnit(
            namespace: "UCUM",
            code: "mm",
            displayName: "millimetre",
            dimension: .length,
            scaleToCanonical: 0.001,
            offsetToCanonical: 0
        )

        #expect(unit.namespace == "UCUM")
        #expect(unit.code == "mm")
        #expect(unit.displayName == "millimetre")
        #expect(unit.dimension == .length)
        #expect(unit.scaleToCanonical == 0.001)
        #expect(unit.offsetToCanonical == 0)

        let differentlyCased = try MeasurementUnit(namespace: "ucum", code: "MM")
        #expect(differentlyCased.namespace == "ucum")
        #expect(differentlyCased.code == "MM")
        #expect(differentlyCased != unit)
    }

    @Test("[Unit][VOX-API-004] identity excludes display text and preserves UTF-8 spelling")
    func identityExcludesDisplayTextAndPreservesSpelling() throws {
        let composed = try MeasurementUnit(
            namespace: "unit\u{00E9}",
            code: "m\u{00E9}",
            displayName: "First label",
            dimension: .length,
            scaleToCanonical: 2,
            offsetToCanonical: 3
        )
        let otherDisplayName = try MeasurementUnit(
            namespace: "unit\u{00E9}",
            code: "m\u{00E9}",
            displayName: "Second label",
            dimension: .length,
            scaleToCanonical: 2,
            offsetToCanonical: 3
        )
        let absentDisplayName = try MeasurementUnit(
            namespace: "unit\u{00E9}",
            code: "m\u{00E9}",
            dimension: .length,
            scaleToCanonical: 2,
            offsetToCanonical: 3
        )
        let decomposedNamespace = try MeasurementUnit(
            namespace: "unite\u{301}",
            code: "m\u{00E9}",
            dimension: .length,
            scaleToCanonical: 2,
            offsetToCanonical: 3
        )
        let decomposedCode = try MeasurementUnit(
            namespace: "unit\u{00E9}",
            code: "me\u{301}",
            dimension: .length,
            scaleToCanonical: 2,
            offsetToCanonical: 3
        )

        #expect(composed == otherDisplayName)
        #expect(composed == absentDisplayName)
        #expect(Set([composed, otherDisplayName, absentDisplayName]).count == 1)
        #expect(composed != decomposedNamespace)
        #expect(composed != decomposedCode)
        #expect(Set([composed, decomposedNamespace, decomposedCode]).count == 3)

        let otherDimension = try MeasurementUnit(
            namespace: composed.namespace,
            code: composed.code,
            dimension: .dimensionless,
            scaleToCanonical: composed.scaleToCanonical,
            offsetToCanonical: composed.offsetToCanonical
        )
        let otherScale = try MeasurementUnit(
            namespace: composed.namespace,
            code: composed.code,
            dimension: composed.dimension,
            scaleToCanonical: 4,
            offsetToCanonical: composed.offsetToCanonical
        )
        let otherOffset = try MeasurementUnit(
            namespace: composed.namespace,
            code: composed.code,
            dimension: composed.dimension,
            scaleToCanonical: composed.scaleToCanonical,
            offsetToCanonical: 5
        )
        let absentInterpretation = try MeasurementUnit(
            namespace: composed.namespace,
            code: composed.code
        )
        #expect(composed != otherDimension)
        #expect(composed != otherScale)
        #expect(composed != otherOffset)
        #expect(composed != absentInterpretation)
    }

    @Test("[Unit][VOX-ARC-002] keeps conversion metadata explicitly absent")
    func preservesAbsentConversion() throws {
        let unit = try MeasurementUnit(
            namespace: "DICOM",
            code: "HU",
            displayName: "Hounsfield unit",
            dimension: .dimensionless
        )

        #expect(unit.scaleToCanonical == nil)
        #expect(unit.offsetToCanonical == nil)

        let scaleOnly = try MeasurementUnit(
            namespace: "example.units",
            code: "scaled",
            scaleToCanonical: 2
        )
        let offsetOnly = try MeasurementUnit(
            namespace: "example.units",
            code: "offset",
            offsetToCanonical: -273.15
        )
        #expect(scaleOnly.scaleToCanonical == 2)
        #expect(scaleOnly.offsetToCanonical == nil)
        #expect(offsetOnly.scaleToCanonical == nil)
        #expect(offsetOnly.offsetToCanonical == -273.15)
    }

    @Test("[Unit] rejects blank unit identity fields")
    func rejectsBlankIdentity() {
        #expect(throws: MeasurementUnitError.emptyNamespace) {
            try MeasurementUnit(namespace: "", code: "mm")
        }
        #expect(throws: MeasurementUnitError.emptyNamespace) {
            try MeasurementUnit(namespace: " \n\t", code: "mm")
        }
        #expect(throws: MeasurementUnitError.emptyCode) {
            try MeasurementUnit(namespace: "UCUM", code: "")
        }
        #expect(throws: MeasurementUnitError.emptyCode) {
            try MeasurementUnit(namespace: "UCUM", code: " \n\t")
        }
    }

    @Test("[Unit] rejects non-finite conversion metadata")
    func rejectsNonFiniteConversionMetadata() {
        for value in [Double.nan, Double.infinity, -Double.infinity] {
            #expect(throws: MeasurementUnitError.nonFiniteScaleToCanonical) {
                try MeasurementUnit(
                    namespace: "UCUM",
                    code: "mm",
                    scaleToCanonical: value
                )
            }
            #expect(throws: MeasurementUnitError.nonFiniteOffsetToCanonical) {
                try MeasurementUnit(
                    namespace: "UCUM",
                    code: "Cel",
                    offsetToCanonical: value
                )
            }
        }
    }

    @Test("[Unit][VOX-API-004] canonicalizes signed zero conversion metadata")
    func canonicalizesSignedZeroConversionMetadata() throws {
        let negativeZero = try MeasurementUnit(
            namespace: "example.units",
            code: "zero",
            scaleToCanonical: -0.0,
            offsetToCanonical: -0.0
        )
        let positiveZero = try MeasurementUnit(
            namespace: "example.units",
            code: "zero",
            scaleToCanonical: 0.0,
            offsetToCanonical: 0.0
        )

        #expect(negativeZero.scaleToCanonical?.bitPattern == Double(0).bitPattern)
        #expect(negativeZero.offsetToCanonical?.bitPattern == Double(0).bitPattern)
        #expect(negativeZero == positiveZero)
        #expect(Set([negativeZero, positiveZero]).count == 1)

        let encoded = try JSONEncoder().encode(negativeZero)
        let object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        let encodedScale = try #require(object["scaleToCanonical"] as? NSNumber)
        let encodedOffset = try #require(object["offsetToCanonical"] as? NSNumber)
        #expect(encodedScale.doubleValue.bitPattern == Double(0).bitPattern)
        #expect(encodedOffset.doubleValue.bitPattern == Double(0).bitPattern)

        let decodedNegativeZero = try JSONDecoder().decode(
            MeasurementUnit.self,
            from: Data(
                #"{"namespace":"example.units","code":"zero","displayName":null,"dimension":null,"scaleToCanonical":-0.0,"offsetToCanonical":-0.0}"#
                    .utf8
            )
        )
        #expect(decodedNegativeZero.scaleToCanonical?.bitPattern == Double(0).bitPattern)
        #expect(decodedNegativeZero.offsetToCanonical?.bitPattern == Double(0).bitPattern)
    }

    @Test("[Unit][VOX-API-004] Codable preserves fields and revalidates input")
    func codableRoundTripAndValidation() throws {
        let source = Data(
            #"{"namespace":"UCUM","code":"mm","displayName":"millimetre","dimension":"length","scaleToCanonical":0.001,"offsetToCanonical":0.0}"#
                .utf8
        )
        let unit = try JSONDecoder().decode(MeasurementUnit.self, from: source)
        let decoded = try JSONDecoder().decode(
            MeasurementUnit.self,
            from: JSONEncoder().encode(unit)
        )

        #expect(decoded == unit)

        let encodedObject = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(unit))
                as? [String: Any]
        )
        #expect(
            Set(encodedObject.keys) == [
                "namespace",
                "code",
                "displayName",
                "dimension",
                "scaleToCanonical",
                "offsetToCanonical",
            ]
        )

        let absentOptionals = try MeasurementUnit(namespace: "UCUM", code: "1")
        let absentObject = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(absentOptionals))
                as? [String: Any]
        )
        #expect(absentObject["displayName"] is NSNull)
        #expect(absentObject["dimension"] is NSNull)
        #expect(absentObject["scaleToCanonical"] is NSNull)
        #expect(absentObject["offsetToCanonical"] is NSNull)

        let malformedShapes = [
            #"{"namespace":"UCUM","code":"mm"}"#,
            #"{"namespace":"UCUM","code":"mm","displayName":null,"dimension":null,"scaleToCanonical":null,"offsetToCanonical":null,"extra":true}"#,
            #"[]"#,
        ]
        for malformedShape in malformedShapes {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    MeasurementUnit.self,
                    from: Data(malformedShape.utf8)
                )
            }
        }

        let invalidIdentity = Data(
            #"{"namespace":" ","code":"mm","displayName":null,"dimension":"length","scaleToCanonical":0.001,"offsetToCanonical":0.0}"#
                .utf8
        )
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(MeasurementUnit.self, from: invalidIdentity)
        }

        let nonFinite = Data(
            #"{"namespace":"UCUM","code":"mm","displayName":null,"dimension":"length","scaleToCanonical":"NaN","offsetToCanonical":0.0}"#
                .utf8
        )
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        #expect(throws: DecodingError.self) {
            try decoder.decode(MeasurementUnit.self, from: nonFinite)
        }
    }
}
