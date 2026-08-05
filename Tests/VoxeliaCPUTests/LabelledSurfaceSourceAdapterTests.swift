// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaCPU

@Suite("CPU labelled-surface source adapter")
struct LabelledSurfaceSourceAdapterTests {
    @Test("[Unit][VOX-ERR-001][VOX-CON-006] admission and label precedence is exact")
    func admissionAndLabelPrecedence() async throws {
        let fixture = try LabelledSurfaceTestSupport.fixture()
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        let invalidLimits = LabelledSurfaceTestSupport.request(
            fixture: fixture,
            selectedLabels: .unsigned([]),
            maximumSelectedLabelCount: 65_537,
            maximumVertexCount: 0,
            maximumTriangleCount: 0
        )
        await #expect(throws: LabelledSurfaceExtractionError.cancelled) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: invalidLimits,
                coordinator: coordinator,
                cancellation: { $0 == .admission }
            )
        }
        await #expect(throws: LabelledSurfaceExtractionError.invalidLimits) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: invalidLimits,
                coordinator: coordinator
            )
        }

        for labels in [
            LabelledSurfaceLabelSet.unsigned([]),
            .unsigned([1, 1]),
            .unsigned([2, 1]),
        ] {
            await #expect(throws: LabelledSurfaceExtractionError.invalidLabelSet) {
                try await CPULabelledSurfaceExtractionOperation.extractMesh(
                    request: LabelledSurfaceTestSupport.request(
                        fixture: fixture,
                        selectedLabels: labels
                    ),
                    coordinator: coordinator
                )
            }
        }
        await #expect(
            throws: LabelledSurfaceExtractionError.resourceLimitExceeded
        ) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(
                    fixture: fixture,
                    selectedLabels: .unsigned([1, 2]),
                    maximumSelectedLabelCount: 1
                ),
                coordinator: coordinator
            )
        }
        #expect(fixture.owner.readCount == 0)
    }

    @Test("[Unit][VOX-CON-006] label validation polls before governed ordinals")
    func labelValidationCancellationBoundaries() async throws {
        let fixture = try LabelledSurfaceTestSupport.fixture()
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        await #expect(throws: LabelledSurfaceExtractionError.cancelled) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(fixture: fixture),
                coordinator: coordinator,
                cancellation: { $0 == .labelValidation(0) }
            )
        }
        for invalidOrdinal in [4_095, 4_096, 4_097] {
            var labels = ContiguousArray((0..<4_098).map(UInt64.init))
            labels[invalidOrdinal] = labels[invalidOrdinal - 1]
            let expected: LabelledSurfaceExtractionError =
                invalidOrdinal == 4_095 ? .invalidLabelSet : .cancelled
            await #expect(throws: expected) {
                try await CPULabelledSurfaceExtractionOperation.extractMesh(
                    request: LabelledSurfaceTestSupport.request(
                        fixture: fixture,
                        selectedLabels: .unsigned(labels)
                    ),
                    coordinator: coordinator,
                    cancellation: { $0 == .labelValidation(4_096) }
                )
            }
        }
        #expect(fixture.owner.readCount == 0)
    }

    @Test("[Unit][VOX-GEO-007][VOX-SEC-001] descriptor admission is closed")
    func descriptorAdmissionIsClosed() async throws {
        let unit = try MeasurementUnit(
            namespace: "UCUM",
            code: "1",
            dimension: .dimensionless
        )
        let linear = try LinearValueTransformDescriptor(scale: 1, offset: 0)
        let table = try LookupTableDescriptor(
            firstMappedValue: 0,
            values: [0, 1]
        )
        let composition = try ValueTransformComposition(
            transforms: [.identity]
        )
        let maximum = Double.greatestFiniteMagnitude
        let fixtures = try [
            LabelledSurfaceTestSupport.fixture(
                extents: [2, 2],
                values: .unsigned([7, 0, 0, 0]),
                spatialAxes: [0, 1]
            ),
            LabelledSurfaceTestSupport.fixture(componentCount: 2),
            LabelledSurfaceTestSupport.fixture(
                interpretation: .vector
            ),
            LabelledSurfaceTestSupport.fixture(semantic: .intensity),
            LabelledSurfaceTestSupport.fixture(scalarType: .float32),
            LabelledSurfaceTestSupport.fixture(
                scalarType: .uint16,
                validBitCount: 12
            ),
            LabelledSurfaceTestSupport.fixture(
                valueTransform: .linear(linear)
            ),
            LabelledSurfaceTestSupport.fixture(
                valueTransform: .lookupTable(table)
            ),
            LabelledSurfaceTestSupport.fixture(
                valueTransform: .composed(composition)
            ),
            LabelledSurfaceTestSupport.fixture(units: unit),
            LabelledSurfaceTestSupport.fixture(includesGeometry: false),
            LabelledSurfaceTestSupport.fixture(spatialAxes: [0, 1]),
            LabelledSurfaceTestSupport.fixture(
                matrixElements: [
                    maximum, 0, 0, 0,
                    0, maximum, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ]
            ),
            LabelledSurfaceTestSupport.fixture(
                extents: [9_007_199_254_740_994, 1, 1],
                values: .unsigned([0]),
                allocateBytes: false
            ),
        ]
        for fixture in fixtures {
            try await expectUnsupportedBeforeRead(fixture)
        }
    }

    @Test("[Unit][VOX-GEO-007] signedness valid bits and identity transform stay exact")
    func exactDomainAdmission() async throws {
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        let signed = try LabelledSurfaceTestSupport.fixture(
            scalarType: .int64,
            values: .signed([7, -4, -4, -4, -4, -4, -4, -4]),
            valueTransform: .identity,
            validBitCount: 64
        )
        let signedMesh = try await CPULabelledSurfaceExtractionOperation.extractMesh(
            request: LabelledSurfaceTestSupport.request(
                fixture: signed,
                selectedLabels: .signed([7])
            ),
            coordinator: coordinator
        )
        #expect(
            signedMesh.positions.components
                == LabelledSurfaceTestSupport.singleCornerPositions
        )
        await #expect(throws: LabelledSurfaceExtractionError.unsupportedSource) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(
                    fixture: signed,
                    selectedLabels: .unsigned([7])
                ),
                coordinator: coordinator
            )
        }
        #expect(signed.owner.readCount == 1)

        let unsigned = try LabelledSurfaceTestSupport.fixture()
        for labels in [
            LabelledSurfaceLabelSet.signed([7]),
            .unsigned([7]),
        ] {
            let shouldSucceed: Bool
            switch labels {
            case .signed: shouldSucceed = false
            case .unsigned: shouldSucceed = true
            }
            if shouldSucceed {
                _ = try await CPULabelledSurfaceExtractionOperation.extractMesh(
                    request: LabelledSurfaceTestSupport.request(
                        fixture: unsigned,
                        selectedLabels: labels
                    ),
                    coordinator: coordinator
                )
            } else {
                await #expect(
                    throws: LabelledSurfaceExtractionError.unsupportedSource
                ) {
                    try await CPULabelledSurfaceExtractionOperation.extractMesh(
                        request: LabelledSurfaceTestSupport.request(
                            fixture: unsigned,
                            selectedLabels: labels
                        ),
                        coordinator: coordinator
                    )
                }
            }
        }
        #expect(unsigned.owner.readCount == 1)
        #expect(await coordinator.currentChargedByteCount == 0)
    }

    @Test("[Unit][VOX-EXE-002][VOX-ERR-001] read failures map and release payload-free")
    func coordinatedFailuresAndByteMismatch() async throws {
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        let providerFailure = try LabelledSurfaceTestSupport.fixture(
            readFailure: .providerFailure
        )
        await #expect(throws: LabelledSurfaceExtractionError.sourceReadFailed) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(
                    fixture: providerFailure
                ),
                coordinator: coordinator
            )
        }
        #expect(providerFailure.owner.readCount == 1)

        let providerCancellation = try LabelledSurfaceTestSupport.fixture(
            readFailure: .cancelled
        )
        await #expect(throws: LabelledSurfaceExtractionError.cancelled) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(
                    fixture: providerCancellation
                ),
                coordinator: coordinator
            )
        }
        #expect(providerCancellation.owner.readCount == 1)

        let valid = try LabelledSurfaceTestSupport.fixture()
        let budgetFailure = StorageReadCoordinator(
            maximumRetainedResultByteCount: 0
        )
        await #expect(throws: LabelledSurfaceExtractionError.sourceReadFailed) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(fixture: valid),
                coordinator: budgetFailure
            )
        }

        let request = LabelledSurfaceTestSupport.request(fixture: valid)
        let admission = try LabelledSurfaceSourceAdmission(request: request)
        #expect(throws: LabelledSurfaceExtractionError.sourceReadFailed) {
            try LabelledSurfaceSourceAdapter(
                request: request,
                admission: admission,
                bytes: []
            )
        }
        #expect(await coordinator.currentChargedByteCount == 0)
        #expect(await budgetFailure.currentChargedByteCount == 0)
    }

    @Test("[Unit][VOX-CON-006][VOX-CON-007] sample cell and final cancellation are atomic")
    func cancellationBoundaries() async throws {
        let sampleZeroFixture = try LabelledSurfaceTestSupport.fixture()
        let sampleZeroCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        await #expect(throws: LabelledSurfaceExtractionError.cancelled) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(
                    fixture: sampleZeroFixture
                ),
                coordinator: sampleZeroCoordinator,
                cancellation: { $0 == .sampleValidation(0) }
            )
        }

        let sampleFixture = try LabelledSurfaceTestSupport.fixture(
            extents: [4_098, 1, 1],
            values: .unsigned([0])
        )
        let sampleCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 8_192
        )
        await #expect(throws: LabelledSurfaceExtractionError.cancelled) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(
                    fixture: sampleFixture
                ),
                coordinator: sampleCoordinator,
                cancellation: { $0 == .sampleValidation(4_096) }
            )
        }

        let firstCellFixture = try LabelledSurfaceTestSupport.fixture()
        let firstCellCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        await #expect(throws: LabelledSurfaceExtractionError.cancelled) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(
                    fixture: firstCellFixture
                ),
                coordinator: firstCellCoordinator,
                cancellation: { $0 == .cell(0) }
            )
        }
        #expect(firstCellFixture.owner.readCount == 1)

        let cellFixture = try LabelledSurfaceTestSupport.fixture(
            extents: [66, 2, 2],
            values: .unsigned([0])
        )
        let cellCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        await #expect(throws: LabelledSurfaceExtractionError.cancelled) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(fixture: cellFixture),
                coordinator: cellCoordinator,
                cancellation: { $0 == .cell(64) }
            )
        }

        let finalFixture = try LabelledSurfaceTestSupport.fixture(
            values: .unsigned([0])
        )
        let finalCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        await #expect(throws: LabelledSurfaceExtractionError.cancelled) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(
                    fixture: finalFixture
                ),
                coordinator: finalCoordinator,
                cancellation: { $0 == .final }
            )
        }
        #expect(await sampleZeroCoordinator.currentChargedByteCount == 0)
        #expect(await sampleCoordinator.currentChargedByteCount == 0)
        #expect(await firstCellCoordinator.currentChargedByteCount == 0)
        #expect(await cellCoordinator.currentChargedByteCount == 0)
        #expect(await finalCoordinator.currentChargedByteCount == 0)
    }

    private func expectUnsupportedBeforeRead(
        _ fixture: LabelledSurfaceFixture
    ) async throws {
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: UInt64.max
        )
        await #expect(throws: LabelledSurfaceExtractionError.unsupportedSource) {
            try await CPULabelledSurfaceExtractionOperation.extractMesh(
                request: LabelledSurfaceTestSupport.request(fixture: fixture),
                coordinator: coordinator
            )
        }
        #expect(fixture.owner.readCount == 0)
        #expect(await coordinator.currentChargedByteCount == 0)
    }
}
