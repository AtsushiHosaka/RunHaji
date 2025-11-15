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
                    Button("戻る") {
                        withAnimation {
                            viewModel.previousStep()
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if viewModel.currentStep < viewModel.totalSteps - 1 {
                    Button("次へ") {
                        withAnimation {
                            viewModel.nextStep()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canProceed())
                } else {
                    Button("完了") {
                        Task {
                            do {
                                try await viewModel.completeOnboarding()
                                onComplete()
                            } catch {
                                errorMessage = "プロフィールの保存に失敗しました: \(error.localizedDescription)"
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
        .alert("エラー", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
