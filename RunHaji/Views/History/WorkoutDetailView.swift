//
//  WorkoutDetailView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI
import Combine

struct WorkoutDetailView: View {
    let session: WorkoutSession
    @StateObject private var viewModel: WorkoutDetailViewModel
    
    init(session: WorkoutSession) {
        self.session = session
        _viewModel = StateObject(wrappedValue: WorkoutDetailViewModel(session: session))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                headerCard
                
                // Stats Grid
                statsGrid
                
                // Reflection Section
                if let reflection = viewModel.reflection {
                    reflectionSection(reflection: reflection)
                } else if viewModel.isLoading {
                    ProgressView(NSLocalizedString("workout_detail.loading_reflection", comment: "Loading reflection"))
                }
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("workout_detail.nav.title", comment: "Workout detail nav title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadReflection()
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            Text(formatDate(session.startDate))
                .font(.title3)
                .fontWeight(.semibold)
            
            if let rpe = session.rpe {
                RPEBadge(rpe: rpe)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                icon: "ruler",
                title: NSLocalizedString("workout_detail.stats.distance", comment: "Distance"),
                value: formatDistance(session.distance),
                color: .blue
            )
            
            StatCard(
                icon: "clock",
                title: NSLocalizedString("workout_detail.stats.duration", comment: "Duration"),
                value: formatDuration(session.duration),
                color: .green
            )
            
            StatCard(
                icon: "gauge",
                title: NSLocalizedString("workout_detail.stats.pace", comment: "Pace"),
                value: formatPace(session.distance, session.duration),
                color: .orange
            )
            
            StatCard(
                icon: "flame",
                title: NSLocalizedString("workout_detail.stats.calories", comment: "Calories"),
                value: formatCalories(session.calories),
                color: .red
            )
        }
    }
    
    private func reflectionSection(reflection: WorkoutReflection) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("workout_detail.reflection.title", comment: "AI reflection title"))
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Label(NSLocalizedString("workout_detail.reflection.todays_run", comment: "Today's run"), systemImage: "note.text")
                    .font(.headline)
                
                Text(reflection.reflection)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 12) {
                Label(NSLocalizedString("workout_detail.reflection.suggestions", comment: "Suggestions for next time"), systemImage: "lightbulb")
                    .font(.headline)
                
                Text(reflection.suggestions)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if let milestone = reflection.milestoneProgress, milestone.isAchieved {
                VStack(alignment: .leading, spacing: 12) {
                    Label(NSLocalizedString("workout_detail.reflection.milestone_achieved", comment: "Milestone achieved"), systemImage: "star.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Text(milestone.achievementMessage ?? NSLocalizedString("workout_detail.reflection.congratulations", comment: "Congratulations"))
                        .font(.body)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.locale = .current
        return formatter.string(from: date)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        String(format: "%.2f km", meters / 1000.0)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private func formatPace(_ meters: Double, _ seconds: TimeInterval) -> String {
        guard meters > 0 else { return "--:--" }
        let paceSeconds = (seconds / (meters / 1000.0))
        let mins = Int(paceSeconds) / 60
        let secs = Int(paceSeconds) % 60
        return String(format: "%d:%02d /km", mins, secs)
    }
    
    private func formatCalories(_ calories: Double) -> String {
        String(format: "%.0f kcal", calories)
    }
}

@MainActor
class WorkoutDetailViewModel: ObservableObject {
    @Published var reflection: WorkoutReflection?
    @Published var isLoading = false
    
    private let session: WorkoutSession
    
    init(session: WorkoutSession) {
        self.session = session
    }
    
    func loadReflection() async {
        guard let userId = UserSessionManager.shared.storedUserId else {
            return
        }
        
        isLoading = true
        
        do {
            let reflections = try await SupabaseService.shared.getWorkoutReflections(
                userId: userId.uuidString,
                limit: 100
            )
            
            reflection = reflections.first { $0.workoutSessionId == session.id }
        } catch {
            print("Failed to load reflection: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    NavigationView {
        WorkoutDetailView(session: WorkoutSession(
            userId: "test",
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            duration: 1800,
            distance: 5000,
            calories: 300,
            rpe: 6
        ))
    }
}
