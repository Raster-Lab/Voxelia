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
        .library(name: "VoxeliaCompression", targets: ["VoxeliaCompression"]),
        .library(name: "VoxeliaValidation", targets: ["VoxeliaValidation"]),
        .library(name: "VoxeliaDICOMKit", targets: ["VoxeliaDICOMKit"]),
        .library(name: "Voxelia", targets: ["Voxelia"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Raster-Lab/DICOMKit.git",
            exact: "2.2.11"
        ),
        .package(
            url: "https://github.com/Raster-Lab/J2KSwift.git",
            exact: "11.0.2"
        ),
    ],
    targets: [
        .target(name: "VoxeliaSpatial", swiftSettings: [.strictMemorySafety()]),
        .target(
            name: "VoxeliaCore", dependencies: ["VoxeliaSpatial"],
            swiftSettings: [.strictMemorySafety()]),
        .target(
            name: "VoxeliaStorage", dependencies: ["VoxeliaCore"],
            swiftSettings: [.strictMemorySafety()]),
        .target(
            name: "VoxeliaExecution", dependencies: ["VoxeliaStorage"],
            swiftSettings: [.strictMemorySafety()]),
        .target(
            name: "VoxeliaImaging", dependencies: ["VoxeliaExecution"],
            swiftSettings: [.strictMemorySafety()]),
        .target(
            name: "VoxeliaCompression",
            dependencies: [
                "VoxeliaCore",
                .product(name: "J2KCodec", package: "J2KSwift"),
                .product(name: "J2K3D", package: "J2KSwift"),
            ],
            swiftSettings: [.strictMemorySafety()]
        ),
        .target(
            name: "VoxeliaGeometry",
            dependencies: ["VoxeliaCore", "VoxeliaSpatial"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .target(
            name: "VoxeliaRendering",
            dependencies: ["VoxeliaImaging", "VoxeliaGeometry"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .target(
            name: "VoxeliaInteraction", dependencies: ["VoxeliaRendering"],
            swiftSettings: [.strictMemorySafety()]),
        .target(
            name: "VoxeliaCPU",
            dependencies: ["VoxeliaImaging", "VoxeliaGeometry", "VoxeliaExecution"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .target(
            name: "VoxeliaMetal",
            dependencies: ["VoxeliaExecution", "VoxeliaRendering"],
            resources: [.process("Resources")],
            swiftSettings: [.strictMemorySafety()]
        ),
        .target(
            name: "VoxeliaDICOMKit",
            dependencies: [
                "VoxeliaImaging",
                .product(name: "DICOMKit", package: "DICOMKit"),
            ],
            swiftSettings: [.strictMemorySafety()]
        ),
        .target(
            name: "VoxeliaValidation", dependencies: ["VoxeliaCPU", "VoxeliaMetal"],
            swiftSettings: [.strictMemorySafety()]),
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
            ],
            swiftSettings: [.strictMemorySafety()]
        ),
        .target(
            name: "VoxeliaTestSupport",
            dependencies: ["VoxeliaCore", "VoxeliaValidation"],
            path: "Tests/Support",
            resources: [.process("Resources")],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaSpatialTests",
            dependencies: ["VoxeliaSpatial", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaCoreTests",
            dependencies: ["VoxeliaCore", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaStorageTests",
            dependencies: ["VoxeliaStorage", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaExecutionTests",
            dependencies: ["VoxeliaExecution", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaImagingTests",
            dependencies: ["VoxeliaImaging", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaDICOMKitTests",
            dependencies: ["VoxeliaDICOMKit", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaCompressionTests",
            dependencies: [
                "VoxeliaCompression",
                "VoxeliaStorage",
                "VoxeliaTestSupport",
            ],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaGeometryTests",
            dependencies: [
                "VoxeliaGeometry",
                "VoxeliaSpatial",
                "VoxeliaTestSupport",
            ],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaRenderingTests",
            dependencies: ["VoxeliaRendering", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaInteractionTests",
            dependencies: ["VoxeliaInteraction", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaCPUTests",
            dependencies: ["VoxeliaCPU", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaMetalTests",
            dependencies: ["VoxeliaMetal", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaValidationTests",
            dependencies: ["VoxeliaValidation", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]
        ),
        .testTarget(
            name: "VoxeliaTests", dependencies: ["Voxelia", "VoxeliaTestSupport"],
            swiftSettings: [.strictMemorySafety()]),
    ],
    swiftLanguageModes: [.v6]
)
