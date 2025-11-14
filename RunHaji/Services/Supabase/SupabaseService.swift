//
//  SupabaseService.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import Supabase

// MARK: - Data Transfer Objects

private struct UserProfileDTO: Codable {
    let user_id: String
    let email: String?
    let age: Int?
    let height: Double?
    let weight: Double?
    let available_time_per_week: Int?
    let ideal_frequency: Int?
    let current_frequency: Int?
    let goal: String?
    let updated_at: Double
}

private struct RoadmapDTO: Codable {
    let id: String
    let user_id: String
    let title: String
    let goal: String
    let target_date: Double?
    let updated_at: Double
}

private struct MilestoneDTO: Codable {
    let id: String
    let roadmap_id: String
    let title: String
    let description: String?
    let target_date: Double?
    let is_completed: Bool
    let completed_at: Double?
    let updated_at: Double
}

private struct WorkoutSessionDTO: Codable {
    let id: String
    let user_id: String
    let start_date: Double
    let end_date: Double
    let duration: Double
    let distance: Double
    let calories: Double
    let rpe: Int?
}

private struct WorkoutReflectionDTO: Codable {
    let id: String
    let workout_session_id: String
    let estimated_rpe: Int
    let reflection: String
    let suggestions: String
    let milestone_id: String?
    let is_milestone_achieved: Bool
    let achievement_message: String?
}

private struct UpcomingWorkoutDTO: Codable {
    let id: String
    let user_id: String
    let title: String
    let estimated_duration: Double
    let target_distance: Double?
    let notes: String?
}

final class SupabaseService {
    static let shared = SupabaseService()

    private let client: SupabaseClient?

    private init() {
        // Initialize Supabase client if configuration is available
        guard let urlString = SupabaseConfig.url,
              let url = URL(string: urlString),
              let anonKey = SupabaseConfig.anonKey else {
            print("Supabase configuration not found. Service will operate in offline mode.")
            self.client = nil
            return
        }

        self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    // MARK: - User Profile Management

    func saveUserProfile(_ user: User) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        // Convert User model to DTO
        let dto = UserProfileDTO(
            user_id: user.id.uuidString,
            email: user.email,
            age: user.profile.age,
            height: user.profile.height,
            weight: user.profile.weight,
            available_time_per_week: user.profile.availableTimePerWeek,
            ideal_frequency: user.profile.idealFrequency,
            current_frequency: user.profile.currentFrequency,
            goal: user.profile.goal?.rawValue,
            updated_at: Date().timeIntervalSince1970
        )

        try await client.database
            .from("user_profiles")
            .upsert(dto)
            .execute()
    }

    func getUserProfile(userId: UUID) async throws -> User? {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let response = try await client.database
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()

        let data = response.data
        if data.isEmpty {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(User.self, from: data)
    }

    // MARK: - Roadmap Management

    func saveRoadmap(_ roadmap: Roadmap) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        // Convert Roadmap to DTO
        let dto = RoadmapDTO(
            id: roadmap.id.uuidString,
            user_id: roadmap.userId,
            title: roadmap.title,
            goal: roadmap.goal.rawValue,
            target_date: roadmap.targetDate?.timeIntervalSince1970,
            updated_at: Date().timeIntervalSince1970
        )

        try await client.database
            .from("roadmaps")
            .upsert(dto)
            .execute()

        // Save milestones
        for milestone in roadmap.milestones {
            try await saveMilestone(milestone, roadmapId: roadmap.id)
        }
    }

    private func saveMilestone(_ milestone: Milestone, roadmapId: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let dto = MilestoneDTO(
            id: milestone.id.uuidString,
            roadmap_id: roadmapId.uuidString,
            title: milestone.title,
            description: milestone.description,
            target_date: milestone.targetDate?.timeIntervalSince1970,
            is_completed: milestone.isCompleted,
            completed_at: milestone.completedAt?.timeIntervalSince1970,
            updated_at: Date().timeIntervalSince1970
        )

        try await client.database
            .from("milestones")
            .upsert(dto)
            .execute()
    }

