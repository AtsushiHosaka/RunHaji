//
//  ContentView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("current_user_id") private var storedUserId: String?

    var body: some View {
        Group {
            if storedUserId != nil {
                MainTabView()
            } else {
                OnboardingView(onComplete: {
                    // Onboarding completion will save userId, triggering UI update
                })
            }
        }
    }
}

#Preview {
    ContentView()
}
