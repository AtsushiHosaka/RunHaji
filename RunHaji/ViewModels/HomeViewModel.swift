//
//  HomeViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var user: User?
    @Published var roadmap: Roadmap?
    @Published var upcomingWorkouts: [UpcomingWorkout] = []
    @Published var recentSessions: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false

    init() {
        // Listen for workout reflection saved notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WorkoutReflectionSaved"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let reflection = notification.userInfo?["reflection"] as? WorkoutReflection {
                Task { @MainActor in
                    self?.updateMilestoneFromReflection(reflection)
                }
            }
        }

        // Load data asynchronously
        Task {
            await loadAllData()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var progressPercentage: Double {
        roadmap?.progressPercentage ?? 0.0
    }

    var completedMilestones: Int {
        roadmap?.completedMilestones ?? 0
    }

    var totalMilestones: Int {
        roadmap?.milestones.count ?? 0
    }

    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "おはようございます"
        case 12..<18:
            return "こんにちは"
        default:
            return "こんばんは"
        }
    }

    /// Load all data from Supabase
    func loadAllData() async {
        guard let userId = UserSessionManager.shared.storedUserId else {
            // User hasn't completed onboarding
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Load user profile
            user = try await SupabaseService.shared.getUserProfile(userId: userId)

            // Load roadmap
            if let loadedRoadmap = try await SupabaseService.shared.getRoadmap(userId: userId.uuidString) {
                roadmap = loadedRoadmap
            } else {
                // Create default roadmap if none exists
                await createDefaultRoadmap()
            }

            // Load upcoming workouts
            let loadedWorkouts = try await SupabaseService.shared.getUpcomingWorkouts(userId: userId.uuidString)
            if loadedWorkouts.isEmpty {
                await createDefaultUpcomingWorkouts()
            } else {
                upcomingWorkouts = loadedWorkouts
            }

            // Load recent workout sessions
            let sessions = try await SupabaseService.shared.getWorkoutSessions(userId: userId.uuidString, limit: 5)
            recentSessions = sessions

        } catch {
            errorMessage = "データの読み込みに失敗しました: \(error.localizedDescription)"
            print("Failed to load data from Supabase: \(error)")
        }

        isLoading = false
    }

    func createDefaultRoadmap() async {
        guard let user = user else {
            errorMessage = "ユーザーデータが見つかりません。オンボーディングを完了してください。"
            showErrorAlert = true
            return
        }

        isLoading = true
        errorMessage = nil
        showErrorAlert = false

        do {
            // Generate roadmap using OpenAI
            roadmap = try await OpenAIService.shared.generateRoadmap(for: user)

            // Save to Supabase
            saveRoadmap()
        } catch {
            print("Failed to generate roadmap: \(error)")
            errorMessage = "ロードマップの生成に失敗しました。\n\(error.localizedDescription)\n\nもう一度お試しください。"
            showErrorAlert = true
        }

        isLoading = false
    }

    func createDefaultUpcomingWorkouts() async {
        guard let user = user, let roadmap = roadmap else {
            errorMessage = "ユーザーまたはロードマップが見つかりません"
            return
        }

        isLoading = true

        do {
            // Generate workouts using OpenAI
            upcomingWorkouts = try await OpenAIService.shared.generateUpcomingWorkouts(
                for: user,
                roadmap: roadmap,
                count: 3
            )

            // Save to Supabase
            saveUpcomingWorkouts()
        } catch {
            print("Failed to generate workouts: \(error)")
            errorMessage = "ワークアウトの生成に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func saveRoadmap() {
        guard let roadmap = roadmap else { return }

        // Save to Supabase
        Task {
            do {
                try await SupabaseService.shared.saveRoadmap(roadmap)
                print("Roadmap saved to Supabase successfully")
            } catch {
                errorMessage = "ロードマップの保存に失敗しました: \(error.localizedDescription)"
                print("Failed to save roadmap to Supabase: \(error.localizedDescription)")
            }
        }
    }

    func saveUpcomingWorkouts() {
        guard let userId = UserSessionManager.shared.storedUserId else { return }

        // Save to Supabase
        Task {
            do {
                for workout in upcomingWorkouts {
                    try await SupabaseService.shared.saveUpcomingWorkout(workout, userId: userId.uuidString)
                }
                print("Upcoming workouts saved to Supabase successfully")
            } catch {
                errorMessage = "予定の保存に失敗しました: \(error.localizedDescription)"
                print("Failed to save upcoming workouts to Supabase: \(error.localizedDescription)")
            }
        }
    }

    func toggleMilestone(_ milestone: Milestone) {
        guard var roadmap = roadmap else { return }

        if let index = roadmap.milestones.firstIndex(where: { $0.id == milestone.id }) {
            roadmap.milestones[index].isCompleted.toggle()
            roadmap.milestones[index].completedAt = roadmap.milestones[index].isCompleted ? Date() : nil
            self.roadmap = roadmap
            saveRoadmap()
        }
    }

    func refresh() async {
        await loadAllData()
    }

    /// ワークアウト振り返りを受け取ってマイルストーンを自動更新
    func updateMilestoneFromReflection(_ reflection: WorkoutReflection) {
        guard var roadmap = roadmap else { return }
        guard let milestoneProgress = reflection.milestoneProgress else { return }
        guard milestoneProgress.isAchieved else { return }

        // Find the milestone by ID if available, otherwise use first uncompleted
        var index: Int?
        if let milestoneId = milestoneProgress.milestoneId {
            index = roadmap.milestones.firstIndex(where: { $0.id == milestoneId })
        } else {
            index = roadmap.milestones.firstIndex(where: { !$0.isCompleted })
        }

        if let index = index {
            roadmap.milestones[index].isCompleted = true
            roadmap.milestones[index].completedAt = Date()
            self.roadmap = roadmap
            saveRoadmap()
        }
    }
}
