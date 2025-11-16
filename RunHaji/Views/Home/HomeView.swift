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

                    // Step Progress View
                    if viewModel.roadmap != nil {
                        StepProgressView(
                            currentMilestone: viewModel.currentMilestone,
                            totalMilestones: viewModel.totalMilestones,
                            completedMilestones: viewModel.completedMilestones
                        )
                        .padding(.horizontal)
                    }

                    // Gear List (そろえるもの)
                    GearListView(
                        userProducts: $viewModel.userProducts,
                        onTogglePurchase: { userProductId in
                            Task {
                                await viewModel.toggleProductPurchase(userProductId: userProductId)
                            }
                        }
                    )

                    // Roadmap Visualization
                    RoadmapView(
                        roadmap: viewModel.roadmap,
                        isGenerating: viewModel.isGeneratingRoadmap,
                        onGenerateRoadmap: {
                            await viewModel.createDefaultRoadmap()
                        }
                    )
                    .padding(.horizontal)

                    // Recent Activity
                    recentActivitySection
                }
                .padding(.vertical)
            }
            .navigationTitle("DASHINBAN")
            .refreshable {
                await viewModel.refresh()
            }
            .alert(
                NSLocalizedString("home.roadmap_error.title", comment: ""),
                isPresented: $viewModel.showErrorAlert,
                actions: {
                    Button(NSLocalizedString("home.roadmap_error.retry", comment: "")) {
                        Task {
                            await viewModel.createDefaultRoadmap()
                        }
                    }
                    Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) {
                        viewModel.showErrorAlert = false
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

            Text(NSLocalizedString("home.greeting", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var progressOverviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(NSLocalizedString("home.progress.title", comment: ""))
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(String(format: NSLocalizedString("home.progress.completed_format", comment: ""), viewModel.completedMilestones, viewModel.totalMilestones))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress Bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient.appGradient)
                    .frame(height: 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scaleEffect(x: viewModel.progressPercentage / 100, y: 1, anchor: .leading)
            }
            .frame(height: 12)

            Text(String(format: NSLocalizedString("home.progress.percentage_format", comment: ""), Int(viewModel.progressPercentage)))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("home.recent_activity.title", comment: ""))
                .font(.headline)
                .padding(.horizontal)

            if viewModel.recentSessions.isEmpty {
                emptyStateView(message: NSLocalizedString("home.recent_activity.empty", comment: ""))
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

struct RecentSessionCard: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("home.recent_activity.running", comment: ""))
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
                    Text(NSLocalizedString("home.recent_activity.distance", comment: ""))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedDistance(session.distance))
                        .font(.caption)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("home.recent_activity.duration", comment: ""))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedDuration(session.duration))
                        .font(.caption)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("home.recent_activity.calories", comment: ""))
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
        DateFormatter.localizedMedium.string(from: date)
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
