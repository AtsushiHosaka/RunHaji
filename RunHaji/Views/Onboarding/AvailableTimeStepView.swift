//
//  AvailableTimeStepView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct AvailableTimeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 30) {
            Text(NSLocalizedString("available_time.title", comment: "Available time title"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            VStack(spacing: 20) {
                Text(String(format: NSLocalizedString("available_time.hours.format", comment: "Hours format"), viewModel.availableTime))
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.blue)

                Stepper("", value: $viewModel.availableTime, in: 1...20)
                    .labelsHidden()
                    .accessibilityLabel(NSLocalizedString("available_time.stepper.label", comment: "Stepper label"))
                    .accessibilityValue(String(format: NSLocalizedString("available_time.hours.format", comment: "Hours format"), viewModel.availableTime))
                    .padding(.horizontal, 50)
            }

            Text(NSLocalizedString("available_time.subtitle", comment: "Available time subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

#Preview {
    AvailableTimeStepView(viewModel: OnboardingViewModel())
}
