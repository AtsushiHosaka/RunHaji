//
//  HomeView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Greeting Section
                    greetingSection

                    // Progress Overview
                    progressOverviewSection

                    // Roadmap Visualization
                    RoadmapView(roadmap: viewModel.roadmap)
                        .padding(.horizontal)

                    // Upcoming Workouts
                    upcomingWorkoutsSection

                    // Recent Activity
                    recentActivitySection
                }
                .padding(.vertical)
            }
            .navigationTitle("ホーム")
            .refreshable {
                await viewModel.refresh()
            }
            .alert(
                "エラー",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                actions: {
                    Button("OK") {
                        viewModel.errorMessage = nil
                    }
                },
                message: {
                    if let error = viewModel.errorMessage {
                        Text(error)
                    }
                }
            )
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.greetingMessage)
                .font(.title2)
                .fontWeight(.bold)

            Text("今日も頑張りましょう!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var progressOverviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("達成状況")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(viewModel.completedMilestones) / \(viewModel.totalMilestones)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress Bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scaleEffect(x: viewModel.progressPercentage / 100, y: 1, anchor: .leading)
            }
            .frame(height: 12)

            Text("\(Int(viewModel.progressPercentage))% 完了")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var upcomingWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今後の予定")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.upcomingWorkouts.isEmpty {
                emptyStateView(message: "予定されたワークアウトはありません")
            } else {
                ForEach(viewModel.upcomingWorkouts) { workout in
                    UpcomingWorkoutCard(workout: workout)
                        .padding(.horizontal)
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近の活動")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.recentSessions.isEmpty {
                emptyStateView(message: "まだワークアウトの記録がありません")
            } else {
                ForEach(viewModel.recentSessions) { session in
                    RecentSessionCard(session: session)
                        .padding(.horizontal)
                }
            }
        }
    }

    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.gray)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

struct UpcomingWorkoutCard: View {
    let workout: UpcomingWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(workout.title)
                    .font(.headline)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                Label(
                    formattedDuration(workout.estimatedDuration),
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundColor(.secondary)

                if let distance = workout.targetDistance {
                    Label(
                        formattedDistance(distance),
                        systemImage: "figure.run"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            if let notes = workout.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        duration.formattedMinutes()
    }

    private func formattedDistance(_ distance: Double) -> String {
        distance.formattedDistance()
    }
}

struct RecentSessionCard: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ランニング")
                        .font(.headline)

                    Text(formattedDate(session.startDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let rpe = session.rpe {
                    VStack(spacing: 2) {
                        Text("RPE")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(rpe)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("距離")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedDistance(session.distance))
                        .font(.caption)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("時間")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedDuration(session.duration))
                        .font(.caption)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("カロリー")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(session.calories)) kcal")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormatter.japaneseMedium.string(from: date)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        duration.formattedDuration()
    }

    private func formattedDistance(_ distance: Double) -> String {
        distance.formattedDistance()
    }
}

#Preview {
    HomeView()
}
