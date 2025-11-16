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
    @Published var userProducts: [UserProduct] = []
    @Published var isLoading = false
    @Published var isGeneratingRoadmap = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false

    // Task management to prevent duplicate requests
    private var loadDataTask: Task<Void, Never>?

    init() {

        // Listen for workout reflection saved notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WorkoutReflectionSaved"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let reflection = notification.userInfo?["reflection"] as? WorkoutReflection {
                Task { @MainActor in

                    // Update milestone and save to Supabase (wait for completion)
                    await self?.updateMilestoneFromReflection(reflection)

                    // Always reload recent sessions and roadmap to show latest data
                    await self?.loadRecentSessions()
                    await self?.reloadRoadmap()

                }
            }
        }

        // Load data asynchronously
        loadDataTask = Task {
            await loadAllData()
        }
    }

    deinit {
        // Cancel any ongoing tasks
        loadDataTask?.cancel()
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
            return NSLocalizedString("greeting.morning", comment: "")
        case 12..<18:
            return NSLocalizedString("greeting.afternoon", comment: "")
        default:
            return NSLocalizedString("greeting.evening", comment: "")
        }
    }

    /// Load all data from Supabase
    func loadAllData() async {

        // Check if task was cancelled
        if Task.isCancelled {
            return
        }

        guard let userId = UserSessionManager.shared.storedUserId else {
            return
        }

        // Prevent duplicate requests
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Check cancellation before each major operation
            if Task.isCancelled {
                isLoading = false
                return
            }

            // Load user profile
            user = try await SupabaseService.shared.getUserProfile(userId: userId)

            if Task.isCancelled {
                isLoading = false
                return
            }

            // Load roadmap
            if let loadedRoadmap = try await SupabaseService.shared.getRoadmap(userId: userId.uuidString) {
                roadmap = loadedRoadmap
                // Load user products for existing roadmap
                await loadUserProducts()
            } else {
                // Create default roadmap if none exists
                // (This will automatically load products via Edge Function)
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
            print("❌ loadAllData failed: \(error)")
        }

        isLoading = false
    }

    /// Reload recent workout sessions
    func loadRecentSessions() async {
        guard let userId = UserSessionManager.shared.storedUserId else {
            return
        }

        do {
            let sessions = try await SupabaseService.shared.getWorkoutSessions(userId: userId.uuidString, limit: 5)
            recentSessions = sessions
        } catch {
            print("❌ Failed to reload recent sessions: \(error)")
        }
    }

    /// Reload roadmap to update progress
    func reloadRoadmap() async {
        guard let userId = UserSessionManager.shared.storedUserId else {
            return
        }

        do {
            if let loadedRoadmap = try await SupabaseService.shared.getRoadmap(userId: userId.uuidString) {
                roadmap = loadedRoadmap
            }
        } catch {
            print("❌ Failed to reload roadmap: \(error)")
        }
    }

    func createDefaultRoadmap() async {
        guard let user = user else {
            errorMessage = "ユーザーデータが見つかりません。オンボーディングを完了してください。"
            showErrorAlert = true
            return
        }

        isLoading = true
        isGeneratingRoadmap = true
        errorMessage = nil
        showErrorAlert = false

        do {

            // Call Edge Function to generate everything (roadmap + gear + workouts)
            let roadmapId = try await SupabaseService.shared.initializeRoadmap(user: user)


            // Load the created roadmap from Supabase
            if let userId = UserSessionManager.shared.storedUserId {
                roadmap = try await SupabaseService.shared.getRoadmap(userId: userId.uuidString)
            }

            // Wait a moment for all data to be committed
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Load all generated data
            await loadUserProducts()
            await loadUpcomingWorkouts()

        } catch {
            print("❌ Failed to initialize roadmap: \(error)")
            errorMessage = "ロードマップの生成に失敗しました。\n\(error.localizedDescription)\n\nもう一度お試しください。"
            showErrorAlert = true
        }

        isLoading = false
        isGeneratingRoadmap = false
    }

    private func loadUpcomingWorkouts() async {
        guard let userId = UserSessionManager.shared.storedUserId else {
            return
        }

        do {
            upcomingWorkouts = try await SupabaseService.shared.getUpcomingWorkouts(userId: userId.uuidString)
        } catch {
            print("❌ Failed to load upcoming workouts: \(error)")
        }
    }

    /// Call Edge Function to generate gear recommendations
    private func requestGearRecommendations(roadmapId: UUID) async {
        guard let user = user,
              let userId = UserSessionManager.shared.storedUserId else {
            return
        }

        do {
            try await SupabaseService.shared.requestGearRecommendations(
                userId: userId.uuidString,
                roadmapId: roadmapId,
                userAge: user.profile.age,
                userGoal: user.profile.goal?.rawValue,
                userIdealFrequency: user.profile.idealFrequency,
                userCurrentFrequency: user.profile.currentFrequency,
                roadmapGoal: roadmap?.goal.rawValue ?? "健康改善"
            )


            // Wait a moment for database to commit
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Reload user products after recommendations are generated
            await loadUserProducts()

        } catch {
            print("❌ Failed to generate gear recommendations: \(error)")
            print("Error details: \(String(describing: error))")
            // Still try to load products in case some exist
            await loadUserProducts()
        }
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

    func saveRoadmap() async {
        guard let roadmap = roadmap else { return }

        // Save to Supabase
        do {
            try await SupabaseService.shared.saveRoadmap(roadmap)
        } catch {
            errorMessage = "ロードマップの保存に失敗しました: \(error.localizedDescription)"
            print("❌ Failed to save roadmap to Supabase: \(error.localizedDescription)")
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

    func toggleMilestone(_ milestone: Milestone) async {
        guard var roadmap = roadmap else { return }

        if let index = roadmap.milestones.firstIndex(where: { $0.id == milestone.id }) {
            roadmap.milestones[index].isCompleted.toggle()
            roadmap.milestones[index].completedAt = roadmap.milestones[index].isCompleted ? Date() : nil
            self.roadmap = roadmap
            await saveRoadmap()
        }
    }

    func refresh() async {

        // Cancel existing task if running
        loadDataTask?.cancel()

        // Start new task
        loadDataTask = Task {
            await loadAllData()
        }

        // Wait for completion
        await loadDataTask?.value
    }

    /// ワークアウト振り返りを受け取ってマイルストーンを自動更新
    func updateMilestoneFromReflection(_ reflection: WorkoutReflection) async {
        guard var roadmap = roadmap else { return }
        guard let milestoneProgress = reflection.milestoneProgress else { return }

        // Find the milestone by ID if available, otherwise use first uncompleted
        var index: Int?
        if let milestoneId = milestoneProgress.milestoneId {
            index = roadmap.milestones.firstIndex(where: { $0.id == milestoneId })
        } else {
            index = roadmap.milestones.firstIndex(where: { !$0.isCompleted })
        }

        if let index = index {
            // If achieved, mark as completed
            if milestoneProgress.isAchieved {
                roadmap.milestones[index].isCompleted = true
                roadmap.milestones[index].completedAt = Date()
            }

            self.roadmap = roadmap

            // Save to Supabase and wait for completion
            await saveRoadmap()
        }
    }

    // MARK: - Product Management

    /// Load user's products for the current roadmap
    func loadUserProducts() async {
        guard let userId = UserSessionManager.shared.storedUserId,
              let roadmapId = roadmap?.id else {
            return
        }


        do {
            userProducts = try await SupabaseService.shared.getUserProducts(
                userId: userId.uuidString,
                roadmapId: roadmapId
            )

            // Debug: print each product
            for (index, userProduct) in userProducts.enumerated() {
            }
        } catch {
            print("❌ Failed to load user products: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error details: \(String(describing: error))")
            errorMessage = "ギアの読み込みに失敗しました: \(error.localizedDescription)"
        }
    }

    /// Toggle product purchase status
    func toggleProductPurchase(userProductId: UUID) async {
        guard let index = userProducts.firstIndex(where: { $0.id == userProductId }) else {
            return
        }

        let newStatus = !userProducts[index].isPurchased

        do {
            try await SupabaseService.shared.updateProductPurchaseStatus(
                userProductId: userProductId,
                isPurchased: newStatus
            )

            // Update local state
            userProducts[index].isPurchased = newStatus
        } catch {
            print("Failed to update purchase status: \(error)")
            errorMessage = "購入状態の更新に失敗しました"
        }
    }

    var currentMilestone: Milestone? {
        roadmap?.milestones.first(where: { !$0.isCompleted })
    }
}
