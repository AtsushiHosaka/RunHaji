//
//  WorkoutReflection.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

struct WorkoutReflection: Codable, Identifiable {
    let id: UUID
    let workoutSessionId: UUID
    let estimatedRPE: Int // ChatGPTが推定したRPE (1-10)
    let reflection: String // 今日のワークアウトの振り返り
    let suggestions: String // 次回へのアドバイス
    let milestoneProgress: MilestoneProgress?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        workoutSessionId: UUID,
        estimatedRPE: Int,
        reflection: String,
        suggestions: String,
        milestoneProgress: MilestoneProgress? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.workoutSessionId = workoutSessionId
        self.estimatedRPE = estimatedRPE
        self.reflection = reflection
        self.suggestions = suggestions
        self.milestoneProgress = milestoneProgress
        self.createdAt = createdAt
    }
}

struct MilestoneProgress: Codable {
    let milestoneId: UUID?
    let isAchieved: Bool
    let achievementMessage: String

    init(milestoneId: UUID? = nil, isAchieved: Bool, achievementMessage: String) {
        self.milestoneId = milestoneId
        self.isAchieved = isAchieved
        self.achievementMessage = achievementMessage
    }
}
