//
//  MilestoneDetailView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

struct MilestoneDetailView: View {
    let milestone: Milestone
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GearViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                // Progress
                if !milestone.isCompleted {
                    progressSection
                }

                // Description
                if let description = milestone.description {
                    descriptionSection(description)
                }

                // Recommended Products
                recommendedProductsSection

                // Tips
                tipsSection
            }
            .padding()
        }
        .navigationTitle(milestone.title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadRecommendations()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(milestone.isCompleted ? .green : .gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let targetDate = milestone.targetDate {
                        Label(
                            formattedDate(targetDate),
                            systemImage: "calendar"
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
            }

            if milestone.isCompleted, let completedAt = milestone.completedAt {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("達成日: \(formattedDate(completedAt))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("進捗状況")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("このマイルストーンに向けてワークアウトを続けましょう！")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let targetDate = milestone.targetDate {
                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                    if daysRemaining > 0 {
                        Text("目標まで残り\(daysRemaining)日")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("目標の詳細")
                .font(.headline)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var recommendedProductsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("おすすめのギア")
                    .font(.headline)
                Spacer()
                NavigationLink("もっと見る") {
                    GearView()
                }
                .font(.subheadline)
            }

            Text("このマイルストーン達成に役立つアイテム")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Show 2-3 recommended products
                    ForEach(recommendedProducts().prefix(3)) { product in
                        ProductCard(product: product)
                    }
                }
            }
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("達成のためのヒント")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                TipRow(
                    icon: "lightbulb.fill",
                    text: "無理をせず、自分のペースで進めましょう",
                    color: .yellow
                )
                TipRow(
                    icon: "heart.fill",
                    text: "水分補給を忘れずに",
                    color: .red
                )
                TipRow(
                    icon: "checkmark.circle.fill",
                    text: "ワークアウト後はしっかりストレッチ",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func recommendedProducts() -> [Product] {
        // Get products relevant to this milestone
        var products: [Product] = []

        // Always recommend shoes and apparel for beginners
        products += viewModel.products(for: .shoes).prefix(1)
        products += viewModel.products(for: .apparel).prefix(1)

        // Add accessories for intermediate milestones
        if !milestone.isCompleted {
            products += viewModel.products(for: .accessories).prefix(1)
        }

        return products
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormatter.japaneseMedium.string(from: date)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    NavigationView {
        MilestoneDetailView(
            milestone: Milestone(
                title: "初めてのランニング",
                description: "15分間のランニングを完了する",
                targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                isCompleted: false
            )
        )
    }
}
