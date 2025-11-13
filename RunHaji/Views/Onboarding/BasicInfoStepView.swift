//
//  BasicInfoStepView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct BasicInfoStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 30) {
            Text("あなたについて教えてください")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("年齢")
                        .font(.headline)
                    TextField("例: 30", text: $viewModel.age)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("身長 (cm)")
                        .font(.headline)
                    TextField("例: 170", text: $viewModel.height)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("体重 (kg)")
                        .font(.headline)
                    TextField("例: 65", text: $viewModel.weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
    }
}

#Preview {
    BasicInfoStepView(viewModel: OnboardingViewModel())
}
