---
title: LangGraph 開発ガイド
author: Claude Code
sources:
  - repository: https://github.com/langchain-ai/langgraphjs
  - tool: DeepWiki MCP
references:
  - https://deepwiki.com/search/how-to-pass-initial-state-and_436a1cba-cdba-41a5-8c42-e3b23119e3a8
  - https://deepwiki.com/search/show-examples-of-stategraph-wi_ae6d0f93-0a5a-4e7c-9d66-8b7412d3e572
  - https://deepwiki.com/search/what-is-the-official-terminolo_ecadd7a8-c21a-47a6-94d3-2923d1c81ac9
  - https://deepwiki.com/search/what-is-the-official-terminolo_fbf8ff94-e649-40e9-98bc-4ced98156f1d
  - https://deepwiki.com/search/show-examples-of-how-configsch_9fc6231c-7662-4ab9-9c17-418a6aca8115
  - https://deepwiki.com/search/in-langgraph-where-should-init_0e2bc88c-ef3f-4d51-990b-a65bbcb1f2d2
  - https://deepwiki.com/search/for-custom-stategraph-implemen_84815de1-a190-443b-ba1a-bc1c31df7795
---

# LangGraph 開発ガイド

## State (Input) と configSchema の使い分け

LangGraph では、データの性質と用途に応じて **State (Input)** と **configSchema** を使い分けることが重要です。

### State（状態） / Input（入力）

**特徴：**

- ワークフロー実行中に変更される可能性がある動的なデータ
- ワークフロー内のノード間で共有される状態
- Reducer によって更新・集約される

**使用する場合：**

```typescript
// 状態定義
const WorkflowAnnotation = Annotation.Root({
  ...MessagesAnnotation.spec,
  currentUrl: Annotation<string>({
    reducer: (prev, next) => next || prev,
    default: () => "",
  }),
  collectedData: Annotation<Record<string, any>>({
    reducer: (prev, next) => ({ ...prev, ...next }),
    default: () => ({}),
  }),
});

// 実行時
await graph.stream({
  messages: [{ role: "user", content: "タスクを開始" }],
  currentUrl: "https://example.com",
  collectedData: {},
});
```

**適している用途：**

- 実行中に変化するデータ（現在の URL、収集したデータ、処理ステータス）
- ノード間で共有・更新される情報
- ワークフローの進行状況を表すデータ

※ LangGraphJS では、グラフの状態を `State` と呼び、実行開始時に提供する初期値を `input` と呼びます。
また、必要に応じて `input` と `output` を別スキーマとして定義することもできます。

### configSchema（設定スキーマ）

**特徴：**

- ワークフロー実行中にノード側から変更しない想定のデータ（各実行呼び出しごとに差し替えることは可能）
- 実行環境や動作設定を定義
- `config.configurable` 経由でアクセス

**使用する場合：**

```typescript
// 設定スキーマ定義
const myConfigSchema = Annotation.Root({
  runnable: Annotation<Runnable>,
  apiKey: Annotation<string>,
  maxRetries: Annotation<number>({ default: () => 3 }),
  timeout: Annotation<number>({ default: () => 30000 }),
});
```

**補足:** LangGraphJS の `configSchema` は型付けやエディタ補完のためのメタデータであり、`config.configurable` に渡したオブジェクトから未定義キーを自動で除外したり、実行時バリデーションを行うわけではありません。必要に応じて独自の検証ロジックを入れてください。

```typescript
// StateGraph の第2引数として configSchema を指定
const graph = new StateGraph(
  StateAnnotation, // 第1引数: State スキーマ
  myConfigSchema // 第2引数: configSchema
);

// 実行時
await graph.stream(
  { messages: initialMessages },
  {
    configurable: {
      runnable: chatModel,
      apiKey: process.env.API_KEY,
      maxRetries: 5,
      timeout: 60000,
    },
  }
);
```

**適している用途：**

- API キーや認証情報
- モデル設定（使用する LLM、温度パラメータなど）
- リトライ回数、タイムアウト値などの動作設定
- 実行環境固有の設定

### 実践的な使い分けガイドライン

#### 1. データの変更可能性で判断

| データタイプ | State (Input) | configSchema |
| ------------ | ------------- | ------------ |
| ユーザー入力 | ✓             |              |
| 処理結果     | ✓             |              |
| 実行状況     | ✓             |              |
| API キー     |               | ✓            |
| モデル設定   |               | ✓            |
| 環境設定     |               | ✓            |

