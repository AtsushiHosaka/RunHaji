//
//  MainTabView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(NSLocalizedString("tab.home", comment: ""), systemImage: "house.fill")
                }

            RunningView()
                .tabItem {
                    Label(NSLocalizedString("tab.running", comment: ""), systemImage: "figure.run")
                }

            GearView()
                .tabItem {
                    Label(NSLocalizedString("tab.gear", comment: ""), systemImage: "cart.fill")
                }

            WorkoutHistoryView()
                .tabItem {
                    Label(NSLocalizedString("tab.history", comment: ""), systemImage: "list.bullet")
                }

            SettingsView()
                .tabItem {
                    Label(NSLocalizedString("tab.settings", comment: ""), systemImage: "gearshape.fill")
                }
        }
        .tint(.accent)
    }
}

#Preview {
    MainTabView()
}
