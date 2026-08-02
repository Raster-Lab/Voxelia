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
