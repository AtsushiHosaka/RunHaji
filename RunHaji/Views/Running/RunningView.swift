//
//  RunningView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI
import HealthKit

struct RunningView: View {
    @StateObject private var viewModel: RunningViewModel

    init() {
        _viewModel = StateObject(wrappedValue: RunningViewModel(healthKitManager: HealthKitManager()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient.appGradient
                    .opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.isRunning {
                        // Active workout view
                        activeWorkoutView
                    } else {
                        // Start view
                        startView
                    }
                }
            }
            .alert("ワークアウトを終了しますか?", isPresented: $viewModel.showingEndWorkoutAlert) {
                Button("キャンセル", role: .cancel) {
                    viewModel.cancelEndWorkout()
                }
                Button("終了", role: .destructive) {
                    Task {
                        await viewModel.endWorkout()
                    }
                }
            } message: {
                Text("ワークアウトを終了すると、データが保存されます。")
            }
            .navigationDestination(isPresented: $viewModel.showingScoringView) {
                if let workout = viewModel.completedWorkout,
                   let userId = UserSessionManager.shared.storedUserId {
                    ScoringViewWrapper(
                        workout: workout,
                        userId: userId.uuidString
                    )
                }
            }
            .task {
                await viewModel.requestAuthorization()
            }
        }
    }

    // MARK: - Start View

    private var startView: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("ランニング")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Image(systemName: "figure.run")
                .font(.system(size: 100))
                .foregroundColor(.accent)

            Button(action: {
                viewModel.startWorkout()
            }) {
                Text("START")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 60)
                    .background(Color.green)
                    .cornerRadius(30)
                    .shadow(radius: 10)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Active Workout View

    private var activeWorkoutView: some View {
        VStack(spacing: 24) {
            // Main distance display
            VStack(spacing: 8) {
                Text(viewModel.formattedDistance())
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("KM")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)

            Spacer()

            // Stats row
            HStack(spacing: 40) {
                // Duration
                StatItem(
                    icon: "timer",
                    value: viewModel.formattedDuration(),
                    label: "時間"
                )

                // Calories
                StatItem(
                    icon: "flame.fill",
                    value: viewModel.formattedCalories(),
                    label: "カロリー"
                )
            }
            .padding(.horizontal)

            Spacer()

            // Control buttons
            HStack(spacing: 60) {
                // Pause/Resume button
                Button(action: {
                    if viewModel.isPaused {
                        viewModel.resumeWorkout()
                    } else {
                        viewModel.pauseWorkout()
                    }
                }) {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 10)
                }

                // End button
                Button(action: {
                    viewModel.requestEndWorkout()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Circle().fill(Color.red))
                        .shadow(radius: 10)
                }
            }
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Stat Item Component

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accent)

            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Scoring View Wrapper

struct ScoringViewWrapper: View {
    let workout: HKWorkout
    let userId: String

    @State private var user: User?
    @State private var currentMilestone: Milestone?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("読み込み中...")
            } else {
                let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                let duration = workout.duration
                let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0

                let _ = {
                    print("📊 ScoringView - Workout Data:")
                    print("   Distance: \(distance) meters (\(distance/1000.0) km)")
                    print("   Duration: \(duration) seconds (\(duration/60.0) minutes)")
                    print("   Calories: \(calories) kcal")
                    print("   totalDistance raw: \(workout.totalDistance?.description ?? "nil")")
                }()

                ScoringView(
                    healthKitManager: HealthKitManager(),
                    userId: userId,
                    workoutStartDate: workout.startDate,
                    workoutEndDate: workout.endDate,
                    distance: distance,
                    duration: duration,
                    calories: calories,
                    userGoal: user?.profile.goal,
                    idealFrequency: user?.profile.idealFrequency,
                    currentMilestone: currentMilestone
                )
            }
        }
        .task {
            await loadUserData()
        }
    }

    private func loadUserData() async {
        guard let userIdUUID = UUID(uuidString: userId) else {
            isLoading = false
            return
        }

        do {
            // Load user profile
            user = try await SupabaseService.shared.getUserProfile(userId: userIdUUID)

            // Load roadmap and get current milestone
            if let roadmap = try await SupabaseService.shared.getRoadmap(userId: userId) {
                currentMilestone = roadmap.milestones.first(where: { !$0.isCompleted })
            }
        } catch {
            print("Failed to load user data: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    RunningView()
}
