# Dotfiles v2.0

モダンで効率的なdotfiles管理システム

## ✨ 特徴

- **🚀 ワンライナーインストール** - 1つのコマンドで環境構築が完了
- **🔄 双方向同期** - ローカルの変更も簡単にリポジトリに反映
- **📦 統一されたCLI** - `dot`コマンドですべての操作を実行
- **⚙️ 宣言的設定** - YAMLベースの設定ファイルで管理
- **💾 自動バックアップ** - タイムスタンプ付きバックアップで安全に管理
- **🔍 自動検出** - 新しいdotfilesを自動的に発見
- **🎯 選択的同期** - 特定のグループのみを同期可能
- **🏗️ プラットフォーム対応** - macOS/Linux対応

## 🚀 クイックスタート

### インストール

```bash
curl -fsSL https://raw.githubusercontent.com/sotayamashita/dotfiles/main/install.sh | bash
```

このコマンドは以下を自動的に実行します：
- 必要なツールのインストール（Xcode CLT、Homebrew等）
- dotfilesリポジトリのクローン
- `dot`コマンドのインストール

### 初期セットアップ

```bash
# dotfilesの初期インストール
dot install

# 状態を確認
dot status
```

## 📖 使い方

### 基本コマンド

```bash
# インストール/初期設定
dot install

# 双方向同期
dot sync

# リポジトリから最新を取得
dot update

# 現在の状態を確認
dot status

# 差分を表示
dot diff

# バックアップを作成
dot backup

# バックアップから復元
dot restore [backup-name]

# 新しいdotfilesを検出
dot discover

# ヘルプを表示
dot help
```

### 高度な使い方

#### ドライランモード

実際の変更を行わずに、何が実行されるかを確認：

```bash
dot sync --dry-run
```

#### 選択的同期

特定のグループのみを同期：

```bash
dot sync --only=git,fish
```

#### バックアップと復元

```bash
# バックアップを作成
dot backup

# 利用可能なバックアップを確認
dot restore

# 特定のバックアップから復元
dot restore 20240101-120000
```

## ⚙️ 設定

設定ファイル `config/dotfiles.yaml` で管理：

```yaml
dotfiles:
  - name: git
    files:
      - source: .gitconfig
        target: ~/.gitconfig
    platform: all
    
  - name: fish
    files:
      - source: .config/fish/
        target: ~/.config/fish/
        type: directory
    platform: all

brew:
  formulas:
    - fish
    - starship
  casks:
    - visual-studio-code

hooks:
  pre_install:
    - scripts/pre-install.sh
  post_install:
    - scripts/post-install.sh
```

### 設定オプション

- **dotfiles**: 管理するファイルのグループ
  - `name`: グループ名
  - `files`: ファイルのリスト
    - `source`: リポジトリ内のパス
    - `target`: ローカルのターゲットパス
    - `type`: `file`（デフォルト）または `directory`
  - `platform`: `all`、`macos`、または `linux`

- **brew**: Homebrewパッケージ（macOSのみ）
  - `taps`: Homebrewタップ
  - `formulas`: Homebrewフォーミュラ
  - `casks`: Homebrewキャスク

- **hooks**: カスタムスクリプト
  - `pre_install`: インストール前に実行
  - `post_install`: インストール後に実行
  - `pre_sync`: 同期前に実行
  - `post_sync`: 同期後に実行

## 📁 ディレクトリ構造

```
dotfiles/
├── dot                    # メインCLIツール
├── install.sh            # ワンライナーインストールスクリプト
├── config/
│   └── dotfiles.yaml     # 設定ファイル
├── scripts/
│   ├── installers/       # 各種インストーラー
│   ├── hooks/           # フックスクリプト
│   └── lib/             # ユーティリティ関数
├── .config/             # アプリケーション設定
│   ├── fish/
│   ├── starship.toml
│   └── ...
├── .claude/             # Claude設定
└── docs/               # ドキュメント
```

## 🔄 アップグレード

旧バージョンからのアップグレード：

```bash
# リポジトリを更新
cd ~/Projects/dotfiles
git pull

# 新しいシステムをインストール
./install.sh

# 設定を移行
dot install
```

## 🐛 トラブルシューティング

### PATHに`dot`コマンドが見つからない

```bash
# PATHに追加
export PATH="${HOME}/.local/bin:${PATH}"

# シェル設定ファイルに永続化
echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> ~/.bashrc
```

### SSHアクセスができない

1Password SSH Agentを使用している場合：

```bash
# 1Password CLIをインストール
brew install --cask 1password/tap/1password-cli

# SSH設定を確認
cat ~/.ssh/config
```

### 同期時のコンフリクト

```bash
# 差分を確認
dot diff

# バックアップを作成してから同期
dot backup
dot sync
```

## 📝 ライセンス

MIT License

## 🤝 コントリビューション

Issue報告やPull Requestは歓迎です！

[GitHub Issues](https://github.com/sotayamashita/dotfiles/issues)