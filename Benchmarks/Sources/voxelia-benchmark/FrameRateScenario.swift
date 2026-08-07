// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaExecution
import VoxeliaMetal
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

/// The `VOX-PER-004` frame-rate scenario per `ADR-0346`.
///
/// Renders the row's own conventional case — a 512-cubed volume — and
/// its level-select representations through the accepted exact volume
/// renderer, in this clean process, and prints raw per-frame timings.
/// The same request is rendered for every frame of a configuration, so
/// frame-to-frame variance is measured on identical work.
enum FrameRateScenario {
    struct Configuration {
        let label: String
        let volumeName: String
        let frameCount: Int
    }

    static func run() async throws {
        let software = try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
        let readCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 700_000_000
        )
        let publisher = PublicationCoordinator(
            maximumPublishedObjectCount: 128,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 128,
                maximumParentEdgeCount: 128,
                maximumAncestryDepth: 16,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: readCoordinator,
            resultCache: nil
        )

        FileHandle.standardError.write(Data("building 512^3 volume...\n".utf8))
        let full = try makeVolume(software: software)
        _ = try await publisher.publish(full, mode: .complete)

        for (index, factor) in [2, 4].enumerated() {
            let level = try BrickResolutionLevel(
                index: index + 1,
                downsamplingFactors: [factor, factor, factor]
            )
            let levelImage = try await LevelSelectOperation.execute(
                input: full,
                level: level,
                outputObjectID: try objectID("bench-level-\(index + 1)"),
                outputProvenanceID: try provenanceID("record-bench-level-\(index + 1)"),
                createdAt: try CanonicalInstant(utcString: "2026-08-07T12:00:00Z"),
                software: software,
                coordinator: readCoordinator
            )
            _ = try await publisher.publish(levelImage, mode: .complete)
        }

        let renderer = ExactVolumeRenderer(
            publisher: publisher,
            readCoordinator: readCoordinator,
            software: software
        )
        let configurations = [
            Configuration(label: "level-0-512", volumeName: "bench-volume", frameCount: 3),
            Configuration(label: "level-1-256", volumeName: "bench-level-1", frameCount: 8),
            Configuration(label: "level-2-128", volumeName: "bench-level-2", frameCount: 20),
        ]

        var report = [[String: Any]]()
        for configuration in configurations {
            FileHandle.standardError.write(
                Data("rendering \(configuration.label)...\n".utf8)
            )
            var frameMilliseconds = [Double]()
            for frame in 0..<configuration.frameCount {
                let request = try makeRequest(volumeName: configuration.volumeName)
                let start = ContinuousClock.now
                _ = try await renderer.render(
                    request,
                    outputObjectID: try objectID(
                        "bench-\(configuration.label)-frame-\(frame)"
                    ),
                    outputProvenanceID: try provenanceID(
                        "record-bench-\(configuration.label)-frame-\(frame)"
                    ),
                    createdAt: try CanonicalInstant(
                        utcString: "2026-08-07T12:00:00Z"
                    )
                )
                let elapsed = start.duration(to: .now)
                let milliseconds =
                    Double(elapsed.components.seconds) * 1_000.0
                    + Double(elapsed.components.attoseconds) / 1e15
                frameMilliseconds.append(milliseconds)
            }
            let sorted = frameMilliseconds.sorted()
            let median = sorted[(sorted.count - 1) / 2]
            report.append([
                "configuration": configuration.label,
                "viewport": "512x512",
                "frameCount": configuration.frameCount,
                "frameMilliseconds": frameMilliseconds.map { round($0 * 10) / 10 },
                "medianMilliseconds": round(median * 10) / 10,
                "framesPerSecondAtMedian": round(1_000.0 / median * 1_000) / 1_000,
            ])
        }

        let data = try JSONSerialization.data(
            withJSONObject: ["scenario": "voxelia.frames.vox-per-004", "results": report],
            options: [.prettyPrinted, .sortedKeys]
        )
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }

    private static func objectID(_ raw: String) throws -> DataObjectID {
        guard let id = DataObjectID(rawValue: raw) else {
            throw BenchmarkScenarioError.invalidIdentifier
        }
        return id
    }

    private static func provenanceID(_ raw: String) throws -> ProvenanceID {
        guard let id = ProvenanceID(rawValue: raw) else {
            throw BenchmarkScenarioError.invalidIdentifier
        }
        return id
    }

    private static func makeRequest(volumeName: String) throws -> VolumeRenderRequest {
        guard let space = CoordinateSpaceID(rawValue: "patient") else {
            throw BenchmarkScenarioError.invalidIdentifier
        }
        var entries = ContiguousArray<TransferFunctionEntry>()
        for index in 0..<256 {
            let level = UInt8(index)
            entries.append(
                TransferFunctionEntry(
                    red: level,
                    green: level,
                    blue: level,
                    opacity: level
                )
            )
        }
        return VolumeRenderRequest(
            volumeObjectID: try objectID(volumeName),
            table: try TransferFunction1D(entries: entries),
            camera: try RenderCamera(
                position: try Point3D(
                    x: 255.5,
                    y: 255.5,
                    z: -600,
                    coordinateSpace: space
                ),
                target: try Point3D(
                    x: 255.5,
                    y: 255.5,
                    z: 255.5,
                    coordinateSpace: space
                ),
                up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
                projection: .orthographic(planeHeight: 600)
            ),
            viewport: try ViewportSize(width: 512, height: 512),
            quality: "org.voxelia.quality.full",
            lighting: .none,
            clip: nil,
            crop: nil,
            mask: nil,
            acceleration: nil
        )
    }

    private static func makeVolume(software: SoftwareIdentity) throws -> ImageData {
        let extent = 512
        let extents = [extent, extent, extent]
        var bytes = [UInt8](repeating: 0, count: extent * extent * extent)
        var offset = 0
        for i2 in 0..<extent {
            for i1 in 0..<extent {
                for i0 in 0..<extent {
                    bytes[offset] = UInt8(truncatingIfNeeded: i0 &+ i1 &+ i2)
                    offset += 1
                }
            }
        }
        guard let space = CoordinateSpaceID(rawValue: "patient") else {
            throw BenchmarkScenarioError.invalidIdentifier
        }
        let descriptorSpace = try CoordinateSpaceDescriptor(
            id: space,
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
        let geometry = try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: try Matrix4x4Double(elements: [
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ]),
            coordinateSpace: descriptorSpace
        )
        var axes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        for (index, name) in ["x", "y", "z"].enumerated() {
            guard let axisID = AxisID(rawValue: name) else {
                throw BenchmarkScenarioError.invalidIdentifier
            }
            axes.append(
                try AxisDescriptor(
                    id: axisID,
                    name: name,
                    semantic: semantics[index],
                    unit: nil,
                    sampling: .indexOnly
                )
            )
        }
        let shape = try ImageShape(extents: ContiguousArray(extents))
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
                scalarFormat: try ScalarFormat(
                    type: .uint8,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 1,
                    interpretation: .scalar,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: .intensity,
                axes: axes,
                spatialGeometry: .affine(geometry),
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: shape,
                        scalarType: .uint8,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try provenanceID("record-bench-volume"),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-07T12:00:00Z"),
                subject: .object(try objectID("bench-volume")),
                software: software,
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try objectID("bench-volume"),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "org.voxelia.benchmark",
                        identifier: "synthetic-512-ramp",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }
}

enum BenchmarkScenarioError: Error {
    case invalidIdentifier
}
