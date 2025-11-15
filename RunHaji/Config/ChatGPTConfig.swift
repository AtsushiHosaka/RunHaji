//
//  ChatGPTConfig.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

struct ChatGPTConfig {
    static let apiKey: String? = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["OPENAI_API_KEY"] as? String,
              !key.isEmpty,
              key.hasPrefix("sk-") else {
            return nil
        }
        return key
    }()

    static let apiEndpoint = "https://api.openai.com/v1/chat/completions"
    static let model = "gpt-5-nano" // Ultra cost-effective nano model for workout analysis
}
