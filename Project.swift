import ProjectDescription

let project = Project(
    name: "WorkoutPlaza",
    organizationName: "bbdyno",
    settings: .settings(
        base: [
            "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
            "SWIFT_VERSION": "5.0",
            "DEVELOPMENT_TEAM": "M79H9K226Y",
            "MARKETING_VERSION": "1.0",
            "CURRENT_PROJECT_VERSION": "1",
            "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
            "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
            "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "SUPPORTS_MACCATALYST": "NO",
            "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO"
        ]
    ),
    targets: [
        .target(
            name: "WorkoutPlaza",
            destinations: .iOS,
            product: .app,
            bundleId: "com.bbdyno.app.WorkoutPlaza",
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [
                    "UIImageRespectsSafeAreaInsets": true,
                    "UIColorName": "systemBackground"
                ],
                "UIAppFonts": [
                    "Alata-Regular.ttf",
                    "BebasNeue-Regular.ttf",
                    "Explora-Regular.ttf",
                    "OoohBaby-Regular.ttf"
                ],
                "NSHealthShareUsageDescription": "운동 기록과 경로를 확인하기 위해 HealthKit 데이터 접근이 필요합니다.",
                "NSHealthUpdateUsageDescription": "운동 기록을 업데이트하기 위해 HealthKit 데이터 접근이 필요합니다.",
                "NSPhotoLibraryAddUsageDescription": "운동 기록 이미지를 앨범에 저장하기 위해 사진 라이브러리 접근 권한이 필요합니다.",
                "NSPhotoLibraryUsageDescription": "배경 이미지를 선택하고 운동 기록 이미지를 저장하기 위해 사진 라이브러리 접근 권한이 필요합니다.",
                "LSSupportsOpeningDocumentsInPlace": true,
                "UISupportsDocumentBrowser": true,
                "UIFileSharingEnabled": true,
                "CFBundleDocumentTypes": [
                    [
                        "CFBundleTypeName": "WorkoutPlaza Workout",
                        "CFBundleTypeRole": "Editor",
                        "LSHandlerRank": "Owner",
                        "LSItemContentTypes": ["com.workoutplaza.workout"]
                    ]
                ],
                "UTExportedTypeDeclarations": [
                    [
                        "UTTypeIdentifier": "com.workoutplaza.workout",
                        "UTTypeDescription": "WorkoutPlaza Workout File",
                        "UTTypeConformsTo": ["public.json", "public.data"],
                        "UTTypeTagSpecification": [
                            "public.filename-extension": ["wplaza"]
                        ]
                    ]
                ],
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                    "UISceneConfigurations": [
                        "UIWindowSceneSessionRoleApplication": [
                            [
                                "UISceneConfigurationName": "Default Configuration",
                                "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
                                "UISceneStoryboardFile": "Main"
                            ]
                        ]
                    ]
                ]
            ]),
            sources: ["WorkoutPlaza/**/*.swift"],
            resources: [
                "WorkoutPlaza/Assets.xcassets",
                "WorkoutPlaza/Base.lproj/**",
                "WorkoutPlaza/Fonts/**",
                "Resources/**/*.strings",
                "WorkoutPlaza/GoogleService-Info.plist"
            ],
            entitlements: "WorkoutPlaza/WorkoutPlaza.entitlements",
            dependencies: [
                .external(name: "SnapKit"),
                .external(name: "FirebaseRemoteConfig"),
                .external(name: "FirebaseAnalytics")
            ],
            settings: .settings(
                base: [
                    "TARGETED_DEVICE_FAMILY": "1,2",
                    "SUPPORTS_MACCATALYST": "NO",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                    "INFOPLIST_KEY_NSHealthShareUsageDescription": "운동 기록과 경로를 확인하기 위해 HealthKit 데이터 접근이 필요합니다.",
                    "INFOPLIST_KEY_NSHealthUpdateUsageDescription": "운동 기록을 업데이트하기 위해 HealthKit 데이터 접근이 필요합니다.",
                    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
                    "INFOPLIST_KEY_UIMainStoryboardFile": "Main",
                    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
                    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
                    "OTHER_LDFLAGS": ["-ObjC"]
                ],
                configurations: [
                    .debug(name: "Debug", settings: [
                        "CODE_SIGN_STYLE": "Manual",
                        "CODE_SIGN_IDENTITY": "iPhone Developer",
                        "PROVISIONING_PROFILE_SPECIFIER": "WorkoutPlaza App Provisioning",
                        "DEVELOPMENT_TEAM": "M79H9K226Y"
                    ]),
                    .release(name: "Release", settings: [
                        "CODE_SIGN_STYLE": "Manual",
                        "CODE_SIGN_IDENTITY": "Apple Distribution",
                        "PROVISIONING_PROFILE_SPECIFIER": "WorkoutPlaza App Distribution Provisioning",
                        "DEVELOPMENT_TEAM": "M79H9K226Y"
                    ])
                ]
            )
        ),
        .target(
            name: "WorkoutPlazaTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.bbdyno.app.WorkoutPlazaTests",
            infoPlist: .default,
            sources: ["WorkoutPlazaTests/**/*.swift"],
            dependencies: [
                .target(name: "WorkoutPlaza")
            ]
        ),
        .target(
            name: "WorkoutPlazaUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.bbdyno.app.WorkoutPlazaUITests",
            infoPlist: .default,
            sources: ["WorkoutPlazaUITests/**/*.swift"],
            dependencies: [
                .target(name: "WorkoutPlaza")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "WorkoutPlaza",
            shared: true,
            buildAction: .buildAction(targets: ["WorkoutPlaza"]),
            testAction: .targets(
                ["WorkoutPlazaTests"],
                configuration: .debug
            ),
            runAction: .runAction(
                configuration: .debug,
                executable: "WorkoutPlaza"
            ),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(configuration: .release),
            analyzeAction: .analyzeAction(configuration: .debug)
        )
    ]
)
