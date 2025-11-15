//
//  ProfileEditView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

struct ProfileEditView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("基本情報") {
                Picker("年齢", selection: $viewModel.age) {
                    ForEach(10...100, id: \.self) { age in
                        Text("\(age)歳")
                            .tag(age)
                    }
                }

                Picker("身長", selection: $viewModel.height) {
                    ForEach(Array(stride(from: 140.0, through: 210.0, by: 1.0)), id: \.self) { height in
                        Text(String(format: "%.0f cm", height))
                            .tag(height)
                    }
                }

                Picker("体重", selection: $viewModel.weight) {
                    ForEach(Array(stride(from: 35.0, through: 150.0, by: 0.5)), id: \.self) { weight in
                        Text(String(format: "%.1f kg", weight))
                            .tag(weight)
                    }
                }
            }

            Section("週間目標") {
                Stepper("週\(viewModel.idealFrequency)回", value: $viewModel.idealFrequency, in: 1...7)
            }
        }
        .navigationTitle("プロフィール編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    Task {
                        await viewModel.saveProfile()
                        dismiss()
                    }
                }
            }
        }
    }
}
