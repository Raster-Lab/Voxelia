// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaGeometry

@Suite("TriangleMesh")
struct TriangleMeshTests {
    @Test("[Unit][VOX-GEO-001][VOX-GEO-002] positions preserve space and exact finite triples")
    func positionsPreserveSpaceAndExactFiniteTriples() throws {
        let coordinateSpace = try space()
        let empty = try TriangleMeshPositionDomain(
            coordinateSpace: coordinateSpace,
            components: []
        )
        #expect(empty.vertexCount == 0)
        #expect(empty.components.isEmpty)
        #expect(empty.coordinateSpace == coordinateSpace)

        let supplied: ContiguousArray<Double> = [-0.0, 1, 2, 3, 4, 5]
        let positions = try TriangleMeshPositionDomain(
            coordinateSpace: coordinateSpace,
            components: supplied
        )
        #expect(positions.vertexCount == 2)
        #expect(positions.components.count == supplied.count)
        for index in supplied.indices {
            #expect(
                positions.components[index].bitPattern
                    == supplied[index].bitPattern
            )
        }
        #expect(positions.components[0].bitPattern == (-0.0).bitPattern)
    }

    @Test("[Unit][VOX-ERR-001] position admission is complete before finite")
    func positionAdmissionPrecedence() throws {
        let coordinateSpace = try space()
        #expect(throws: TriangleMeshPositionDomainError.incompleteVertex) {
            try TriangleMeshPositionDomain(
                coordinateSpace: coordinateSpace,
                components: [.nan]
            )
        }
        for components: ContiguousArray<Double> in [
            [.nan, 0, 0],
            [.infinity, 0, 0],
            [-.infinity, 0, 0],
        ] {
            #expect(throws: TriangleMeshPositionDomainError.nonFinitePosition) {
                try TriangleMeshPositionDomain(
                    coordinateSpace: coordinateSpace,
                    components: components
                )
            }
        }
    }

    @Test("[Unit][VOX-GEO-003][VOX-GEO-004] attributes preserve defined layouts and bytes")
    func attributesPreserveDefinedLayoutsAndBytes() throws {
        let interleavedDescriptor = try descriptor(
            semantic: .normal,
            scalarType: .uint16,
            componentCount: 3,
            layout: .interleaved,
            elementCount: 2
        )
        let interleavedBytes: ContiguousArray<UInt8> = [
            0, 1, 2, 3, 4, 5,
            6, 7, 8, 9, 10, 11,
        ]
        let interleaved = try TriangleMeshVertexAttribute(
            descriptor: interleavedDescriptor,
            bytes: interleavedBytes
        )
        #expect(interleaved.descriptor == interleavedDescriptor)
        #expect(interleaved.bytes == interleavedBytes)

        let planarDescriptor = try descriptor(
            semantic: .colour,
            scalarType: .uint8,
            componentCount: 4,
            layout: .planar,
            elementCount: 2
        )
        let planarBytes: ContiguousArray<UInt8> = [
            0, 1,
            2, 3,
            4, 5,
            6, 7,
        ]
        let planar = try TriangleMeshVertexAttribute(
            descriptor: planarDescriptor,
            bytes: planarBytes
        )
        #expect(planar.descriptor == planarDescriptor)
        #expect(planar.bytes == planarBytes)

        let emptyDescriptor = try descriptor(
            semantic: .label,
            scalarType: .uint64,
            componentCount: 1,
            layout: .interleaved,
            elementCount: 0
        )
        let empty = try TriangleMeshVertexAttribute(
            descriptor: emptyDescriptor,
            bytes: []
        )
        #expect(empty.bytes.isEmpty)
    }

    @Test("[Unit][VOX-SEC-001][VOX-ERR-001] attribute admission is fail-closed in fixed order")
    func attributeAdmissionPrecedenceAndOverflow() throws {
        let reservedDescriptor = try descriptor(
            semantic: .position,
            scalarType: .uint64,
            componentCount: 3,
            layout: .storageDefined,
            elementCount: Int.max
        )
        #expect(
            throws: TriangleMeshVertexAttributeError.positionSemanticReserved
        ) {
            try TriangleMeshVertexAttribute(
                descriptor: reservedDescriptor,
                bytes: []
            )
        }

        let undefinedDescriptor = try descriptor(
            semantic: .normal,
            scalarType: .uint64,
            componentCount: 3,
            layout: .storageDefined,
            elementCount: Int.max
        )
        #expect(
            throws: TriangleMeshVertexAttributeError.undefinedComponentLayout
        ) {
            try TriangleMeshVertexAttribute(
                descriptor: undefinedDescriptor,
                bytes: []
            )
        }

        let overflowingDescriptor = try descriptor(
            semantic: .normal,
            scalarType: .uint64,
            componentCount: 2,
            layout: .interleaved,
            elementCount: Int.max
        )
        #expect(throws: TriangleMeshVertexAttributeError.byteCountOverflow) {
            try TriangleMeshVertexAttribute(
                descriptor: overflowingDescriptor,
                bytes: []
            )
        }

        let byteProductOverflowDescriptor = try descriptor(
            semantic: .label,
            scalarType: .uint64,
            componentCount: 1,
            layout: .planar,
            elementCount: Int.max / 2
        )
        #expect(throws: TriangleMeshVertexAttributeError.byteCountOverflow) {
            try TriangleMeshVertexAttribute(
                descriptor: byteProductOverflowDescriptor,
                bytes: []
            )
        }

        let mismatchedDescriptor = try descriptor(
            semantic: .normal,
            scalarType: .uint16,
            componentCount: 3,
            layout: .interleaved,
            elementCount: 1
        )
        #expect(throws: TriangleMeshVertexAttributeError.byteCountMismatch) {
            try TriangleMeshVertexAttribute(
                descriptor: mismatchedDescriptor,
                bytes: [0, 1, 2, 3, 4]
            )
        }
    }

    @Test("[Unit][VOX-GEO-002][VOX-GEO-003][VOX-GEO-005] binds independent mesh domains")
    func bindsIndependentMeshDomains() throws {
        let coordinateSpace = try space()
        let positions = try TriangleMeshPositionDomain(
            coordinateSpace: coordinateSpace,
            components: [
                0, 0, 0,
                1, 0, 0,
                0, 1, 0,
            ]
        )
        let topology = try TriangleMeshTopology(
            vertexCount: 3,
            indices: [0, 1, 2]
        )
        let normalBytes = ContiguousArray<UInt8>(repeating: 0, count: 72)
        let normal = try TriangleMeshVertexAttribute(
            descriptor: try descriptor(
                semantic: .normal,
                scalarType: .float64,
                componentCount: 3,
                layout: .interleaved,
                elementCount: 3
            ),
            bytes: normalBytes
        )
        let labels = try TriangleMeshVertexAttribute(
            descriptor: try descriptor(
                semantic: .label,
                scalarType: .uint8,
                componentCount: 1,
                layout: .planar,
                elementCount: 3
            ),
            bytes: [4, 5, 6]
        )

        let mesh = try TriangleMesh(
            positions: positions,
            topology: topology,
            vertexAttributes: [normal, labels]
        )
        #expect(mesh.coordinateSpace == coordinateSpace)
        #expect(mesh.positions.components == positions.components)
        #expect(mesh.topology.indices == [0, 1, 2])
        #expect(mesh.vertexAttributes.count == 2)
        #expect(mesh.vertexAttributes[0].descriptor.semantic == .normal)
        #expect(mesh.vertexAttributes[0].bytes == normalBytes)
        #expect(mesh.vertexAttributes[1].descriptor.semantic == .label)
        #expect(mesh.vertexAttributes[1].bytes == [4, 5, 6])

        let empty = try TriangleMesh(
            positions: try TriangleMeshPositionDomain(
                coordinateSpace: coordinateSpace,
                components: []
            ),
            topology: try TriangleMeshTopology(vertexCount: 0, indices: []),
            vertexAttributes: []
        )
        #expect(empty.positions.vertexCount == 0)
        #expect(empty.topology.triangleCount == 0)
        #expect(empty.vertexAttributes.isEmpty)
    }

    @Test("[Unit][VOX-ERR-001] mesh binding follows fixed precedence")
    func meshBindingPrecedence() throws {
        let positions = try TriangleMeshPositionDomain(
            coordinateSpace: try space(),
            components: [
                0, 0, 0,
                1, 0, 0,
                0, 1, 0,
            ]
        )
        let mismatchedAttribute = try attribute(
            semantic: .normal,
            elementCount: 2,
            componentCount: 1
        )
        #expect(throws: TriangleMeshError.vertexCountMismatch) {
            try TriangleMesh(
                positions: positions,
                topology: try TriangleMeshTopology(vertexCount: 2, indices: []),
                vertexAttributes: [mismatchedAttribute, mismatchedAttribute]
            )
        }

        let topology = try TriangleMeshTopology(
            vertexCount: 3,
            indices: [0, 1, 2]
        )
        #expect(throws: TriangleMeshError.attributeCountMismatch) {
            try TriangleMesh(
                positions: positions,
                topology: topology,
                vertexAttributes: [mismatchedAttribute, mismatchedAttribute]
            )
        }

        let first = try attribute(
            semantic: .normal,
            elementCount: 3,
            componentCount: 1
        )
        let duplicate = try attribute(
            semantic: .normal,
            elementCount: 3,
            componentCount: 2
        )
        #expect(throws: TriangleMeshError.duplicateAttributeSemantic) {
            try TriangleMesh(
                positions: positions,
                topology: topology,
                vertexAttributes: [first, duplicate]
            )
        }
    }

    @Test("[Unit][VOX-API-003][VOX-API-010] values and errors transfer safely")
    func valuesAndErrorsAreSendable() async throws {
        requireSendable(TriangleMeshPositionDomain.self)
        requireSendable(TriangleMeshPositionDomainError.self)
        requireSendable(TriangleMeshVertexAttribute.self)
        requireSendable(TriangleMeshVertexAttributeError.self)
        requireSendable(TriangleMesh.self)
        requireSendable(TriangleMeshError.self)

        let positions = try TriangleMeshPositionDomain(
            coordinateSpace: try space(),
            components: [
                0, 0, 0,
                1, 0, 0,
                0, 1, 0,
            ]
        )
        let mesh = try TriangleMesh(
            positions: positions,
            topology: try TriangleMeshTopology(
                vertexCount: 3,
                indices: [0, 1, 2]
            ),
            vertexAttributes: []
        )

        let observation = await Task.detached {
            (
                mesh.positions.vertexCount,
                mesh.topology.triangleCount,
                mesh.vertexAttributes.count
            )
        }.value
        #expect(observation.0 == 3)
        #expect(observation.1 == 1)
        #expect(observation.2 == 0)
        #expect(
            TriangleMeshPositionDomainError.nonFinitePosition
                == .nonFinitePosition
        )
        #expect(
            TriangleMeshVertexAttributeError.byteCountOverflow
                == .byteCountOverflow
        )
        #expect(
            TriangleMeshError.duplicateAttributeSemantic
                == .duplicateAttributeSemantic
        )
    }

    private func space() throws -> CoordinateSpaceDescriptor {
        guard let id = CoordinateSpaceID(rawValue: "patient") else {
            throw FixtureError.invalidCoordinateSpaceID
        }
        return try CoordinateSpaceDescriptor(
            id: id,
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                dimension: .length
            ),
            externalReferences: []
        )
    }

    private func descriptor(
        semantic: GeometryAttributeSemantic,
        scalarType: ScalarType,
        componentCount: Int,
        layout: ComponentLayout,
        elementCount: Int
    ) throws -> GeometryAttributeDescriptor {
        try GeometryAttributeDescriptor(
            semantic: semantic,
            scalarFormat: ScalarFormat(
                type: scalarType,
                validBitCount: nil,
                byteOrder: .littleEndian
            ),
            components: ComponentDescriptor(
                count: componentCount,
                interpretation: .vector,
                layout: layout
            ),
            elementCount: elementCount
        )
    }

    private func attribute(
        semantic: GeometryAttributeSemantic,
        elementCount: Int,
        componentCount: Int
    ) throws -> TriangleMeshVertexAttribute {
        try TriangleMeshVertexAttribute(
            descriptor: try descriptor(
                semantic: semantic,
                scalarType: .uint8,
                componentCount: componentCount,
                layout: .interleaved,
                elementCount: elementCount
            ),
            bytes: ContiguousArray<UInt8>(
                repeating: 0,
                count: elementCount * componentCount
            )
        )
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}

    private enum FixtureError: Error {
        case invalidCoordinateSpaceID
    }
}
