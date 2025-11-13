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
            Text("運動のきつさ")
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

                HStack {
                    Text("非常に楽")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("非常にきつい")
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
        "走り終わった直後の感覚で、どれくらいきつかったかを教えてください"
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
        switch selectedRPE {
        case 1...3:
            return .green
        case 4...6:
            return .yellow
        case 7...8:
            return .orange
        case 9...10:
            return .red
        default:
            return .gray
        }
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
