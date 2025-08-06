# Dotfiles 改善提案

## 現在の問題点

### 1. 複数スクリプトの管理が煩雑
- `init.sh` と `sync.sh` の2つのスクリプトが必要
- 初回インストール後、手動でディレクトリ移動が必要
- ユーザーエクスペリエンスが分断されている

### 2. 設定ファイルの管理が非効率
- `symlinks.sh` にファイルパスがハードコードされている
- 新しいファイルの追加時に手動更新が必要
- 設定ファイルの自動検出機能がない

### 3. 同期が一方向のみ
- リポジトリ → ローカル の同期のみ
- ローカルの変更をリポジトリに反映する機能がない
- 設定の更新ワークフローが不明確

### 4. バックアップシステムの問題
- バックアップファイルが同じディレクトリに散在
- 復元機能がない
- バックアップの管理が困難

### 5. エラーハンドリングと状態管理の不足
- 部分的な失敗時の対処が不明確
- インストール状態の追跡がない
- ドライランモードがない

## 提案する改善システム

### 1. 統一されたCLIツール: `dot`

```bash
# 初回インストール（ワンライナー）
curl -fsSL https://raw.githubusercontent.com/sotayamashita/dotfiles/main/install.sh | bash

# その後の操作
dot install    # 初期セットアップ
dot sync       # 双方向同期
dot update     # リポジトリから最新を取得
dot backup     # 現在の設定をバックアップ
dot restore    # バックアップから復元
dot status     # 現在の状態を確認
dot diff       # ローカルとリポジトリの差分確認
```

### 2. 設定ベースのファイル管理

`config/dotfiles.yaml` による宣言的な管理：

```yaml
dotfiles:
  - name: git
    files:
      - source: .gitconfig
        target: ~/.gitconfig
      - source: .gitconfig.alias
        target: ~/.gitconfig.alias
    platform: all
    
  - name: fish
    files:
      - source: .config/fish/
        target: ~/.config/fish/
        type: directory
    platform: macos
    
  - name: claude
    files:
      - source: .claude/
        target: ~/.claude/
        type: directory
    platform: all
    
brew:
  taps:
    - homebrew/cask-fonts
  formulas:
    - fish
    - starship
    - git-delta
  casks:
    - 1password-cli
    - visual-studio-code

hooks:
  pre_install:
    - scripts/pre-install.sh
  post_install:
    - scripts/post-install.sh
  pre_sync:
    - scripts/pre-sync.sh
```

### 3. インテリジェントな同期システム

```bash
#!/usr/bin/env bash
# dot - 統一されたdotfiles管理ツール

class DotfilesManager {
    # 双方向同期の実装
    sync() {
        # 1. 差分検出
        detect_changes
        
        # 2. コンフリクト解決
        resolve_conflicts
        
        # 3. 同期実行
        apply_changes
        
        # 4. ステータス更新
        update_status
    }
    
    # スマートバックアップ
    backup() {
        # タイムスタンプ付きバックアップ
        # ~/.dotfiles-backup/2024-12-20-123456/
        create_versioned_backup
    }
    
    # 差分表示
    diff() {
        # カラフルな差分表示
        show_diff --color --context
    }
}
```

### 4. プラグインアーキテクチャ

```bash
plugins/
├── macos/
│   ├── preferences.sh
│   └── dock.sh
├── linux/
│   └── gnome.sh
└── common/
    ├── git.sh
    └── vim.sh
```

### 5. 改善された機能

#### a. 自動検出システム
```bash
# 新しいdotfileを自動検出
dot discover
# => Found new dotfiles:
#    - ~/.config/nvim/init.vim
#    Add to repository? (y/n)
```

#### b. ドライランモード
```bash
# 実際の変更なしで実行内容を確認
dot sync --dry-run
```

#### c. 選択的同期
```bash
# 特定のカテゴリのみ同期
dot sync --only=git,fish
```

#### d. バージョン管理
```bash
# 設定のスナップショット作成
dot snapshot create "before-big-change"

# スナップショットから復元
dot snapshot restore "before-big-change"
```

## 実装計画

### Phase 1: 基盤構築（1週間）
- [ ] `dot` CLIツールの基本構造
- [ ] YAMLベースの設定システム
- [ ] 基本的なインストール・同期機能

### Phase 2: 高度な機能（1週間）
- [ ] 双方向同期
- [ ] コンフリクト解決
- [ ] バックアップ・復元システム

### Phase 3: ユーザビリティ向上（3日間）
- [ ] ドライランモード
- [ ] インタラクティブモード
- [ ] 進捗表示とログシステム

### Phase 4: テストとドキュメント（3日間）
- [ ] ユニットテスト
- [ ] インテグレーションテスト
- [ ] ドキュメント作成

## 技術的な改善点

### 1. エラーハンドリング
```bash
# トランザクション型の操作
begin_transaction
try {
    perform_operations
    commit_transaction
} catch {
    rollback_transaction
    report_error
}
```

### 2. 並列処理
```bash
# 複数のインストールタスクを並列実行
parallel_install() {
    local -a pids=()
    for installer in "${installers[@]}"; do
        run_installer "$installer" &
        pids+=($!)
    done
    wait "${pids[@]}"
}
```

### 3. ログシステム
```bash
# 構造化ログ
log --level=info --component=sync "Starting synchronization"
log --level=error --component=backup "Failed to create backup: $error"
```

## 移行パス

1. 新システムを`feature/improved-sync`ブランチで開発
2. 既存の設定ファイルを自動的に新形式に変換するマイグレーションツール
3. 段階的な移行：
   - Phase 1: 新CLIツールを追加（既存スクリプトと共存）
   - Phase 2: 既存スクリプトを新システムのラッパーに
   - Phase 3: 完全移行後、レガシーコードを削除

## まとめ

この提案により、以下の利点が得られます：

1. **シンプルで統一されたインターフェース**
2. **柔軟で拡張可能な設定管理**
3. **安全で信頼性の高い同期メカニズム**
4. **優れたエラーハンドリングとリカバリ機能**
5. **プラットフォーム間での一貫性**

これにより、dotfilesの管理が大幅に簡素化され、保守性と使いやすさが向上します。