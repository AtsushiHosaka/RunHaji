//
//  SettingsViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var user: User?
    @Published var isSyncing = false
    @Published var showingDeleteAlert = false
    @Published var errorMessage: String?
    
    // Profile editing
    @Published var age: Int = 25
    @Published var height: Double = 170
    @Published var weight: Double = 60
    @Published var selectedGoal: RunningGoal?
    @Published var idealFrequency: Int = 2
    
    func loadUserProfile() async {
        guard let userId = UserSessionManager.shared.storedUserId else {
            return
        }
        
        do {
            user = try await SupabaseService.shared.getUserProfile(userId: userId)

            if let user = user {
                age = user.profile.age ?? 25
                height = user.profile.height ?? 170
                weight = user.profile.weight ?? 60
                selectedGoal = user.profile.goal
                idealFrequency = user.profile.idealFrequency ?? 2
            }
        } catch {
            errorMessage = "プロフィールの読み込みに失敗しました"
        }
    }
    
    func saveProfile() async {
        guard let userId = UserSessionManager.shared.storedUserId else {
            return
        }
        
        do {
            let profile = UserProfile(
                age: age,
                height: height,
                weight: weight,
                availableTimePerWeek: user?.profile.availableTimePerWeek,
                idealFrequency: idealFrequency,
                currentFrequency: user?.profile.currentFrequency,
                goal: selectedGoal
            )

            let updatedUser = User(id: userId, email: user?.email, profile: profile)
            try await SupabaseService.shared.saveUserProfile(updatedUser)

            user = updatedUser
        } catch {
            errorMessage = "プロフィールの保存に失敗しました"
        }
    }
    
    func syncData() async {
        isSyncing = true
        await loadUserProfile()
        isSyncing = false
    }
    
    func deleteAllData() {
        // Clear all local data
        UserSessionManager.shared.clearSession()
        // App will automatically show onboarding screen when there's no stored user ID
    }
}
