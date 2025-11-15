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
    @Published var age: String = ""
    @Published var height: String = ""
    @Published var weight: String = ""
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
            guard let ageVal = Int(age), ageVal > 0,
                  let heightVal = Double(height), heightVal > 0,
                  let weightVal = Double(weight), weightVal > 0 else {
                return false
            }
            return true
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
        // Create user profile
        let profile = UserProfile(
            age: Int(age) ?? 0,
            height: Double(height) ?? 0.0,
            weight: Double(weight) ?? 0.0,
            availableTimePerWeek: availableTime,
            idealFrequency: idealFrequency,
            currentFrequency: currentFrequency,
            goal: selectedGoal
        )

        let user = User(profile: profile)

        // Save to UserDefaults (for offline access)
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(user)
        UserDefaults.standard.set(encoded, forKey: "user_profile")

        // Save to Supabase (for cloud sync)
        do {
            try await SupabaseService.shared.saveUserProfile(user)
            print("User profile saved to Supabase successfully")
        } catch {
            // Log error but don't fail onboarding if Supabase is not configured
            print("Failed to save user profile to Supabase: \(error.localizedDescription)")
        }

        isCompleted = true
    }
}
