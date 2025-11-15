//
//  GearViewModel.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import Foundation
import Combine

@MainActor
class GearViewModel: ObservableObject {
    @Published var allProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadRecommendations() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all products from Supabase
            allProducts = try await SupabaseService.shared.getAllProducts()
        } catch {
            print("Failed to load products: \(error)")
            errorMessage = "商品の読み込みに失敗しました"
            // Fallback to sample data for now
            allProducts = sampleProducts()
        }

        isLoading = false
    }

    func products(for category: ProductCategory) -> [Product] {
        allProducts.filter { $0.category == category }
    }

    private func sampleProducts() -> [Product] {
        [
            Product(
                id: UUID(),
                title: "エントリーランニングシューズ",
                price: 5980,
                imageURL: nil,
                purchaseURL: "https://www.workman.co.jp",
                recommendedFor: "これからランニングを始める方、クッション性と安定性を重視したい方",
                category: .shoes
            ),
            Product(
                id: UUID(),
                title: "ミッドレンジランニングシューズ",
                price: 12800,
                imageURL: nil,
                purchaseURL: "https://www.decathlon.co.jp",
                recommendedFor: "定期的に走りたい方、長距離にも対応したい方",
                category: .shoes
            ),
            Product(
                id: UUID(),
                title: "速乾Tシャツ",
                price: 1980,
                imageURL: nil,
                purchaseURL: "https://www.uniqlo.com",
                recommendedFor: "オールシーズン使える定番アイテム",
                category: .apparel
            ),
            Product(
                id: UUID(),
                title: "ランニングパンツ",
                price: 2480,
                imageURL: nil,
                purchaseURL: "https://www.workman.co.jp",
                recommendedFor: "快適に走りたい方、動きやすさを重視する方",
                category: .apparel
            ),
            Product(
                id: UUID(),
                title: "ランニングキャップ",
                price: 1280,
                imageURL: nil,
                purchaseURL: "https://www.decathlon.co.jp",
                recommendedFor: "日中のランニング、日差し対策が必要な方",
                category: .accessories
            ),
            Product(
                id: UUID(),
                title: "塩分タブレット",
                price: 380,
                imageURL: nil,
                purchaseURL: "https://www.amazon.co.jp",
                recommendedFor: "夏場のランニング、長時間走る方",
                category: .supplements
            ),
            Product(
                id: UUID(),
                title: "ランニングウォッチ",
                price: 15800,
                imageURL: nil,
                purchaseURL: "https://www.amazon.co.jp",
                recommendedFor: "データを見ながら走りたい方、ペース管理をしたい方",
                category: .gadgets
            )
        ]
    }
}
