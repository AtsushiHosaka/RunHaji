//
//  DateFormatter+Extensions.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

extension DateFormatter {
    // 端末の言語に追従する日付フォーマッタ
    static let localizedMedium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale.autoupdatingCurrent
        formatter.calendar = Calendar.autoupdatingCurrent
        return formatter
    }()

    static let localizedMediumWithTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.autoupdatingCurrent
        formatter.calendar = Calendar.autoupdatingCurrent
        return formatter
    }()

    static let localizedShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale.autoupdatingCurrent
        formatter.calendar = Calendar.autoupdatingCurrent
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
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        formatter.calendar = Calendar.autoupdatingCurrent
        return formatter.string(from: self) ?? String(Int(self / 60))
    }
}

extension Double {
    func formattedDistance() -> String {
        let km = self / 1000
        return String(format: "%.2f km", km)
    }
}
