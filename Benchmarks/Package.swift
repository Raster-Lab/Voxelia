// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "VoxeliaBenchmarkTools",
    platforms: [.macOS(.v15)],
    dependencies: [.package(name: "Voxelia", path: "..")],
    targets: [
        .executableTarget(
            name: "voxelia-benchmark",
            dependencies: [
                .product(name: "Voxelia", package: "Voxelia")
            ]
        ),
        .testTarget(
            name: "VoxeliaBenchmarkToolTests",
            dependencies: ["voxelia-benchmark"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
