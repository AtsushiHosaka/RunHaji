# RunHaji

ランニング初心者の「0→1」を支援する、パーソナライズド・ロードマップ・プラットフォーム

## セットアップ

### 1. 必要なパッケージのインストール

#### Supabase Swift SDK
1. Xcodeでプロジェクトを開く
2. File > Add Package Dependencies...
3. 以下のURLを入力: `https://github.com/supabase-community/supabase-swift`
4. "Up to Next Major Version"を選択し、バージョン`2.0.0`を指定
5. "Add Package"をクリック

### 2. Info.plistの設定

1. `RunHaji/Info.plist.template`をコピーして`RunHaji/Info.plist`を作成（存在しない場合は新規作成）
2. 以下のキーを設定:
   ```xml
   <key>SUPABASE_URL</key>
   <string>あなたのSupabaseプロジェクトURL</string>
   <key>SUPABASE_ANON_KEY</key>
   <string>あなたのSupabase Anon Key</string>
   <key>OPENAI_API_KEY</key>
   <string>あなたのOpenAI APIキー</string>
   ```
3. **重要**: `Info.plist`は`.gitignore`で除外されています。GitHubにpushしないでください。

### 3. HealthKitの権限設定

Info.plistには以下のHealthKit権限が含まれています：
- `NSHealthShareUsageDescription`: ランニング記録の取得
- `NSHealthUpdateUsageDescription`: ワークアウトデータの保存
- `NSLocationWhenInUseUsageDescription`: 位置情報の記録
- `NSMotionUsageDescription`: モーションデータの記録

### 4. ビルド

1. Xcodeでプロジェクトを開く
2. ターゲットデバイス/シミュレータを選択
3. ⌘R でビルド＆実行

## プロジェクト構成

```
RunHaji/
├── App/                    # アプリエントリーポイント
├── Models/                 # データモデル
├── ViewModels/             # ビューモデル
├── Views/                  # SwiftUI Views
│   ├── Onboarding/        # オンボーディング画面
│   ├── Home/              # ホーム画面
│   ├── Running/           # ランニング実行画面
│   └── Scoring/           # スコアリング画面
├── Services/              # 外部サービス連携
│   ├── HealthKit/         # HealthKit連携
│   ├── Supabase/          # Supabase連携
│   └── ChatGPT/           # ChatGPT/OpenAI連携
├── Config/                # 設定ファイル（API Keys等）
└── Resources/             # Assets等のリソース
```

## 主な機能

- **自動ワークアウト分析**: ChatGPT APIを使ってHealthKitデータを分析し、運動強度（RPE）を自動推定
  ※API呼び出しに失敗した場合は、距離ベースの簡易推定にフォールバックし、ワークアウトデータを確実に保存
- **AI振り返り**: ワークアウト終了後にAIが振り返りと次回へのアドバイスを生成
- **マイルストーン自動判定**: ワークアウトデータに基づいて、マイルストーンの達成状況を自動判定
- **パーソナライズドロードマップ**: ユーザーの目標に合わせたランニングプランを提供

## 開発

詳細な開発ルールとタスク一覧は以下を参照してください：
- `../CLAUDE.md`: 開発ルール、アーキテクチャ、Git運用方針
- `../tasks.md`: 実装タスク一覧

