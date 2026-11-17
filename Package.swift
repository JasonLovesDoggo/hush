// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Hush",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Hush",
            path: "Sources/Hush",
            swiftSettings: [.defaultIsolation(MainActor.self)],
            linkerSettings: [
                .linkedFramework("IOBluetooth"),
                .linkedFramework("CoreBluetooth"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement"),
            ]
        )
    ]
)
