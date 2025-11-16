//
//  RPEInputView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import SwiftUI

struct RPEInputView: View {
    @Binding var selectedRPE: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("rpe.title", comment: "RPE title"))
                .font(.headline)
                .foregroundColor(.primary)

            Text(rpeDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // RPE Slider
            VStack(spacing: 12) {
                HStack {
                    Text("1")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(selectedRPE)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(rpeColor)

                    Spacer()

                    Text("10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { Double(selectedRPE) },
                        set: { selectedRPE = Int($0.rounded()) }
                    ),
                    in: 1...10,
                    step: 1
                )
                .tint(rpeColor)
                .accessibilityLabel(NSLocalizedString("rpe.slider.label", comment: "RPE slider label"))
                .accessibilityValue("\(selectedRPE)、\(rpeLevel)")

                HStack {
                    Text(NSLocalizedString("rpe.slider.min.label", comment: "RPE slider min label"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(NSLocalizedString("rpe.slider.max.label", comment: "RPE slider max label"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )

            // RPE Description Card
            HStack(spacing: 12) {
                Circle()
                    .fill(rpeColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: rpeIcon)
                            .foregroundColor(rpeColor)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(rpeLevel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(rpeDetailedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(rpeColor.opacity(0.1))
            )
        }
    }

    // MARK: - Computed Properties

    private var rpeDescription: String {
        NSLocalizedString("rpe.description", comment: "RPE description")
    }

    private var rpeLevel: String {
        guard let rpe = RPE(value: selectedRPE) else { return "" }
        return rpe.description
    }

    private var rpeDetailedDescription: String {
        guard let rpe = RPE(value: selectedRPE) else { return "" }
        return rpe.detailedDescription
    }

    private var rpeColor: Color {
        guard let rpe = RPE(value: selectedRPE) else { return .gray }
        return rpe.color
    }

    private var rpeIcon: String {
        switch selectedRPE {
        case 1...3:
            return "face.smiling"
        case 4...6:
            return "face.dashed"
        case 7...8:
            return "flame"
        case 9...10:
            return "flame.fill"
        default:
            return "circle"
        }
    }
}

// MARK: - Preview

struct RPEInputView_Previews: PreviewProvider {
    static var previews: some View {
        RPEInputView(selectedRPE: .constant(5))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
