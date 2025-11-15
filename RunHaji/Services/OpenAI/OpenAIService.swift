//
//  OpenAIService.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import Foundation

// MARK: - Request/Response Models

private struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let response_format: ResponseFormat?

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Codable {
        let type: String
    }
}

private struct ChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}

private struct RoadmapGenerationResponse: Codable {
    let title: String
    let milestones: [MilestoneData]

    struct MilestoneData: Codable {
        let title: String
        let description: String
        let daysFromNow: Int

        enum CodingKeys: String, CodingKey {
            case title
            case description
            case daysFromNow = "days_from_now"
        }
    }
}

final class OpenAIService {
    static let shared = OpenAIService()

    private let apiKey: String?
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    private init() {
        self.apiKey = OpenAIConfig.apiKey
    }

    func generateRoadmap(for user: User) async throws -> Roadmap {
        guard let apiKey = apiKey else {
            throw OpenAIError.notConfigured
        }

        // Create prompt based on user profile
        let prompt = buildRoadmapPrompt(for: user)

        let request = ChatCompletionRequest(
            model: "gpt-4o-mini",
            messages: [
                ChatCompletionRequest.Message(
                    role: "system",
                    content: """
                    あなたはランニング初心者向けのパーソナルコーチです。
                    ユーザーのプロフィール情報に基づいて、達成可能で段階的なロードマップを作成してください。
                    必ずJSON形式で返してください。
                    """
                ),
                ChatCompletionRequest.Message(
                    role: "user",
                    content: prompt
                )
            ],
            temperature: 0.7,
            response_format: ChatCompletionRequest.ResponseFormat(type: "json_object")
        )

        // Make API request
        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OpenAIError.apiError("API request failed")
        }

        // Parse response
        let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = completionResponse.choices.first?.message.content else {
            throw OpenAIError.invalidResponse
        }

        // Parse JSON content
        let roadmapData = try JSONDecoder().decode(
            RoadmapGenerationResponse.self,
            from: content.data(using: .utf8)!
        )

        // Convert to Roadmap model
        let milestones = roadmapData.milestones.map { milestone in
            Milestone(
                title: milestone.title,
                description: milestone.description,
                targetDate: Calendar.current.date(byAdding: .day, value: milestone.daysFromNow, to: Date()),
                isCompleted: false,
                completedAt: nil,
                workouts: []
            )
        }

        let goal = user.profile.goal ?? .healthImprovement

