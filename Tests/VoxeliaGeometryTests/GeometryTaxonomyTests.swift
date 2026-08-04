// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaGeometry

@Suite("GeometryTaxonomy")
struct GeometryTaxonomyTests {
    @Test("[Unit][VOX-ARC-007][VOX-GEO-001] exposes exact geometry kinds")
    func exposesExactGeometryKinds() throws {
        let expected: [(value: GeometryKind, tag: String)] = [
            (.pointSet, "pointSet"),
            (.lineSet, "lineSet"),
            (.polylineSet, "polylineSet"),
            (.centreLine, "centreLine"),
            (.triangleMesh, "triangleMesh"),
            (.polygonMesh, "polygonMesh"),
            (.boundingVolume, "boundingVolume"),
        ]

        try verifyRawTaxonomy(expected)
        #expect(GeometryKind(rawValue: "centerLine") == nil)
        #expect(GeometryKind(rawValue: "PointSet") == nil)
    }

    @Test("[Unit][VOX-GEO-003] exposes exact mesh primitives")
    func exposesExactMeshPrimitives() throws {
        let expected: [(value: MeshPrimitive, tag: String)] = [
            (.points, "points"),
            (.lines, "lines"),
            (.lineStrip, "lineStrip"),
            (.triangles, "triangles"),
            (.triangleStrip, "triangleStrip"),
            (.polygons, "polygons"),
        ]

        try verifyRawTaxonomy(expected)
        #expect(MeshPrimitive(rawValue: "linestrip") == nil)
        #expect(MeshPrimitive(rawValue: "Triangles") == nil)
    }

    @Test("[Unit][VOX-GEO-003][VOX-API-004] exposes exact index types")
    func exposesExactIndexTypes() throws {
        let expected: [(value: IndexType, tag: String)] = [
            (.uint16, "uint16"),
            (.uint32, "uint32"),
            (.uint64, "uint64"),
        ]

        try verifyRawTaxonomy(expected)
        #expect(IndexType(rawValue: "UInt16") == nil)
        #expect(IndexType(rawValue: "int32") == nil)
    }

