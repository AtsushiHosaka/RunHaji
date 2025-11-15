//
//  HealthKitManager.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import HealthKit
import Combine

// For HKError type checking
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var workouts: [HKWorkout] = []

    // Current workout tracking
    @Published var isWorkoutActive = false
    @Published var isPaused = false
    @Published var currentDistance: Double = 0.0 // meters
    @Published var currentDuration: TimeInterval = 0.0 // seconds
    @Published var currentCalories: Double = 0.0 // kcal
    @Published var currentHeartRate: Double? = nil // bpm
    @Published var currentPace: Double? = nil // min/km

    private let healthKitService = HealthKitService.shared
    private var timer: Timer?
    private var workoutStartDate: Date?

    deinit {
        timer?.invalidate()
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            try await healthKitService.requestAuthorization()
            isAuthorized = true
        } catch {
            print("HealthKit authorization failed: \(error)")
            isAuthorized = false
        }
    }

    // MARK: - Workout Management

    func startWorkout() {
        guard !isWorkoutActive else {
            print("⚠️ Workout already active, ignoring start request")
            return
        }

        print("🏃 Starting workout...")

        Task {
            do {
                try await healthKitService.startWorkoutSession()

                print("✅ Workout session started successfully")

                workoutStartDate = Date()
                isWorkoutActive = true
                isPaused = false
                currentDistance = 0.0
                currentDuration = 0.0
                currentCalories = 0.0
                currentHeartRate = nil
                currentPace = nil

                // Start timer to update UI
                startTimer()
                print("✅ Timer started")
            } catch {
                print("❌ Failed to start workout session: \(error)")
                print("Error details: \(error.localizedDescription)")
                if let hkError = error as? HKError {
                    print("HealthKit error code: \(hkError.code)")
                }
            }
        }
    }

    func pauseWorkout() {
        guard isWorkoutActive, !isPaused else { return }

        healthKitService.pauseWorkoutSession()
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resumeWorkout() {
        guard isWorkoutActive, isPaused else { return }

        healthKitService.resumeWorkoutSession()
        isPaused = false
        startTimer()
    }

    func endWorkout() async -> HKWorkout? {
        guard isWorkoutActive else { return nil }

        timer?.invalidate()
        timer = nil

        // Capture current values before ending
        let finalDistance = currentDistance
        let finalDuration = currentDuration
        let finalCalories = currentCalories

        print("🏁 Ending workout...")
        print("   Final Distance: \(finalDistance) meters")
        print("   Final Duration: \(finalDuration) seconds")
        print("   Final Calories: \(finalCalories) kcal")

        do {
            let workout = try await healthKitService.endWorkoutSession()

            print("✅ Workout ended successfully")
            print("   Workout.totalDistance: \(workout?.totalDistance?.doubleValue(for: .meter()) ?? 0) meters")
            print("   Workout.duration: \(workout?.duration ?? 0) seconds")
            print("   Workout.totalEnergyBurned: \(workout?.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) kcal")

            isWorkoutActive = false
            isPaused = false
            workoutStartDate = nil

            return workout
        } catch {
            print("❌ Failed to end workout: \(error)")
            return nil
        }
    }

    // MARK: - Timer

    private func startTimer() {
        // Use DispatchSource timer for better main thread handling
        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Update duration manually (instead of relying on HealthKit)
            if let startDate = self.workoutStartDate, !self.isPaused {
                let duration = Date().timeIntervalSince(startDate)

                // Force UI update on main thread
                DispatchQueue.main.async {
                    self.currentDuration = duration

                    // Update other data from HealthKit
                    self.currentDistance = self.healthKitService.getCurrentDistance()
                    self.currentCalories = self.healthKitService.getCurrentCalories()
                    self.currentHeartRate = self.healthKitService.getCurrentHeartRate()
                    self.updatePace()

                    // Log every 5 seconds
                    let seconds = Int(duration)
                    if seconds > 0 && seconds % 5 == 0 {
                        print("📊 Duration: \(seconds)s, Distance: \(self.currentDistance)m, Cal: \(self.currentCalories)")
                    }
                }
            }
        }
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    private func updateWorkoutData() {
        // This method is no longer used - timer handles updates directly
    }

    private func updatePace() {
        currentPace = healthKitService.calculatePace(
            distance: currentDistance,
            duration: currentDuration
        )
    }

    // MARK: - Data Retrieval

    func loadWorkouts() async {
        do {
            let fetchedWorkouts = try await healthKitService.getWorkouts(limit: 20)
            workouts = fetchedWorkouts
        } catch {
            print("Failed to load workouts: \(error)")
            workouts = []
        }
    }

    // MARK: - Helper Methods

    func getDistance(for workout: HKWorkout) -> Double {
        return healthKitService.getDistance(for: workout)
    }

    func getDuration(for workout: HKWorkout) -> TimeInterval {
        return healthKitService.getDuration(for: workout)
    }

    func getCalories(for workout: HKWorkout) -> Double {
        return healthKitService.getCalories(for: workout)
    }

    func getPace(for workout: HKWorkout) -> Double? {
        let distance = getDistance(for: workout)
        let duration = getDuration(for: workout)
        return healthKitService.calculatePace(distance: distance, duration: duration)
    }

    func getPace(for distance: Double, duration: TimeInterval) -> Double? {
        return healthKitService.calculatePace(distance: distance, duration: duration)
    }

    func formatPace(_ pace: Double?) -> String {
        return healthKitService.formatPace(pace)
    }

    func formatDistance(_ distance: Double) -> String {
        let km = distance / 1000.0
        return String(format: "%.2f km", km)
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
