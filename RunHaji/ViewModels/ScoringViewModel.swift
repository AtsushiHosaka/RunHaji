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

    // MARK: - Workout Completion Processing

    /// ワークアウト完了処理を一括で実行（分析→保存→通知）
    /// - Parameters:
    ///   - userGoal: ユーザーの目標
    ///   - currentMilestone: 現在のマイルストーン
    /// - Returns: マイルストーン達成の場合true
    func processWorkoutCompletion(userGoal: RunningGoal?, currentMilestone: Milestone?) async -> Bool {
        guard workoutSession != nil else {
            errorMessage = "ワークアウトデータが見つかりません"
            return false
        }

        // Step 1: Load recent workout sessions
        await loadRecentWorkoutSessions()

        // Step 2: Analyze workout with AI
        await analyzeWorkout(userGoal: userGoal, currentMilestone: currentMilestone)

        // Step 3: Save workout (with reflection or fallback)
        var milestoneAchieved = false
        if workoutReflection != nil {
            // Analysis succeeded
            milestoneAchieved = workoutReflection?.milestoneProgress?.isAchieved ?? false
            await saveWorkoutWithReflection()
        } else if errorMessage != nil {
            // Analysis failed - save with fallback
            print("⚠️ Analysis failed, saving with fallback reflection")
            await saveWorkoutWithFallback()
        }

        return milestoneAchieved
    }

    // MARK: - Recent Workout Sessions

    /// 最近のワークアウトセッションをSupabaseから読み込み（AI分析用）
    private func loadRecentWorkoutSessions() async {
        do {
            // Load recent workout sessions from Supabase (past 7 days)
            let sessions = try await SupabaseService.shared.getWorkoutSessions(userId: userId, limit: 20)
            let calendar = Calendar.current
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

            // Filter sessions from the past 7 days
            recentWorkoutSessions = sessions.filter { $0.startDate >= weekAgo }

            print("✅ Loaded \(recentWorkoutSessions.count) recent workout sessions for AI analysis")
        } catch {
            print("❌ Failed to load recent workout sessions: \(error)")
            recentWorkoutSessions = []
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

    func formatCalories(_ calories: Double) -> String {
        return String(format: "%.0f kcal", calories)
    }
}
