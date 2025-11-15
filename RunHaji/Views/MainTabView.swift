//
//  MainTabView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            RunningView()
                .tabItem {
                    Label("ランニング", systemImage: "figure.run")
                }
                .environmentObject(healthKitManager)

            WorkoutHistoryView()
                .tabItem {
                    Label("履歴", systemImage: "list.bullet")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
