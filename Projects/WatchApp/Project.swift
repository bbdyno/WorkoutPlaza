import ProjectDescription

let project = Project(
    name: "WorkoutPlazaWatchProject",
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
            name: "WorkoutPlazaWatch",
            destinations: [.appleWatch],
            product: .app,
            bundleId: "com.bbdyno.app.WorkoutPlaza.watchkitapp",
            deploymentTargets: .watchOS("10.0"),
            infoPlist: .extendingDefault(with: [
                "WKApplication": true,
                "WKCompanionAppBundleIdentifier": "com.bbdyno.app.WorkoutPlaza",
                "WKBackgroundModes": ["workout-processing"],
                "NSLocationWhenInUseUsageDescription": "러닝 거리와 페이스를 측정하기 위해 위치 정보가 필요합니다.",
                "NSHealthShareUsageDescription": "심박수와 러닝 운동 데이터를 읽기 위해 건강 데이터 접근이 필요합니다.",
                "NSHealthUpdateUsageDescription": "러닝 운동 결과를 건강 앱에 저장하기 위해 건강 데이터 접근이 필요합니다."
            ]),
            sources: ["../../Targets/WorkoutPlazaWatch/Sources/**"],
            resources: [
                "../../Targets/WorkoutPlazaWatch/Resources/**"
            ],
            entitlements: "../../Targets/WorkoutPlazaWatch/WorkoutPlazaWatch.entitlements",
            dependencies: [
                .project(target: "RunningKit", path: "../RunningKit")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "WorkoutPlazaWatch",
            shared: true,
            buildAction: .buildAction(targets: ["WorkoutPlazaWatch"]),
            runAction: .runAction(
                configuration: .debug,
                executable: "WorkoutPlazaWatch"
            )
        )
    ]
)
