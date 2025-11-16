//
//  GearListView.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

struct GearListView: View {
    @Binding var userProducts: [UserProduct]
    let onTogglePurchase: (UUID) -> Void

    private var sortedProducts: [UserProduct] {
        userProducts.sorted { !$0.isPurchased && $1.isPurchased }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("gear_list.title", comment: ""))
                .font(.headline)
                .padding(.horizontal)

            if userProducts.isEmpty {
                emptyStateView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(sortedProducts) { userProduct in
                            if let product = userProduct.product {
                                GearItemCard(
                                    product: product,
                                    isPurchased: userProduct.isPurchased,
                                    onTogglePurchase: {
                                        onTogglePurchase(userProduct.id)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.5))

            Text(NSLocalizedString("gear_list.empty", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

struct GearItemCard: View {
    let product: Product
    let isPurchased: Bool
    let onTogglePurchase: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder with purchase badge
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient.appGradient
                                .opacity(0.1)
                        )
                        .frame(width: 160, height: 120)
                        .cornerRadius(12)

                    if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: categoryIcon(for: product.category))
                                .font(.largeTitle)
                                .foregroundColor(.accent.opacity(0.5))
                        }
                        .frame(width: 160, height: 120)
                        .clipped()
                        .cornerRadius(12)
                    } else {
                        Image(systemName: categoryIcon(for: product.category))
                            .font(.largeTitle)
                            .foregroundColor(.accent.opacity(0.5))
                    }
                }

                // Purchase status badge
                Button(action: onTogglePurchase) {
                    Image(systemName: isPurchased ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isPurchased ? .accent : .gray.opacity(0.4))
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                        )
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Product title
                Text(product.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .opacity(isPurchased ? 0.5 : 1)

                // Price
                Text("¥\(product.price.formatted())")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accent)
                    .opacity(isPurchased ? 0.5 : 1)

                // Purchase button or purchased label
                if isPurchased {
                    Text(NSLocalizedString("gear_list.purchased", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                } else {
                    Link(destination: URL(string: product.purchaseURL)!) {
                        HStack(spacing: 4) {
                            Image(systemName: "cart.fill")
                            Text(NSLocalizedString("gear_list.purchase_button", comment: ""))
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accent)
                        .cornerRadius(6)
                    }
                }
            }
        }
        .frame(width: 160)
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .opacity(isPurchased ? 0.6 : 1)
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
    GearListView(
        userProducts: .constant([
            UserProduct(
                id: UUID(),
                userId: "test",
                productId: UUID(),
                roadmapId: UUID(),
                isPurchased: false,
                createdAt: Date(),
                product: Product(
                    id: UUID(),
                    title: "ランニングシューズ",
                    price: 12000,
                    imageURL: nil,
                    purchaseURL: "https://amazon.co.jp",
                    recommendedFor: "初心者向け",
                    category: .shoes
                )
            ),
            UserProduct(
                id: UUID(),
                userId: "test",
                productId: UUID(),
                roadmapId: UUID(),
                isPurchased: true,
                createdAt: Date(),
                product: Product(
                    id: UUID(),
                    title: "ランニングウェア",
                    price: 5000,
                    imageURL: nil,
                    purchaseURL: "https://amazon.co.jp",
                    recommendedFor: "初心者向け",
                    category: .apparel
                )
            )
        ]),
        onTogglePurchase: { _ in }
    )
    .padding()
}
