// swift-tools-version: 5.9
import PackageDescription

// Used by Flutter 3.44+ by default and by 3.27-3.43 once SPM is on; pushwoosh_geozones.podspec stays for CocoaPods apps.
// No FlutterFramework dependency: that package only exists from Flutter 3.44 and would break SPM on older Flutter.
let package = Package(
    name: "pushwoosh_geozones",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "pushwoosh-geozones", targets: ["pushwoosh_geozones"])
    ],
    dependencies: [
        // A range, not exact: pushwoosh_flutter pins the native SDK, and an exact pin here would fail to resolve
        // whenever the app has pushwoosh_flutter and pushwoosh_geozones from different releases.
        .package(url: "https://github.com/Pushwoosh/Pushwoosh-XCFramework.git", from: "7.2.8"),
        // Released together with the native SDK: keep it at the same version as the pin in pushwoosh_flutter.
        .package(url: "https://github.com/Pushwoosh/PushwooshGeozones-XCFramework.git", exact: "7.2.8")
    ],
    targets: [
        .target(
            name: "pushwoosh_geozones",
            dependencies: [
                .product(name: "PushwooshFramework", package: "Pushwoosh-XCFramework"),
                .product(name: "PushwooshCore", package: "Pushwoosh-XCFramework"),
                .product(name: "PushwooshBridge", package: "Pushwoosh-XCFramework"),
                .product(name: "PushwooshGeozones", package: "PushwooshGeozones-XCFramework")
            ],
            cSettings: [
                .headerSearchPath("include/pushwoosh_geozones")
            ]
        )
    ]
)
