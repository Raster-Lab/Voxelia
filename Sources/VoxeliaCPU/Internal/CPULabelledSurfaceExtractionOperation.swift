// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

/// Internal cancellation sites frozen by `ADR-0192` and `ALG-0029`.
enum CPULabelledSurfaceCancellationCheckpoint: Sendable, Equatable {
    case admission
    case labelValidation(UInt64)
    case sampleValidation(UInt64)
    case cell(UInt64)
    case final
}

typealias CPULabelledSurfaceCancellationProbe =
    @Sendable (CPULabelledSurfaceCancellationCheckpoint) -> Bool

/// The migration-step-two CPU source-read and numerical boundary.
///
/// Publication claims and the public `execute` entry point arrive in
/// `ADR-0192` migration step three. Keeping this entry internal prevents an
/// incomplete mesh-only operation from becoming public API.
enum CPULabelledSurfaceExtractionOperation {
    static let implementationIdentifier =
        "org.voxelia.impl.labelled-surface-extraction.cpu"

    static func extractMesh(
        request: LabelledSurfaceExtractionRequest,
        coordinator: StorageReadCoordinator,
        cancellation: @escaping CPULabelledSurfaceCancellationProbe = { _ in
            Task.isCancelled
        },
        checksFinalCancellation: Bool = true
    ) async throws -> TriangleMesh {
        if cancellation(.admission) {
            throw LabelledSurfaceExtractionError.cancelled
        }
        guard
            request.limits.maximumSelectedLabelCount > 0,
            request.limits.maximumSelectedLabelCount
                <= LabelledSurfaceExtractionRequest.maximumSupportedLabelCount,
            request.limits.maximumVertexCount > 0,
            request.limits.maximumTriangleCount > 0
        else {
            throw LabelledSurfaceExtractionError.invalidLimits
        }

        try validateSelectedLabels(
            request.selectedLabels,
            maximumCount: request.limits.maximumSelectedLabelCount,
            cancellation: cancellation
        )
        let admission = try LabelledSurfaceSourceAdmission(request: request)

        let fullRegion: ImageRegion
        do {
            fullRegion = try ImageRegion(
                lowerBounds: [0, 0, 0],
                upperBounds: admission.extents
            )
        } catch {
            throw LabelledSurfaceExtractionError.sourceReadFailed
        }

        let read: CoordinatedReadResult
        do {
            read = try await coordinator.read(
                from: request.source.storage,
                region: fullRegion
            )
        } catch let error as StorageContractError {
            if error == .cancelled || Task.isCancelled {
                throw LabelledSurfaceExtractionError.cancelled
            }
            throw LabelledSurfaceExtractionError.sourceReadFailed
        } catch {
            if Task.isCancelled {
                throw LabelledSurfaceExtractionError.cancelled
            }
            throw LabelledSurfaceExtractionError.sourceReadFailed
        }

        // RegionReadResult already owns immutable packed bytes. Retain that
        // value locally, then release the coordinator's budget token before
        // decoder validation or numerical traversal.
        let stagedBytes = read.result.bytes
        do {
            try await coordinator.release(read.retention)
        } catch {
            throw LabelledSurfaceExtractionError.sourceReadFailed
        }

        let source = try LabelledSurfaceSourceAdapter(
            request: request,
            admission: admission,
            bytes: stagedBytes
        )
        try source.validateSamples(cancellation: cancellation)
        return try LabelledSurfaceReferenceKernel.extract(
            request: request,
            source: source,
            cancellation: cancellation,
            checksFinalCancellation: checksFinalCancellation
        )
    }

    private static func validateSelectedLabels(
        _ selectedLabels: LabelledSurfaceLabelSet,
        maximumCount: UInt64,
        cancellation: CPULabelledSurfaceCancellationProbe
    ) throws {
        switch selectedLabels {
        case .signed(let labels):
            try validateLabels(
                labels,
                maximumCount: maximumCount,
                cancellation: cancellation
            )
        case .unsigned(let labels):
            try validateLabels(
                labels,
                maximumCount: maximumCount,
                cancellation: cancellation
            )
        }
    }

    private static func validateLabels<Value: Comparable>(
        _ labels: ContiguousArray<Value>,
        maximumCount: UInt64,
        cancellation: CPULabelledSurfaceCancellationProbe
    ) throws {
        guard !labels.isEmpty else {
            throw LabelledSurfaceExtractionError.invalidLabelSet
        }
        guard UInt64(labels.count) <= maximumCount else {
            throw LabelledSurfaceExtractionError.resourceLimitExceeded
        }
        for index in labels.indices {
            if index.isMultiple(of: 4_096),
                cancellation(.labelValidation(UInt64(index)))
            {
                throw LabelledSurfaceExtractionError.cancelled
            }
            if index > labels.startIndex,
                labels[index - 1] >= labels[index]
            {
                throw LabelledSurfaceExtractionError.invalidLabelSet
            }
        }
    }
}
