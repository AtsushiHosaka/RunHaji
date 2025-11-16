//
//  StepProgressView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

struct StepProgressView: View {
    let currentMilestone: Milestone?
    let totalMilestones: Int
    let completedMilestones: Int

    private var progress: Double {
        guard totalMilestones > 0 else { return 0 }
        return Double(completedMilestones) / Double(totalMilestones)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Current milestone title
            if let milestone = currentMilestone {
                Text(milestone.title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Add top padding for the runner icon
            Spacer()
                .frame(height: 40)

            // Progress bar with runner icon
            VStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 40)

                    // Progress gradient
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient.appGradient)
                        .frame(height: 40)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .scaleEffect(x: progress, y: 1, anchor: .leading)

                    // Runner icon on top of progress bar
                    GeometryReader { geometry in
                        Image(systemName: "figure.run")
                            .font(.system(size: 72))
                            .foregroundColor(.accent)
                            .offset(
                                x: max(0, min(
                                    geometry.size.width * progress - 36,
                                    geometry.size.width - 72
                                )),
                                y: -54
                            )
                    }
                }
                .frame(height: 40)

                // Percentage display below the runner
                GeometryReader { geometry in
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accent)
                        .offset(
                            x: max(0, min(
                                geometry.size.width * progress - 12,
                                geometry.size.width - 24
                            ))
                        )
                }
                .frame(height: 20)
            }
            .padding(.bottom, 30)

            // Progress text
            if let milestone = currentMilestone {
                Text(milestone.description ?? NSLocalizedString("step_progress.keep_going", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        StepProgressView(
            currentMilestone: Milestone(
                title: "初めてのランニング",
                description: "15分間のランニングを完了する",
                targetDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                isCompleted: false
            ),
            totalMilestones: 5,
            completedMilestones: 2
        )

        StepProgressView(
            currentMilestone: Milestone(
                title: "5km完走",
                description: "5kmを休まず走り切る",
                targetDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isCompleted: false
            ),
            totalMilestones: 5,
            completedMilestones: 0
        )
    }
    .padding()
}
