// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Voxelia",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "VoxeliaSpatial", targets: ["VoxeliaSpatial"]),
        .library(name: "VoxeliaCore", targets: ["VoxeliaCore"]),
        .library(name: "VoxeliaStorage", targets: ["VoxeliaStorage"]),
        .library(name: "VoxeliaExecution", targets: ["VoxeliaExecution"]),
        .library(name: "VoxeliaImaging", targets: ["VoxeliaImaging"]),
        .library(name: "VoxeliaGeometry", targets: ["VoxeliaGeometry"]),
        .library(name: "VoxeliaRendering", targets: ["VoxeliaRendering"]),
        .library(name: "VoxeliaInteraction", targets: ["VoxeliaInteraction"]),
        .library(name: "VoxeliaCPU", targets: ["VoxeliaCPU"]),
        .library(name: "VoxeliaMetal", targets: ["VoxeliaMetal"]),
        .library(name: "VoxeliaValidation", targets: ["VoxeliaValidation"]),
        .library(name: "VoxeliaDICOMKit", targets: ["VoxeliaDICOMKit"]),
        .library(name: "Voxelia", targets: ["Voxelia"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Raster-Lab/DICOMKit.git",
            exact: "2.2.11"
        )
    ],
    targets: [
        .target(name: "VoxeliaSpatial"),
        .target(name: "VoxeliaCore", dependencies: ["VoxeliaSpatial"]),
        .target(name: "VoxeliaStorage", dependencies: ["VoxeliaCore"]),
        .target(name: "VoxeliaExecution", dependencies: ["VoxeliaStorage"]),
        .target(name: "VoxeliaImaging", dependencies: ["VoxeliaExecution"]),
        .target(
            name: "VoxeliaGeometry",
            dependencies: ["VoxeliaCore", "VoxeliaSpatial"]
        ),
        .target(
            name: "VoxeliaRendering",
            dependencies: ["VoxeliaImaging", "VoxeliaGeometry"]
        ),
        .target(name: "VoxeliaInteraction", dependencies: ["VoxeliaRendering"]),
        .target(
            name: "VoxeliaCPU",
            dependencies: ["VoxeliaImaging", "VoxeliaGeometry", "VoxeliaExecution"]
        ),
        .target(
            name: "VoxeliaMetal",
            dependencies: ["VoxeliaExecution", "VoxeliaRendering"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "VoxeliaDICOMKit",
            dependencies: [
                "VoxeliaImaging",
                .product(name: "DICOMKit", package: "DICOMKit"),
            ]
        ),
        .target(name: "VoxeliaValidation", dependencies: ["VoxeliaCPU", "VoxeliaMetal"]),
        .target(
            name: "Voxelia",
            dependencies: [
                "VoxeliaSpatial",
                "VoxeliaCore",
                "VoxeliaStorage",
                "VoxeliaExecution",
                "VoxeliaImaging",
                "VoxeliaGeometry",
                "VoxeliaRendering",
                "VoxeliaInteraction",
            ]
        ),
        .target(
            name: "VoxeliaTestSupport",
            dependencies: ["VoxeliaCore", "VoxeliaValidation"],
            path: "Tests/Support",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "VoxeliaSpatialTests",
            dependencies: ["VoxeliaSpatial", "VoxeliaTestSupport"]
        ),
        .testTarget(
            name: "VoxeliaCoreTests",
            dependencies: ["VoxeliaCore", "VoxeliaTestSupport"]
        ),
        .testTarget(
            name: "VoxeliaStorageTests",
            dependencies: ["VoxeliaStorage", "VoxeliaTestSupport"]
        ),
        .testTarget(
            name: "VoxeliaExecutionTests",
            dependencies: ["VoxeliaExecution", "VoxeliaTestSupport"]
        ),
        .testTarget(
            name: "VoxeliaImagingTests",
            dependencies: ["VoxeliaImaging", "VoxeliaTestSupport"]
        ),
        .testTarget(
            name: "VoxeliaDICOMKitTests",
            dependencies: ["VoxeliaDICOMKit", "VoxeliaTestSupport"]
        ),
        .testTarget(
            name: "VoxeliaGeometryTests",
            dependencies: [
                "VoxeliaGeometry",
                "VoxeliaSpatial",
                "VoxeliaTestSupport",
            ]
        ),
        .testTarget(
            name: "VoxeliaRenderingTests",
            dependencies: ["VoxeliaRendering", "VoxeliaTestSupport"]
        ),
        .testTarget(
            name: "VoxeliaInteractionTests",
            dependencies: ["VoxeliaInteraction", "VoxeliaTestSupport"]
        ),
        .testTarget(
            name: "VoxeliaCPUTests",
            dependencies: ["VoxeliaCPU", "VoxeliaTestSupport"]
        ),
        .testTarget(
            name: "VoxeliaMetalTests",
            dependencies: ["VoxeliaMetal", "VoxeliaTestSupport"]
        ),
        .testTarget(
            name: "VoxeliaValidationTests",
            dependencies: ["VoxeliaValidation", "VoxeliaTestSupport"]
        ),
        .testTarget(name: "VoxeliaTests", dependencies: ["Voxelia", "VoxeliaTestSupport"]),
    ],
    swiftLanguageModes: [.v6]
)
