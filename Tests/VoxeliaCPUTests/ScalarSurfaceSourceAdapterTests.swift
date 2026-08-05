// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

@testable import VoxeliaCPU

@Suite("CPU scalar-surface source adapter")
struct ScalarSurfaceSourceAdapterTests {
    @Test("[Unit][VOX-ERR-001] admission follows cancellation-first precedence")
    func admissionPrecedence() async throws {
        let valid = try ScalarSurfaceTestSupport.fixture()
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        let invalidRequest = ScalarSurfaceTestSupport.request(
            fixture: valid,
            isovalue: .nan,
            maximumVertexCount: 0,
            maximumTriangleCount: 0
        )
        await #expect(throws: ScalarSurfaceExtractionError.cancelled) {
            try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: invalidRequest,
                coordinator: coordinator,
                cancellation: { $0 == .admission }
            )
        }
        #expect(valid.owner.readCount == 0)

        await #expect(throws: ScalarSurfaceExtractionError.invalidLimits) {
            try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: invalidRequest,
                coordinator: coordinator
            )
        }
        #expect(valid.owner.readCount == 0)

        let rankTwo = try ScalarSurfaceTestSupport.fixture(
            extents: [2, 2],
            values: [1, 0, 0, 0],
            spatialAxes: [0, 1]
        )
        await #expect(throws: ScalarSurfaceExtractionError.unsupportedSource) {
            try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: ScalarSurfaceTestSupport.request(
                    fixture: rankTwo,
                    isovalue: .nan
                ),
                coordinator: coordinator
            )
        }
        #expect(rankTwo.owner.readCount == 0)

        await #expect(throws: ScalarSurfaceExtractionError.nonFiniteIsovalue) {
            try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: ScalarSurfaceTestSupport.request(
                    fixture: valid,
                    isovalue: .infinity
                ),
                coordinator: coordinator
            )
        }
        #expect(valid.owner.readCount == 0)
    }

    @Test(
        "[Unit][VOX-GEO-007] non-scalar component interpretations reject before reading",
        arguments: [
            ComponentInterpretation.vector,
            .tensor,
            .complex,
            .labelProbability,
            .generic(namespace: "test", name: "generic"),
        ]
    )
    func rejectsNonScalarInterpretation(
        interpretation: ComponentInterpretation
    ) async throws {
        let fixture = try ScalarSurfaceTestSupport.fixture(
            interpretation: interpretation
        )
        try await expectUnsupportedBeforeRead(fixture)
    }

    @Test("[Unit][VOX-GEO-007] colour component interpretations reject before reading")
    func rejectsColourInterpretations() async throws {
        for fixture in try [
            ScalarSurfaceTestSupport.fixture(
                componentCount: 3,
                interpretation: .rgb,
                semantic: .colour
            ),
            ScalarSurfaceTestSupport.fixture(
                componentCount: 4,
                interpretation: .rgba,
                semantic: .colour
            ),
        ] {
            try await expectUnsupportedBeforeRead(fixture)
        }
    }

    @Test(
        "[Unit][VOX-GEO-007] unsupported image semantics reject before reading",
        arguments: [
            ImageSemantic.label,
            .vectorField,
            .deformationField,
            .tensor,
            .mask,
            .generic(namespace: "test", name: "generic"),
        ]
    )
    func rejectsUnsupportedSemantic(semantic: ImageSemantic) async throws {
        let fixture = try ScalarSurfaceTestSupport.fixture(semantic: semantic)
        try await expectUnsupportedBeforeRead(fixture)
    }

    @Test(
        "[Unit][VOX-GEO-007] every accepted image semantic produces the same scalar mesh",
        arguments: [
            ImageSemantic.intensity,
            .probability,
            .parametric,
        ]
    )
    func acceptsScalarSemantic(semantic: ImageSemantic) async throws {
        let fixture = try ScalarSurfaceTestSupport.fixture(semantic: semantic)
        let mesh = try await extract(fixture)
        #expect(
            mesh.positions.components
                == ScalarSurfaceTestSupport.singleCornerPositions
        )
        #expect(
            mesh.topology.indices
                == ScalarSurfaceTestSupport.singleCornerIndices
        )
    }

    @Test("[Unit][VOX-GEO-007][VOX-SEC-001] geometry and scalar source admission is closed")
    func rejectsUnsupportedGeometryAndScalarContainers() async throws {
        let missingGeometry = try ScalarSurfaceTestSupport.fixture(
            includesGeometry: false
        )
        let partialMapping = try ScalarSurfaceTestSupport.fixture(
            spatialAxes: [0, 1]
        )
        let maximum = Double.greatestFiniteMagnitude
        let infiniteDeterminant = try ScalarSurfaceTestSupport.fixture(
            matrixElements: [
                maximum, 0, 0, 0,
                0, maximum, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ]
        )
        let oversizedIndex = try ScalarSurfaceTestSupport.fixture(
            extents: [9_007_199_254_740_994, 1, 1],
            values: [0],
            allocateBytes: false
        )
        let int64 = try ScalarSurfaceTestSupport.fixture(
            scalarType: .int64
        )
        let uint64 = try ScalarSurfaceTestSupport.fixture(
            scalarType: .uint64
        )

        for fixture in [
            missingGeometry,
            partialMapping,
            infiniteDeterminant,
            oversizedIndex,
            int64,
            uint64,
        ] {
            try await expectUnsupportedBeforeRead(fixture)
        }
    }

    @Test("[Unit][VOX-GEO-007] valid-bit metadata never invents bit placement")
    func validBitMetadataPreservesContainerDecoding() async throws {
        let fixture = try ScalarSurfaceTestSupport.fixture(
            scalarType: .uint16,
            validBitCount: 12
        )
        let mesh = try await extract(fixture)
        #expect(
            mesh.positions.components
                == ScalarSurfaceTestSupport.singleCornerPositions
        )
    }

    @Test("[Unit][VOX-GEO-006] absent, identity, linear, table and composed transforms are exact")
    func acceptedValueTransforms() async throws {
        let linear = try LinearValueTransformDescriptor(
            scale: 2,
            offset: -1
        )
        let table = try LookupTableDescriptor(
            firstMappedValue: 0,
            values: [-1, 1]
        )
        let secondLinear = try LinearValueTransformDescriptor(
            scale: 0.5,
            offset: 0
        )
        let tableChain = try ValueTransformComposition(
            transforms: [
                .identity,
                .lookupTable(table),
                .linear(secondLinear),
            ]
        )
        let linearChain = try ValueTransformComposition(
            transforms: [
                .linear(linear),
                .linear(
                    try LinearValueTransformDescriptor(
                        scale: 1,
                        offset: 0
                    )
                ),
            ]
        )

        let cases: [(ValueTransform?, Double)] = [
            (nil, 0.5),
            (.identity, 0.5),
            (.linear(linear), 0),
            (.lookupTable(table), 0),
            (.composed(tableChain), 0),
            (.composed(linearChain), 0),
        ]
        for (transform, isovalue) in cases {
            let fixture = try ScalarSurfaceTestSupport.fixture(
                valueTransform: transform
            )
            let mesh = try await extract(fixture, isovalue: isovalue)
            #expect(
                mesh.positions.components
                    == ScalarSurfaceTestSupport.singleCornerPositions
            )
            #expect(
                mesh.topology.indices
                    == ScalarSurfaceTestSupport.singleCornerIndices
            )
        }
    }

    @Test("[Unit][VOX-GEO-006] linear transforms retain separate binary64 rounding")
    func linearTransformDoesNotFuseMultiplyAndAdd() throws {
        let storedValue = 1.0 + 0x1p-27
        let scale = 1.0 - 0x1p-27
        let transform = try LinearValueTransformDescriptor(
            scale: scale,
            offset: -1
        )
        let fixture = try ScalarSurfaceTestSupport.fixture(
            scalarType: .float64,
            values: [storedValue, 0, 0, 0, 0, 0, 0, 0],
            valueTransform: .linear(transform)
        )
        let request = ScalarSurfaceTestSupport.request(fixture: fixture)
        let admission = try ScalarSurfaceSourceAdmission(request: request)
        let adapter = try ScalarSurfaceSourceAdapter(
            request: request,
            admission: admission,
            bytes: fixture.owner.bytes
        )

        #expect(try adapter.authoritativeValue(at: 0).bitPattern == 0)
        #expect(
            (-1.0).addingProduct(storedValue, scale).bitPattern
                == 0xbc90_0000_0000_0000
        )
    }

    @Test("[Unit][VOX-GEO-006] integer extremes and table-overflow clamps are exact")
    func integerExtremesAndTableOverflow() throws {
        let integerFixture = try ScalarSurfaceTestSupport.fixture(
            scalarType: .int32,
            values: [
                Double(Int32.min),
                Double(Int32.max),
                0, 0, 0, 0, 0, 0,
            ]
        )
        let integerRequest = ScalarSurfaceTestSupport.request(
            fixture: integerFixture,
            isovalue: 0
        )
        let integerAdmission = try ScalarSurfaceSourceAdmission(
            request: integerRequest
        )
        let integerAdapter = try ScalarSurfaceSourceAdapter(
            request: integerRequest,
            admission: integerAdmission,
            bytes: integerFixture.owner.bytes
        )
        #expect(
            try integerAdapter.authoritativeValue(at: 0)
                == Double(Int32.min)
        )
        #expect(
            try integerAdapter.authoritativeValue(at: 1)
                == Double(Int32.max)
        )

        let upperClamp = try LookupTableDescriptor(
            firstMappedValue: Int64.min,
            values: [-1, 7]
        )
        let lowerClamp = try LookupTableDescriptor(
            firstMappedValue: Int64.max,
            values: [-7, 1]
        )
        let clampCases: [(LookupTableDescriptor, ScalarType, [Double], Double)] = [
            (upperClamp, .uint8, [1, 0, 0, 0, 0, 0, 0, 0], 7),
            (
                lowerClamp,
                .int32,
                [Double(Int32.min), 0, 0, 0, 0, 0, 0, 0],
                -7
            ),
        ]
        for (table, scalarType, values, expected) in clampCases {
            let fixture = try ScalarSurfaceTestSupport.fixture(
                scalarType: scalarType,
                values: values,
                valueTransform: .lookupTable(table)
            )
            let request = ScalarSurfaceTestSupport.request(fixture: fixture)
            let admission = try ScalarSurfaceSourceAdmission(request: request)
            let adapter = try ScalarSurfaceSourceAdapter(
                request: request,
                admission: admission,
                bytes: fixture.owner.bytes
            )
            #expect(try adapter.authoritativeValue(at: 0) == expected)
        }
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-001] transform admission fails after one released read")
    func rejectsUnsupportedValueTransformsAndReleasesRead() async throws {
        let emptyTable = try LookupTableDescriptor(
            firstMappedValue: 0,
            values: []
        )
        let validTable = try LookupTableDescriptor(
            firstMappedValue: 0,
            values: [0, 1]
        )
        let linear = try LinearValueTransformDescriptor(scale: 1, offset: 0)
        let nested = try ValueTransformComposition(
            transforms: [
                .composed(
                    try ValueTransformComposition(transforms: [.identity])
                )
            ]
        )
        let linearThenTable = try ValueTransformComposition(
            transforms: [.linear(linear), .lookupTable(validTable)]
        )
        let nineStages = try ValueTransformComposition(
            transforms: Array(repeating: ValueTransform.identity, count: 9)
        )
        let cases: [(ScalarType, ValueTransform)] = [
            (.uint8, .lookupTable(emptyTable)),
            (.float32, .lookupTable(validTable)),
            (.uint8, .composed(linearThenTable)),
            (.uint8, .composed(nested)),
            (.uint8, .composed(nineStages)),
        ]

        for (scalarType, transform) in cases {
            let fixture = try ScalarSurfaceTestSupport.fixture(
                scalarType: scalarType,
                valueTransform: transform
            )
            let coordinator = StorageReadCoordinator(
                maximumRetainedResultByteCount: 1_024
            )
            await #expect(
                throws: ScalarSurfaceExtractionError.sourceReadFailed
            ) {
                try await CPUScalarSurfaceExtractionOperation.extractMesh(
                    request: ScalarSurfaceTestSupport.request(fixture: fixture),
                    coordinator: coordinator
                )
            }
            #expect(fixture.owner.readCount == 1)
            #expect(await coordinator.currentChargedByteCount == 0)
        }
    }

    @Test("[Unit][VOX-ERR-001] non-finite decoded and transformed samples fail in order")
    func rejectsNonFiniteAuthoritativeSamples() async throws {
        let decoded = try ScalarSurfaceTestSupport.fixture(
            scalarType: .float64,
            values: [.nan, 0, 0, 0, 0, 0, 0, 0]
        )
        let transformed = try ScalarSurfaceTestSupport.fixture(
            scalarType: .float64,
            values: [Double.greatestFiniteMagnitude, 0, 0, 0, 0, 0, 0, 0],
            valueTransform: .linear(
                try LinearValueTransformDescriptor(scale: 2, offset: 0)
            )
        )
        for fixture in [decoded, transformed] {
            let coordinator = StorageReadCoordinator(
                maximumRetainedResultByteCount: 1_024
            )
            await #expect(
                throws: ScalarSurfaceExtractionError.nonFiniteSample
            ) {
                try await CPUScalarSurfaceExtractionOperation.extractMesh(
                    request: ScalarSurfaceTestSupport.request(fixture: fixture),
                    coordinator: coordinator
                )
            }
            #expect(fixture.owner.readCount == 1)
            #expect(await coordinator.currentChargedByteCount == 0)
        }
    }

    @Test("[Unit][VOX-EXE-002][VOX-ERR-001] coordinated failures map and release payload-free")
    func mapsCoordinatedReadFailures() async throws {
        let fixture = try ScalarSurfaceTestSupport.fixture(
            readFailure: .providerFailure
        )
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        await #expect(throws: ScalarSurfaceExtractionError.sourceReadFailed) {
            try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: ScalarSurfaceTestSupport.request(fixture: fixture),
                coordinator: coordinator
            )
        }
        #expect(fixture.owner.readCount == 1)
        #expect(await coordinator.currentChargedByteCount == 0)

        let budgetFailure = StorageReadCoordinator(
            maximumRetainedResultByteCount: 0
        )
        let valid = try ScalarSurfaceTestSupport.fixture()
        await #expect(throws: ScalarSurfaceExtractionError.sourceReadFailed) {
            try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: ScalarSurfaceTestSupport.request(fixture: valid),
                coordinator: budgetFailure
            )
        }
        #expect(await budgetFailure.currentChargedByteCount == 0)
    }

    @Test("[Unit][VOX-EXE-006][VOX-ERR-001] sample cancellation boundaries preserve precedence")
    func sampleValidationCancellationBoundaries() async throws {
        let sampleZero = try ScalarSurfaceTestSupport.fixture(
            scalarType: .float64,
            values: [.nan, 0, 0, 0, 0, 0, 0, 0]
        )
        let sampleZeroCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        await #expect(throws: ScalarSurfaceExtractionError.cancelled) {
            try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: ScalarSurfaceTestSupport.request(fixture: sampleZero),
                coordinator: sampleZeroCoordinator,
                cancellation: { $0 == .sampleValidation(0) }
            )
        }
        #expect(await sampleZeroCoordinator.currentChargedByteCount == 0)

        for nonFiniteOrdinal in [4_095, 4_096, 4_097] {
            var values = [Double](repeating: 0, count: 4_098)
            values[nonFiniteOrdinal] = .nan
            let fixture = try ScalarSurfaceTestSupport.fixture(
                extents: [4_098, 1, 1],
                scalarType: .float64,
                values: values
            )
            let coordinator = StorageReadCoordinator(
                maximumRetainedResultByteCount: 40_000
            )
            let expected: ScalarSurfaceExtractionError =
                nonFiniteOrdinal == 4_095 ? .nonFiniteSample : .cancelled
            await #expect(throws: expected) {
                try await CPUScalarSurfaceExtractionOperation.extractMesh(
                    request: ScalarSurfaceTestSupport.request(fixture: fixture),
                    coordinator: coordinator,
                    cancellation: { $0 == .sampleValidation(4_096) }
                )
            }
            #expect(await coordinator.currentChargedByteCount == 0)
        }
    }

    @Test("[Unit][VOX-EXE-006] cell and final cancellation publish no mesh")
    func cellAndFinalCancellationBoundaries() async throws {
        let firstCell = try ScalarSurfaceTestSupport.fixture()
        let firstCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        await #expect(throws: ScalarSurfaceExtractionError.cancelled) {
            try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: ScalarSurfaceTestSupport.request(fixture: firstCell),
                coordinator: firstCoordinator,
                cancellation: { $0 == .cell(0) }
            )
        }

        let sixtyFourthCell = try ScalarSurfaceTestSupport.fixture(
            extents: [66, 2, 2],
            values: [0]
        )
        let cellCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        await #expect(throws: ScalarSurfaceExtractionError.cancelled) {
            try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: ScalarSurfaceTestSupport.request(
                    fixture: sixtyFourthCell
                ),
                coordinator: cellCoordinator,
                cancellation: { $0 == .cell(64) }
            )
        }

        let final = try ScalarSurfaceTestSupport.fixture(values: [0])
        let finalCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        await #expect(throws: ScalarSurfaceExtractionError.cancelled) {
            try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: ScalarSurfaceTestSupport.request(fixture: final),
                coordinator: finalCoordinator,
                cancellation: { $0 == .final }
            )
        }
        #expect(await firstCoordinator.currentChargedByteCount == 0)
        #expect(await cellCoordinator.currentChargedByteCount == 0)
        #expect(await finalCoordinator.currentChargedByteCount == 0)
    }

    private func extract(
        _ fixture: ScalarSurfaceFixture,
        isovalue: Double = 0.5
    ) async throws -> TriangleMesh {
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        return try await CPUScalarSurfaceExtractionOperation.extractMesh(
            request: ScalarSurfaceTestSupport.request(
                fixture: fixture,
                isovalue: isovalue
            ),
            coordinator: coordinator
        )
    }

    private func expectUnsupportedBeforeRead(
        _ fixture: ScalarSurfaceFixture
    ) async throws {
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: UInt64.max
        )
        await #expect(throws: ScalarSurfaceExtractionError.unsupportedSource) {
            try await CPUScalarSurfaceExtractionOperation.extractMesh(
                request: ScalarSurfaceTestSupport.request(fixture: fixture),
                coordinator: coordinator
            )
        }
        #expect(fixture.owner.readCount == 0)
        #expect(await coordinator.currentChargedByteCount == 0)
    }
}
