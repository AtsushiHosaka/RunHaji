//
//  ScoringViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import SwiftUI

@MainActor
class ScoringViewModel: ObservableObject {
    @Published var selectedRPE: Int = 5
    @Published var workoutSession: WorkoutSession?
    @Published var isSaving: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var errorMessage: String?

    // Progress tracking
    @Published var weeklyDistance: Double = 0.0 // meters
    @Published var weeklyWorkouts: Int = 0
    @Published var progressPercentage: Double = 0.0

    private let healthKitManager: HealthKitManager
    private let userId: String

    init(healthKitManager: HealthKitManager, userId: String) {
        self.healthKitManager = healthKitManager
        self.userId = userId
    }

    // MARK: - Workout Data

    /// ワークアウトデータをロード
    func loadWorkoutData(startDate: Date, endDate: Date, distance: Double, duration: TimeInterval, calories: Double) {
        self.workoutSession = WorkoutSession(
            userId: userId,
            startDate: startDate,
            endDate: endDate,
            duration: duration,
            distance: distance,
            calories: calories,
            rpe: nil
        )
    }

    /// 現在のワークアウトデータをHealthKitManagerから取得
    func loadCurrentWorkout() {
        guard !healthKitManager.isWorkoutActive else { return }

        // Note: In a real implementation, this would be called after ending a workout
        // For now, we'll use the last workout data if available
    }

    // MARK: - Progress Calculation

    /// 週間進捗を計算
    func calculateWeeklyProgress(userGoal: RunningGoal?, idealFrequency: Int?) async {
        await loadWeeklyStats()

        // Calculate progress based on user's goal
        if let frequency = idealFrequency {
            progressPercentage = min(Double(weeklyWorkouts) / Double(frequency), 1.0) * 100
        }
    }

    /// 週間統計をロード
    private func loadWeeklyStats() async {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(byAdding: .day, value: -7, to: now) else { return }

        // Load recent workouts
        await healthKitManager.loadWorkouts()

        // Calculate weekly totals
        weeklyDistance = 0.0
        weeklyWorkouts = 0

        for workout in healthKitManager.workouts {
            if workout.startDate >= weekStart {
                weeklyDistance += healthKitManager.getDistance(for: workout)
                weeklyWorkouts += 1
            }
        }
    }

    /// 次のマイルストーンを取得
    func getNextMilestone(userGoal: RunningGoal?, idealFrequency: Int?) -> String {
        guard let frequency = idealFrequency else {
            return "目標を設定してください"
        }

        let remainingWorkouts = max(0, frequency - weeklyWorkouts)

        if remainingWorkouts == 0 {
            return "今週の目標達成！"
        } else if remainingWorkouts == 1 {
            return "あと1回のランで今週の目標達成！"
        } else {
            return "今週あと\(remainingWorkouts)回のランで目標達成"
        }
    }

    // MARK: - Save Workout

    /// RPEを含めてワークアウトを保存
    func saveWorkoutWithRPE() async {
        guard var session = workoutSession else {
            errorMessage = "ワークアウトデータが見つかりません"
            return
        }

        isSaving = true
        errorMessage = nil

        // Update session with RPE
        session = WorkoutSession(
            id: session.id,
            userId: session.userId,
            startDate: session.startDate,
            endDate: session.endDate,
            duration: session.duration,
            distance: session.distance,
            calories: session.calories,
            rpe: selectedRPE,
            createdAt: session.createdAt
        )

        // In a real implementation, save to Supabase
        // For now, just simulate a save
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

        workoutSession = session
        isSaving = false
        showSuccessMessage = true

        // Auto-hide success message after 2 seconds
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        showSuccessMessage = false
    }

    // MARK: - Formatting Helpers

    func formatDistance(_ distance: Double) -> String {
        return healthKitManager.formatDistance(distance)
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        return healthKitManager.formatDuration(duration)
    }

    func formatPace(_ distance: Double, _ duration: TimeInterval) -> String {
        let pace = healthKitManager.healthKitService.calculatePace(
            distance: distance,
            duration: duration
        )
        return healthKitManager.formatPace(pace)
    }

    func formatWeeklyDistance() -> String {
        return String(format: "%.1f km", weeklyDistance / 1000.0)
    }
}
