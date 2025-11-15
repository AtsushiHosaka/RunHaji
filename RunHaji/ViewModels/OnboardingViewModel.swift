//
//  OnboardingViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var isCompleted = false

    // Survey data
    @Published var age: Int = 25
    @Published var height: Double = 170
    @Published var weight: Double = 60
    @Published var availableTime: Int = 1
    @Published var idealFrequency: Int = 1
    @Published var currentFrequency: Int = 0
    @Published var selectedGoal: RunningGoal?

    let totalSteps = 5

    var progress: Double {
        return Double(currentStep + 1) / Double(totalSteps)
    }

    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func canProceed() -> Bool {
        switch currentStep {
        case 0: // Age, Height, Weight
            return age > 0 && height > 0 && weight > 0
        case 1: // Available Time
            return availableTime > 0
        case 2: // Frequency
            return idealFrequency > 0
        case 3: // Current Frequency
            return true // Can be 0
        case 4: // Goal
            return selectedGoal != nil
        default:
            return false
        }
    }

    func completeOnboarding() async throws {
        // Get or create user ID
        let userId = UserSessionManager.shared.currentUserId

        // Create user profile
        let profile = UserProfile(
            age: age,
            height: height,
            weight: weight,
            availableTimePerWeek: availableTime,
            idealFrequency: idealFrequency,
            currentFrequency: currentFrequency,
            goal: selectedGoal
        )

        let user = User(id: userId, profile: profile)

        // Save to Supabase
        try await SupabaseService.shared.saveUserProfile(user)
        print("User profile saved to Supabase successfully")

        isCompleted = true
    }
}
