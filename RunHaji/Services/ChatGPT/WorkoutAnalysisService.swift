//
//  WorkoutAnalysisService.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

final class WorkoutAnalysisService {
    static let shared = WorkoutAnalysisService()

    private let chatGPTService = ChatGPTService.shared

    private init() {}

    /// ワークアウトデータを分析して振り返りを生成
    func analyzeWorkout(
        session: WorkoutSession,
        userGoal: RunningGoal?,
        currentMilestone: Milestone?,
        recentSessions: [WorkoutSession]
    ) async throws -> WorkoutReflection {
        let systemPrompt = """
        あなたはランニング初心者をサポートするAIコーチです。
        ユーザーのワークアウトデータを分析して、励ましの言葉と具体的なアドバイスを提供してください。

        以下のJSON形式で回答してください:
        {
          "estimatedRPE": <1-10の整数>,
          "reflection": "<今日のワークアウトの振り返り（2-3文、ポジティブで励ます内容）>",
          "suggestions": "<次回への具体的なアドバイス（2-3文）>",
          "milestoneProgress": {
            "isAchieved": <true/false>,
            "achievementMessage": "<マイルストーン達成状況のメッセージ>"
          }
        }

        RPE（運動強度）の推定基準:
        - ペースが速い、距離が長い → RPE高め（7-10）
        - ペースが遅い、距離が短い → RPE低め（1-6）
        - 初心者の場合は控えめに評価

        マイルストーン達成判定基準:
        - 現在のマイルストーンのタイトルと説明を確認
        - 今日のワークアウトのデータ（距離、時間、ペース）と説明を比較
        - 達成条件を満たしている場合のみ isAchieved: true とする
        - 例: 「1kmを走りきる」→ 距離が1km以上ならtrue
        - 例: 「15分間のランニングを完了する」→ 時間が15分以上ならtrue
        - 明確な達成条件が不明な場合や、まだ達成していない場合は isAchieved: false
        """

        let userPrompt = buildUserPrompt(
            session: session,
            userGoal: userGoal,
            currentMilestone: currentMilestone,
            recentSessions: recentSessions
        )

        let jsonResponse = try await chatGPTService.generateText(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            useJSON: true
        )

        return try parseReflectionResponse(jsonResponse, workoutSessionId: session.id, milestoneId: currentMilestone?.id)
    }

    // MARK: - Private Methods

    private func buildUserPrompt(
        session: WorkoutSession,
        userGoal: RunningGoal?,
        currentMilestone: Milestone?,
        recentSessions: [WorkoutSession]
    ) -> String {
        let distance = session.distance / 1000.0 // meters to km
        let duration = session.duration / 60.0 // seconds to minutes
        let pace = distance > 0 ? duration / distance : 0

        var prompt = """
        【今日のワークアウト】
        - 距離: \(String(format: "%.2f", distance)) km
        - 時間: \(String(format: "%.1f", duration)) 分
        - ペース: \(String(format: "%.1f", pace)) 分/km
        - 消費カロリー: \(Int(session.calories)) kcal
        """

        if let goal = userGoal {
            prompt += "\n\n【ユーザーの目標】\n- \(goal.rawValue)"
        }

        if let milestone = currentMilestone {
            prompt += "\n\n【現在のマイルストーン】\n- \(milestone.title)"
            if let description = milestone.description {
                prompt += "\n- 内容: \(description)"
            }
        }

        if !recentSessions.isEmpty {
            let recentDistance = recentSessions.reduce(0.0) { $0 + $1.distance } / 1000.0
            let recentCount = recentSessions.count
            prompt += "\n\n【最近のワークアウト（過去7日間）】\n- 回数: \(recentCount)回\n- 合計距離: \(String(format: "%.2f", recentDistance)) km"
        }

        return prompt
    }

    private func parseReflectionResponse(_ jsonString: String, workoutSessionId: UUID, milestoneId: UUID?) throws -> WorkoutReflection {
        guard let data = jsonString.data(using: .utf8) else {
            throw ChatGPTError.decodingError("Invalid UTF-8 string")
        }

        struct ReflectionResponse: Codable {
            let estimatedRPE: Int
            let reflection: String
            let suggestions: String
            let milestoneProgress: MilestoneProgressResponse

            struct MilestoneProgressResponse: Codable {
                let isAchieved: Bool
                let achievementMessage: String
            }
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(ReflectionResponse.self, from: data)

        // Validate RPE
        guard (1...10).contains(response.estimatedRPE) else {
            throw ChatGPTError.decodingError("Invalid RPE value: \(response.estimatedRPE)")
        }

        let milestoneProgress = MilestoneProgress(
            milestoneId: milestoneId,
            isAchieved: response.milestoneProgress.isAchieved,
            achievementMessage: response.milestoneProgress.achievementMessage
        )

        return WorkoutReflection(
            workoutSessionId: workoutSessionId,
            estimatedRPE: response.estimatedRPE,
            reflection: response.reflection,
            suggestions: response.suggestions,
            milestoneProgress: milestoneProgress
        )
    }
}
