//
//  BasicInfoStepView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct BasicInfoStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showAgePicker = false
    @State private var showHeightPicker = false
    @State private var showWeightPicker = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("あなたについて教えてください")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("基本情報を選択してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.horizontal)

            // Info Cards
            VStack(spacing: 16) {
                // Age
                InfoCard(
                    icon: "person.fill",
                    label: "年齢",
                    value: "\(viewModel.age)",
                    unit: "歳",
                    color: .blue
                ) {
                    showAgePicker = true
                }

                // Height
                InfoCard(
                    icon: "ruler.fill",
                    label: "身長",
                    value: String(format: "%.0f", viewModel.height),
                    unit: "cm",
                    color: .green
                ) {
                    showHeightPicker = true
                }

                // Weight
                InfoCard(
                    icon: "scalemass.fill",
                    label: "体重",
                    value: String(format: "%.1f", viewModel.weight),
                    unit: "kg",
                    color: .orange
                ) {
                    showWeightPicker = true
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .sheet(isPresented: $showAgePicker) {
            PickerSheet(
                title: "年齢を選択",
                selection: $viewModel.age,
                range: Array(10...100),
                unit: "歳"
            )
        }
        .sheet(isPresented: $showHeightPicker) {
            PickerSheet(
                title: "身長を選択",
                selection: $viewModel.height,
                range: Array(stride(from: 140.0, through: 210.0, by: 1.0)),
                unit: "cm",
                format: "%.0f"
            )
        }
        .sheet(isPresented: $showWeightPicker) {
            PickerSheet(
                title: "体重を選択",
                selection: $viewModel.weight,
                range: Array(stride(from: 35.0, through: 150.0, by: 0.5)),
                unit: "kg",
                format: "%.1f"
            )
        }
    }
}

// MARK: - Info Card Component

struct InfoCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Label
                Text(label)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Value
                HStack(spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(unit)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Picker Sheet Component

struct PickerSheet<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let range: [T]
    let unit: String
    var format: String = "%@"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Picker(title, selection: $selection) {
                    ForEach(range, id: \.self) { value in
                        if let intValue = value as? Int {
                            Text("\(intValue)")
                                .tag(value)
                        } else if let doubleValue = value as? Double {
                            Text(String(format: format, doubleValue))
                                .tag(value)
                        }
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(300)])
    }
}

#Preview {
    BasicInfoStepView(viewModel: OnboardingViewModel())
}
