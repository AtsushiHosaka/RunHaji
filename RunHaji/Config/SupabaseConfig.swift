//
//  SupabaseConfig.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/13.
//

import Foundation

struct SupabaseConfig {
    static let url: String? = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !url.isEmpty,
              url != "YOUR_SUPABASE_PROJECT_URL",
              URL(string: url) != nil else {
            return nil
        }
        return url
    }()

    static let anonKey: String? = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty,
              key != "YOUR_SUPABASE_ANON_KEY" else {
            return nil
        }
        return key
    }()
}
