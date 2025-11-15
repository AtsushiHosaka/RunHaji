//
//  OpenAIConfig.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import Foundation

struct OpenAIConfig {
    private static func readConfigValue(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let value = config[key] as? String,
              !value.isEmpty else {
            return nil
        }
        return value
    }

    static let apiKey: String? = {
        guard let key = readConfigValue(for: "OPENAI_API_KEY"),
              key.hasPrefix("sk-") else {
            return nil
        }
        return key
    }()
}
