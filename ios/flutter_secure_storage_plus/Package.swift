// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "flutter_secure_storage_plus",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "flutter_secure_storage_plus",
            targets: ["flutter_secure_storage_plus"]
        )
    ],
    targets: [
        // Note: This target points to the plugin's iOS Swift sources.
        // It is a minimal manifest to satisfy tooling checks.
        .target(
            name: "flutter_secure_storage_plus",
            path: "../Classes"
        )
    ]
)



