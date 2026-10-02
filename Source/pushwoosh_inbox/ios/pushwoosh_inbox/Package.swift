// swift-tools-version: 5.9
import PackageDescription

// Used by Flutter 3.44+ by default and by 3.27-3.43 once SPM is on; pushwoosh_inbox.podspec stays for CocoaPods apps.
// No FlutterFramework dependency: that package only exists from Flutter 3.44 and would break SPM on older Flutter.
let package = Package(
    name: "pushwoosh_inbox",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "pushwoosh-inbox", targets: ["pushwoosh_inbox"])
    ],
    dependencies: [
        // A range, not exact: pushwoosh_flutter pins the native SDK, and an exact pin here would fail to resolve
        // whenever the app has pushwoosh_flutter and pushwoosh_inbox from different releases.
        .package(url: "https://github.com/Pushwoosh/Pushwoosh-XCFramework.git", from: "7.2.8"),
        // Legacy inbox UI: 7.0.42 is its last release, the native SDK dropped it in 7.0.43.
        .package(url: "https://github.com/Pushwoosh/PushwooshInboxUI-XCFramework.git", exact: "7.0.42")
    ],
    targets: [
        .target(
            name: "pushwoosh_inbox",
            dependencies: [
                .product(name: "PushwooshFramework", package: "Pushwoosh-XCFramework"),
                .product(name: "PushwooshCore", package: "Pushwoosh-XCFramework"),
                .product(name: "PushwooshBridge", package: "Pushwoosh-XCFramework"),
                .product(name: "PushwooshInboxUI", package: "PushwooshInboxUI-XCFramework")
            ],
            cSettings: [
                .headerSearchPath("include/pushwoosh_inbox")
            ]
        )
    ]
)
