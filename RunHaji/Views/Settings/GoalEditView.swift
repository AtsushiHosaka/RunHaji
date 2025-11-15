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
                            Text(goal.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(goal.description)
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
        .navigationTitle("目標選択")
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
