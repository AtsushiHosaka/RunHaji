//
//  HealthKitManager.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var workouts: [HKWorkout] = []

    // Current workout tracking
    @Published var isWorkoutActive = false
    @Published var currentDistance: Double = 0.0 // meters
    @Published var currentDuration: TimeInterval = 0.0 // seconds
    @Published var currentPace: Double? = nil // min/km

    private let healthKitService = HealthKitService.shared
    private var workoutStartDate: Date?
    private var timer: Timer?

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
        guard !isWorkoutActive else { return }

        workoutStartDate = Date()
        isWorkoutActive = true
        currentDistance = 0.0
        currentDuration = 0.0
        currentPace = nil

        // Start timer to update duration
        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startDate = self.workoutStartDate else { return }
                self.currentDuration = Date().timeIntervalSince(startDate)
                self.updatePace()
            }
        }
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    func updateDistance(_ distance: Double) {
        currentDistance = distance
        updatePace()
    }

    private func updatePace() {
        currentPace = healthKitService.calculatePace(
            distance: currentDistance,
            duration: currentDuration
        )
    }

    func endWorkout(calories: Double = 0.0) async {
        guard isWorkoutActive, let startDate = workoutStartDate else { return }

        timer?.invalidate()
        timer = nil

        let endDate = Date()
        isWorkoutActive = false

        // Save workout to HealthKit
        do {
            try await healthKitService.saveWorkout(
                activityType: .running,
                start: startDate,
                end: endDate,
                distance: currentDistance,
                calories: calories,
                metadata: nil
            )
            print("Workout saved successfully")
        } catch {
            print("Failed to save workout: \(error)")
        }

        // Reset tracking values
        workoutStartDate = nil
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
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
