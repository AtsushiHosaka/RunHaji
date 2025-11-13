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
    @Published var distance: Double = 0.0 // meters
    @Published var duration: TimeInterval = 0.0 // seconds
    @Published var pace: Double? = nil // min/km
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
        healthKitManager.$currentDistance
            .assign(to: &$distance)

        healthKitManager.$currentDuration
            .assign(to: &$duration)

        healthKitManager.$currentPace
            .assign(to: &$pace)

        healthKitManager.$isWorkoutActive
            .assign(to: &$isRunning)
    }

    // MARK: - Workout Control

    func startWorkout() {
        // Request location authorization if needed
        let authStatus = locationManager.authorizationStatus
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }

        // Start workout tracking
        healthKitManager.startWorkout()

        // Start location updates
        locationManager.startUpdatingLocation()
        lastLocation = nil

        isRunning = true
    }

    func requestEndWorkout() {
        showingEndWorkoutAlert = true
    }

    func endWorkout() async {
        // Stop location updates
        locationManager.stopUpdatingLocation()

        // End workout in HealthKit
        await healthKitManager.endWorkout(calories: 0.0)

        isRunning = false
        lastLocation = nil
        showingEndWorkoutAlert = false
    }

    func cancelEndWorkout() {
        showingEndWorkoutAlert = false
    }

    // MARK: - Formatting Helpers

    func formattedDistance() -> String {
        let km = distance / 1000.0
        return String(format: "%.2f", km)
    }

    func formattedDuration() -> String {
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
        guard let pace = pace else {
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

                // Only update if the distance increment is reasonable (< 100m)
                // This helps filter out GPS inaccuracies
                if distanceIncrement > 0 && distanceIncrement < 100 {
                    let newDistance = distance + distanceIncrement
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
