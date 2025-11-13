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

    var description: String {
        return self.rawValue
    }
}
