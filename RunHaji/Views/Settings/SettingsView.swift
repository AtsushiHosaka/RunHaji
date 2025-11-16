//
//  SettingsView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Section
                Section(NSLocalizedString("settings.profile.section", comment: "")) {
                    NavigationLink(destination: ProfileEditView(viewModel: viewModel)) {
                        HStack {
                            Text(NSLocalizedString("settings.profile.basic_info", comment: ""))
                            Spacer()
                            if let user = viewModel.user {
                                Text(String(format: NSLocalizedString("settings.profile.age_height_format", comment: ""), user.profile.age ?? 0, user.profile.height ?? 0))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: GoalEditView(viewModel: viewModel)) {
                        HStack {
                            Text(NSLocalizedString("settings.profile.goal_setting", comment: ""))
                            Spacer()
                            if let goal = viewModel.user?.profile.goal {
                                Text(goal.description)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Data Section
                Section(NSLocalizedString("settings.data.section", comment: "")) {
                    HStack {
                        Text(NSLocalizedString("settings.data.sync_status", comment: ""))
                        Spacer()
                        if viewModel.isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Button(NSLocalizedString("settings.data.manual_sync", comment: "")) {
                        Task {
                            await viewModel.syncData()
                        }
                    }
                }
                
                // App Info Section
                Section(NSLocalizedString("settings.app_info.section", comment: "")) {
                    HStack {
                        Text(NSLocalizedString("settings.app_info.version", comment: ""))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(NSLocalizedString("settings.app_info.privacy_policy", comment: ""), destination: URL(string: "https://example.com/privacy")!)
                    Link(NSLocalizedString("settings.app_info.terms", comment: ""), destination: URL(string: "https://example.com/terms")!)
                }
                
                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        viewModel.showingDeleteAlert = true
                    } label: {
                        Text(NSLocalizedString("settings.danger.reset_button", comment: ""))
                    }
                }
            }
            .navigationTitle(NSLocalizedString("settings.title", comment: ""))
            .alert(NSLocalizedString("settings.danger.alert.title", comment: ""), isPresented: $viewModel.showingDeleteAlert) {
                Button(NSLocalizedString("settings.danger.alert.cancel", comment: ""), role: .cancel) { }
                Button(NSLocalizedString("settings.danger.alert.delete", comment: ""), role: .destructive) {
                    viewModel.deleteAllData()
                }
            } message: {
                Text(NSLocalizedString("settings.danger.alert.message", comment: ""))
            }
            .alert(NSLocalizedString("settings.error.title", comment: ""), isPresented: Binding(
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
            await viewModel.loadUserProfile()
        }
    }
}

#Preview {
    SettingsView()
}
