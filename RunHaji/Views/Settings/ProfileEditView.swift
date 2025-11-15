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
                HStack {
                    Text("年齢")
                    Spacer()
                    TextField("年齢", text: $viewModel.age)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text("歳")
                }
                
                HStack {
                    Text("身長")
                    Spacer()
                    TextField("身長", text: $viewModel.height)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text("cm")
                }
                
                HStack {
                    Text("体重")
                    Spacer()
                    TextField("体重", text: $viewModel.weight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text("kg")
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
