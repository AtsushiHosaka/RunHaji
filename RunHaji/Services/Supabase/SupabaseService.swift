//
//  SupabaseService.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import Supabase

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

        // Convert User model to database format
        let profileData: [String: Any] = [
            "user_id": user.id.uuidString,
            "email": user.email ?? NSNull(),
            "age": user.profile.age ?? NSNull(),
            "height": user.profile.height ?? NSNull(),
            "weight": user.profile.weight ?? NSNull(),
            "available_time_per_week": user.profile.availableTimePerWeek ?? NSNull(),
            "ideal_frequency": user.profile.idealFrequency ?? NSNull(),
            "current_frequency": user.profile.currentFrequency ?? NSNull(),
            "goal": user.profile.goal?.rawValue ?? NSNull(),
            "updated_at": Date().timeIntervalSince1970
        ]

        try await client.database
            .from("user_profiles")
            .upsert(profileData)
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

        guard let data = response.data else {
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

        // Save roadmap
        let roadmapData: [String: Any] = [
            "id": roadmap.id.uuidString,
            "user_id": roadmap.userId,
            "title": roadmap.title,
            "goal": roadmap.goal.rawValue,
            "target_date": roadmap.targetDate?.timeIntervalSince1970 ?? NSNull(),
            "updated_at": Date().timeIntervalSince1970
        ]

        try await client.database
            .from("roadmaps")
            .upsert(roadmapData)
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

        let milestoneData: [String: Any] = [
            "id": milestone.id.uuidString,
            "roadmap_id": roadmapId.uuidString,
            "title": milestone.title,
            "description": milestone.description ?? NSNull(),
            "target_date": milestone.targetDate?.timeIntervalSince1970 ?? NSNull(),
            "is_completed": milestone.isCompleted,
            "completed_at": milestone.completedAt?.timeIntervalSince1970 ?? NSNull(),
            "updated_at": Date().timeIntervalSince1970
        ]

        try await client.database
            .from("milestones")
            .upsert(milestoneData)
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

        guard let roadmapData = roadmapResponse.data else {
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

        if let milestonesData = milestonesResponse.data {
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

        let sessionData: [String: Any] = [
            "id": session.id.uuidString,
            "user_id": session.userId,
            "start_date": session.startDate.timeIntervalSince1970,
            "end_date": session.endDate.timeIntervalSince1970,
            "duration": session.duration,
            "distance": session.distance,
            "calories": session.calories,
            "rpe": session.rpe ?? NSNull()
        ]

        try await client.database
            .from("workout_sessions")
            .upsert(sessionData)
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

        guard let data = response.data else {
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

        let reflectionData: [String: Any] = [
            "id": reflection.id.uuidString,
            "workout_session_id": reflection.workoutSessionId.uuidString,
            "estimated_rpe": reflection.estimatedRPE,
            "reflection": reflection.reflection,
            "suggestions": reflection.suggestions,
            "milestone_id": reflection.milestoneProgress?.milestoneId?.uuidString ?? NSNull(),
            "is_milestone_achieved": reflection.milestoneProgress?.isAchieved ?? false,
            "achievement_message": reflection.milestoneProgress?.achievementMessage ?? NSNull()
        ]

        try await client.database
            .from("workout_reflections")
            .upsert(reflectionData)
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

        guard let data = response.data else {
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

        let workoutData: [String: Any] = [
            "id": workout.id.uuidString,
            "user_id": userId,
            "title": workout.title,
            "estimated_duration": workout.estimatedDuration,
            "target_distance": workout.targetDistance ?? NSNull(),
            "notes": workout.notes ?? NSNull()
        ]

        try await client.database
            .from("upcoming_workouts")
            .upsert(workoutData)
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

        guard let data = response.data else {
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
