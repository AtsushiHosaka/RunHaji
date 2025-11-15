//
//  SupabaseService.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import Supabase

// MARK: - Data Transfer Objects

// Date formatter for ISO8601 timestamps
private let iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

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
    let updated_at: String
}

private struct UserProfileResponseDTO: Codable {
    let user_id: String
    let email: String?
    let age: Int?
    let height: Double?
    let weight: Double?
    let available_time_per_week: Int?
    let ideal_frequency: Int?
    let current_frequency: Int?
    let goal: String?
    let created_at: String
    let updated_at: String
}

private struct RoadmapDTO: Codable {
    let id: String
    let user_id: String
    let title: String
    let goal: String
    let target_date: String?
    let updated_at: String
}

private struct RoadmapResponseDTO: Codable {
    let id: String
    let user_id: String
    let title: String
    let goal: String
    let target_date: String?
    let created_at: String
    let updated_at: String
}

private struct MilestoneDTO: Codable {
    let id: String
    let roadmap_id: String
    let title: String
    let description: String?
    let target_date: String?
    let is_completed: Bool
    let completed_at: String?
    let updated_at: String
}

private struct MilestoneResponseDTO: Codable {
    let id: String
    let roadmap_id: String
    let title: String
    let description: String?
    let target_date: String?
    let is_completed: Bool
    let completed_at: String?
    let created_at: String
    let updated_at: String
}

private struct WorkoutSessionDTO: Codable {
    let id: String
    let user_id: String
    let start_date: String
    let end_date: String
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
            updated_at: iso8601Formatter.string(from: Date())
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
            .execute()

        guard !response.data.isEmpty else {
            return nil
        }

        let decoder = JSONDecoder()
        // Don't use convertFromSnakeCase since DTO already uses snake_case keys
        decoder.dateDecodingStrategy = .iso8601

        let profiles = try decoder.decode([UserProfileResponseDTO].self, from: response.data)
        guard let dto = profiles.first else {
            return nil
        }

        // Convert DTO to User model
        let createdAt = iso8601Formatter.date(from: dto.created_at) ?? Date()
        let updatedAt = iso8601Formatter.date(from: dto.updated_at) ?? Date()

