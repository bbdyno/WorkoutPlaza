import ProjectDescription

let project = Project(
    name: "RunningKit",
    organizationName: "bbdyno",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "5.0",
            "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
            "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor"
        ]
    ),
    targets: [
        .target(
            name: "RunningKit",
            destinations: [.iPhone, .iPad, .appleWatch],
            product: .framework,
            bundleId: "com.bbdyno.app.WorkoutPlaza.runningkit",
            deploymentTargets: .multiplatform(iOS: "18.0", watchOS: "10.0"),
            infoPlist: .default,
            sources: ["../../Targets/RunningKit/Sources/**"]
        )
    ]
)
