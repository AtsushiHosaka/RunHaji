//
//  SupabaseConfig.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

struct SupabaseConfig {
    private static func readConfigValue(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let value = config[key] as? String,
              !value.isEmpty else {
            return nil
        }
        return value
    }

    static let url: String? = {
        guard let url = readConfigValue(for: "SUPABASE_URL"),
              url != "YOUR_SUPABASE_PROJECT_URL",
              URL(string: url) != nil else {
            return nil
        }
        return url
    }()

    static let anonKey: String? = {
        guard let key = readConfigValue(for: "SUPABASE_ANON_KEY"),
              key != "YOUR_SUPABASE_ANON_KEY" else {
            return nil
        }
        return key
    }()
}
