//
//  SettingsViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var user: User?
    @Published var isSyncing = false
    @Published var showingLogoutAlert = false
    @Published var errorMessage: String?
    
    // Profile editing
    @Published var age: String = ""
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var selectedGoal: RunningGoal?
    @Published var idealFrequency: Int = 2
    
    func loadUserProfile() async {
        guard let userId = UserSessionManager.shared.storedUserId else {
            return
        }
        
        do {
            user = try await SupabaseService.shared.getUserProfile(userId: userId)
            
            if let user = user {
                age = "\(user.profile.age ?? 0)"
                height = "\(user.profile.height ?? 0)"
                weight = "\(user.profile.weight ?? 0)"
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
                age: Int(age),
                height: Double(height),
                weight: Double(weight),
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
    
    func logout() {
        UserSessionManager.shared.clearSession()
        // App will restart and show onboarding
    }
}