#### 2. アクセスパターンで判断

**State (Input) を選ぶ場合：**

- 複数のノードで参照・更新する
- 実行の進行に応じて値が変化する
- 最終的な出力に含まれるデータ

**configSchema を選ぶ場合：**

- 実行開始時に一度設定すれば変わらない
- 外部サービスの接続情報
- ワークフローの動作を制御するパラメータ

### まとめ

- **State (Input)**: ワークフローの「今」を表す動的データ（LangGraphJS では State がグラフ全体の状態、input が初期値を指す）
- **configSchema**: ワークフローの「どのように」を定義する静的設定（StateGraph の第 2 引数として指定）
- `configSchema` は主に型情報付与用。ランタイムで不要キーを除外したり厳密に検証はしないので必要なら自前でチェックする
- `config.configurable` は実行ごとに差し替え可能だが、実行中にノードから書き換える前提ではない

この使い分けにより、関心の分離が明確になり、保守性の高い LangGraph アプリケーションを構築できます。

## 初期データの定義場所

カスタム StateGraph 実装において、システムプロンプトや初期設定をどこで定義するかは重要な設計判断です。

### 基本原則

**初期データは graph.stream() / graph.invoke() で定義する**

理由：

1. **関心の分離** - ワークフロー定義と実行時パラメータを分離
2. **再利用性** - 同じワークフローを異なるパラメータで実行可能
3. **LangGraph のベストプラクティス** - 初期状態は実行時に提供

### 実装パターン

#### 1. システムプロンプトとユーザー指示

```typescript
// ワークフロー定義（workflow.ts）
const AgentAnnotation = Annotation.Root({
  messages: MessagesAnnotation,
  targetUrl: Annotation<string>(),
  taskName: Annotation<string>(),
});

// ノード関数はシンプルに保つ
async function processNode(
  state: typeof AgentAnnotation.State,
  config: RunnableConfig
) {
  // state.messages には既にシステムプロンプトが含まれている
  const response = await llm.invoke(state.messages);
  return { messages: [response] };
}

// 実行時（agent.ts）
await graph.stream({
  messages: [
    { role: "system", content: systemPrompt },
    { role: "user", content: userInstruction },
  ],
  targetUrl: "https://example.com",
  taskName: "E2Eテスト生成",
});
```

#### 2. 設定値の扱い方

```typescript
// 環境設定は configurable で渡す
await graph.stream(
  { messages: initialMessages },
  {
    configurable: {
      apiKey: process.env.API_KEY,
      maxRetries: 3,
      timeout: 30000,
    },
  }
);

// ノードから設定値にアクセス
function nodeWithConfig(state: State, config?: RunnableConfig) {
  const apiKey = config?.configurable?.apiKey;
  // 設定値を使用した処理
}
```

### アンチパターン

#### ❌ ノード関数内でのプロンプト定義

```typescript
// 避けるべきパターン
async function processNode(state: State) {
  // ノード内でシステムプロンプトを定義
  const messages = [
    { role: "system", content: "You are a helpful assistant" },
    ...state.messages,
  ];
  // これは柔軟性を損なう
}
```

#### ❌ ワークフロー定義に固有値をハードコード

```typescript
// 避けるべきパターン
const workflow = new StateGraph(annotation).addNode(
  "process",
  async (state) => {
    // 特定のURLをハードコード
    const url = "https://specific-site.com";
    // 再利用性が低下
  }
);
```

### 判断基準

| データの種類       | 定義場所                    | 理由                             |
| ------------------ | --------------------------- | -------------------------------- |
| システムプロンプト | graph.stream() の初期 State | 実行ごとに変更可能にするため     |
| ユーザー入力       | graph.stream() の初期 State | 動的なデータのため               |
| 開始 URL           | graph.stream() の初期 State | シナリオごとに異なるため         |
| API キー           | config.configurable         | 環境設定のため                   |
| モデル設定         | config.configurable         | 実行環境の設定のため             |
| 共通処理ロジック   | ノード関数内                | ワークフローの本質的な部分のため |

### まとめ

- **ワークフロー定義（workflow.ts）**: 汎用的な処理フローを定義
- **実行時（agent.ts）**: 具体的なパラメータと初期データを提供
- この分離により、テスタビリティと保守性が向上します
