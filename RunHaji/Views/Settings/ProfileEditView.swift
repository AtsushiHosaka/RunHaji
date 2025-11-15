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
            Section(NSLocalizedString("profile_edit.basic_info", comment: "")) {
                Picker(NSLocalizedString("profile_edit.age", comment: ""), selection: $viewModel.age) {
                    ForEach(10...100, id: \.self) { age in
                        Text(String(format: NSLocalizedString("basicinfo.age.unit", comment: ""), age))
                            .tag(age)
                    }
                }

                Picker(NSLocalizedString("profile_edit.height", comment: ""), selection: $viewModel.height) {
                    ForEach(Array(stride(from: 140.0, through: 210.0, by: 1.0)), id: \.self) { height in
                        Text(String(format: "%.0f %@", height, NSLocalizedString("basicinfo.height.unit", comment: "")))
                            .tag(height)
                    }
                }

                Picker(NSLocalizedString("profile_edit.weight", comment: ""), selection: $viewModel.weight) {
                    ForEach(Array(stride(from: 35.0, through: 150.0, by: 0.5)), id: \.self) { weight in
                        Text(String(format: "%.1f %@", weight, NSLocalizedString("basicinfo.weight.unit", comment: "")))
                            .tag(weight)
                    }
                }
            }

            Section(NSLocalizedString("profile_edit.weekly_goal", comment: "")) {
                Stepper(String(format: NSLocalizedString("profile_edit.weekly_frequency_format", comment: ""), viewModel.idealFrequency), value: $viewModel.idealFrequency, in: 1...7)
            }
        }
        .navigationTitle(NSLocalizedString("profile_edit.title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(NSLocalizedString("profile_edit.save", comment: "")) {
                    Task {
                        await viewModel.saveProfile()
                        dismiss()
                    }
                }
            }
        }
    }
}
