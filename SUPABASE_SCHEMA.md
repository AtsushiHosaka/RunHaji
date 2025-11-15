# Supabase Schema for Product/Gear Management

このドキュメントでは、ギア推奨機能に必要なSupabaseのテーブルスキーマを説明します。

## テーブル構成

### 1. `products` テーブル (マスターデータ)

全ての商品情報を管理するマスターテーブル。

```sql
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    price INTEGER NOT NULL,
    image_url TEXT,
    purchase_url TEXT NOT NULL,
    recommended_for TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('shoes', 'apparel', 'accessories', 'supplements', 'gadgets')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックス
CREATE INDEX idx_products_category ON products(category);

-- RLS (Row Level Security) を有効化
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- 全ユーザーが読み取り可能
CREATE POLICY "Products are viewable by everyone"
    ON products FOR SELECT
    USING (true);
```

### 2. `user_products` テーブル (ユーザー固有データ)

各ユーザーのロードマップに紐づいた商品と購入状態を管理。

```sql
CREATE TABLE user_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    roadmap_id UUID NOT NULL REFERENCES roadmaps(id) ON DELETE CASCADE,
    is_purchased BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックス
CREATE INDEX idx_user_products_user_id ON user_products(user_id);
CREATE INDEX idx_user_products_roadmap_id ON user_products(roadmap_id);
CREATE INDEX idx_user_products_product_id ON user_products(product_id);
CREATE INDEX idx_user_products_is_purchased ON user_products(is_purchased);

-- 複合ユニーク制約
CREATE UNIQUE INDEX idx_user_products_unique
    ON user_products(user_id, product_id, roadmap_id);

-- RLS を有効化
ALTER TABLE user_products ENABLE ROW LEVEL SECURITY;
```

## サンプルデータ挿入

```sql
INSERT INTO products (title, price, purchase_url, recommended_for, category) VALUES
    ('エントリーランニングシューズ', 5980, 'https://www.workman.co.jp', 'これからランニングを始める方、クッション性と安定性を重視したい方', 'shoes'),
    ('速乾Tシャツ', 1980, 'https://www.uniqlo.com', 'オールシーズン使える定番アイテム', 'apparel'),
    ('ランニングキャップ', 1280, 'https://www.decathlon.co.jp', '日中のランニング、日差し対策が必要な方', 'accessories');
```
