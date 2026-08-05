// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

/// Internal cancellation sites frozen by `ADR-0191` and `ALG-0028`.
enum CPUScalarSurfaceCancellationCheckpoint: Sendable, Equatable {
    case admission
    case sampleValidation(UInt64)
    case cell(UInt64)
    case final
}

typealias CPUScalarSurfaceCancellationProbe =
    @Sendable (CPUScalarSurfaceCancellationCheckpoint) -> Bool

/// The migration-step-three CPU source-read and numerical boundary.
///
/// Publication claims and the public `execute` entry point arrive in
/// `ADR-0191` migration step four. Keeping this entry internal prevents an
/// incomplete mesh-only operation from becoming public API.
enum CPUScalarSurfaceExtractionOperation {
    static let implementationIdentifier =
        "org.voxelia.impl.scalar-surface-extraction.cpu"

    static func extractMesh(
        request: ScalarSurfaceExtractionRequest,
        coordinator: StorageReadCoordinator,
        cancellation: @escaping CPUScalarSurfaceCancellationProbe = { _ in
            Task.isCancelled
        }
    ) async throws -> TriangleMesh {
        if cancellation(.admission) {
            throw ScalarSurfaceExtractionError.cancelled
        }
        guard
            request.limits.maximumVertexCount > 0,
            request.limits.maximumTriangleCount > 0
        else {
            throw ScalarSurfaceExtractionError.invalidLimits
        }

        let admission = try ScalarSurfaceSourceAdmission(request: request)
        guard request.isovalue.isFinite else {
            throw ScalarSurfaceExtractionError.nonFiniteIsovalue
        }

        let fullRegion: ImageRegion
        do {
            fullRegion = try ImageRegion(
                lowerBounds: [0, 0, 0],
                upperBounds: admission.extents
            )
        } catch {
            throw ScalarSurfaceExtractionError.sourceReadFailed
        }

        let read: CoordinatedReadResult
        do {
            read = try await coordinator.read(
                from: request.source.storage,
                region: fullRegion
            )
        } catch let error as StorageContractError {
            if error == .cancelled || Task.isCancelled {
                throw ScalarSurfaceExtractionError.cancelled
            }
            throw ScalarSurfaceExtractionError.sourceReadFailed
        } catch {
            if Task.isCancelled {
                throw ScalarSurfaceExtractionError.cancelled
            }
            throw ScalarSurfaceExtractionError.sourceReadFailed
        }

        // RegionReadResult already owns immutable packed bytes. Retain that
        // value locally, then release the coordinator's budget token before
        // any transform admission, validation or numerical traversal.
        let stagedBytes = read.result.bytes
        do {
            try await coordinator.release(read.retention)
        } catch {
            throw ScalarSurfaceExtractionError.sourceReadFailed
        }

        let source = try ScalarSurfaceSourceAdapter(
            request: request,
            admission: admission,
            bytes: stagedBytes
        )
        try source.validateFiniteSamples(cancellation: cancellation)
        return try ScalarSurfaceReferenceKernel.extract(
            request: request,
            source: source,
            cancellation: cancellation
        )
    }
}
