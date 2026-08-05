// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaRendering

/// The closed backend policy vocabulary per `ADR-0104`.
///
/// No policy names a device generation or commercial model; selection
/// is capability-driven and always reported through the plan.
public enum BackendPolicy: Sendable, Hashable {
    case reference
    case cpuPreferred
    case gpuPreferred
    case automatic
}

/// The closed backend selection one plan reports per `ADR-0104`.
public enum RendererBackendSelection: Sendable, Hashable {
    case exactCPU
    case device
}

/// One evidence-carrying renderer plan per `ADR-0104`.
///
/// The plan is the report: the selection is always stated, never
/// silent, so a preferred policy that fell back is visible to the
/// host.
public struct RendererPlan: Sendable {
    public let renderer: any SliceRenderer
    public let policy: BackendPolicy
    public let selection: RendererBackendSelection

    init(
        renderer: any SliceRenderer,
        policy: BackendPolicy,
        selection: RendererBackendSelection
    ) {
        self.renderer = renderer
        self.policy = policy
        self.selection = selection
    }
}

/// The version-one execution planner per `ADR-0104`.
///
/// `reference` and `cpuPreferred` select the exact CPU pipeline — the
/// registered binary64 reference; `gpuPreferred` and `automatic`
/// select the device pipeline when the context and both kernels
/// acquire, and otherwise report the exact CPU selection. Every
/// selectable implementation carries measured validation evidence, so
/// the `VOX-CCH-003` fail-closed rule holds by construction; the
/// version-one `gpuPreferred` and `automatic` rules coincide, and
/// `automatic` may later weigh locality, latency and memory cost
/// through its own revisions.
public enum MetalRendererPlanner {
    /// Plans one renderer for the requested policy.
    public static func plan(
        policy: BackendPolicy,
        publisher: PublicationCoordinator,
        readCoordinator: StorageReadCoordinator,
        software: SoftwareIdentity,
        naming: @escaping RenderPublicationNaming
    ) -> RendererPlan {
        func exactPlan() -> RendererPlan {
            RendererPlan(
                renderer: ExactSliceRenderer(
                    publisher: publisher,
                    readCoordinator: readCoordinator,
                    software: software,
                    naming: naming
                ),
                policy: policy,
                selection: .exactCPU
            )
        }
        switch policy {
        case .reference, .cpuPreferred:
            return exactPlan()
        case .gpuPreferred, .automatic:
            // Device selection requires the context and both kernels;
            // any acquisition failure reports the exact CPU selection
            // — preference is not requirement, and the fallback is
            // validated.
            guard
                let context = try? MetalExecutionContext(),
                let windowKernel = try? MetalWindowLevelKernel(
                    context: context, telemetrySink: nil),
                let compositeKernel = try? MetalCompositeKernel(
                    context: context, telemetrySink: nil)
            else {
                return exactPlan()
            }
            return RendererPlan(
                renderer: MetalSliceRenderer(
                    kernel: windowKernel,
                    compositeKernel: compositeKernel,
                    publisher: publisher,
                    readCoordinator: readCoordinator,
                    software: software,
                    naming: naming
                ),
                policy: policy,
                selection: .device
            )
        }
    }
}
