//
//  HealthKitService.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import HealthKit

class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()

    // HealthKit で読み取るデータタイプ
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!
    ]

    // HealthKit に書き込むデータタイプ
    private let typesToWrite: Set<HKSampleType> = [
        HKObjectType.workoutType()
    ]

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
    }

    // MARK: - Workout Management

    func startWorkout(activityType: HKWorkoutActivityType = .running) -> HKWorkoutSession? {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            return session
        } catch {
            print("Failed to create workout session: \(error)")
            return nil
        }
    }

    func saveWorkout(
        activityType: HKWorkoutActivityType = .running,
        start: Date,
        end: Date,
        distance: Double, // meters
        calories: Double,
        metadata: [String: Any]? = nil
    ) async throws {
        let workout = HKWorkout(
            activityType: activityType,
            start: start,
            end: end,
            duration: end.timeIntervalSince(start),
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
            totalDistance: HKQuantity(unit: .meter(), doubleValue: distance),
            metadata: metadata
        )

        try await healthStore.save(workout)
    }

    // MARK: - Data Retrieval

    func getWorkouts(limit: Int = 10) async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: nil,
            limit: limit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching workouts: \(error)")
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    func getDistance(for workout: HKWorkout) -> Double {
        guard let distance = workout.totalDistance else {
            return 0.0
        }
        return distance.doubleValue(for: .meter())
    }

    func getDuration(for workout: HKWorkout) -> TimeInterval {
        return workout.duration
    }

    func getCalories(for workout: HKWorkout) -> Double {
        guard let calories = workout.totalEnergyBurned else {
            return 0.0
        }
        return calories.doubleValue(for: .kilocalorie())
    }

    // MARK: - Pace Calculation

    func calculatePace(distance: Double, duration: TimeInterval) -> Double {
        // Pace in minutes per kilometer
        guard distance > 0 else { return 0.0 }
        let distanceInKm = distance / 1000.0
        let durationInMinutes = duration / 60.0
        return durationInMinutes / distanceInKm
    }

    func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d/km", minutes, seconds)
    }
}

// MARK: - Errors

enum HealthKitError: Error {
    case notAvailable
    case authorizationDenied
    case dataNotFound

    var localizedDescription: String {
        switch self {
        case .notAvailable:
            return "HealthKitはこのデバイスで利用できません"
        case .authorizationDenied:
            return "HealthKitへのアクセスが拒否されました"
        case .dataNotFound:
            return "データが見つかりませんでした"
        }
    }
}
