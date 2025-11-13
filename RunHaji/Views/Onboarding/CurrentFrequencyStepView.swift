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
            Text("現在の運動頻度は？")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            VStack(spacing: 20) {
                Text("週\(viewModel.currentFrequency)回")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.orange)

                Stepper("", value: $viewModel.currentFrequency, in: 0...7)
                    .labelsHidden()
                    .padding(.horizontal, 50)
            }

            Text("現在、週に何回運動していますか？\n（0回でも大丈夫です）")
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
