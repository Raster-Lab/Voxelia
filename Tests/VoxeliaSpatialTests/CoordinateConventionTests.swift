// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("CoordinateConvention")
struct CoordinateConventionTests {
    @Test("[Unit][CDMS-21.3][VOX-SPA-001] exposes the exact convention taxonomy")
    func exposesExactTaxonomy() {
        let values: Set<CoordinateConvention> = [
            .cartesianRightHanded,
            .cartesianLeftHanded,
            .dicomPatientLPS,
            .neuroimagingRAS,
            .imageDisplay,
            .custom(namespace: "org.voxelia", name: "scanner"),
        ]

        #expect(values.count == 6)
    }

    @Test("[Unit][VOX-SPA-005] custom identity is case-sensitive exact UTF-8")
    func customIdentityIsExact() {
        let value = CoordinateConvention.custom(
            namespace: "org.voxelia",
            name: "scanner"
        )

        #expect(value != .custom(namespace: "org.voxelia", name: "Scanner"))
        #expect(value != .custom(namespace: "org.Voxelia", name: "scanner"))
        #expect(
            Set([
                value,
                .custom(namespace: "org.voxelia", name: "scanner"),
                .custom(namespace: "org.voxelia", name: "Scanner"),
            ]).count == 2
        )
    }

    @Test("[Unit][VOX-SPA-006][VOX-SPA-007] built-in handedness matrix is complete")
    func handednessMatrixIsComplete() {
        let expectations: [(convention: CoordinateConvention, handedness: CoordinateHandedness?)] =
            [
                (.cartesianRightHanded, .rightHanded),
                (.dicomPatientLPS, .rightHanded),
                (.neuroimagingRAS, .rightHanded),
                (.cartesianLeftHanded, .leftHanded),
                (.imageDisplay, nil),
                (.custom(namespace: "org.voxelia", name: "scanner"), nil),
            ]

        for expectation in expectations {
            #expect(expectation.convention.impliedHandedness == expectation.handedness)
        }
    }

    @Test("[Unit][VOX-API-004] Codable uses stable strings and the custom object")
    func codableUsesDocumentedWire() throws {
        let builtInValues: [(convention: CoordinateConvention, token: String)] = [
            (.cartesianRightHanded, "cartesianRightHanded"),
            (.cartesianLeftHanded, "cartesianLeftHanded"),
            (.dicomPatientLPS, "dicomPatientLPS"),
            (.neuroimagingRAS, "neuroimagingRAS"),
            (.imageDisplay, "imageDisplay"),
        ]
        for builtInValue in builtInValues {
            let data = try JSONEncoder().encode(builtInValue.convention)
            #expect(String(decoding: data, as: UTF8.self) == #""\#(builtInValue.token)""#)
            #expect(
                try JSONDecoder().decode(CoordinateConvention.self, from: data)
                    == builtInValue.convention
            )
        }

        let custom = CoordinateConvention.custom(
            namespace: "org.voxelia",
            name: "scanner"
        )
        let customData = try JSONEncoder().encode(custom)
        let customObject = try #require(
            JSONSerialization.jsonObject(with: customData)
                as? [String: [String: String]]
        )
        #expect(
            customObject == [
                "custom": ["namespace": "org.voxelia", "name": "scanner"]
            ])
        #expect(
            try JSONDecoder().decode(CoordinateConvention.self, from: customData)
                == custom
        )
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        let rootCorruptedValues = [
            #""unknown""#,
            #""CartesianRightHanded""#,
            #""custom""#,
            #"{}"#,
            #"{"unexpected":{"namespace":"org.voxelia","name":"scanner"}}"#,
            #"{"custom":{"namespace":"org.voxelia","name":"scanner"},"extra":true}"#,
        ]
        for rootCorruptedValue in rootCorruptedValues {
            do {
                _ = try JSONDecoder().decode(
                    CoordinateConvention.self,
                    from: Data(rootCorruptedValue.utf8)
                )
                #expect(Bool(false), "Expected a malformed convention to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        let customCorruptedValues = [
            #"{"custom":{"namespace":"org.voxelia"}}"#,
            #"{"custom":{"name":"scanner"}}"#,
            #"{"custom":{"namespace":"org.voxelia","name":"scanner","extra":true}}"#,
        ]
        for customCorruptedValue in customCorruptedValues {
            do {
                _ = try JSONDecoder().decode(
                    CoordinateConvention.self,
                    from: Data(customCorruptedValue.utf8)
                )
                #expect(Bool(false), "Expected a malformed custom to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.map(\.stringValue) == ["custom"])
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        do {
            _ = try JSONDecoder().decode(
                CoordinateConvention.self,
                from: Data("null".utf8)
            )
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // The keyed-container request rejects null after the string branch.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in ["1", "true", "[]", #"{"custom":"scanner"}"#] {
            do {
                _ = try JSONDecoder().decode(
                    CoordinateConvention.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped convention to fail decoding.")
            } catch DecodingError.typeMismatch {
                // Non-object shapes and the string-valued custom are rejected.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }
    }

    @Test("[Unit][VOX-API-003] values remain Sendable and Hashable")
    func remainsSendableAndHashable() {
        requireSendable(CoordinateConvention.self)
        #expect(
            Set([
                CoordinateConvention.dicomPatientLPS,
                .dicomPatientLPS,
                .neuroimagingRAS,
            ]).count == 2
        )
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
