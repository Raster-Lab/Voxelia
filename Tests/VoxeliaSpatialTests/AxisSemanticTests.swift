// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("AxisSemantic")
struct AxisSemanticTests {
    @Test("[Unit][CDMS-14.2][VOX-DAT-006] exposes the exact axis-semantic taxonomy")
    func exposesExactTaxonomy() {
        let values: Set<AxisSemantic> = [
            .spatialX,
            .spatialY,
            .spatialZ,
            .time,
            .cardiacPhase,
            .respiratoryPhase,
            .energy,
            .echo,
            .diffusionDirection,
            .channel,
            .component,
            .ensemble,
            .generic(namespace: "org.voxelia", name: "custom"),
        ]

        #expect(values.count == 13)
        #expect(
            AxisSemantic.generic(namespace: "org.voxelia", name: "custom")
                != .generic(namespace: "org.voxelia", name: "Custom")
        )
    }

    @Test("[Unit][VOX-API-004] Codable uses stable strings and the generic object")
    func codableUsesDocumentedWire() throws {
        let simpleValues: [(semantic: AxisSemantic, token: String)] = [
            (.spatialX, "spatialX"),
            (.spatialY, "spatialY"),
            (.spatialZ, "spatialZ"),
            (.time, "time"),
            (.cardiacPhase, "cardiacPhase"),
            (.respiratoryPhase, "respiratoryPhase"),
            (.energy, "energy"),
            (.echo, "echo"),
            (.diffusionDirection, "diffusionDirection"),
            (.channel, "channel"),
            (.component, "component"),
            (.ensemble, "ensemble"),
        ]
        for simpleValue in simpleValues {
            let data = try JSONEncoder().encode(simpleValue.semantic)
            #expect(String(decoding: data, as: UTF8.self) == #""\#(simpleValue.token)""#)
            #expect(
                try JSONDecoder().decode(AxisSemantic.self, from: data)
                    == simpleValue.semantic
            )
        }

        let generic = AxisSemantic.generic(namespace: "org.voxelia", name: "custom")
        let genericData = try JSONEncoder().encode(generic)
        let genericObject = try #require(
            JSONSerialization.jsonObject(with: genericData)
                as? [String: [String: String]]
        )
        #expect(
            genericObject == [
                "generic": ["namespace": "org.voxelia", "name": "custom"]
            ])
        #expect(try JSONDecoder().decode(AxisSemantic.self, from: genericData) == generic)
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        let rootCorruptedValues = [
            #""unknown""#,
            #""SpatialX""#,
            #""generic""#,
            #"{}"#,
            #"{"unexpected":{"namespace":"org.voxelia","name":"custom"}}"#,
            #"{"generic":{"namespace":"org.voxelia","name":"custom"},"extra":true}"#,
        ]
        for rootCorruptedValue in rootCorruptedValues {
            do {
                _ = try JSONDecoder().decode(
                    AxisSemantic.self,
                    from: Data(rootCorruptedValue.utf8)
                )
                #expect(Bool(false), "Expected a malformed semantic to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        let genericCorruptedValues = [
            #"{"generic":{"namespace":"org.voxelia"}}"#,
            #"{"generic":{"name":"custom"}}"#,
            #"{"generic":{"namespace":"org.voxelia","name":"custom","extra":true}}"#,
        ]
        for genericCorruptedValue in genericCorruptedValues {
            do {
                _ = try JSONDecoder().decode(
                    AxisSemantic.self,
                    from: Data(genericCorruptedValue.utf8)
                )
                #expect(Bool(false), "Expected a malformed generic to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.map(\.stringValue) == ["generic"])
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        do {
            _ = try JSONDecoder().decode(AxisSemantic.self, from: Data("null".utf8))
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // The keyed-container request rejects null after the string branch.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in ["1", "true", "[]", #"{"generic":"custom"}"#] {
            do {
                _ = try JSONDecoder().decode(
                    AxisSemantic.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped semantic to fail decoding.")
            } catch DecodingError.typeMismatch {
                // Non-object shapes and the string-valued generic are rejected.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }
    }

    @Test("[Unit][VOX-API-003] values remain Sendable and Hashable")
    func remainsSendableAndHashable() {
        requireSendable(AxisSemantic.self)
        #expect(Set([AxisSemantic.time, .time, .echo]).count == 2)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
