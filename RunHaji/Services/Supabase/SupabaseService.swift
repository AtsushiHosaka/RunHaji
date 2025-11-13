//
//  SupabaseService.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
// import Supabase  // Uncomment after adding supabase-swift via SPM

class SupabaseService {
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

    func saveUserProfile(userId: String, profile: [String: Any]) async throws {
        // Implementation after adding Supabase package
        // try await client.database
        //     .from("user_profiles")
        //     .insert(profile)
        //     .execute()
    }

    func getUserProfile(userId: String) async throws -> [String: Any]? {
        // Implementation after adding Supabase package
        // let response = try await client.database
        //     .from("user_profiles")
        //     .select()
        //     .eq("user_id", value: userId)
        //     .single()
        //     .execute()
        // return response.data as? [String: Any]
        return nil
    }

    func saveWorkoutSession(session: [String: Any]) async throws {
        // Implementation after adding Supabase package
        // try await client.database
        //     .from("workout_sessions")
        //     .insert(session)
        //     .execute()
    }

    func getWorkoutSessions(userId: String) async throws -> [[String: Any]] {
        // Implementation after adding Supabase package
        // let response = try await client.database
        //     .from("workout_sessions")
        //     .select()
        //     .eq("user_id", value: userId)
        //     .execute()
        // return response.data as? [[String: Any]] ?? []
        return []
    }
}
