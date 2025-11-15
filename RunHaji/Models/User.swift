//
//  User.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var email: String?
    var profile: UserProfile

    init(id: UUID = UUID(), email: String? = nil, profile: UserProfile) {
        self.id = id
        self.email = email
        self.profile = profile
    }
}

struct UserProfile: Codable {
    var age: Int?
    var height: Double? // cm
    var weight: Double? // kg
    var availableTimePerWeek: Int? // hours
    var idealFrequency: Int? // times per week
    var currentFrequency: Int? // times per week
    var goal: RunningGoal?
    var createdAt: Date
    var updatedAt: Date

    init(
        age: Int? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        availableTimePerWeek: Int? = nil,
        idealFrequency: Int? = nil,
        currentFrequency: Int? = nil,
        goal: RunningGoal? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.age = age
        self.height = height
        self.weight = weight
        self.availableTimePerWeek = availableTimePerWeek
        self.idealFrequency = idealFrequency
        self.currentFrequency = currentFrequency
        self.goal = goal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum RunningGoal: String, Codable, CaseIterable {
    case loseWeight = "体重を減らしたい"
    case buildStamina = "体力をつけたい"
    case stressRelief = "ストレス解消したい"
    case completeDistance = "特定の距離を完走したい"
    case healthImprovement = "健康を改善したい"

    // 表示用タイトル
    var displayTitle: String {
        switch self {
        case .loseWeight:
            return NSLocalizedString("goal.option.lose_weight.title", comment: "")
        case .buildStamina:
            return NSLocalizedString("goal.option.build_stamina.title", comment: "")
        case .stressRelief:
            return NSLocalizedString("goal.option.stress_relief.title", comment: "")
        case .completeDistance:
            return NSLocalizedString("goal.option.complete_distance.title", comment: "")
        case .healthImprovement:
            return NSLocalizedString("goal.option.health_improvement.title", comment: "")
        }
    }

    // 表示用サブタイトル
    var displaySubtitle: String {
        switch self {
        case .loseWeight:
            return NSLocalizedString("goal.option.lose_weight.subtitle", comment: "")
        case .buildStamina:
            return NSLocalizedString("goal.option.build_stamina.subtitle", comment: "")
        case .stressRelief:
            return NSLocalizedString("goal.option.stress_relief.subtitle", comment: "")
        case .completeDistance:
            return NSLocalizedString("goal.option.complete_distance.subtitle", comment: "")
        case .healthImprovement:
            return NSLocalizedString("goal.option.health_improvement.subtitle", comment: "")
        }
    }

    // 既存呼び出し互換のため（表示向けにローカライズ）
    var description: String {
        return displayTitle
    }

    // ロードマップのタイトル（表示用）
    var roadmapTitle: String {
        switch self {
        case .loseWeight:
            return NSLocalizedString("goal.roadmap_title.lose_weight", comment: "")
        case .buildStamina:
            return NSLocalizedString("goal.roadmap_title.build_stamina", comment: "")
        case .stressRelief:
            return NSLocalizedString("goal.roadmap_title.stress_relief", comment: "")
        case .completeDistance:
            return NSLocalizedString("goal.roadmap_title.complete_distance", comment: "")
        case .healthImprovement:
            return NSLocalizedString("goal.roadmap_title.health_improvement", comment: "")
        }
    }
}
