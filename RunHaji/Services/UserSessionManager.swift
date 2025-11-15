//
//  UserSessionManager.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/14.
//

import Foundation

/// Manages user session and user ID persistence
final class UserSessionManager {
    static let shared = UserSessionManager()

    private let userIdKey = "current_user_id"

    private init() {}

    /// Get or create the current user ID
    var currentUserId: UUID {
        if let stored = storedUserId {
            return stored
        }

        // Create new user ID
        let newId = UUID()
        saveUserId(newId)
        return newId
    }

    /// Get stored user ID if exists
    var storedUserId: UUID? {
        guard let uuidString = UserDefaults.standard.string(forKey: userIdKey),
              let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        return uuid
    }

    /// Save user ID to UserDefaults
    func saveUserId(_ userId: UUID) {
        UserDefaults.standard.set(userId.uuidString, forKey: userIdKey)
    }

    /// Clear user session (logout)
    func clearSession() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }

    /// Check if user has completed onboarding
    var hasCompletedOnboarding: Bool {
        return storedUserId != nil
    }
}
