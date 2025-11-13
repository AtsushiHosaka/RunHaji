//
//  DateFormatter+Extensions.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

extension DateFormatter {
    static let japaneseMedium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    static let japaneseMediumWithTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    static let japaneseShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

extension TimeInterval {
    func formattedDuration() -> String {
        let minutes = Int(self / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    func formattedMinutes() -> String {
        let minutes = Int(self / 60)
        return "\(minutes)分"
    }
}

extension Double {
    func formattedDistance() -> String {
        let km = self / 1000
        return String(format: "%.2f km", km)
    }
}
