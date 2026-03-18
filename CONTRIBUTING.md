# Contributing Guide

## ブランチ運用

```
main          # 本番ブランチ（直接pushは禁止）
feature/xxx   # 機能追加
fix/xxx       # バグ修正
```

## 開発フロー

1. `main` から作業ブランチを作成する
   ```bash
   git checkout -b feature/xxx
   ```

2. 変更をコミットする
   ```bash
   git add <files>
   git commit -m "feat: 変更内容"
   ```

3. GitHub にpushしてPRを作成する
   ```bash
   git push origin feature/xxx
   ```

4. PRレビューを受けて `main` にマージする

## コミットメッセージ規約

| プレフィックス | 用途 |
|---------------|------|
| `feat:`  | 機能追加 |
| `fix:`   | バグ修正 |
| `docs:`  | ドキュメント変更 |
| `refactor:` | リファクタリング |
| `chore:` | 設定・環境変更 |

## 注意事項

- `.env` は **絶対にコミットしない**（認証情報・IPアドレスを含むため）
- `recordings/`、`logs/`、`venv/` もコミット対象外
- `main` へのforce pushは禁止
