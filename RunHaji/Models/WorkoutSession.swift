//
//  WorkoutSession.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

struct WorkoutSession: Codable, Identifiable {
    let id: UUID
    let userId: String
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval // seconds
    let distance: Double // meters
    let calories: Double // kcal
    let rpe: Int? // Rate of Perceived Exertion (1-10)
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case duration
        case distance
        case calories
        case rpe
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        userId: String,
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        distance: Double,
        calories: Double,
        rpe: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.distance = distance
        self.calories = calories
        self.rpe = rpe
        self.createdAt = createdAt
    }
}
