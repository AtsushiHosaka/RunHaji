//
//  Product.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import Foundation

enum ProductCategory: String, Codable, CaseIterable {
    case shoes = "shoes"
    case apparel = "apparel"
    case accessories = "accessories"
    case supplements = "supplements"
    case gadgets = "gadgets"

    var displayName: String {
        switch self {
        case .shoes: return "シューズ"
        case .apparel: return "ウェア"
        case .accessories: return "アクセサリー"
        case .supplements: return "サプリメント・補給食"
        case .gadgets: return "ガジェット"
        }
    }
}

enum PriceTier: String, Codable {
    case budget = "エントリー"
    case mid = "ミドル"
    case premium = "プレミアム"
}

/// Product stored in Supabase (master data)
struct Product: Identifiable, Codable {
    let id: UUID
    let title: String
    let price: Int
    let imageURL: String?
    let purchaseURL: String // Amazon等の販売URL
    let recommendedFor: String // どんな人におすすめか（AI判定用）
    let category: ProductCategory

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case price
        case imageURL = "image_url"
        case purchaseURL = "purchase_url"
        case recommendedFor = "recommended_for"
        case category
    }
}

/// User's product with purchase status (user-specific data)
struct UserProduct: Identifiable, Codable {
    let id: UUID
    let userId: String
    let productId: UUID
    let roadmapId: UUID
    var isPurchased: Bool
    let createdAt: Date

    // Joined product data
    var product: Product?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case productId = "product_id"
        case roadmapId = "roadmap_id"
        case isPurchased = "is_purchased"
        case createdAt = "created_at"
        case product
    }
}
