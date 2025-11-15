//
//  WorkoutDetailView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

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
                    ProgressView("振り返りを読み込み中...")
                }
            }
            .padding()
        }
        .navigationTitle("ワークアウト詳細")
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
                title: "距離",
                value: formatDistance(session.distance),
                icon: "ruler",
                color: .blue
            )
            
            StatCard(
                title: "時間",
                value: formatDuration(session.duration),
                icon: "clock",
                color: .green
            )
            
            StatCard(
                title: "ペース",
                value: formatPace(session.distance, session.duration),
                icon: "gauge",
                color: .orange
            )
            
            StatCard(
                title: "カロリー",
                value: formatCalories(session.calories),
                icon: "flame",
                color: .red
            )
        }
    }
    
    private func reflectionSection(reflection: WorkoutReflection) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI振り返り")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Label("今日のランニング", systemImage: "note.text")
                    .font(.headline)
                
                Text(reflection.reflection)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 12) {
                Label("次回へのアドバイス", systemImage: "lightbulb")
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
                    Label("マイルストーン達成！", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Text(milestone.achievementMessage ?? "おめでとうございます！")
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
        formatter.dateFormat = "yyyy年M月d日 (E) HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
