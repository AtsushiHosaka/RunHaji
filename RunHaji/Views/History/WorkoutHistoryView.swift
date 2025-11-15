//
//  WorkoutHistoryView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

struct WorkoutHistoryView: View {
    @StateObject private var viewModel = WorkoutHistoryViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                } else if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    workoutList
                }
            }
            .navigationTitle("ワークアウト履歴")
            .alert("エラー", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .task {
            await viewModel.loadWorkouts()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("まだワークアウトがありません")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("ランニングを記録して、振り返りを確認しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var workoutList: some View {
        List(viewModel.sessions) { session in
            NavigationLink(destination: WorkoutDetailView(session: session)) {
                WorkoutRowView(session: session)
            }
        }
        .refreshable {
            await viewModel.loadWorkouts()
        }
    }
}

struct WorkoutRowView: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(formatDate(session.startDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let rpe = session.rpe {
                        Spacer()
                        RPEBadge(rpe: rpe)
                    }
                }
                
                HStack(spacing: 16) {
                    Label(formatDistance(session.distance), systemImage: "ruler")
                    Label(formatDuration(session.duration), systemImage: "clock")
                }
                .font(.headline)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 (E) HH:mm"
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
}

struct RPEBadge: View {
    let rpe: Int
    
    var body: some View {
        Text("RPE \(rpe)")
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
    
    private var badgeColor: Color {
        switch rpe {
        case 0...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        default: return .red
        }
    }
}

#Preview {
    WorkoutHistoryView()
}
