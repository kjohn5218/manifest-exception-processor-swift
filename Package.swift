// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ManifestExceptionProcessor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "manifest-processor", targets: ["ManifestProcessor"])
    ],
    targets: [
        .executableTarget(
            name: "ManifestProcessor",
            dependencies: [],
            path: "Sources/ManifestProcessor"
        )
    ]
)