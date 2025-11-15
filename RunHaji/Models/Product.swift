//
//  Product.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import Foundation

enum ProductCategory: String, Codable, CaseIterable {
    case shoes = "シューズ"
    case apparel = "ウェア"
    case accessories = "アクセサリー"
    case supplements = "サプリメント・補給食"
    case gadgets = "ガジェット"
}

enum PriceTier: String, Codable {
    case budget = "エントリー"
    case mid = "ミドル"
    case premium = "プレミアム"
}

struct Product: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: ProductCategory
    let priceTier: PriceTier
    let price: Int
    let brand: String
    let description: String
    let imageURL: String?
    let affiliateURL: String
    let features: [String]
    let recommendedFor: String // どんな人におすすめか

    init(
        id: UUID = UUID(),
        name: String,
        category: ProductCategory,
        priceTier: PriceTier,
        price: Int,
        brand: String,
        description: String,
        imageURL: String? = nil,
        affiliateURL: String,
        features: [String] = [],
        recommendedFor: String
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.priceTier = priceTier
        self.price = price
        self.brand = brand
        self.description = description
        self.imageURL = imageURL
        self.affiliateURL = affiliateURL
        self.features = features
        self.recommendedFor = recommendedFor
    }
}

struct ProductRecommendation: Codable {
    let category: ProductCategory
    let products: [Product]
    let reasoning: String // なぜこの商品がおすすめなのか
}
