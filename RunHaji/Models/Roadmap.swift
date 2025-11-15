//
//  Roadmap.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

struct Roadmap: Codable, Identifiable {
    let id: UUID
    let userId: String
    var title: String
    var goal: RunningGoal
    var targetDate: Date?
    var milestones: [Milestone]
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case goal
        case targetDate = "target_date"
        case milestones
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        userId: String,
        title: String,
        goal: RunningGoal,
        targetDate: Date? = nil,
        milestones: [Milestone] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.goal = goal
        self.targetDate = targetDate
        self.milestones = milestones
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var completedMilestones: Int {
        milestones.filter { $0.isCompleted }.count
    }

    var progressPercentage: Double {
        guard !milestones.isEmpty else { return 0.0 }
        return Double(completedMilestones) / Double(milestones.count) * 100
    }
}

struct Milestone: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var targetDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var workouts: [WorkoutSession]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case targetDate = "target_date"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case workouts
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        targetDate: Date? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        workouts: [WorkoutSession] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.workouts = workouts

        // Validate state consistency
        assert(
            (isCompleted && completedAt != nil) || (!isCompleted && completedAt == nil),
            "Milestone state inconsistency: isCompleted=\(isCompleted) but completedAt=\(String(describing: completedAt))"
        )
    }

    var isValid: Bool {
        // Ensure consistency between isCompleted and completedAt
        if isCompleted {
            return completedAt != nil
        } else {
            return completedAt == nil
        }
    }
}

struct UpcomingWorkout: Codable, Identifiable {
    let id: UUID
    var title: String
    var estimatedDuration: TimeInterval
    var targetDistance: Double?
    var notes: String?

    init(
        id: UUID = UUID(),
        title: String,
        estimatedDuration: TimeInterval,
        targetDistance: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.estimatedDuration = estimatedDuration
        self.targetDistance = targetDistance
        self.notes = notes
    }
}
