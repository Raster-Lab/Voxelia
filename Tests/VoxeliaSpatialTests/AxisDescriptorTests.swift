// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("AxisDescriptor")
struct AxisDescriptorTests {
    @Test("[Unit][CDMS-14.1][VOX-DAT-006] preserves the five declared fields")
    func preservesDeclaredFields() throws {
        let unit = try MeasurementUnit(namespace: "UCUM", code: "mm")
        let descriptor = try AxisDescriptor(
            id: AxisID(validating: "org.voxelia.axis.x"),
            name: "Left-right",
            semantic: .spatialX,
            unit: unit,
            sampling: .regular(origin: -120, spacing: 0.75)
        )

        #expect(descriptor.id.rawValue == "org.voxelia.axis.x")
        #expect(descriptor.name == "Left-right")
        #expect(descriptor.semantic == .spatialX)
        #expect(descriptor.unit == unit)
        #expect(descriptor.sampling == .regular(origin: -120, spacing: 0.75))
    }

    @Test("[Unit][CDMS-14.1][VOX-DAT-006] permits an absent unit")
    func permitsAbsentUnit() throws {
        let descriptor = try AxisDescriptor(
            id: AxisID(validating: "org.voxelia.axis.time"),
            name: "Acquisition time",
            semantic: .time,
            sampling: .indexOnly
        )

        #expect(descriptor.unit == nil)
    }

