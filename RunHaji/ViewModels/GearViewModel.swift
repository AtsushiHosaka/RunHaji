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
    @Published var recommendations: [ProductRecommendation] = []
    @Published var isLoading = false

    func loadRecommendations() async {
        isLoading = true

        // TODO: Implement AI-based recommendation system
        // For now, use sample data
        recommendations = sampleRecommendations()

        isLoading = false
    }

    func products(for category: ProductCategory) -> [Product] {
        recommendations
            .first { $0.category == category }?
            .products ?? []
    }

    private func sampleRecommendations() -> [ProductRecommendation] {
        [
            ProductRecommendation(
                category: .shoes,
                products: [
                    Product(
                        name: "エントリーランニングシューズ",
                        category: .shoes,
                        priceTier: .budget,
                        price: 5980,
                        brand: "ワークマン",
                        description: "初心者に最適なクッション性",
                        affiliateURL: "https://www.workman.co.jp",
                        features: ["軽量", "クッション性", "通気性"],
                        recommendedFor: "これからランニングを始める方に"
                    ),
                    Product(
                        name: "ミッドレンジランニングシューズ",
                        category: .shoes,
                        priceTier: .mid,
                        price: 12800,
                        brand: "デカトロン",
                        description: "長距離にも対応できる本格派",
                        affiliateURL: "https://www.decathlon.co.jp",
                        features: ["反発性", "耐久性", "安定性"],
                        recommendedFor: "定期的に走りたい方に"
                    )
                ],
                reasoning: "初心者の方には、クッション性と安定性を重視したシューズがおすすめです"
            ),
            ProductRecommendation(
                category: .apparel,
                products: [
                    Product(
                        name: "速乾Tシャツ",
                        category: .apparel,
                        priceTier: .budget,
                        price: 1980,
                        brand: "ユニクロ",
                        description: "汗を素早く乾かす高機能素材",
                        affiliateURL: "https://www.uniqlo.com",
                        features: ["速乾", "軽量", "UVカット"],
                        recommendedFor: "オールシーズン使える定番アイテム"
                    ),
                    Product(
                        name: "ランニングパンツ",
                        category: .apparel,
                        priceTier: .budget,
                        price: 2480,
                        brand: "ワークマン",
                        description: "動きやすいストレッチ素材",
                        affiliateURL: "https://www.workman.co.jp",
                        features: ["ストレッチ", "ポケット付き", "リフレクター"],
                        recommendedFor: "快適に走りたい方に"
                    )
                ],
                reasoning: "速乾性のあるウェアは快適なランニングに必須です"
            ),
            ProductRecommendation(
                category: .accessories,
                products: [
                    Product(
                        name: "ランニングキャップ",
                        category: .accessories,
                        priceTier: .budget,
                        price: 1280,
                        brand: "デカトロン",
                        description: "日差しから頭を守る",
                        affiliateURL: "https://www.decathlon.co.jp",
                        features: ["通気性", "軽量", "UVカット"],
                        recommendedFor: "日中のランニングに"
                    )
                ],
                reasoning: "帽子は熱中症対策に重要なアイテムです"
            ),
            ProductRecommendation(
                category: .supplements,
                products: [
                    Product(
                        name: "塩分タブレット",
                        category: .supplements,
                        priceTier: .budget,
                        price: 380,
                        brand: "カバヤ",
                        description: "汗で失われた塩分を補給",
                        affiliateURL: "https://www.amazon.co.jp",
                        features: ["携帯に便利", "レモン味", "速溶"],
                        recommendedFor: "夏場のランニングに必須"
                    )
                ],
                reasoning: "長時間のランニングでは塩分補給が大切です"
            ),
            ProductRecommendation(
                category: .gadgets,
                products: [
                    Product(
                        name: "ランニングウォッチ",
                        category: .gadgets,
                        priceTier: .mid,
                        price: 15800,
                        brand: "Xiaomi",
                        description: "GPS搭載でペース管理が簡単",
                        affiliateURL: "https://www.amazon.co.jp",
                        features: ["GPS", "心拍計", "防水"],
                        recommendedFor: "データを見ながら走りたい方に"
                    )
                ],
                reasoning: "ペース管理にはGPSウォッチが便利です"
            )
        ]
    }
}
