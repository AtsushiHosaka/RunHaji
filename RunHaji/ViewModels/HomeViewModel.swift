//
//  HomeViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var user: User?
    @Published var roadmap: Roadmap?
    @Published var upcomingWorkouts: [UpcomingWorkout] = []
    @Published var recentSessions: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        loadUserData()
        loadRoadmap()
        loadUpcomingWorkouts()
        loadRecentSessions()
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
        let name = user?.profile.age != nil ? "さん" : ""

        switch hour {
        case 5..<12:
            return "おはようございます\(name)"
        case 12..<18:
            return "こんにちは\(name)"
        default:
            return "こんばんは\(name)"
        }
    }

    func loadUserData() {
        guard let data = UserDefaults.standard.data(forKey: "user_profile") else {
            return
        }

        let decoder = JSONDecoder()
        do {
            user = try decoder.decode(User.self, from: data)
        } catch {
            errorMessage = "ユーザーデータの読み込みに失敗しました"
        }
    }

    func loadRoadmap() {
        // Load from UserDefaults for now
        guard let data = UserDefaults.standard.data(forKey: "user_roadmap") else {
            // Create default roadmap if none exists
            createDefaultRoadmap()
            return
        }

        let decoder = JSONDecoder()
        do {
            roadmap = try decoder.decode(Roadmap.self, from: data)
        } catch {
            errorMessage = "ロードマップの読み込みに失敗しました"
        }
    }

    func loadUpcomingWorkouts() {
        guard let data = UserDefaults.standard.data(forKey: "upcoming_workouts") else {
            // Create default upcoming workouts
            createDefaultUpcomingWorkouts()
            return
        }

        let decoder = JSONDecoder()
        do {
            upcomingWorkouts = try decoder.decode([UpcomingWorkout].self, from: data)
        } catch {
            errorMessage = "予定の読み込みに失敗しました"
        }
    }

    func loadRecentSessions() {
        guard let data = UserDefaults.standard.data(forKey: "workout_sessions") else {
            return
        }

        let decoder = JSONDecoder()
        do {
            let sessions = try decoder.decode([WorkoutSession].self, from: data)
            recentSessions = Array(sessions.prefix(5))
        } catch {
            errorMessage = "ワークアウト履歴の読み込みに失敗しました"
        }
    }

    func createDefaultRoadmap() {
        guard let user = user else { return }

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
            title: "\(goal.description)への道",
            goal: goal,
            targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            milestones: milestones
        )

        saveRoadmap()
    }

    func createDefaultUpcomingWorkouts() {
        let calendar = Calendar.current
        let today = Date()

        upcomingWorkouts = [
            UpcomingWorkout(
                title: "初回ランニング",
                scheduledDate: calendar.date(byAdding: .day, value: 1, to: today)!,
                estimatedDuration: 900, // 15 minutes
                targetDistance: 1000, // 1km
                notes: "ゆっくりしたペースで走りましょう"
            ),
            UpcomingWorkout(
                title: "2回目のランニング",
                scheduledDate: calendar.date(byAdding: .day, value: 4, to: today)!,
                estimatedDuration: 1200, // 20 minutes
                targetDistance: 1500, // 1.5km
                notes: "前回のペースを維持しましょう"
            )
        ]

        saveUpcomingWorkouts()
    }

    func saveRoadmap() {
        guard let roadmap = roadmap else { return }

        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(roadmap)
            UserDefaults.standard.set(data, forKey: "user_roadmap")
        } catch {
            errorMessage = "ロードマップの保存に失敗しました"
        }
    }

    func saveUpcomingWorkouts() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(upcomingWorkouts)
            UserDefaults.standard.set(data, forKey: "upcoming_workouts")
        } catch {
            errorMessage = "予定の保存に失敗しました"
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
}