        let profile = UserProfile(
            age: dto.age,
            height: dto.height,
            weight: dto.weight,
            availableTimePerWeek: dto.available_time_per_week,
            idealFrequency: dto.ideal_frequency,
            currentFrequency: dto.current_frequency,
            goal: dto.goal.flatMap { RunningGoal(rawValue: $0) },
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        return User(
            id: UUID(uuidString: dto.user_id) ?? userId,
            email: dto.email,
            profile: profile
        )
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
            target_date: roadmap.targetDate.map { iso8601Formatter.string(from: $0) },
            updated_at: iso8601Formatter.string(from: Date())
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
            target_date: milestone.targetDate.map { iso8601Formatter.string(from: $0) },
            is_completed: milestone.isCompleted,
            completed_at: milestone.completedAt.map { iso8601Formatter.string(from: $0) },
            updated_at: iso8601Formatter.string(from: Date())
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
            .execute()

        let roadmapData = roadmapResponse.data
        if roadmapData.isEmpty {
            return nil
        }

        // Parse roadmap
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let roadmapDTOs = try decoder.decode([RoadmapResponseDTO].self, from: roadmapData)
        guard let roadmapDTO = roadmapDTOs.first else {
            return nil
        }

        // Convert DTO to Roadmap model
        let roadmapId = UUID(uuidString: roadmapDTO.id) ?? UUID()
        let createdAt = iso8601Formatter.date(from: roadmapDTO.created_at) ?? Date()
        let updatedAt = iso8601Formatter.date(from: roadmapDTO.updated_at) ?? Date()
        let targetDate = roadmapDTO.target_date.flatMap { iso8601Formatter.date(from: $0) }
        let goal = RunningGoal(rawValue: roadmapDTO.goal) ?? .healthImprovement

        // Fetch milestones
        let milestonesResponse = try await client.database
            .from("milestones")
            .select()
            .eq("roadmap_id", value: roadmapId.uuidString)
            .order("created_at")
            .execute()

        var milestones: [Milestone] = []
        let milestonesData = milestonesResponse.data
        if !milestonesData.isEmpty {
            let milestoneDTOs = try decoder.decode([MilestoneResponseDTO].self, from: milestonesData)
            milestones = milestoneDTOs.map { dto in
                Milestone(
                    id: UUID(uuidString: dto.id) ?? UUID(),
                    title: dto.title,
                    description: dto.description,
                    targetDate: dto.target_date.flatMap { iso8601Formatter.date(from: $0) },
                    isCompleted: dto.is_completed,
                    completedAt: dto.completed_at.flatMap { iso8601Formatter.date(from: $0) },
                    workouts: []
                )
            }
        }

        let roadmap = Roadmap(
            id: roadmapId,
            userId: roadmapDTO.user_id,
            title: roadmapDTO.title,
            goal: goal,
            targetDate: targetDate,
            milestones: milestones,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

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
            start_date: iso8601Formatter.string(from: session.startDate),
            end_date: iso8601Formatter.string(from: session.endDate),
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
        decoder.dateDecodingStrategy = .iso8601
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
        decoder.dateDecodingStrategy = .iso8601
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
        decoder.dateDecodingStrategy = .iso8601
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

    // MARK: - Product Management

    /// Get all products from master data
    func getAllProducts() async throws -> [Product] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let response = try await client.database
            .from("products")
            .select()
            .execute()

        let data = response.data
        if data.isEmpty {
            return []
        }

        let decoder = JSONDecoder()
        return try decoder.decode([Product].self, from: data)
    }

    /// Get user's products for a specific roadmap
    func getUserProducts(userId: String, roadmapId: UUID) async throws -> [UserProduct] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        print("📥 Querying user_products: userId=\(userId), roadmapId=\(roadmapId)")

        let response = try await client.database
            .from("user_products")
            .select("*, product:products(*)")
            .eq("user_id", value: userId)
            .eq("roadmap_id", value: roadmapId.uuidString)
            .order("is_purchased")
            .order("created_at")
            .execute()

        let data = response.data
        print("📦 Response data size: \(data.count) bytes")

        if data.isEmpty {
            print("⚠️ No data returned from query")
            return []
        }

        // Debug: print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Raw JSON response: \(jsonString)")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let products = try decoder.decode([UserProduct].self, from: data)
            print("✅ Successfully decoded \(products.count) user products")
            return products
        } catch {
            print("❌ Decoding error: \(error)")
            throw error
        }
    }

    /// Create user products for a roadmap
    func createUserProducts(userId: String, roadmapId: UUID, productIds: [UUID]) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let userProducts = productIds.map { productId in
            [
                "user_id": userId,
                "product_id": productId.uuidString,
                "roadmap_id": roadmapId.uuidString,
                "is_purchased": false
            ] as [String: Any]
        }

        let jsonData = try JSONSerialization.data(withJSONObject: userProducts)

        try await client.database
            .from("user_products")
            .insert(jsonData)
            .execute()
    }

    /// Update product purchase status
    func updateProductPurchaseStatus(userProductId: UUID, isPurchased: Bool) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        try await client.database
            .from("user_products")
            .update(["is_purchased": isPurchased])
            .eq("id", value: userProductId.uuidString)
            .execute()
    }

    /// Request gear recommendations via Edge Function
    func requestGearRecommendations(
        userId: String,
        roadmapId: UUID,
        userAge: Int?,
        userGoal: String?,
        userIdealFrequency: Int?,
        userCurrentFrequency: Int?,
        roadmapGoal: String
    ) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        struct RequestBody: Encodable {
            let user_id: String
            let roadmap_id: String
            let user_profile: UserProfileData
            let roadmap_goal: String

            struct UserProfileData: Encodable {
                let age: Int?
                let goal: String?
                let ideal_frequency: Int?
                let current_frequency: Int?
            }
        }

        let requestBody = RequestBody(
            user_id: userId,
            roadmap_id: roadmapId.uuidString,
            user_profile: RequestBody.UserProfileData(
                age: userAge,
                goal: userGoal,
                ideal_frequency: userIdealFrequency,
                current_frequency: userCurrentFrequency
            ),
            roadmap_goal: roadmapGoal
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(requestBody)

        print("🔵 Calling Edge Function: recommend-gear")
        print("📤 Request: userId=\(userId), roadmapId=\(roadmapId), goal=\(roadmapGoal)")

        // Call Edge Function
        do {
            try await client.functions.invoke(
                "recommend-gear",
                options: FunctionInvokeOptions(
                    body: jsonData
                )
            )

            print("✅ Edge Function completed successfully")
        } catch {
            print("❌ Edge Function failed with error: \(error)")

            // Try to extract more details from the error
            if let urlError = error as? URLError {
                print("   URLError code: \(urlError.code)")
            }

            print("   Full error: \(String(describing: error))")
            throw error
        }
    }

    /// Initialize complete roadmap (roadmap + gear + workouts) via Edge Function
    func initializeRoadmap(user: User) async throws -> UUID {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        struct RequestBody: Encodable {
            let user_id: String
            let user_profile: UserProfileData

            struct UserProfileData: Encodable {
                let age: Int?
                let height: Double?
                let weight: Double?
                let available_time_per_week: Int?
                let ideal_frequency: Int?
                let current_frequency: Int?
                let goal: String?
            }
        }

        struct ResponseBody: Decodable {
            let success: Bool
            let roadmap_id: String
            let message: String
        }

        let requestBody = RequestBody(
            user_id: user.id.uuidString,
            user_profile: RequestBody.UserProfileData(
                age: user.profile.age,
                height: user.profile.height,
                weight: user.profile.weight,
                available_time_per_week: user.profile.availableTimePerWeek,
                ideal_frequency: user.profile.idealFrequency,
                current_frequency: user.profile.currentFrequency,
                goal: user.profile.goal?.rawValue
            )
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(requestBody)

        print("🚀 Calling Edge Function: initialize-roadmap")
        print("📤 Request: userId=\(user.id)")

        // Call Edge Function (doesn't return response in current SDK version)
        try await client.functions.invoke(
            "initialize-roadmap",
            options: FunctionInvokeOptions(
                body: jsonData
            )
        )

        print("✅ Edge Function: initialize-roadmap completed")

        // Since we can't get the roadmap_id from the response,
        // we'll fetch the most recent roadmap for this user
        if let latestRoadmap = try await getRoadmap(userId: user.id.uuidString) {
            print("✅ Roadmap ID: \(latestRoadmap.id)")
            return latestRoadmap.id
        } else {
            throw SupabaseError.invalidResponse
        }
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
