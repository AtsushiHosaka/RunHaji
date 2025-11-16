//
//  RunningViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import Combine
import HealthKit

@MainActor
class RunningViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var showingEndWorkoutAlert = false
    @Published var showingScoringView = false
    @Published var errorMessage: String?
    @Published var completedWorkout: HKWorkout?

    // Real-time workout data
    @Published var currentDistance: Double = 0.0
    @Published var currentDuration: TimeInterval = 0.0
    @Published var currentCalories: Double = 0.0

    private let healthKitManager: HealthKitManager
    private var cancellables = Set<AnyCancellable>()

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
        observeHealthKitManager()
    }

    // MARK: - Setup

    private func observeHealthKitManager() {
        // Observe HealthKitManager's published properties
        healthKitManager.$isWorkoutActive
            .assign(to: &$isRunning)

        healthKitManager.$isPaused
            .assign(to: &$isPaused)

        // Observe workout data for real-time updates
        healthKitManager.$currentDistance
            .assign(to: &$currentDistance)

        healthKitManager.$currentDuration
            .assign(to: &$currentDuration)

        healthKitManager.$currentCalories
            .assign(to: &$currentCalories)
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        await healthKitManager.requestAuthorization()
    }

    // MARK: - Workout Control

    func startWorkout() {
        healthKitManager.startWorkout()
    }

    func pauseWorkout() {
        healthKitManager.pauseWorkout()
    }

    func resumeWorkout() {
        healthKitManager.resumeWorkout()
    }

    func requestEndWorkout() {
        showingEndWorkoutAlert = true
    }

    func endWorkout() async {
        if let workout = await healthKitManager.endWorkout() {
            completedWorkout = workout
            showingEndWorkoutAlert = false
            showingScoringView = true
        }
    }

    func cancelEndWorkout() {
        showingEndWorkoutAlert = false
    }

    // MARK: - Formatting Helpers

    func formattedDistance() -> String {
        let km = currentDistance / 1000.0
        return String(format: "%.2f", km)
    }

    func formattedDuration() -> String {
        let duration = currentDuration
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    func formattedCalories() -> String {
        return String(format: "%.0f", currentCalories)
    }
}