    @Test("[Unit][CDMS-14.4][VOX-ERR-001] construction rejects blank metadata")
    func constructionRejectsBlankMetadata() throws {
        let id = try AxisID(validating: "org.voxelia.axis.x")

        #expect(throws: AxisDescriptorError.blankName) {
            try AxisDescriptor(
                id: id,
                name: " \u{2003}",
                semantic: .spatialX,
                sampling: .indexOnly
            )
        }
        #expect(throws: AxisDescriptorError.blankSemanticNamespace) {
            try AxisDescriptor(
                id: id,
                name: "Custom",
                semantic: .generic(namespace: " ", name: "custom"),
                sampling: .indexOnly
            )
        }
        #expect(throws: AxisDescriptorError.blankSemanticName) {
            try AxisDescriptor(
                id: id,
                name: "Custom",
                semantic: .generic(namespace: "org.voxelia", name: " "),
                sampling: .indexOnly
            )
        }
    }

    @Test("[Unit][CDMS-14.4][VOX-ERR-001] construction revalidates sampling")
    func constructionRevalidatesSampling() throws {
        let id = try AxisID(validating: "org.voxelia.axis.x")

        #expect(throws: AxisSamplingError.zeroSpacing) {
            try AxisDescriptor(
                id: id,
                name: "Left-right",
                semantic: .spatialX,
                sampling: .regular(origin: 0, spacing: 0)
            )
        }
        #expect(throws: AxisSamplingError.nonFiniteCoordinate(index: 0)) {
            try AxisDescriptor(
                id: id,
                name: "Left-right",
                semantic: .spatialX,
                sampling: .irregular(coordinates: [.infinity])
            )
        }
    }

    @Test("[Unit][VOX-API-004] Codable round trips the strict five-field shape")
    func codableRoundTrip() throws {
        let withUnit = try AxisDescriptor(
            id: AxisID(validating: "org.voxelia.axis.x"),
            name: "Left-right",
            semantic: .spatialX,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm"),
            sampling: .regular(origin: -120, spacing: 0.75)
        )
        let withoutUnit = try AxisDescriptor(
            id: AxisID(validating: "org.voxelia.axis.label"),
            name: "Tissue class",
            semantic: .generic(namespace: "org.voxelia", name: "tissueClass"),
            sampling: .categorical(labels: ["background", "lesion"])
        )

        for descriptor in [withUnit, withoutUnit] {
            let data = try JSONEncoder().encode(descriptor)
            let object = try #require(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            #expect(
                Set(object.keys) == ["id", "name", "semantic", "unit", "sampling"]
            )
            #expect(
                try JSONDecoder().decode(AxisDescriptor.self, from: data) == descriptor
            )
        }

        let absentUnitObject = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(withoutUnit))
                as? [String: Any]
        )
        #expect(absentUnitObject["unit"] is NSNull)
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding is strict and revalidates fields")
    func decodingIsStrictAndRevalidates() throws {
        let validJSON = """
            {"id":{"rawValue":"org.voxelia.axis.x"},"name":"Left-right",\
            "semantic":"spatialX","unit":null,\
            "sampling":{"regular":{"origin":-120,"spacing":0.75}}}
            """
        #expect(
            try JSONDecoder().decode(
                AxisDescriptor.self,
                from: Data(validJSON.utf8)
            ).name == "Left-right"
        )

        let missingKeyJSON = """
            {"id":{"rawValue":"org.voxelia.axis.x"},"name":"Left-right",\
            "semantic":"spatialX","sampling":"indexOnly"}
            """
        let extraKeyJSON = """
            {"id":{"rawValue":"org.voxelia.axis.x"},"name":"Left-right",\
            "semantic":"spatialX","unit":null,"sampling":"indexOnly","extra":true}
            """
        for wrongKeyJSON in [missingKeyJSON, extraKeyJSON, "[]"] {
            do {
                _ = try JSONDecoder().decode(
                    AxisDescriptor.self,
                    from: Data(wrongKeyJSON.utf8)
                )
                #expect(Bool(false), "Expected a wrong-keyed descriptor to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
            } catch DecodingError.typeMismatch {
                // The keyed-container request rejects the array shape.
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        let blankNameJSON = """
            {"id":{"rawValue":"org.voxelia.axis.x"},"name":" ",\
            "semantic":"spatialX","unit":null,"sampling":"indexOnly"}
            """
        do {
            _ = try JSONDecoder().decode(
                AxisDescriptor.self,
                from: Data(blankNameJSON.utf8)
            )
            #expect(Bool(false), "Expected a blank name to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["name"])
            #expect(context.underlyingError as? AxisDescriptorError == .blankName)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        let blankSemanticJSON = """
            {"id":{"rawValue":"org.voxelia.axis.x"},"name":"Custom",\
            "semantic":{"generic":{"namespace":" ","name":"custom"}},\
            "unit":null,"sampling":"indexOnly"}
            """
        do {
            _ = try JSONDecoder().decode(
                AxisDescriptor.self,
                from: Data(blankSemanticJSON.utf8)
            )
            #expect(Bool(false), "Expected a blank namespace to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["semantic"])
            #expect(
                context.underlyingError as? AxisDescriptorError
                    == .blankSemanticNamespace
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        let blankIDJSON = """
            {"id":{"rawValue":" "},"name":"Left-right",\
            "semantic":"spatialX","unit":null,"sampling":"indexOnly"}
            """
        do {
            _ = try JSONDecoder().decode(
                AxisDescriptor.self,
                from: Data(blankIDJSON.utf8)
            )
            #expect(Bool(false), "Expected a blank axis identifier to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["id", "rawValue"])
            #expect(
                context.underlyingError as? VoxeliaStringIdentifierError
                    == .emptyOrWhitespaceOnly
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        let invalidSamplingJSON = """
            {"id":{"rawValue":"org.voxelia.axis.x"},"name":"Left-right",\
            "semantic":"spatialX","unit":null,\
            "sampling":{"regular":{"origin":0,"spacing":0}}}
            """
        do {
            _ = try JSONDecoder().decode(
                AxisDescriptor.self,
                from: Data(invalidSamplingJSON.utf8)
            )
            #expect(Bool(false), "Expected zero spacing to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["sampling", "regular"])
            #expect(context.underlyingError as? AxisSamplingError == .zeroSpacing)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    @Test("[Unit][VOX-API-003][VOX-CON-003] values remain Sendable and Hashable")
    func remainsSendableAndHashable() throws {
        requireSendable(AxisDescriptor.self)
        requireSendable(AxisDescriptorError.self)

        let first = try AxisDescriptor(
            id: AxisID(validating: "org.voxelia.axis.x"),
            name: "Left-right",
            semantic: .spatialX,
            sampling: .indexOnly
        )
        let second = try AxisDescriptor(
            id: AxisID(validating: "org.voxelia.axis.x"),
            name: "Left-right",
            semantic: .spatialX,
            sampling: .indexOnly
        )
        #expect(Set([first, second]).count == 1)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
