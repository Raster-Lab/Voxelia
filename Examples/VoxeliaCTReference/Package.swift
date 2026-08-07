// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "VoxeliaCTReference",
    platforms: [.macOS(.v15)],
    dependencies: [.package(name: "Voxelia", path: "../..")],
    targets: [
        .executableTarget(
            name: "VoxeliaCTReference",
            dependencies: [
                .product(name: "Voxelia", package: "Voxelia"),
                .product(name: "VoxeliaMetal", package: "Voxelia"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
