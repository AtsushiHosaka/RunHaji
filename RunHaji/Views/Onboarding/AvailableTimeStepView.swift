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
            Text("1週間に使える時間は？")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            VStack(spacing: 20) {
                Text("\(viewModel.availableTime)時間")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.blue)

                Stepper("", value: $viewModel.availableTime, in: 1...20)
                    .labelsHidden()
                    .padding(.horizontal, 50)
            }

            Text("運動に使える週あたりの時間を教えてください")
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
