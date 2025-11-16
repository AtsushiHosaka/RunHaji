//
//  OnboardingView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            ProgressView(value: viewModel.progress)
                .tint(.accent)
                .padding()

            // Content
            TabView(selection: $viewModel.currentStep) {
                BasicInfoStepView(viewModel: viewModel)
                    .tag(0)

                AvailableTimeStepView(viewModel: viewModel)
                    .tag(1)

                IdealFrequencyStepView(viewModel: viewModel)
                    .tag(2)

                CurrentFrequencyStepView(viewModel: viewModel)
                    .tag(3)

                GoalStepView(viewModel: viewModel)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Navigation Buttons
            HStack(spacing: 20) {
                if viewModel.currentStep > 0 {
                    Button(NSLocalizedString("common.back", comment: "")) {
                        withAnimation {
                            viewModel.previousStep()
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if viewModel.currentStep < viewModel.totalSteps - 1 {
                    Button(NSLocalizedString("common.next", comment: "")) {
                        withAnimation {
                            viewModel.nextStep()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canProceed())
                } else {
                    Button(NSLocalizedString("common.done", comment: "")) {
                        Task {
                            do {
                                try await viewModel.completeOnboarding()
                                onComplete()
                            } catch {
                                errorMessage = String(format: NSLocalizedString("onboarding.error.save_profile", comment: ""), error.localizedDescription)
                                showError = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canProceed())
                }
            }
            .padding()
        }
        .tint(.accent)
        .interactiveDismissDisabled()
        .alert(NSLocalizedString("common.error", comment: ""), isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
