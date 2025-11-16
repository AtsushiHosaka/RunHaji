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
                Text(NSLocalizedString("basicinfo.title", comment: "Basic info title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(NSLocalizedString("basicinfo.subtitle", comment: "Basic info subtitle"))
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
                    label: NSLocalizedString("basicinfo.age", comment: "Age"),
                    value: "\(viewModel.age)",
                    unit: NSLocalizedString("basicinfo.age.unit", comment: "Age unit"),
                    color: .blue
                ) {
                    showAgePicker = true
                }

                // Height
                InfoCard(
                    icon: "ruler.fill",
                    label: NSLocalizedString("basicinfo.height", comment: "Height"),
                    value: String(format: "%.0f", viewModel.height),
                    unit: NSLocalizedString("basicinfo.height.unit", comment: "Height unit"),
                    color: .green
                ) {
                    showHeightPicker = true
                }

                // Weight
                InfoCard(
                    icon: "scalemass.fill",
                    label: NSLocalizedString("basicinfo.weight", comment: "Weight"),
                    value: String(format: "%.1f", viewModel.weight),
                    unit: NSLocalizedString("basicinfo.weight.unit", comment: "Weight unit"),
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
                title: NSLocalizedString("basicinfo.age.picker.title", comment: "Age picker title"),
                selection: $viewModel.age,
                range: Array(10...100),
                unit: NSLocalizedString("basicinfo.age.unit", comment: "Age unit")
            )
        }
        .sheet(isPresented: $showHeightPicker) {
            PickerSheet(
                title: NSLocalizedString("basicinfo.height.picker.title", comment: "Height picker title"),
                selection: $viewModel.height,
                range: Array(stride(from: 140.0, through: 210.0, by: 1.0)),
                unit: NSLocalizedString("basicinfo.height.unit", comment: "Height unit"),
                format: "%.0f"
            )
        }
        .sheet(isPresented: $showWeightPicker) {
            PickerSheet(
                title: NSLocalizedString("basicinfo.weight.picker.title", comment: "Weight picker title"),
                selection: $viewModel.weight,
                range: Array(stride(from: 35.0, through: 150.0, by: 0.5)),
                unit: NSLocalizedString("basicinfo.weight.unit", comment: "Weight unit"),
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
                    Button(NSLocalizedString("common.done", comment: "Done button")) {
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
