//
//  ChatGPTService.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

final class ChatGPTService {
    static let shared = ChatGPTService()

    private init() {}

    struct ChatMessage: Codable {
        let role: String
        let content: String
    }

    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
        let response_format: ResponseFormat?

        struct ResponseFormat: Codable {
            let type: String
        }
    }

    struct ChatResponse: Codable {
        let choices: [Choice]

        struct Choice: Codable {
            let message: ChatMessage
        }
    }

    /// ChatGPT APIを呼び出してテキストを生成
    func generateText(systemPrompt: String, userPrompt: String, useJSON: Bool = false) async throws -> String {
        guard let apiKey = ChatGPTConfig.apiKey else {
            throw ChatGPTError.missingApiKey
        }

        guard let url = URL(string: ChatGPTConfig.apiEndpoint) else {
            throw ChatGPTError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: userPrompt)
        ]

        let chatRequest = ChatRequest(
            model: ChatGPTConfig.model,
            messages: messages,
            temperature: 1.0,
            response_format: useJSON ? ChatRequest.ResponseFormat(type: "json_object") : nil
        )

        request.httpBody = try JSONEncoder().encode(chatRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatGPTError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Log the raw response for debugging
            if let errorResponse = String(data: data, encoding: .utf8) {
                print("ChatGPT API error: statusCode=\(httpResponse.statusCode), response=\(errorResponse)")
            }
            throw ChatGPTError.apiError(statusCode: httpResponse.statusCode, message: "APIエラーが発生しました")
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

        guard let firstChoice = chatResponse.choices.first else {
            throw ChatGPTError.noResponse
        }

        return firstChoice.message.content
    }
}

enum ChatGPTError: Error, LocalizedError {
    case missingApiKey
    case invalidResponse
    case noResponse
    case apiError(statusCode: Int, message: String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "OpenAI APIキーが設定されていません。Info.plistにOPENAI_API_KEYを追加してください。"
        case .invalidResponse:
            return "APIからの応答が無効です"
        case .noResponse:
            return "APIからの応答がありません"
        case .apiError(let statusCode, let message):
            return "APIエラー (\(statusCode)): \(message)"
        case .decodingError(let message):
            return "データの解析に失敗しました: \(message)"
        }
    }
}
