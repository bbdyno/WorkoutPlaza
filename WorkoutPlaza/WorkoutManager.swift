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
    
    // MARK: - GPS 기반 운동 가져오기
    func fetchGPSWorkouts(completion: @escaping ([WorkoutData]) -> Void) {
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
                    if !route.isEmpty {
                        let workoutData = WorkoutData(
                            workout: workout,
                            route: route
                        )
                        workoutDataArray.append(workoutData)
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(workoutDataArray)
            }
        }
        
        healthStore.execute(query)
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

// MARK: - 데이터 모델
struct WorkoutData {
    let workout: HKWorkout
    let route: [CLLocation]
    
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
    
    var workoutType: String {
        switch workout.workoutActivityType {
        case .running:
            return "러닝"
        case .cycling:
            return "사이클링"
        case .walking:
            return "걷기"
        case .hiking:
            return "하이킹"
        default:
            return "운동"
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
}
