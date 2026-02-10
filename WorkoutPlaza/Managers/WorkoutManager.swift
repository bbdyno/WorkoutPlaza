//
//  WorkoutManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import Foundation
import HealthKit
import CoreLocation

class WorkoutManager {
    static let shared = WorkoutManager()
    private let healthStore = HKHealthStore()
    
    private init() {}

    func authorizationState(completion: @escaping (HealthKitAuthorizationState) -> Void) {
        func complete(_ state: HealthKitAuthorizationState) {
            DispatchQueue.main.async {
                completion(state)
            }
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            complete(.notAvailable)
            return
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]

        healthStore.getRequestStatusForAuthorization(toShare: Set<HKSampleType>(), read: typesToRead) { status, error in
            if error != nil {
                complete(.unknown)
                return
            }

            switch status {
            case .unnecessary:
                complete(.authorized)
            case .shouldRequest:
                complete(.requestNeeded)
            case .unknown:
                complete(.unknown)
            @unknown default:
                complete(.unknown)
            }
        }
    }
    
    // MARK: - HealthKit 권한 요청
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available"]))
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            completion(success, error)
        }
    }
    
    // MARK: - 운동 가져오기 (GPS 유무와 관계없이 모든 운동)
    func fetchWorkouts(completion: @escaping ([WorkoutData]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 50, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                completion([])
                return
            }

            let dispatchGroup = DispatchGroup()
            var workoutDataArray: [WorkoutData] = []

            for workout in workouts {
                dispatchGroup.enter()

                self?.fetchRoute(for: workout) { route in
                    // GPS 경로 유무와 관계없이 모든 운동을 포함
                    let workoutData = WorkoutData(
                        id: workout.uuid,
                        workout: workout,
                        route: route
                    )
                    workoutDataArray.append(workoutData)
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(workoutDataArray)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - GPS 기반 운동 가져오기 (하위 호환용)
    func fetchGPSWorkouts(completion: @escaping ([WorkoutData]) -> Void) {
        fetchWorkouts { workouts in
            // GPS 경로가 있는 운동만 필터링
            let gpsWorkouts = workouts.filter { $0.hasRoute }
            completion(gpsWorkouts)
        }
    }
    
    // MARK: - 경로 데이터 가져오기
    private func fetchRoute(for workout: HKWorkout, completion: @escaping ([CLLocation]) -> Void) {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        let query = HKSampleQuery(sampleType: routeType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] query, samples, error in
            guard let routeSamples = samples as? [HKWorkoutRoute], let firstRoute = routeSamples.first else {
                completion([])
                return
            }
            
            var locations: [CLLocation] = []
            let routeQuery = HKWorkoutRouteQuery(route: firstRoute) { query, routeData, done, error in
                if let routeData = routeData {
                    locations.append(contentsOf: routeData)
                }
                
                if done {
                    completion(locations)
                }
            }
            
            self?.healthStore.execute(routeQuery)
        }
        
        healthStore.execute(query)
    }
}

enum HealthKitAuthorizationState {
    case notAvailable
    case requestNeeded
    case authorized
    case unknown
}

// MARK: - 데이터 모델
struct WorkoutData {
    let id: UUID
    let workout: HKWorkout
    let route: [CLLocation]

    /// GPS 경로 데이터 존재 여부
    var hasRoute: Bool {
        !route.isEmpty
    }

    var distance: Double {
        workout.totalDistance?.doubleValue(for: .meter()) ?? 0
    }
    
    var duration: TimeInterval {
        workout.duration
    }
    
    var startDate: Date {
        workout.startDate
    }
    
    var endDate: Date {
        workout.endDate
    }
    
    var workoutType: WorkoutType {
        switch workout.workoutActivityType {
        case .running, .cycling, .walking, .hiking:
            return .running
        default:
            return .running
        }
    }

    var workoutTypeDisplayName: String {
        switch workout.workoutActivityType {
        case .running:
            return WorkoutPlazaStrings.Workout.running
        case .cycling:
            return WorkoutPlazaStrings.Workout.cycling
        case .walking:
            return WorkoutPlazaStrings.Workout.walking
        case .hiking:
            return WorkoutPlazaStrings.Workout.hiking
        default:
            return WorkoutPlazaStrings.Workout.generic
        }
    }
    
    var pace: Double {
        // 분/km 계산
        guard distance > 0 else { return 0 }
        let distanceInKm = distance / 1000.0
        let durationInMinutes = duration / 60.0
        return durationInMinutes / distanceInKm
    }
    
    var avgSpeed: Double {
        // km/h 계산
        guard duration > 0 else { return 0 }
        let distanceInKm = distance / 1000.0
        let durationInHours = duration / 3600.0
        return distanceInKm / durationInHours
    }
    
    var calories: Double {
        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           let energyQuantity = workout.statistics(for: energyType)?.sumQuantity() {
            return energyQuantity.doubleValue(for: .kilocalorie())
        }
        return 0
    }

    var avgHeartRate: Double {
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
           let avgQuantity = workout.statistics(for: heartRateType)?.averageQuantity() {
            return avgQuantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        }
        return 0
    }
}
