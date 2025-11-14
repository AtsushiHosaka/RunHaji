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

    init() {
        // Listen for workout reflection saved notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WorkoutReflectionSaved"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let reflection = notification.userInfo?["reflection"] as? WorkoutReflection {
                self?.updateMilestoneFromReflection(reflection)
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
                createDefaultRoadmap()
            }

            // Load upcoming workouts
            let loadedWorkouts = try await SupabaseService.shared.getUpcomingWorkouts(userId: userId.uuidString)
            if loadedWorkouts.isEmpty {
                createDefaultUpcomingWorkouts()
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

    func createDefaultRoadmap() {
        guard let user = user else {
            errorMessage = "ユーザーデータが見つかりません。オンボーディングを完了してください。"
            return
        }

        let goal = user.profile.goal ?? .healthImprovement

        let milestones = [
            Milestone(
                title: "初めてのランニング",
                description: "15分間のランニングを完了する",
                targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                isCompleted: false
            ),
            Milestone(
                title: "1kmランニング達成",
                description: "1kmを走りきる",
                targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                isCompleted: false
            ),
            Milestone(
                title: "週2回のペースを確立",
                description: "2週間連続で週2回走る",
                targetDate: Calendar.current.date(byAdding: .day, value: 28, to: Date()),
                isCompleted: false
            )
        ]

        roadmap = Roadmap(
            userId: user.id.uuidString,
            title: goal.roadmapTitle,
            goal: goal,
            targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            milestones: milestones
        )

        saveRoadmap()
    }

    func createDefaultUpcomingWorkouts() {
        upcomingWorkouts = [
            UpcomingWorkout(
                title: "初回ランニング",
                estimatedDuration: 900, // 15 minutes
                targetDistance: 1000, // 1km
                notes: "ゆっくりしたペースで走りましょう"
            ),
            UpcomingWorkout(
                title: "2回目のランニング",
                estimatedDuration: 1200, // 20 minutes
                targetDistance: 1500, // 1.5km
                notes: "前回のペースを維持しましょう"
            )
        ]

        saveUpcomingWorkouts()
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
        guard let userId = user?.id.uuidString else { return }

        // Save to Supabase
        Task {
            do {
                for workout in upcomingWorkouts {
                    try await SupabaseService.shared.saveUpcomingWorkout(workout, userId: userId)
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
        isLoading = true
        loadUserData()
        loadRoadmap()
        loadUpcomingWorkouts()
        loadRecentSessions()

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
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
