// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "SnapKit": .framework,
            "FirebaseRemoteConfig": .staticFramework,
            "FirebaseAnalytics": .staticFramework
        ]
    )
#endif

let package = Package(
    name: "WorkoutPlaza",
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0")
    ]
)
