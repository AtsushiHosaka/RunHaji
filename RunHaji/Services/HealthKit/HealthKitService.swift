//
//  HealthKitService.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import HealthKit

@MainActor
class HealthKitService: NSObject {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()

    // Workout session
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    // HealthKit で読み取るデータタイプ
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!
    ]

    // HealthKit に書き込むデータタイプ
    private let typesToWrite: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!
    ]

    override private init() {
        super.init()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
    }

    // MARK: - Workout Session Management

    func startWorkoutSession() async throws {
        print("📱 Creating workout configuration...")
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        print("📱 Creating workout session...")
        // Create workout session
        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        let builder = session.associatedWorkoutBuilder()

        print("📱 Setting up data source...")
        // Set data source
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )

        workoutSession = session
        workoutBuilder = builder

        print("📱 Starting activity...")
        // Start session
        session.startActivity(with: Date())

        print("📱 Beginning collection...")
        try await builder.beginCollection(at: Date())

        print("✅ Workout session fully initialized")
    }

    func pauseWorkoutSession() {
        guard let session = workoutSession else { return }
        session.pause()
    }

    func resumeWorkoutSession() {
        guard let session = workoutSession else { return }
        session.resume()
    }

    func endWorkoutSession() async throws -> HKWorkout? {
        guard let session = workoutSession,
              let builder = workoutBuilder else {
            return nil
        }

        // End collection
        session.end()
        try await builder.endCollection(at: Date())

        // Finalize workout
        let workout = try await builder.finishWorkout()

        // Clean up
        workoutSession = nil
        workoutBuilder = nil

        return workout
    }

    // Get current workout statistics
    func getWorkoutStatistics(for identifier: HKQuantityTypeIdentifier) -> HKStatistics? {
        guard let builder = workoutBuilder else { return nil }
        let quantityType = HKQuantityType.quantityType(forIdentifier: identifier)!
        return builder.statistics(for: quantityType)
    }

    func getCurrentDistance() -> Double {
        guard let statistics = getWorkoutStatistics(for: .distanceWalkingRunning) else {
            return 0.0
        }
        return statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0
    }

    func getCurrentCalories() -> Double {
        guard let statistics = getWorkoutStatistics(for: .activeEnergyBurned) else {
            return 0.0
        }
        return statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0
    }

    func getCurrentHeartRate() -> Double? {
        guard let statistics = getWorkoutStatistics(for: .heartRate) else {
            return nil
        }
        return statistics.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    }

    func getCurrentDuration() -> TimeInterval {
        guard let builder = workoutBuilder else { return 0 }
        return builder.elapsedTime
    }

    // MARK: - Data Retrieval

    func getWorkouts(limit: Int = 10) async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

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

    func calculatePace(distance: Double, duration: TimeInterval) -> Double? {
        // Pace in minutes per kilometer
        guard distance > 0 else { return nil }
        let distanceInKm = distance / 1000.0
        let durationInMinutes = duration / 60.0
        return durationInMinutes / distanceInKm
    }

    func formatPace(_ pace: Double?) -> String {
        guard let pace = pace, pace.isFinite else {
            return "--:--/km"
        }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d/km", minutes, seconds)
    }
}

// MARK: - Errors

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case dataNotFound

    var errorDescription: String? {
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
