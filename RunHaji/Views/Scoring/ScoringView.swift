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

                        Text(NSLocalizedString("scoring.header.title", comment: "Scoring header title"))
                            .font(.title)
                            .fontWeight(.bold)

                        Text(NSLocalizedString("scoring.header.subtitle", comment: "Scoring header subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Workout Summary
                    workoutSummarySection

                    Divider()
                        .padding(.horizontal)

                    // Workout Reflection
                    if viewModel.isAnalyzing {
                        analyzingSection
                    } else if let reflection = viewModel.workoutReflection {
                        reflectionSection(reflection)
                    }

                    Divider()
                        .padding(.horizontal)

                    // Progress Section
                    progressSection

                    // Save Button
                    if viewModel.workoutReflection != nil {
                        saveButton
                    } else if !viewModel.isAnalyzing && viewModel.errorMessage != nil {
                        // Analysis failed, show fallback save option
                        fallbackSaveSection
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("scoring.nav.title", comment: "Scoring navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("common.skip", comment: "Skip button")) {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.showSuccessMessage {
                    successOverlay
                }
            }
            .alert(NSLocalizedString("common.error", comment: ""), isPresented: Binding(
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
            Text(NSLocalizedString("scoring.summary.title", comment: "Workout summary title"))
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    icon: "figure.run",
                    title: NSLocalizedString("scoring.summary.distance", comment: "Distance"),
                    value: viewModel.formatDistance(distance),
                    color: .blue
                )

                StatCard(
                    icon: "clock",
                    title: NSLocalizedString("scoring.summary.duration", comment: "Duration"),
                    value: viewModel.formatDuration(duration),
                    color: .green
                )

                StatCard(
                    icon: "speedometer",
                    title: NSLocalizedString("scoring.summary.pace", comment: "Pace"),
                    value: viewModel.formatPace(distance, duration),
                    color: .orange
                )

                StatCard(
                    icon: "flame",
                    title: NSLocalizedString("scoring.summary.calories", comment: "Calories"),
                    value: viewModel.formatCalories(calories),
                    color: .red
                )
            }
        }
    }

    private var analyzingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text(NSLocalizedString("scoring.analyzing.text", comment: "Analyzing workout text"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func reflectionSection(_ reflection: WorkoutReflection) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("scoring.reflection.title", comment: "Today's reflection title"))
                .font(.headline)
                .foregroundColor(.primary)

            // RPE Badge
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(rpeColor(reflection.estimatedRPE).opacity(0.2))
                        .frame(width: 60, height: 60)

                    VStack(spacing: 2) {
                        Text("RPE")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(reflection.estimatedRPE)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(rpeColor(reflection.estimatedRPE))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(rpeLevel(reflection.estimatedRPE))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(NSLocalizedString("scoring.reflection.rpe.level", comment: "RPE level"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )

            // Reflection
            VStack(alignment: .leading, spacing: 8) {
                Label(NSLocalizedString("scoring.reflection.reflection", comment: "Reflection"), systemImage: "bubble.left.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                Text(reflection.reflection)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )

            // Suggestions
            VStack(alignment: .leading, spacing: 8) {
                Label(NSLocalizedString("scoring.reflection.suggestions", comment: "Suggestions"), systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)

                Text(reflection.suggestions)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )

            // Milestone Progress
            if let milestoneProgress = reflection.milestoneProgress, milestoneProgress.isAchieved {
                HStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("scoring.reflection.milestone.achieved", comment: "Milestone achieved"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(milestoneProgress.achievementMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.1))
                )
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("scoring.progress.title", comment: "Weekly progress title"))
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(NSLocalizedString("scoring.progress.completion_rate", comment: "Completion rate"))
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
                        Text(NSLocalizedString("scoring.progress.weekly_distance", comment: "Weekly distance"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.formatWeeklyDistance())
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Divider()
                        .frame(height: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("scoring.progress.weekly_workouts", comment: "Weekly workouts"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: NSLocalizedString("scoring.progress.workouts.unit", comment: "Workouts unit"), viewModel.weeklyWorkouts))
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
                        Text(NSLocalizedString("scoring.progress.next_milestone", comment: "Next milestone"))
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
                await viewModel.saveWorkoutWithReflection()
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
                    Text(NSLocalizedString("scoring.save_button", comment: "Save button"))
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

    private var fallbackSaveSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.orange)

                Text(NSLocalizedString("scoring.fallback.title", comment: "Fallback title"))
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(NSLocalizedString("scoring.fallback.subtitle", comment: "Fallback subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )

            Button {
                Task {
                    await viewModel.saveWorkoutWithFallback()
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
                        Text(NSLocalizedString("scoring.fallback.save_button", comment: "Fallback save button"))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isSaving)
        }
    }

    private var successOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                Text(NSLocalizedString("scoring.success.message", comment: "Success message"))
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

            // Only analyze if not already done
            guard viewModel.workoutReflection == nil && !viewModel.isAnalyzing else { return }

            // Get current milestone from ViewModel
            let currentMilestone: Milestone? = viewModel.loadCurrentMilestone()

            // Analyze workout with ChatGPT
            await viewModel.analyzeWorkout(
                userGoal: userGoal,
                currentMilestone: currentMilestone
            )
        }
    }

    private func rpeColor(_ rpe: Int) -> Color {
        guard let rpeModel = RPE(value: rpe) else { return .gray }
        return rpeModel.color
    }

    private func rpeLevel(_ rpe: Int) -> String {
        guard let rpeModel = RPE(value: rpe) else { return "" }
        return rpeModel.description
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
