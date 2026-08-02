// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "VoxeliaValidationTools",
    platforms: [.macOS(.v15)],
    dependencies: [.package(name: "Voxelia", path: "..")],
    targets: [
        .executableTarget(
            name: "voxelia-validation",
            dependencies: [
                .product(name: "VoxeliaValidation", package: "Voxelia")
            ]
        ),
        .testTarget(
            name: "VoxeliaValidationToolTests",
            dependencies: ["voxelia-validation"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
