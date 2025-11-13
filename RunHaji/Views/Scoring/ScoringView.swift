//
//  ScoringView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct ScoringView: View {
    @StateObject private var viewModel: ScoringViewModel
    @Environment(\.dismiss) private var dismiss

    let workoutStartDate: Date
    let workoutEndDate: Date
    let distance: Double
    let duration: TimeInterval
    let calories: Double

    // User data for progress calculation
    let userGoal: RunningGoal?
    let idealFrequency: Int?

    init(
        healthKitManager: HealthKitManager,
        userId: String,
        workoutStartDate: Date,
        workoutEndDate: Date,
        distance: Double,
        duration: TimeInterval,
        calories: Double,
        userGoal: RunningGoal? = nil,
        idealFrequency: Int? = nil
    ) {
        _viewModel = StateObject(wrappedValue: ScoringViewModel(
            healthKitManager: healthKitManager,
            userId: userId
        ))
        self.workoutStartDate = workoutStartDate
        self.workoutEndDate = workoutEndDate
        self.distance = distance
        self.duration = duration
        self.calories = calories
        self.userGoal = userGoal
        self.idealFrequency = idealFrequency
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("お疲れ様でした！")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("ワークアウトを記録します")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Workout Summary
                    workoutSummarySection

                    Divider()
                        .padding(.horizontal)

                    // RPE Input
                    rpeInputSection

                    Divider()
                        .padding(.horizontal)

                    // Progress Section
                    progressSection

                    // Save Button
                    saveButton
                }
                .padding()
            }
            .navigationTitle("ワークアウト記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("スキップ") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.showSuccessMessage {
                    successOverlay
                }
            }
            .alert("エラー", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .onAppear {
            loadData()
        }
    }

    // MARK: - View Components

    private var workoutSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ワークアウト概要")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    icon: "figure.run",
                    title: "距離",
                    value: viewModel.formatDistance(distance),
                    color: .blue
                )

                StatCard(
                    icon: "clock",
                    title: "時間",
                    value: viewModel.formatDuration(duration),
                    color: .green
                )

                StatCard(
                    icon: "speedometer",
                    title: "ペース",
                    value: viewModel.formatPace(distance, duration),
                    color: .orange
                )

                StatCard(
                    icon: "flame",
                    title: "カロリー",
                    value: viewModel.formatCalories(calories),
                    color: .red
                )
            }
        }
    }

    private var rpeInputSection: some View {
        RPEInputView(selectedRPE: $viewModel.selectedRPE)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今週の進捗")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("達成率")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(String(format: "%.0f%%", viewModel.progressPercentage))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * (viewModel.progressPercentage / 100),
                                    height: 12
                                )
                        }
                    }
                    .frame(height: 12)
                }

                Divider()

                // Weekly Stats
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今週の走行距離")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.formatWeeklyDistance())
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Divider()
                        .frame(height: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("ワークアウト回数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.weeklyWorkouts)回")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }

                Divider()

                // Next Milestone
                HStack(spacing: 12) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.orange)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("次のマイルストーン")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.getNextMilestone(userGoal: userGoal, idealFrequency: idealFrequency))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                await viewModel.saveWorkoutWithRPE()
                // Wait a moment before dismissing to show success message
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                dismiss()
            }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("記録を保存")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isSaving)
    }

    private var successOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                Text("保存しました")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            .padding()
            .background(
                Capsule()
                    .fill(Color.green)
            )
            .padding(.bottom, 50)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: viewModel.showSuccessMessage)
    }

    // MARK: - Helper Methods

    private func loadData() {
        viewModel.loadWorkoutData(
            startDate: workoutStartDate,
            endDate: workoutEndDate,
            distance: distance,
            duration: duration,
            calories: calories
        )

        Task {
            await viewModel.calculateWeeklyProgress(
                userGoal: userGoal,
                idealFrequency: idealFrequency
            )
        }
    }
}

// MARK: - StatCard Component

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

struct ScoringView_Previews: PreviewProvider {
    static var previews: some View {
        ScoringView(
            healthKitManager: HealthKitManager(),
            userId: "test-user",
            workoutStartDate: Date().addingTimeInterval(-1800),
            workoutEndDate: Date(),
            distance: 5000,
            duration: 1800,
            calories: 300,
            userGoal: .buildStamina,
            idealFrequency: 3
        )
    }
}