    func getRoadmap(userId: String) async throws -> Roadmap? {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        // Fetch roadmap
        let roadmapResponse = try await client.database
            .from("roadmaps")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()

        let roadmapData = roadmapResponse.data
        if roadmapData.isEmpty {
            return nil
        }

        // Parse roadmap
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        var roadmap = try decoder.decode(Roadmap.self, from: roadmapData)

        // Fetch milestones
        let milestonesResponse = try await client.database
            .from("milestones")
            .select()
            .eq("roadmap_id", value: roadmap.id.uuidString)
            .order("created_at")
            .execute()

        let milestonesData = milestonesResponse.data
        if !milestonesData.isEmpty {
            let milestones = try decoder.decode([Milestone].self, from: milestonesData)
            roadmap.milestones = milestones
        }

        return roadmap
    }

    // MARK: - Workout Session Management

    func saveWorkoutSession(_ session: WorkoutSession) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let dto = WorkoutSessionDTO(
            id: session.id.uuidString,
            user_id: session.userId,
            start_date: session.startDate.timeIntervalSince1970,
            end_date: session.endDate.timeIntervalSince1970,
            duration: session.duration,
            distance: session.distance,
            calories: session.calories,
            rpe: session.rpe
        )

        try await client.database
            .from("workout_sessions")
            .upsert(dto)
            .execute()
    }

    func getWorkoutSessions(userId: String, limit: Int = 50) async throws -> [WorkoutSession] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let response = try await client.database
            .from("workout_sessions")
            .select()
            .eq("user_id", value: userId)
            .order("start_date", ascending: false)
            .limit(limit)
            .execute()

        let data = response.data
        if data.isEmpty {
            return []
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([WorkoutSession].self, from: data)
    }

    // MARK: - Workout Reflection Management

    func saveWorkoutReflection(_ reflection: WorkoutReflection) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let dto = WorkoutReflectionDTO(
            id: reflection.id.uuidString,
            workout_session_id: reflection.workoutSessionId.uuidString,
            estimated_rpe: reflection.estimatedRPE,
            reflection: reflection.reflection,
            suggestions: reflection.suggestions,
            milestone_id: reflection.milestoneProgress?.milestoneId?.uuidString,
            is_milestone_achieved: reflection.milestoneProgress?.isAchieved ?? false,
            achievement_message: reflection.milestoneProgress?.achievementMessage
        )

        try await client.database
            .from("workout_reflections")
            .upsert(dto)
            .execute()
    }

    func getWorkoutReflections(userId: String, limit: Int = 50) async throws -> [WorkoutReflection] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        // Get reflections with joined workout sessions
        let response = try await client.database
            .from("workout_reflections")
            .select("""
                *,
                workout_sessions!inner(user_id)
            """)
            .eq("workout_sessions.user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()

        let data = response.data
        if data.isEmpty {
            return []
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([WorkoutReflection].self, from: data)
    }

    // MARK: - Upcoming Workout Management

    func saveUpcomingWorkout(_ workout: UpcomingWorkout, userId: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let dto = UpcomingWorkoutDTO(
            id: workout.id.uuidString,
            user_id: userId,
            title: workout.title,
            estimated_duration: workout.estimatedDuration,
            target_distance: workout.targetDistance,
            notes: workout.notes
        )

        try await client.database
            .from("upcoming_workouts")
            .upsert(dto)
            .execute()
    }

    func getUpcomingWorkouts(userId: String) async throws -> [UpcomingWorkout] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let response = try await client.database
            .from("upcoming_workouts")
            .select()
            .eq("user_id", value: userId)
            .order("created_at")
            .execute()

        let data = response.data
        if data.isEmpty {
            return []
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([UpcomingWorkout].self, from: data)
    }

    func deleteUpcomingWorkout(id: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        try await client.database
            .from("upcoming_workouts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Error Types

enum SupabaseError: Error, LocalizedError {
    case notConfigured
    case invalidResponse
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabaseが設定されていません。Info.plistにSUPABASE_URLとSUPABASE_ANON_KEYを追加してください。"
        case .invalidResponse:
            return "Supabaseからの応答が無効です"
        case .decodingError(let message):
            return "データの解析に失敗しました: \(message)"
        }
    }
}
