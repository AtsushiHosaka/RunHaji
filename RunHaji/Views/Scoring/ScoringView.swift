//
//  ScoringView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI
import ConfettiSwiftUI

struct ScoringView: View {
    @StateObject private var viewModel: ScoringViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confettiCounter = 0

    let workoutStartDate: Date
    let workoutEndDate: Date
    let distance: Double
    let duration: TimeInterval
    let calories: Double

    // User data for progress calculation
    let userGoal: RunningGoal?
    let idealFrequency: Int?
    let currentMilestone: Milestone?

    init(
        healthKitManager: HealthKitManager,
        userId: String,
        workoutStartDate: Date,
        workoutEndDate: Date,
        distance: Double,
        duration: TimeInterval,
        calories: Double,
        userGoal: RunningGoal? = nil,
        idealFrequency: Int? = nil,
        currentMilestone: Milestone? = nil
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
        self.currentMilestone = currentMilestone
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

                    // Current Milestone Section (only show after analysis)
                    if !viewModel.isAnalyzing {
                        Divider()
                            .padding(.horizontal)

                        currentMilestoneSection
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
            .confettiCannon(trigger: $confettiCounter)
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

    private var currentMilestoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("scoring.milestone.current_title", comment: "Current milestone title"))
                .font(.headline)
                .foregroundColor(.primary)

            if let milestone = currentMilestone {
                VStack(spacing: 16) {
                    // Milestone Info
                    HStack(spacing: 12) {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.orange)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(milestone.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            if let description = milestone.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }

                    // Achievement Status (if reflection available)
                    if let reflection = viewModel.workoutReflection,
                       let milestoneProgress = reflection.milestoneProgress {
                        Divider()

                        VStack(spacing: 12) {
                            // Status Icon and Message
                            HStack(spacing: 12) {
                                Image(systemName: milestoneProgress.isAchieved ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(milestoneProgress.isAchieved ? .green : .secondary)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(milestoneProgress.isAchieved ? NSLocalizedString("scoring.milestone.achieved", comment: "Milestone achieved") : NSLocalizedString("scoring.milestone.in_progress", comment: "Milestone in progress"))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(milestoneProgress.isAchieved ? .green : .primary)

                                    Text(milestoneProgress.achievementMessage)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            } else {
                Text(NSLocalizedString("scoring.milestone.no_milestone", comment: "No milestone in progress"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
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
            // Only process if not already done
            guard viewModel.workoutReflection == nil && !viewModel.isAnalyzing else { return }

            // Process workout completion (analyze + save)
            let milestoneAchieved = await viewModel.processWorkoutCompletion(
                userGoal: userGoal,
                currentMilestone: currentMilestone
            )

            // Trigger confetti if milestone was achieved
            if milestoneAchieved {
                // Delay slightly for better UX
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                confettiCounter += 1
            }
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