        return Roadmap(
            userId: user.id.uuidString,
            title: roadmapData.title,
            goal: goal,
            targetDate: milestones.last?.targetDate,
            milestones: milestones
        )
    }

    private func buildRoadmapPrompt(for user: User) -> String {
        let profile = user.profile
        let goal = profile.goal?.description ?? "健康を改善したい"
        let age = profile.age.map { "\($0)歳" } ?? "不明"
        let availableTime = profile.availableTimePerWeek.map { "\($0)分/週" } ?? "不明"
        let currentFrequency = profile.currentFrequency.map { "週\($0)回" } ?? "なし"

        return """
        以下のプロフィールを持つランニング初心者のために、3〜5個のマイルストーンを含むロードマップを作成してください。

        【ユーザー情報】
        - 年齢: \(age)
        - 目標: \(goal)
        - 週の利用可能時間: \(availableTime)
        - 現在の運動頻度: \(currentFrequency)

        【要件】
        1. 各マイルストーンは達成可能で、段階的に難易度が上がること
        2. 初心者に優しく、怪我のリスクが低いこと
        3. ユーザーの目標に沿った内容であること
        4. 各マイルストーンの目標達成日は今日から何日後かを指定すること（7〜90日の範囲）

        以下のJSON形式で返してください：
        {
          "title": "ロードマップのタイトル",
          "milestones": [
            {
              "title": "マイルストーンのタイトル",
              "description": "具体的な達成目標",
              "days_from_now": 7
            }
          ]
        }
        """
    }

    func generateUpcomingWorkouts(for user: User, roadmap: Roadmap, count: Int = 3) async throws -> [UpcomingWorkout] {
        guard let apiKey = apiKey else {
            throw OpenAIError.notConfigured
        }

        let prompt = buildWorkoutPrompt(for: user, roadmap: roadmap, count: count)

        let request = ChatCompletionRequest(
            model: "gpt-4o-mini",
            messages: [
                ChatCompletionRequest.Message(
                    role: "system",
                    content: """
                    あなたはランニング初心者向けのトレーニングプランナーです。
                    ユーザーのロードマップと現在の進捗に基づいて、今後のワークアウトプランを提案してください。
                    必ずJSON形式で返してください。
                    """
                ),
                ChatCompletionRequest.Message(
                    role: "user",
                    content: prompt
                )
            ],
            temperature: 0.7,
            response_format: ChatCompletionRequest.ResponseFormat(type: "json_object")
        )

        // Make API request
        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OpenAIError.apiError("API request failed")
        }

        let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = completionResponse.choices.first?.message.content else {
            throw OpenAIError.invalidResponse
        }

        let workoutData = try JSONDecoder().decode(
            WorkoutPlanResponse.self,
            from: content.data(using: .utf8)!
        )

        return workoutData.workouts.map { workout in
            UpcomingWorkout(
                userId: user.id.uuidString,
                title: workout.title,
                estimatedDuration: workout.estimatedDuration * 60, // minutes to seconds
                targetDistance: workout.targetDistance.map { $0 * 1000 }, // km to meters
                notes: workout.notes
            )
        }
    }

    private func buildWorkoutPrompt(for user: User, roadmap: Roadmap, count: Int) -> String {
        let profile = user.profile
        let goal = profile.goal?.description ?? "健康を改善したい"
        let availableTime = profile.availableTimePerWeek.map { "\($0)分/週" } ?? "不明"

        // Find current milestone (first uncompleted one)
        let currentMilestone = roadmap.milestones.first { !$0.isCompleted }
        let milestoneInfo = currentMilestone.map {
            "現在のマイルストーン: \($0.title) - \($0.description ?? "")"
        } ?? "マイルストーンなし"

        return """
        以下のプロフィールを持つランニング初心者のために、今後\(count)回分のワークアウトプランを作成してください。

        【ユーザー情報】
        - 目標: \(goal)
        - 週の利用可能時間: \(availableTime)
        - \(milestoneInfo)

        【ロードマップタイトル】
        \(roadmap.title)

        【要件】
        1. 各ワークアウトは段階的に難易度が上がること
        2. 初心者に優しく、無理のない内容であること
        3. 現在のマイルストーンに向けて進捗できる内容であること
        4. 具体的な目標（距離または時間）を含めること

        以下のJSON形式で返してください：
        {
          "workouts": [
            {
              "title": "ワークアウトのタイトル",
              "estimatedDuration": 15,  // 分
              "targetDistance": 1.0,     // km (省略可)
              "notes": "具体的なアドバイスやポイント"
            }
          ]
        }
        """
    }
}

private struct WorkoutPlanResponse: Codable {
    let workouts: [WorkoutData]

    struct WorkoutData: Codable {
        let title: String
        let estimatedDuration: Double
        let targetDistance: Double?
        let notes: String

        enum CodingKeys: String, CodingKey {
            case title
            case estimatedDuration = "estimatedDuration"
            case targetDistance = "targetDistance"
            case notes
        }
    }
}

// MARK: - Error Types

enum OpenAIError: Error, LocalizedError {
    case notConfigured
    case apiError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "OpenAI APIキーが設定されていません。Config.plistにOPENAI_API_KEYを追加してください。"
        case .apiError(let message):
            return "OpenAI API エラー: \(message)"
        case .invalidResponse:
            return "OpenAIからの応答が無効です"
        }
    }
}
