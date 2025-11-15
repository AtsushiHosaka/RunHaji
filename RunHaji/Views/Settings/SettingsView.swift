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
                Section("プロフィール") {
                    NavigationLink(destination: ProfileEditView(viewModel: viewModel)) {
                        HStack {
                            Text("基本情報")
                            Spacer()
                            if let user = viewModel.user {
                                Text("\(user.profile.age ?? 0)歳・\(String(format: "%.0f", user.profile.height ?? 0))cm")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: GoalEditView(viewModel: viewModel)) {
                        HStack {
                            Text("目標設定")
                            Spacer()
                            if let goal = viewModel.user?.profile.goal {
                                Text(goal.description)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Data Section
                Section("データ") {
                    HStack {
                        Text("同期状態")
                        Spacer()
                        if viewModel.isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Button("手動同期") {
                        Task {
                            await viewModel.syncData()
                        }
                    }
                }
                
                // App Info Section
                Section("アプリについて") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("プライバシーポリシー", destination: URL(string: "https://example.com/privacy")!)
                    Link("利用規約", destination: URL(string: "https://example.com/terms")!)
                }
                
                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        viewModel.showingDeleteAlert = true
                    } label: {
                        Text("データを削除してリセット")
                    }
                }
            }
            .navigationTitle("設定")
            .alert("データを削除", isPresented: $viewModel.showingDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    viewModel.deleteAllData()
                }
            } message: {
                Text("全てのデータ（ロードマップ、ワークアウト履歴、プロフィール）が削除され、オンボーディング画面に戻ります。本当によろしいですか？")
            }
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
            await viewModel.loadUserProfile()
        }
    }
}

#Preview {
    SettingsView()
}
