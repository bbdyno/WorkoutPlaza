//
//  AppShowcaseManager.swift
//  WorkoutPlaza
//
//  Created by Codex on 4/9/26.
//

import CoreLocation
import UIKit

enum AppShowcaseManager {
    enum Screen: String {
        case home
        case statisticsAll = "statistics-all"
        case runningDetail = "running-detail"
        case climbingInput = "climbing-input"
        case savedCardDetail = "saved-card-detail"
    }

    static var isEnabled: Bool {
        requestedScreen != nil
    }

    static var requestedScreen: Screen? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "--showcase-screen"),
              arguments.indices.contains(flagIndex + 1) else {
            return nil
        }
        return Screen(rawValue: arguments[flagIndex + 1])
    }

    static func configure(window: UIWindow?) {
        guard let requestedScreen, let window, let rootViewController = window.rootViewController else { return }

        seedSampleData()
        WalkthroughManager.markCompleted()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            present(screen: requestedScreen, from: rootViewController)
        }
    }

    private static func seedSampleData() {
        AppDataManager.shared.resetAllInAppData()

        let sampleGym = ClimbingGym(
            id: "showcase_the_climb_hannam",
            name: "The Climb",
            logoSource: .none,
            gradeColors: ["#111111", "#3A3A3A", "#6A6963", "#A6A69D", "#D9D7CF"],
            branchColor: "#111111",
            isBuiltIn: false,
            metadata: .init(region: "Seoul", branch: "Hannam")
        )
        ClimbingGymManager.shared.saveGyms([sampleGym])

        let runningWorkouts = makeSampleRunningWorkouts()
        for workout in runningWorkouts {
            ExternalWorkoutManager.shared.saveWorkout(workout)
        }

        let climbingSessions = makeSampleClimbingSessions(gym: sampleGym)
        ClimbingDataManager.shared.saveSessions(climbingSessions)

        let primaryWorkout = runningWorkouts.first?.workoutData
        let cardDate = primaryWorkout?.startDate ?? Date()
        let cardTitle = "Evening Run Poster"
        let cardImage = makeSamplePosterImage(
            title: cardTitle,
            subtitle: "12.4 km  ·  58 min",
            date: cardDate
        )

        _ = WorkoutCardManager.shared.createCard(
            sportType: .running,
            workoutId: "showcase-card-workout",
            workoutTitle: cardTitle,
            workoutDate: cardDate,
            image: cardImage
        )
    }

    private static func present(screen: Screen, from rootViewController: UIViewController) {
        guard let tabBarController = rootViewController as? MainTabBarController else { return }

        switch screen {
        case .home:
            tabBarController.selectedIndex = 0

        case .statisticsAll:
            tabBarController.selectedIndex = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard let navigationController = tabBarController.selectedViewController as? UINavigationController,
                      let statisticsViewController = navigationController.viewControllers.first as? StatisticsViewController else {
                    return
                }
                statisticsViewController.handlePeriodChanged(.all)
            }

        case .runningDetail:
            tabBarController.selectedIndex = 0
            guard let navigationController = tabBarController.selectedViewController as? UINavigationController,
                  let workout = ExternalWorkoutManager.shared.getAllWorkouts().first else {
                return
            }

            let detailViewController = RunningDetailViewController()
            detailViewController.externalWorkout = workout
            detailViewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(detailViewController, animated: false)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                detailViewController.applyTemplate(.dark)
                detailViewController.applyWidgetTemplate(.basicRunning)
                for widget in detailViewController.widgets {
                    (widget as? Selectable)?.applyColor(ColorSystem.background)
                }
            }

        case .climbingInput:
            tabBarController.selectedIndex = 0
            let climbingInputViewController = ClimbingInputViewController()
            let navigationController = UINavigationController(rootViewController: climbingInputViewController)
            navigationController.modalPresentationStyle = .fullScreen
            topPresenter(from: tabBarController)?.present(navigationController, animated: false)

        case .savedCardDetail:
            tabBarController.selectedIndex = 2
            guard let navigationController = tabBarController.selectedViewController as? UINavigationController,
                  let card = WorkoutCardManager.shared.loadCards().first,
                  let image = WorkoutCardManager.shared.loadFullImage(for: card) else {
                return
            }

            let detailViewController = CardDetailViewController(card: card, image: image)
            navigationController.pushViewController(detailViewController, animated: false)
        }
    }

    private static func topPresenter(from rootViewController: UIViewController) -> UIViewController? {
        var current: UIViewController? = rootViewController
        while let presented = current?.presentedViewController {
            current = presented
        }
        return current
    }

    private static func makeSampleRunningWorkouts() -> [ExternalWorkout] {
        let calendar = Calendar.current
        let now = Date()

        let primaryRunDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let secondaryRunDate = calendar.date(byAdding: .day, value: -4, to: now) ?? now
        let monthRunDate = calendar.date(byAdding: .month, value: -2, to: now) ?? now
        let yearRunDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now

        return [
            ExternalWorkout(
                sourceFileName: "showcase-evening-run.wplaza",
                creatorName: nil,
                workoutData: makeRunningWorkout(
                    distance: 12_400,
                    duration: 58 * 60 + 21,
                    calories: 812,
                    avgHeartRate: 151,
                    startDate: primaryRunDate,
                    route: makeRoute(seedLatitude: 37.5348, seedLongitude: 126.9946)
                )
            ),
            ExternalWorkout(
                sourceFileName: "showcase-river-run.wplaza",
                creatorName: nil,
                workoutData: makeRunningWorkout(
                    distance: 7_800,
                    duration: 39 * 60 + 12,
                    calories: 496,
                    avgHeartRate: 145,
                    startDate: secondaryRunDate,
                    route: makeRoute(seedLatitude: 37.5201, seedLongitude: 127.0064)
                )
            ),
            ExternalWorkout(
                sourceFileName: "showcase-tempo-run.wplaza",
                creatorName: nil,
                workoutData: makeRunningWorkout(
                    distance: 9_300,
                    duration: 44 * 60 + 48,
                    calories: 588,
                    avgHeartRate: 149,
                    startDate: monthRunDate,
                    route: makeRoute(seedLatitude: 37.5089, seedLongitude: 127.0632)
                )
            ),
            ExternalWorkout(
                sourceFileName: "showcase-last-year-run.wplaza",
                creatorName: nil,
                workoutData: makeRunningWorkout(
                    distance: 15_100,
                    duration: 71 * 60 + 5,
                    calories: 914,
                    avgHeartRate: 153,
                    startDate: yearRunDate,
                    route: makeRoute(seedLatitude: 37.4988, seedLongitude: 127.0276)
                )
            )
        ]
    }

    private static func makeRunningWorkout(
        distance: Double,
        duration: TimeInterval,
        calories: Double,
        avgHeartRate: Double,
        startDate: Date,
        route: [RoutePoint]
    ) -> ExportableWorkoutData {
        let endDate = startDate.addingTimeInterval(duration)
        let pace = (duration / 60) / max(distance / 1000, 0.1)
        let avgSpeed = (distance / 1000) / max(duration / 3600, 0.1)

        return ExportableWorkoutData(
            type: .running,
            distance: distance,
            duration: duration,
            startDate: startDate,
            endDate: endDate,
            pace: pace,
            avgSpeed: avgSpeed,
            calories: calories,
            route: route,
            avgHeartRate: avgHeartRate
        )
    }

    private static func makeRoute(seedLatitude: Double, seedLongitude: Double) -> [RoutePoint] {
        let offsets: [(Double, Double)] = [
            (0.0000, 0.0000),
            (0.0006, 0.0008),
            (0.0015, 0.0013),
            (0.0026, 0.0017),
            (0.0035, 0.0025),
            (0.0044, 0.0037),
            (0.0050, 0.0046),
            (0.0061, 0.0050),
            (0.0072, 0.0059),
            (0.0080, 0.0071)
        ]

        return offsets.map { latOffset, lonOffset in
            RoutePoint(lat: seedLatitude + latOffset, lon: seedLongitude + lonOffset)
        }
    }

    private static func makeSampleClimbingSessions(gym: ClimbingGym) -> [ClimbingData] {
        let calendar = Calendar.current
        let now = Date()

        let sessionA = ClimbingData(
            gymName: gym.name,
            gymId: gym.id,
            gymBranch: gym.metadata?.branch,
            gymRegion: gym.metadata?.region,
            discipline: .bouldering,
            routes: [
                ClimbingRoute(grade: "V3", colorHex: "#111111", attempts: 2, isSent: true),
                ClimbingRoute(grade: "V4", colorHex: "#3A3A3A", attempts: 3, isSent: true),
                ClimbingRoute(grade: "V5", colorHex: "#6A6963", attempts: 5, isSent: false),
                ClimbingRoute(grade: "V2", colorHex: "#A6A69D", attempts: 1, isSent: true)
            ],
            sessionDate: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            sessionDuration: 90 * 60
        )

        let sessionB = ClimbingData(
            gymName: gym.name,
            gymId: gym.id,
            gymBranch: gym.metadata?.branch,
            gymRegion: gym.metadata?.region,
            discipline: .bouldering,
            routes: [
                ClimbingRoute(grade: "V2", colorHex: "#111111", attempts: 1, isSent: true),
                ClimbingRoute(grade: "V3", colorHex: "#3A3A3A", attempts: 2, isSent: true),
                ClimbingRoute(grade: "V4", colorHex: "#6A6963", attempts: 4, isSent: false)
            ],
            sessionDate: calendar.date(byAdding: .day, value: -6, to: now) ?? now,
            sessionDuration: 75 * 60
        )

        let sessionC = ClimbingData(
            gymName: gym.name,
            gymId: gym.id,
            gymBranch: gym.metadata?.branch,
            gymRegion: gym.metadata?.region,
            discipline: .leadEndurance,
            routes: [
                ClimbingRoute(grade: "5.11a", colorHex: "#111111", takes: 1, isSent: true),
                ClimbingRoute(grade: "5.11c", colorHex: "#3A3A3A", takes: 2, isSent: false)
            ],
            sessionDate: calendar.date(byAdding: .month, value: -3, to: now) ?? now,
            sessionDuration: 105 * 60
        )

        return [sessionA, sessionB, sessionC].sorted { $0.sessionDate > $1.sessionDate }
    }

    private static func makeSamplePosterImage(title: String, subtitle: String, date: Date) -> UIImage {
        let size = CGSize(width: 1080, height: 1440)
        let renderer = UIGraphicsImageRenderer(size: size)
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM d")
        let dateText = formatter.string(from: date).uppercased()

        return renderer.image { context in
            let cgContext = context.cgContext
            let colors = [
                UIColor(hex: "#F5F4EF")?.cgColor ?? UIColor.white.cgColor,
                UIColor(hex: "#D5D2CA")?.cgColor ?? UIColor.lightGray.cgColor,
                UIColor(hex: "#111111")?.cgColor ?? UIColor.black.cgColor
            ] as CFArray

            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 0.45, 1.0])
            cgContext.drawLinearGradient(
                gradient!,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            let arcPath = UIBezierPath()
            arcPath.move(to: CGPoint(x: 120, y: 1020))
            arcPath.addCurve(
                to: CGPoint(x: 920, y: 860),
                controlPoint1: CGPoint(x: 260, y: 880),
                controlPoint2: CGPoint(x: 620, y: 760)
            )
            arcPath.lineWidth = 16
            UIColor.white.withAlphaComponent(0.88).setStroke()
            arcPath.stroke()

            let brandAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 220, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 52, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            let metaAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 28, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.74)
            ]

            let monogram = NSAttributedString(string: "WP", attributes: brandAttributes)
            monogram.draw(at: CGPoint(x: 120, y: 128))

            let titleText = NSAttributedString(string: title.uppercased(), attributes: titleAttributes)
            titleText.draw(at: CGPoint(x: 120, y: 1060))

            let subtitleText = NSAttributedString(string: subtitle, attributes: metaAttributes)
            subtitleText.draw(at: CGPoint(x: 120, y: 1142))

            let dateString = NSAttributedString(string: dateText, attributes: metaAttributes)
            dateString.draw(at: CGPoint(x: 120, y: 1202))
        }
    }
}
