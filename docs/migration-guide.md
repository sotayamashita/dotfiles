# 移行ガイド: Dotfiles v1.0 → v2.0

このガイドでは、既存のdotfilesシステムから新しい統一システムへの移行方法を説明します。

## 📋 移行前のチェックリスト

- [ ] 現在の設定をバックアップ
- [ ] Gitの変更をコミット
- [ ] 重要な設定ファイルの確認

## 🔄 移行手順

### ステップ 1: 現在の状態を保存

```bash
# 現在のブランチで変更を保存
git add .
git commit -m "chore: save current state before migration to v2"

# 安全のためにタグを作成
git tag -a v1-final -m "Last version before v2 migration"
```

### ステップ 2: 新しいブランチに切り替え

```bash
# feature/improve-dotfiles-sync ブランチを使用
git checkout feature/improve-dotfiles-sync
```

### ステップ 3: 新システムのインストール

```bash
# 新しいインストールスクリプトを実行
./install.sh

# dotコマンドが使えることを確認
dot help
```

### ステップ 4: 設定の確認と調整

新しい設定ファイル `config/dotfiles.yaml` が自動的に作成されます。必要に応じて調整してください：

```bash
# 設定ファイルを編集
vim config/dotfiles.yaml

# 現在の状態を確認
dot status

# ドライランで変更内容を確認
dot sync --dry-run
```

### ステップ 5: 初回同期

```bash
# バックアップを作成
dot backup

# 同期を実行
dot sync
```

## 🔀 主な変更点

### コマンドの対応表

| 旧コマンド | 新コマンド | 説明 |
|---------|---------|-----|
| `./init.sh` | `curl ... \| bash` → `dot install` | 初期インストール |
| `./sync.sh` | `dot sync` | 設定の同期 |
| `git pull && ./sync.sh` | `dot update` | リポジトリ更新と同期 |
| 手動バックアップ | `dot backup` | 自動バックアップ |
| なし | `dot restore` | バックアップから復元 |
| なし | `dot diff` | 差分表示 |
| なし | `dot discover` | 新しいdotfilesの検出 |

### ファイル構造の変更

**旧構造:**
```
dotfiles/
├── init.sh           # 初期化スクリプト
├── sync.sh           # 同期スクリプト
└── scripts/
    └── modules/
        └── core/
            └── symlinks.sh  # ハードコードされたファイルリスト
```

**新構造:**
```
dotfiles/
├── dot               # 統一CLIツール
├── install.sh        # ワンライナーインストール
├── config/
│   └── dotfiles.yaml # 宣言的設定ファイル
└── scripts/          # 既存のスクリプト（互換性のため保持）
```

### 設定管理の変更

**旧方式（symlinks.sh内でハードコード）:**
```bash
SYMLINK_TARGETS=(
    ".gitconfig"
    ".config/fish/config.fish"
    # ...
)
```

**新方式（config/dotfiles.yaml）:**
```yaml
dotfiles:
  - name: git
    files:
      - source: .gitconfig
        target: ~/.gitconfig
  - name: fish
    files:
      - source: .config/fish/config.fish
        target: ~/.config/fish/config.fish
```

## 🚨 トラブルシューティング

### Q: 旧システムと新システムが競合する

A: 新システムは旧システムと共存可能ですが、混乱を避けるため、完全に移行することを推奨します：

```bash
# 旧システムのシンボリックリンクを確認
ls -la ~ | grep "^l"

# 新システムで管理されているか確認
dot status
```

### Q: 設定が正しく同期されない

A: 設定ファイルのパスを確認してください：

```bash
# 設定ファイルの検証
cat config/dotfiles.yaml

# 差分を確認
dot diff

# 詳細なログを有効化
DEBUG=1 dot sync
```

### Q: バックアップから復元したい

A: 新システムのバックアップ機能を使用：

```bash
# 利用可能なバックアップを確認
ls -la ~/.dotfiles-backup/

# 特定のバックアップから復元
dot restore [バックアップ名]
```

## 📊 比較表

| 機能 | 旧システム | 新システム |
|-----|----------|----------|
| インストール方法 | 2段階（init.sh → sync.sh） | ワンライナー |
| コマンド体系 | 複数のスクリプト | 統一された`dot`コマンド |
| 設定管理 | ハードコード | YAML設定ファイル |
| 同期方向 | 単方向（repo→local） | 双方向 |
| バックアップ | 手動 | 自動・バージョン管理 |
| 差分確認 | なし | `dot diff` |
| ドライラン | なし | `dot sync --dry-run` |
| 新ファイル検出 | なし | `dot discover` |
| 選択的同期 | なし | `dot sync --only=...` |
| エラーハンドリング | 基本的 | 包括的 |

## ✅ 移行完了チェックリスト

- [ ] `dot`コマンドが動作する
- [ ] `dot status`で正しい情報が表示される
- [ ] `dot sync --dry-run`でエラーが出ない
- [ ] 重要な設定ファイルがすべて管理されている
- [ ] バックアップが作成されている
- [ ] ドキュメントを読んで新機能を理解した

## 🎉 移行完了

移行が完了したら、mainブランチにマージすることを検討してください：

```bash
# テストが完了したら
git checkout main
git merge feature/improve-dotfiles-sync
git push origin main

# 成功タグを作成
git tag -a v2.0.0 -m "Dotfiles v2.0 - Unified management system"
git push origin v2.0.0
```

## 📚 参考資料

- [新システムのREADME](../README-new.md)
- [改善提案書](./improvement-proposal.md)
- [dot コマンドヘルプ](../dot) (`dot help`)

## 💬 サポート

問題が発生した場合は、以下の方法でサポートを受けられます：

1. GitHubのIssueを作成
2. 旧システムへのロールバック（`git checkout v1-final`）
3. ドキュメントの確認（`dot help`）

---

この移行により、dotfilesの管理がより簡単で、安全で、効率的になります。新しい機能を活用して、快適な開発環境を構築してください！