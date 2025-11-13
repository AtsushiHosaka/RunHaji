//
//  SupabaseService.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
// import Supabase  // Uncomment after adding supabase-swift via SPM

final class SupabaseService {
    static let shared = SupabaseService()

    // Uncomment after adding supabase-swift via SPM
    // private let client: SupabaseClient

    private init() {
        // Initialize Supabase client after adding the package
        // self.client = SupabaseClient(
        //     supabaseURL: URL(string: SupabaseConfig.url)!,
        //     supabaseKey: SupabaseConfig.anonKey
        // )
    }

    // MARK: - User Management

    func createUser(email: String, password: String) async throws {
        // Implementation after adding Supabase package
        // try await client.auth.signUp(email: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        // Implementation after adding Supabase package
        // try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        // Implementation after adding Supabase package
        // try await client.auth.signOut()
    }

    // MARK: - Database Operations

    func saveUserProfile(_ profile: UserProfile) async throws {
        // Implementation after adding Supabase package
        // let encoder = JSONEncoder()
        // let data = try encoder.encode(profile)
        // try await client.database
        //     .from("user_profiles")
        //     .insert(data)
        //     .execute()
    }

    func getUserProfile(userId: String) async throws -> UserProfile? {
        // Implementation after adding Supabase package
        // let response = try await client.database
        //     .from("user_profiles")
        //     .select()
        //     .eq("user_id", value: userId)
        //     .single()
        //     .execute()
        // let decoder = JSONDecoder()
        // return try decoder.decode(UserProfile.self, from: response.data)
        return nil
    }

    func saveWorkoutSession(_ session: WorkoutSession) async throws {
        // Implementation after adding Supabase package
        // let encoder = JSONEncoder()
        // let data = try encoder.encode(session)
        // try await client.database
        //     .from("workout_sessions")
        //     .insert(data)
        //     .execute()
    }

    func getWorkoutSessions(userId: String) async throws -> [WorkoutSession] {
        // Implementation after adding Supabase package
        // let response = try await client.database
        //     .from("workout_sessions")
        //     .select()
        //     .eq("user_id", value: userId)
        //     .execute()
        // let decoder = JSONDecoder()
        // return try decoder.decode([WorkoutSession].self, from: response.data)
        return []
    }
}
