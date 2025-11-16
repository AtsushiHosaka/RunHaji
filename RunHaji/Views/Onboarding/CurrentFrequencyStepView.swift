//
//  CurrentFrequencyStepView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct CurrentFrequencyStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 30) {
            Text(NSLocalizedString("current_frequency.title", comment: ""))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            VStack(spacing: 20) {
                Text(String(format: NSLocalizedString("common.frequency_format.week", comment: ""), viewModel.currentFrequency))
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.orange)

                Stepper("", value: $viewModel.currentFrequency, in: 0...7)
                    .labelsHidden()
                    .accessibilityLabel(NSLocalizedString("current_frequency.accessibility.label", comment: ""))
                    .accessibilityValue(String(format: NSLocalizedString("common.frequency_format.week", comment: ""), viewModel.currentFrequency))
                    .padding(.horizontal, 50)
            }

            Text(NSLocalizedString("current_frequency.description", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

#Preview {
    CurrentFrequencyStepView(viewModel: OnboardingViewModel())
}
