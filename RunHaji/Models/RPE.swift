//
//  RPE.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation
import SwiftUI

/// RPE (Rate of Perceived Exertion) - 主観的運動強度
/// 1-10のスケールで運動のきつさを評価
struct RPE: Codable, Equatable {
    let value: Int

    init?(value: Int) {
        guard value >= 1 && value <= 10 else {
            return nil
        }
        self.value = value
    }

    /// RPE値に基づく説明テキスト
    var description: String {
        switch value {
        case 1...2:
            return "非常に楽"
        case 3...4:
            return "楽"
        case 5...6:
            return "ややきつい"
        case 7...8:
            return "きつい"
        case 9...10:
            return "非常にきつい"
        default:
            return ""
        }
    }

    /// RPE値に基づく詳細説明
    var detailedDescription: String {
        switch value {
        case 1:
            return "ほとんど何も感じない"
        case 2:
            return "非常に楽"
        case 3:
            return "楽"
        case 4:
            return "やや楽"
        case 5:
            return "少しきつい"
        case 6:
            return "ややきつい"
        case 7:
            return "きつい"
        case 8:
            return "かなりきつい"
        case 9:
            return "非常にきつい"
        case 10:
            return "最大努力"
        default:
            return ""
        }
    }

    /// RPE値に基づく色
    var color: Color {
        switch value {
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
}
