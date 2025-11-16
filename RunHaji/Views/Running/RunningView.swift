//
//  RunningView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct RunningView: View {
    @StateObject private var viewModel: RunningViewModel

    init() {
        // Use default HealthKitManager
        _viewModel = StateObject(wrappedValue: RunningViewModel(healthKitManager: HealthKitManager()))
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient.appGradient
                .opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Title
                Text(NSLocalizedString("running.title", comment: "Running title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Stats Display
                VStack(spacing: 30) {
                    // Distance
                    StatView(
                        title: NSLocalizedString("running.stats.distance", comment: "Distance"),
                        value: viewModel.formattedDistance(),
                        unit: "km"
                    )

                    // Timer
                    StatView(
                        title: NSLocalizedString("running.stats.duration", comment: "Duration"),
                        value: viewModel.formattedDuration(),
                        unit: ""
                    )

                    // Pace
                    StatView(
                        title: NSLocalizedString("running.stats.pace", comment: "Pace"),
                        value: viewModel.formattedPace(),
                        unit: "min/km"
                    )
                }
                .padding(.horizontal)

                Spacer()

                // Control Button
                if viewModel.isRunning {
                    Button(action: {
                        viewModel.requestEndWorkout()
                    }) {
                        Text(NSLocalizedString("running.button.finish", comment: "Finish button"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 60)
                            .background(Color.red)
                            .cornerRadius(30)
                            .shadow(radius: 10)
                    }
                } else {
                    Button(action: {
                        viewModel.startWorkout()
                    }) {
                        Text(NSLocalizedString("running.button.start", comment: "Start button"))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 60)
                            .background(Color.green)
                            .cornerRadius(30)
                            .shadow(radius: 10)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .alert(NSLocalizedString("running.alert.end_workout.title", comment: "End workout alert title"), isPresented: $viewModel.showingEndWorkoutAlert) {
            Button(NSLocalizedString("common.cancel", comment: "Cancel button"), role: .cancel) {
                viewModel.cancelEndWorkout()
            }
            Button(NSLocalizedString("running.button.finish", comment: "Finish button"), role: .destructive) {
                Task {
                    await viewModel.endWorkout()
                }
            }
        } message: {
            Text(NSLocalizedString("running.alert.end_workout.message", comment: "End workout alert message"))
        }
        .alert(NSLocalizedString("common.error", comment: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(NSLocalizedString("common.ok", comment: "OK button")) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await viewModel.requestAuthorization()
        }
    }
}

// MARK: - Stat View Component

struct StatView: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    RunningView()
}
