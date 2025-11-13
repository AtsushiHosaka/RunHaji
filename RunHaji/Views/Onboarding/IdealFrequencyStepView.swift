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
            Text("理想の運動頻度は？")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            VStack(spacing: 20) {
                Text("週\(viewModel.idealFrequency)回")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.green)

                Stepper("", value: $viewModel.idealFrequency, in: 1...7)
                    .labelsHidden()
                    .accessibilityLabel("理想の運動頻度")
                    .accessibilityValue("週\(viewModel.idealFrequency)回")
                    .padding(.horizontal, 50)
            }

            Text("週に何回運動したいですか？")
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