    @Test("[Unit][VOX-GEO-004][VOX-API-004] encodes exact built-in semantics")
    func encodesExactBuiltInSemantics() throws {
        let expected: [(value: GeometryAttributeSemantic, tag: String)] = [
            (.position, "position"),
            (.normal, "normal"),
            (.tangent, "tangent"),
            (.colour, "colour"),
            (.textureCoordinate, "textureCoordinate"),
            (.scalarValue, "scalarValue"),
            (.label, "label"),
            (.confidence, "confidence"),
        ]

        for item in expected {
            let encoded = try JSONEncoder().encode(item.value)
            #expect(String(decoding: encoded, as: UTF8.self) == #""\#(item.tag)""#)
            #expect(
                try JSONDecoder().decode(
                    GeometryAttributeSemantic.self,
                    from: encoded
                ) == item.value
            )
        }
    }

    @Test("[Unit][VOX-GEO-004][VOX-API-004] custom semantics use a strict object")
    func customSemanticsUseStrictObject() throws {
        let semantic = GeometryAttributeSemantic.custom(
            namespace: "org.voxelia",
            name: "curvature"
        )
        let encoded = try JSONEncoder().encode(semantic)
        let object = try #require(
            JSONSerialization.jsonObject(with: encoded)
                as? [String: [String: String]]
        )

        #expect(
            object == [
                "custom": [
                    "namespace": "org.voxelia",
                    "name": "curvature",
                ]
            ]
        )
        #expect(
            try JSONDecoder().decode(
                GeometryAttributeSemantic.self,
                from: encoded
            ) == semantic
        )

        let empty = GeometryAttributeSemantic.custom(namespace: "", name: "")
        let emptyData = try JSONEncoder().encode(empty)
        #expect(
            try JSONDecoder().decode(
                GeometryAttributeSemantic.self,
                from: emptyData
            ) == empty
        )
    }

    @Test("[Unit][VOX-API-003] custom identity preserves exact UTF-8")
    func customIdentityPreservesExactUTF8() throws {
        let composed = "caf\u{00E9}"
        let decomposed = "cafe\u{0301}"
        let values: [GeometryAttributeSemantic] = [
            .custom(namespace: composed, name: "curvature"),
            .custom(namespace: decomposed, name: "curvature"),
            .custom(namespace: "org.voxelia", name: composed),
            .custom(namespace: "org.voxelia", name: decomposed),
        ]

        #expect(Set(values).count == values.count)

        for value in values {
            let encoded = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(
                GeometryAttributeSemantic.self,
                from: encoded
            )
            #expect(decoded == value)

            let originalParts = try customParts(of: value)
            let decodedParts = try customParts(of: decoded)
            #expect(
                Array(originalParts.namespace.utf8)
                    == Array(decodedParts.namespace.utf8)
            )
            #expect(Array(originalParts.name.utf8) == Array(decodedParts.name.utf8))
        }
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] rejects unknown or malformed taxonomy values")
    func rejectsUnknownOrMalformedValues() {
        expectExactInvalidRawValueDecoding(GeometryKind.self)
        expectExactInvalidRawValueDecoding(MeshPrimitive.self)
        expectExactInvalidRawValueDecoding(IndexType.self)

        let rootCorruptedValues = [
            #""Position""#,
            #""custom""#,
            #"{}"#,
            #"{"unexpected":{"namespace":"org.voxelia","name":"value"}}"#,
            #"{"custom":{"namespace":"org.voxelia","name":"value"},"extra":true}"#,
        ]
        for rootCorruptedValue in rootCorruptedValues {
            expectSemanticDataCorruptedDecoding(json: rootCorruptedValue, path: [])
        }

        let customCorruptedValues = [
            #"{"custom":{"namespace":"org.voxelia"}}"#,
            #"{"custom":{"name":"value"}}"#,
            #"{"custom":{"namespace":"org.voxelia","name":"value","extra":true}}"#,
        ]
        for customCorruptedValue in customCorruptedValues {
            expectSemanticDataCorruptedDecoding(
                json: customCorruptedValue,
                path: ["custom"]
            )
        }

        do {
            _ = try JSONDecoder().decode(
                GeometryAttributeSemantic.self,
                from: Data("null".utf8)
            )
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // The keyed-container request rejects null after the string branch.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in ["1", "true", "[]", #"{"custom":"value"}"#] {
            do {
                _ = try JSONDecoder().decode(
                    GeometryAttributeSemantic.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped semantic to fail decoding.")
            } catch DecodingError.typeMismatch {
                // Non-object shapes and the string-valued custom payload are rejected.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }
    }

    private func expectExactInvalidRawValueDecoding<Value: Decodable>(
        _ type: Value.Type
    ) {
        do {
            _ = try JSONDecoder().decode(type, from: Data(#""unknown""#.utf8))
            #expect(Bool(false), "Expected an unknown token to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.isEmpty)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        do {
            _ = try JSONDecoder().decode(type, from: Data("null".utf8))
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // Null is rejected for the non-optional raw value.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in ["1", "true", "{}", "[]"] {
            do {
                _ = try JSONDecoder().decode(type, from: Data(wrongShape.utf8))
                #expect(Bool(false), "Expected a wrong-shaped value to fail decoding.")
            } catch DecodingError.typeMismatch {
                // Non-string shapes are rejected before raw-value lookup.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }
    }

    private func expectSemanticDataCorruptedDecoding(json: String, path: [String]) {
        do {
            _ = try JSONDecoder().decode(
                GeometryAttributeSemantic.self,
                from: Data(json.utf8)
            )
            #expect(Bool(false), "Expected a malformed semantic to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == path)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    @Test("[Unit][VOX-API-003] taxonomies remain Sendable and Hashable")
    func taxonomiesRemainSendableAndHashable() {
        requireSendable(GeometryKind.self)
        requireSendable(GeometryAttributeSemantic.self)
        requireSendable(MeshPrimitive.self)
        requireSendable(IndexType.self)

        #expect(
            Set<GeometryKind>([
                .pointSet,
                .lineSet,
                .polylineSet,
                .centreLine,
                .triangleMesh,
                .polygonMesh,
                .boundingVolume,
            ]).count == 7
        )
        #expect(
            Set<GeometryAttributeSemantic>([
                .position,
                .normal,
                .tangent,
                .colour,
                .textureCoordinate,
                .scalarValue,
                .label,
                .confidence,
                .custom(namespace: "org.voxelia", name: "curvature"),
            ]).count == 9
        )
        #expect(
            Set<MeshPrimitive>([
                .points,
                .lines,
                .lineStrip,
                .triangles,
                .triangleStrip,
                .polygons,
            ]).count == 6
        )
        #expect(Set<IndexType>([.uint16, .uint32, .uint64]).count == 3)
    }

    private func verifyRawTaxonomy<Value>(
        _ expected: [(value: Value, tag: String)]
    ) throws where Value: Codable & Hashable & RawRepresentable, Value.RawValue == String {
        for item in expected {
            #expect(item.value.rawValue == item.tag)
            #expect(Value(rawValue: item.tag) == item.value)

            let encoded = try JSONEncoder().encode(item.value)
            #expect(String(decoding: encoded, as: UTF8.self) == #""\#(item.tag)""#)
            #expect(try JSONDecoder().decode(Value.self, from: encoded) == item.value)
        }
    }

    private func customParts(
        of semantic: GeometryAttributeSemantic
    ) throws -> (namespace: String, name: String) {
        guard case .custom(let namespace, let name) = semantic else {
            throw UnexpectedSemanticError()
        }
        return (namespace, name)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}

    private struct UnexpectedSemanticError: Error {}
}
