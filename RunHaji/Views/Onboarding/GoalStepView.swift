//
//  GoalStepView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct GoalStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 30) {
            Text(NSLocalizedString("goal.title", comment: "Goal selection title"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            Text(NSLocalizedString("goal.subtitle", comment: "Goal selection subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                ForEach(RunningGoal.allCases, id: \.self) { goal in
                    Button(action: {
                        viewModel.selectedGoal = goal
                    }) {
                        HStack {
                            Text(goal.description)
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            if viewModel.selectedGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.selectedGoal == goal ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
    }
}

#Preview {
    GoalStepView(viewModel: OnboardingViewModel())
}
