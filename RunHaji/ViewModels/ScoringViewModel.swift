//
//  ScoringViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import SwiftUI
import Combine
import HealthKit

@MainActor
class ScoringViewModel: ObservableObject {
    @Published var workoutSession: WorkoutSession?
    @Published var workoutReflection: WorkoutReflection?
    @Published var isAnalyzing: Bool = false
    @Published var isSaving: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var errorMessage: String?

    // Progress tracking
    @Published var weeklyDistance: Double = 0.0 // meters
    @Published var weeklyWorkouts: Int = 0
    @Published var progressPercentage: Double = 0.0

    private let healthKitManager: HealthKitManager
    private let userId: String
    private let analysisService = WorkoutAnalysisService.shared
    private var recentWorkoutSessions: [WorkoutSession] = []

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
        if let frequency = idealFrequency, frequency > 0 {
            progressPercentage = min(Double(weeklyWorkouts) / Double(frequency), 1.0) * 100
        }
    }

    /// 週間統計をロード
    private func loadWeeklyStats() async {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(byAdding: .day, value: -7, to: now) else { return }

        // Load recent workouts
        // Note: This loads up to 20 workouts. If user has more than 20 workouts in the past week,
        // some may not be included in the weekly stats calculation.
        await healthKitManager.loadWorkouts()

        // Calculate weekly totals and build recent workout sessions
        weeklyDistance = 0.0
        weeklyWorkouts = 0
        recentWorkoutSessions = []

        for workout in healthKitManager.workouts {
            if workout.startDate >= weekStart {
                weeklyDistance += healthKitManager.getDistance(for: workout)
                weeklyWorkouts += 1

                // Build WorkoutSession for AI analysis
                let session = WorkoutSession(
                    userId: userId,
                    startDate: workout.startDate,
                    endDate: workout.endDate,
                    duration: workout.duration,
                    distance: healthKitManager.getDistance(for: workout),
                    calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                    rpe: nil
                )
                recentWorkoutSessions.append(session)
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

    // MARK: - Workout Analysis

    /// 現在のマイルストーンをロード
    /// Note: This method is deprecated. The view layer should pass the current milestone
    /// from HomeViewModel's roadmap instead of loading it here.
    func loadCurrentMilestone() -> Milestone? {
        // TODO: Remove this method and have the view pass the milestone from HomeViewModel
        return nil
    }

    /// ワークアウトを分析して振り返りを生成
    func analyzeWorkout(userGoal: RunningGoal?, currentMilestone: Milestone?) async {
        guard let session = workoutSession else {
            errorMessage = "ワークアウトデータが見つかりません"
            return
        }

        isAnalyzing = true
        errorMessage = nil

        do {
            // Use recentWorkoutSessions (already populated by calculateWeeklyProgress -> loadWeeklyStats)
            // Analyze workout with ChatGPT
            let reflection = try await analysisService.analyzeWorkout(
                session: session,
                userGoal: userGoal,
                currentMilestone: currentMilestone,
                recentSessions: recentWorkoutSessions
            )

            workoutReflection = reflection
        } catch {
            print("Workout analysis failed: \(error.localizedDescription)")
            errorMessage = "振り返りの生成に失敗しました。ネットワーク接続を確認してください。"
        }

        isAnalyzing = false
    }

    // MARK: - Save Workout

    /// フォールバックreflectionを作成（AI分析失敗時）
    private func createFallbackReflection(session: WorkoutSession) -> WorkoutReflection {
        let distance = session.distance / 1000.0
        let duration = session.duration / 60.0

        // 簡易RPE推定
        let estimatedRPE: Int
        if distance < 1.0 {
            estimatedRPE = 4
        } else if distance < 3.0 {
            estimatedRPE = 5
        } else if distance < 5.0 {
            estimatedRPE = 6
        } else {
            estimatedRPE = 7
        }

        return WorkoutReflection(
            workoutSessionId: session.id,
            estimatedRPE: estimatedRPE,
            reflection: "今日も走ることができました！\(String(format: "%.2f", distance))kmを\(String(format: "%.0f", duration))分で完走しました。",
            suggestions: "次回も同じペースで走り続けましょう。少しずつ距離を伸ばしていきましょう。",
            milestoneProgress: MilestoneProgress(
                isAchieved: false,
                achievementMessage: "引き続き頑張りましょう！"
            )
        )
    }

    /// フォールバックreflectionで保存（AI分析失敗時）
    func saveWorkoutWithFallback() async {
        guard let session = workoutSession else {
            errorMessage = "ワークアウトデータが見つかりません"
            return
        }

        // Create fallback reflection
        let fallbackReflection = createFallbackReflection(session: session)
        workoutReflection = fallbackReflection

        // Save with fallback reflection
        await saveWorkoutWithReflection()
    }

    /// 振り返りを含めてワークアウトを保存
    func saveWorkoutWithReflection() async {
        guard var session = workoutSession else {
            errorMessage = "ワークアウトデータが見つかりません"
            return
        }

        guard let reflection = workoutReflection else {
            errorMessage = "振り返りが生成されていません"
            return
        }

        isSaving = true
        errorMessage = nil

        // Update session with estimated RPE
        session = WorkoutSession(
            id: session.id,
            userId: session.userId,
            startDate: session.startDate,
            endDate: session.endDate,
            duration: session.duration,
            distance: session.distance,
            calories: session.calories,
            rpe: reflection.estimatedRPE,
            createdAt: session.createdAt
        )

        // Save to Supabase
        do {
            try await SupabaseService.shared.saveWorkoutSession(session)
            try await SupabaseService.shared.saveWorkoutReflection(reflection)
            print("Workout session and reflection saved to Supabase successfully")
        } catch {
            errorMessage = "ワークアウトの保存に失敗しました: \(error.localizedDescription)"
            print("Failed to save to Supabase: \(error.localizedDescription)")
            isSaving = false
            return
        }

        workoutSession = session
        isSaving = false
        showSuccessMessage = true

        // Always notify HomeViewModel to refresh data
        NotificationCenter.default.post(
            name: NSNotification.Name("WorkoutReflectionSaved"),
            object: nil,
            userInfo: ["reflection": reflection]
        )

        // Auto-hide success message after 2 seconds
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        if !Task.isCancelled {
            showSuccessMessage = false
        }
    }

    // MARK: - Formatting Helpers

    func formatDistance(_ distance: Double) -> String {
        return healthKitManager.formatDistance(distance)
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        return healthKitManager.formatDuration(duration)
    }

    func formatPace(_ distance: Double, _ duration: TimeInterval) -> String {
        let pace = healthKitManager.getPace(for: distance, duration: duration)
        return healthKitManager.formatPace(pace)
    }

    func formatWeeklyDistance() -> String {
        return String(format: "%.1f km", weeklyDistance / 1000.0)
    }

    func formatCalories(_ calories: Double) -> String {
        return String(format: "%.0f kcal", calories)
    }
}
