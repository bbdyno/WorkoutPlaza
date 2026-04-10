import Foundation
import ProjectDescription

private let teamID: SettingValue = "M79H9K226Y"
private let debugProvisioningProfileName: SettingValue = "WorkoutPlaza App Provisioning"
private let debugProvisioningProfileUUID: SettingValue = "7a672c61-38dc-4008-a0ae-3d17c038f7b0"
private let releaseProvisioningProfileName: SettingValue = "WorkoutPlaza App Distribution Provisioning"
private let releaseProvisioningProfileUUID: SettingValue = "9fd5c43e-57b4-4f12-86da-e2888b5dbfc9"
private let storeKitConfigurationRelativePath = "../../Configs/StoreKit/WorkoutPlaza.storekit"
private let storeKitConfigurationURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent(storeKitConfigurationRelativePath)
    .standardizedFileURL
private let workoutPlazaRunActionOptions: RunActionOptions = FileManager.default.fileExists(atPath: storeKitConfigurationURL.path)
    ? .options(storeKitConfigurationPath: .relativeToManifest(storeKitConfigurationRelativePath))
    : .options()

let project = Project(
    name: "WorkoutPlazaApp",
    organizationName: "bbdyno",
    settings: .settings(
        base: [
            "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
            "SWIFT_VERSION": "5.0",
            "DEVELOPMENT_TEAM": teamID,
            "MARKETING_VERSION": "1.2.0",
            "CURRENT_PROJECT_VERSION": "2026.04.10.1",
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
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "UILaunchScreen": [
                    "UIImageRespectsSafeAreaInsets": true,
                    "UIColorName": "systemBackground"
                ],
                "UIAppFonts": [
                    "Alata-Regular.ttf",
                    "BebasNeue-Regular.ttf",
                    "Explora-Regular.ttf",
                    "OoohBaby-Regular.ttf",
                    "GmarketSansTTFLight.ttf",
                    "GmarketSansTTFMedium.ttf",
                    "GmarketSansTTFBold.ttf",
                    "Paperlogy-1Thin.ttf",
                    "Paperlogy-2ExtraLight.ttf",
                    "Paperlogy-3Light.ttf",
                    "Paperlogy-4Regular.ttf",
                    "Paperlogy-5Medium.ttf",
                    "Paperlogy-6SemiBold.ttf",
                    "Paperlogy-7Bold.ttf",
                    "Paperlogy-8ExtraBold.ttf",
                    "Paperlogy-9Black.ttf",
                    "RIDIBatang.otf",
                    "PaytoneOne-Regular.ttf",
                    "SpaceMono-Regular.ttf",
                    "SpaceMono-Bold.ttf",
                    "Caveat-Regular.ttf",
                    "Caveat-Bold.ttf",
                    "Gaegu-Regular.ttf",
                    "Gaegu-Bold.ttf",
                    "Pretendard-Regular.otf",
                    "Pretendard-SemiBold.otf",
                    "Pretendard-Bold.otf",
                    "Montserrat-Regular.ttf",
                    "Montserrat-SemiBold.ttf",
                    "Montserrat-Bold.ttf"
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
                "CFBundleURLTypes": [
                    [
                        "CFBundleURLName": "com.bbdyno.app.WorkoutPlaza",
                        "CFBundleTypeRole": "Editor",
                        "CFBundleURLSchemes": ["workoutplaza"]
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
            sources: ["../../WorkoutPlaza/**/*.swift"],
            resources: [
                "../../WorkoutPlaza/Assets.xcassets",
                "../../WorkoutPlaza/Base.lproj/**",
                "../../WorkoutPlaza/Fonts/**",
                "../../Resources/**/*.strings",
                "../../WorkoutPlaza/GoogleService-Info.plist"
            ],
            entitlements: "../../WorkoutPlaza/WorkoutPlaza.entitlements",
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
                        "CODE_SIGN_IDENTITY": "Apple Development",
                        "PROVISIONING_PROFILE": debugProvisioningProfileUUID,
                        "PROVISIONING_PROFILE_SPECIFIER": debugProvisioningProfileName,
                        "DEVELOPMENT_TEAM": teamID
                    ]),
                    .release(name: "Release", settings: [
                        "CODE_SIGN_STYLE": "Manual",
                        "CODE_SIGN_IDENTITY": "Apple Distribution",
                        "PROVISIONING_PROFILE": releaseProvisioningProfileUUID,
                        "PROVISIONING_PROFILE_SPECIFIER": releaseProvisioningProfileName,
                        "DEVELOPMENT_TEAM": teamID
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
            sources: ["../../WorkoutPlazaTests/**/*.swift"],
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
            sources: ["../../WorkoutPlazaUITests/**/*.swift"],
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
                ["WorkoutPlazaTests", "WorkoutPlazaUITests"],
                configuration: .debug
            ),
            runAction: .runAction(
                configuration: .debug,
                executable: "WorkoutPlaza",
                options: workoutPlazaRunActionOptions
            ),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(configuration: .release),
            analyzeAction: .analyzeAction(configuration: .debug)
        )
    ]
)
