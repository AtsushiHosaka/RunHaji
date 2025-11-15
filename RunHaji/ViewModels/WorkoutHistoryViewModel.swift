//
//  WorkoutHistoryViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import Foundation
import Combine

@MainActor
class WorkoutHistoryViewModel: ObservableObject {
    @Published var sessions: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadWorkouts() async {
        guard let userId = UserSessionManager.shared.storedUserId else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            sessions = try await SupabaseService.shared.getWorkoutSessions(
                userId: userId.uuidString,
                limit: 100
            )
        } catch {
            errorMessage = "ワークアウト履歴の読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
