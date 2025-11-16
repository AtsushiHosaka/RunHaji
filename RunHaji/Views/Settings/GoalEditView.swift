//
//  GoalEditView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

struct GoalEditView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            ForEach(RunningGoal.allCases, id: \.self) { goal in
                Button {
                    viewModel.selectedGoal = goal
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.displayTitle)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(goal.displaySubtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.selectedGoal == goal {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("goal_edit.title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(NSLocalizedString("goal_edit.save", comment: "")) {
                    Task {
                        await viewModel.saveProfile()
                        dismiss()
                    }
                }
            }
        }
    }
}
