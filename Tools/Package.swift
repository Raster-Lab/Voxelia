// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "VoxeliaRepositoryTools",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "voxelia-repo-check", targets: ["voxelia-repo-check"]),
    ],
    targets: [
        .executableTarget(name: "voxelia-repo-check"),
        .testTarget(
            name: "VoxeliaRepositoryToolTests",
            dependencies: ["voxelia-repo-check"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
