//
//  ColorScheme.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

extension Color {
    // アクセントカラー（アプリアイコンから抽出）
    static let accent = Color(red: 0.2, green: 0.7, blue: 0.6) // Teal/Cyan

    // グラデーション用の色
    static let gradientStart = Color(red: 0.4, green: 0.8, blue: 0.9) // Light Blue
    static let gradientEnd = Color(red: 0.2, green: 0.7, blue: 0.6) // Teal

    // カード背景
    static let cardBackground = Color(.systemBackground)

    // セカンダリ背景
    static let secondaryBackground = Color(.secondarySystemBackground)
}

extension LinearGradient {
    static let appGradient = LinearGradient(
        gradient: Gradient(colors: [Color.gradientStart, Color.gradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
