//
//  RunningViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class RunningViewModel: NSObject, ObservableObject {
    @Published var isRunning = false
    @Published var showingEndWorkoutAlert = false
    @Published var errorMessage: String?

    private let healthKitManager: HealthKitManager
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var cancellables = Set<AnyCancellable>()

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
        super.init()

        setupLocationManager()
        observeHealthKitManager()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 10 // Update every 10 meters
    }

    private func observeHealthKitManager() {
        // Observe HealthKitManager's published properties
        healthKitManager.$isWorkoutActive
            .assign(to: &$isRunning)
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        await healthKitManager.requestAuthorization()
    }

    // MARK: - Workout Control

    func startWorkout() {
        // Request location authorization if needed
        locationManager.requestWhenInUseAuthorization()

        // Start workout tracking
        healthKitManager.startWorkout()

        // Start location updates
        locationManager.startUpdatingLocation()
        lastLocation = nil
    }

    func requestEndWorkout() {
        showingEndWorkoutAlert = true
    }

    func endWorkout() async {
        // Stop location updates
        locationManager.stopUpdatingLocation()

        // End workout in HealthKit
        await healthKitManager.endWorkout(calories: 0.0)

        lastLocation = nil
        showingEndWorkoutAlert = false
    }

    func cancelEndWorkout() {
        showingEndWorkoutAlert = false
    }

    // MARK: - Formatting Helpers

    func formattedDistance() -> String {
        let km = healthKitManager.currentDistance / 1000.0
        return String(format: "%.2f", km)
    }

    func formattedDuration() -> String {
        let duration = healthKitManager.currentDuration
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    func formattedPace() -> String {
        guard let pace = healthKitManager.currentPace else {
            return "--:--"
        }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - CLLocationManagerDelegate

extension RunningViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }

            // Only count distance if we have a previous location
            if let lastLocation = lastLocation {
                let distanceIncrement = location.distance(from: lastLocation)

                // Only update if the distance increment is reasonable (< 100m) and GPS accuracy is good (< 50m)
                // This helps filter out GPS inaccuracies
                if distanceIncrement > 0 && distanceIncrement < 100 && location.horizontalAccuracy < 50 {
                    let newDistance = healthKitManager.currentDistance + distanceIncrement
                    healthKitManager.updateDistance(newDistance)
                }
            }

            self.lastLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("Location manager error: \(error.localizedDescription)")
            errorMessage = "位置情報の取得に失敗しました"
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            if status == .denied || status == .restricted {
                errorMessage = "位置情報へのアクセスが許可されていません"
            }
        }
    }
}
