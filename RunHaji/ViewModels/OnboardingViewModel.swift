//
//  OnboardingViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

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
        return Double(currentStep) / Double(totalSteps)
    }

    func nextStep() {
        if currentStep < totalSteps {
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
            return !age.isEmpty && !height.isEmpty && !weight.isEmpty
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

    func completeOnboarding() async {
        // Create user profile
        let profile = UserProfile(
            age: Int(age),
            height: Double(height),
            weight: Double(weight),
            availableTimePerWeek: availableTime,
            idealFrequency: idealFrequency,
            currentFrequency: currentFrequency,
            goal: selectedGoal
        )

        let user = User(profile: profile)

        // Save to UserDefaults (temporary - will be saved to Supabase later)
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "user_profile")
        }

        // TODO: Save to Supabase
        // try await SupabaseService.shared.saveUserProfile(...)

        isCompleted = true
    }
}
