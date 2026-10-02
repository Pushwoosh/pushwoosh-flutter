// swift-tools-version: 5.9
import PackageDescription

// Used by Flutter 3.44+ by default and by 3.27-3.43 once SPM is on; pushwoosh_flutter.podspec stays for CocoaPods apps.
// No FlutterFramework dependency: that package only exists from Flutter 3.44 and would break SPM on older Flutter.
let package = Package(
    name: "pushwoosh_flutter",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "pushwoosh-flutter", targets: ["pushwoosh_flutter"])
    ],
    dependencies: [
        // exact: mirrors the hard pin in pushwoosh_flutter.podspec, so CocoaPods and SPM apps get the same native SDK.
        // pushwoosh_inbox and pushwoosh_geozones only ask for a range and follow this pin.
        .package(url: "https://github.com/Pushwoosh/Pushwoosh-XCFramework.git", exact: "7.2.8")
    ],
    targets: [
        .target(
            name: "pushwoosh_flutter",
            dependencies: [
                .product(name: "PushwooshFramework", package: "Pushwoosh-XCFramework"),
                .product(name: "PushwooshCore", package: "Pushwoosh-XCFramework"),
                .product(name: "PushwooshBridge", package: "Pushwoosh-XCFramework"),
                .product(name: "PushwooshInApp", package: "Pushwoosh-XCFramework"),
                .product(name: "PushwooshLiveActivities", package: "Pushwoosh-XCFramework")
            ],
            cSettings: [
                .headerSearchPath("include/pushwoosh_flutter")
            ]
        )
    ]
)
