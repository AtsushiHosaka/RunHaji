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

1. `RunHaji/Info.plist.template`をコピーして`RunHaji/Info.plist`を作成
2. SupabaseのプロジェクトURLとAnon Keyを設定:
   ```xml
   <key>SUPABASE_URL</key>
   <string>あなたのSupabaseプロジェクトURL</string>
   <key>SUPABASE_ANON_KEY</key>
   <string>あなたのSupabase Anon Key</string>
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
│   └── Supabase/          # Supabase連携
├── Config/                # 設定ファイル
└── Resources/             # Assets等のリソース
```

## 開発

詳細な開発ルールとタスク一覧は以下を参照してください：
- `../CLAUDE.md`: 開発ルール、アーキテクチャ、Git運用方針
- `../tasks.md`: 実装タスク一覧

