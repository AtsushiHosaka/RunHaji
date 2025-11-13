//
//  ChatGPTConfig.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

struct ChatGPTConfig {
    static let apiKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !key.isEmpty,
              key != "YOUR_OPENAI_API_KEY" else {
            fatalError("OPENAI_API_KEY not found or invalid in Info.plist")
        }
        return key
    }()

    static let apiEndpoint = "https://api.openai.com/v1/chat/completions"
    static let model = "gpt-4o-mini" // Cost-effective model for workout analysis
}
