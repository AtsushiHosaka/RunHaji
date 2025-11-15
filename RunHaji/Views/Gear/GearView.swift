//
//  GearView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

struct GearView: View {
    @StateObject private var viewModel = GearViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Categories
                    ForEach(ProductCategory.allCases, id: \.self) { category in
                        CategorySection(
                            category: category,
                            products: viewModel.products(for: category)
                        )
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("ギア推奨")
            .refreshable {
                await viewModel.loadRecommendations()
            }
        }
        .task {
            await viewModel.loadRecommendations()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("あなたにおすすめのギア")
                .font(.title2)
                .fontWeight(.bold)

            Text("ランニングを始めるために必要なアイテムを、予算別にご紹介します")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

struct CategorySection: View {
    let category: ProductCategory
    let products: [Product]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(category.rawValue)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            if products.isEmpty {
                emptyStateView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(products) { product in
                            ProductCard(product: product)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("商品を読み込み中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

struct ProductCard: View {
    let product: Product

    var body: some View {
        Link(destination: URL(string: product.purchaseURL)!) {
            VStack(alignment: .leading, spacing: 12) {
                // Image placeholder
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient.appGradient
                                .opacity(0.1)
                        )
                        .frame(height: 150)
                        .cornerRadius(12)

                    Image(systemName: categoryIcon(for: product.category))
                        .font(.largeTitle)
                        .foregroundColor(.accent.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Product title
                    Text(product.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Price
                    Text("¥\(product.price.formatted())")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.accent)

                    // Recommended for
                    Text(product.recommendedFor)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(width: 200)
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func categoryIcon(for category: ProductCategory) -> String {
        switch category {
        case .shoes: return "shoe.2"
        case .apparel: return "tshirt"
        case .accessories: return "eyeglasses"
        case .supplements: return "pills"
        case .gadgets: return "applewatch"
        }
    }
}

#Preview {
    GearView()
}
