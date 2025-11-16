//
//  IdealFrequencyStepView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct IdealFrequencyStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 30) {
            Text(NSLocalizedString("ideal_frequency.title", comment: ""))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            VStack(spacing: 20) {
                Text(String(format: NSLocalizedString("common.frequency_format.week", comment: ""), viewModel.idealFrequency))
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.green)

                Stepper("", value: $viewModel.idealFrequency, in: 1...7)
                    .labelsHidden()
                    .accessibilityLabel(NSLocalizedString("ideal_frequency.accessibility.label", comment: ""))
                    .accessibilityValue(String(format: NSLocalizedString("common.frequency_format.week", comment: ""), viewModel.idealFrequency))
                    .padding(.horizontal, 50)
            }

            Text(NSLocalizedString("ideal_frequency.description", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

#Preview {
    IdealFrequencyStepView(viewModel: OnboardingViewModel())
}
