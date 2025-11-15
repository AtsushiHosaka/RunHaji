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
                Text("ランニング")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Stats Display
                VStack(spacing: 30) {
                    // Distance
                    StatView(
                        title: "距離",
                        value: viewModel.formattedDistance(),
                        unit: "km"
                    )

                    // Timer
                    StatView(
                        title: "時間",
                        value: viewModel.formattedDuration(),
                        unit: ""
                    )

                    // Pace
                    StatView(
                        title: "ペース",
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
                        Text("終了")
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
                        Text("START")
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
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") {
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
