//
//  RoadmapView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct RoadmapView: View {
    let roadmap: Roadmap?
    let isGenerating: Bool
    var onGenerateRoadmap: (() async -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isGenerating {
                generatingView
            } else if let roadmap = roadmap {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ロードマップ")
                        .font(.headline)

                    Text(roadmap.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    if let targetDate = roadmap.targetDate {
                        HStack {
                            Image(systemName: "flag.checkered")
                                .foregroundColor(.orange)
                            Text("目標日: \(formattedDate(targetDate))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 8)

                // Milestones
                VStack(spacing: 16) {
                    ForEach(Array(roadmap.milestones.enumerated()), id: \.element.id) { index, milestone in
                        MilestoneCard(
                            milestone: milestone,
                            isLast: index == roadmap.milestones.count - 1
                        )
                    }
                }
            } else {
                emptyRoadmapView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var generatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accent)

            Text("生成中...")
                .font(.headline)
                .foregroundColor(.primary)

            Text("あなた専用のロードマップを作成しています")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyRoadmapView: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.largeTitle)
                .foregroundColor(.gray)

            Text("ロードマップがまだ作成されていません")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let onGenerateRoadmap = onGenerateRoadmap {
                Button(action: {
                    Task {
                        await onGenerateRoadmap()
                    }
                }) {
                    Text("ロードマップを作成")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accent)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormatter.japaneseMedium.string(from: date)
    }
}

struct MilestoneCard: View {
    let milestone: Milestone
    let isLast: Bool

    var body: some View {
        NavigationLink(destination: MilestoneDetailView(milestone: milestone)) {
            HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(milestone.isCompleted ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: milestone.isCompleted ? "checkmark" : "circle")
                            .font(.caption2)
                            .foregroundColor(milestone.isCompleted ? .white : .gray)
                    )
                    .accessibilityLabel(milestone.isCompleted ? "完了済み" : "未完了")

                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 20)
            .accessibilityElement(children: .combine)

            // Milestone content
            VStack(alignment: .leading, spacing: 8) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(milestone.isCompleted ? .secondary : .primary)
                    .strikethrough(milestone.isCompleted)

                if let description = milestone.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    if let targetDate = milestone.targetDate {
                        Label(
                            formattedDate(targetDate),
                            systemImage: "calendar"
                        )
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }

                    if milestone.isCompleted, let completedAt = milestone.completedAt {
                        Label(
                            "完了: \(formattedDate(completedAt))",
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.caption2)
                        .foregroundColor(.green)
                    }
                }

                // Workouts count
                if !milestone.workouts.isEmpty {
                    Text("\(milestone.workouts.count)回のワークアウト")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.bottom, isLast ? 0 : 16)

            Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(milestone.title), \(milestone.isCompleted ? "完了済み" : "未完了")")
            .accessibilityHint(milestone.description ?? "")
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormatter.japaneseShort.string(from: date)
    }
}

#Preview {
    let sampleMilestones = [
        Milestone(
            title: "初めてのランニング",
            description: "15分間のランニングを完了する",
            targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            isCompleted: true,
            completedAt: Date()
        ),
        Milestone(
            title: "1kmランニング達成",
            description: "1kmを走りきる",
            targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
            isCompleted: false
        ),
        Milestone(
            title: "週2回のペースを確立",
            description: "2週間連続で週2回走る",
            targetDate: Calendar.current.date(byAdding: .day, value: 28, to: Date()),
            isCompleted: false
        )
    ]

    let sampleRoadmap = Roadmap(
        userId: "test-user",
        title: "健康改善への道",
        goal: .healthImprovement,
        targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
        milestones: sampleMilestones
    )

    ScrollView {
        RoadmapView(roadmap: sampleRoadmap, isGenerating: false)
            .padding()
    }
}
