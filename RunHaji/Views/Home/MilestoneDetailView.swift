//
//  MilestoneDetailView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

struct MilestoneDetailView: View {
    let milestone: Milestone
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient.appGradient
                .ignoresSafeArea()
                .opacity(0.1)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Progress
                    if !milestone.isCompleted {
                        progressSection
                    }

                    // Description
                    if let description = milestone.description {
                        descriptionSection(description)
                    }

                    // Tips
                    tipsSection
                }
                .padding()
            }
        }
        .navigationTitle(milestone.title)
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 40))
                    .foregroundColor(milestone.isCompleted ? .accent : .gray.opacity(0.3))

                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let targetDate = milestone.targetDate {
                        Label(
                            formattedDate(targetDate),
                            systemImage: "calendar"
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            if milestone.isCompleted, let completedAt = milestone.completedAt {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.accent)
                    Text(String(format: NSLocalizedString("milestone_detail.completed_date", comment: ""), formattedDate(completedAt)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("milestone_detail.progress_title", comment: ""))
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("milestone_detail.progress_prompt", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let targetDate = milestone.targetDate {
                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                    if daysRemaining > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .foregroundColor(.accent)
                            Text(String(format: NSLocalizedString("milestone_detail.days_remaining", comment: ""), daysRemaining))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accent.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient.appGradient
                .opacity(0.15)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("milestone_detail.details_title", comment: ""))
                .font(.headline)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("milestone_detail.tips_title", comment: ""))
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                TipRow(
                    icon: "lightbulb.fill",
                    text: NSLocalizedString("milestone_detail.tip1", comment: ""),
                    color: .yellow
                )
                TipRow(
                    icon: "heart.fill",
                    text: NSLocalizedString("milestone_detail.tip2", comment: ""),
                    color: .red
                )
                TipRow(
                    icon: "checkmark.circle.fill",
                    text: NSLocalizedString("milestone_detail.tip3", comment: ""),
                    color: .green
                )
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormatter.localizedMedium.string(from: date)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    NavigationView {
        MilestoneDetailView(
            milestone: Milestone(
                title: NSLocalizedString("milestone.preview.first_run.title", comment: ""),
                description: "15分間のランニングを完了する",
                targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                isCompleted: false
            )
        )
    }
}
