---
name: obsidian-summary
description: Use this skill for ANY request to understand, summarize, or preview what a clipping or article says. This skill MUST be used whenever someone asks about the content of files in 35-clippings/ — do not summarize clippings manually. It produces a specific 280-char structured summary format. Triggers: summarize, what does it say, what's it about, is it worth reading, explain the argument, 要約, 概要, 何が書いてあるか, 中身を把握, 論理展開, 読みづらそう, ざっと知りたい. Covers any phrasing that asks "what does this content contain?" for clippings. Handles single and batch requests. Do NOT use for editing, tagging, property management, creating notes from clippings, or summarizing files outside 35-clippings/.
---

# Obsidian Clipping Summary

Generate a concise summary (280 characters max) of a clipping file to help the user decide whether it's worth reading.

## Purpose

The summary exists for one purpose: to let the user quickly judge whether the full article is relevant to them. The user will assess relevance to their existing knowledge themselves — the summary only needs to convey what the article says and how it argues its point.

## Format

The summary has three components in this order:

1. **Theme (one phrase)**: What the article is about, in the fewest words possible
2. **Claim or content**: The article's main argument or thesis. For reference/documentation that has no argument, describe what the content covers instead
3. **Structure**: The logical steps or progression of the article, connected with "→" arrows

## Writing style: plain and readable

LLM-generated summaries tend to be hard to read for reasons that have nothing to do with the topic's difficulty. The following rules address specific, research-backed causes of unnecessary cognitive load. Technical terms from the source material are fine — the problem is when the *surrounding language* is needlessly dense.

### Use verbs, not nominalizations

Nominalization (turning verbs into nouns) strips out who does what and when, forcing the reader to reconstruct the action. Write "精度が落ちる" instead of "精度低下". Write "文脈を失う" instead of "文脈喪失". If a phrase can be a short sentence with a subject and verb, write it that way.

- Bad: 「知識の蓄積と探索の効率化」
- Good: 「知識を溜めて探しやすくする」

### Keep lexical density moderate

When almost every word is a content word (noun, verb, adjective), the reader has no breathing room. Add particles, conjunctions, and short bridging phrases so the reader can parse the structure. A summary should read like compressed *speech*, not like a telegram.

- Bad: 「評価基準具体化・分離評価検証」
- Good: 「評価基準を具体化し、作る側と評価する側を分けて検証」

### Be concrete, not abstract

Replace vague labels with what actually happens. "本番品質の" tells the reader nothing. "顧客に出せる" tells them what it means. If a term from the article is specific enough to picture, keep it. If it is an abstraction the article itself explains, unpack it briefly.

- Bad: 「本番品質のLLMエージェント設計原則」
- Good: 「顧客に出せるLLMエージェントの作り方」

### Choose 和語 over 漢語

LLMs tend to pick Sino-Japanese compounds (漢語) where native Japanese words (和語) would be more natural. This happens because models internally process through English-like representations and map English concepts to their 漢語 equivalents ("privilege" → 「特権」, "follow" → 「従う」, "develop" → 「展開」). The result sounds like translationese (翻訳調).

The fix: when the surrounding language is explanatory (not a technical term from the source), prefer 和語 — words you would actually say out loud.

| 漢語 (avoid) | 和語 (prefer) | Why |
|---|---|---|
| 特権 | ありがたいもの、助かるもの | 「特権」は権力・身分の語感が重すぎる |
| 展開する | 説明する、述べる、見ていく | 「展開」は曖昧で何も伝えない |
| 従える | 守れる、こなせる | 「従える」は文語的で硬い |
| 効率化 | 楽にする、速くする | 何がどう良くなるか不明 |
| 蓄積 | 溜める、増やす | 動作が見えない |
| 進捗する | はかどる、進む | 日常語で十分 |
| 達成 | できる、うまくいく | 大げさ |

This does NOT apply to technical terms from the article itself (e.g., "ステートレスreducer", "IFScale"). Those are the article's vocabulary and should be kept as-is. The rule applies to the *glue language* around them.

### Write in a natural register

The summary should sound like one knowledgeable person explaining an article to another — not like a paper abstract. Use casual written Japanese (だ/である調 is fine, but avoid stiff academic phrasing). Short sentences are better than long noun chains.

## Constraints

- 280 characters maximum (Japanese)
- Write in Japanese
- No line breaks — the summary is a single continuous block of text
- Use "→" to show logical progression in the structure portion
- Do not include value judgments about whether the user should read it
- Do not assess relevance to the user's existing knowledge — that is the user's job

## Examples

**Tweet with argument + procedure (Karpathy):**

> LLMで個人用の知識Wikiを自動で作る話。ソースをraw/に集め→LLMが.mdにまとめてリンクや分類をつける→Obsidianで見る→溜まったWikiに質問する→Lintで整合性を保つ→調べた結果もWikiに戻す、という循環で知識が勝手に育つ仕組みを提案している。

**Technical article (Anthropic):**

> LLMに長時間コードを書かせるときのハーネス設計。作る側と評価する側を分けるGAN的な構造で、1エージェントの限界を超えられるという話。単純にやると文脈を見失い自己評価も甘い→まずデザイン領域で評価基準を決めて分離を試す→フルスタックに拡張（planner+generator+evaluator）→モデルが賢くなるたびハーネスを削る→評価者が要るかはタスクの難しさ次第。

**Essay (Paul Graham):**

> 好きなことを仕事にすべきか。偉大な仕事をしたいなら答えはイエスだが、そうでなければ場合による。好きと稼ぐの対立を整理→変わった趣味が高収入になるケース→大きな富は好きなことから生まれやすい（midwit peak）→迷うのは自分を知らないから→不確実なら「試す」か「選択肢が広い方を選ぶ」。

**Reference/documentation (Claude Code):**

> Claude Codeにスキルを追加する方法のリファレンス。SKILL.mdを書くとClaudeが新しい能力を使えるようになる。基本の構造（フロントマター+本文）→置き場所でスコープが変わる→誰が呼ぶか制御できる（手動/自動）→動的にデータを注入したりサブエージェントで動かす高度な使い方→スクリプトで図やHTMLも出せる。

## Adapting to content type

- **Articles with a thesis**: Use "主張" or "〜という提案" to state the claim
- **Essays/opinion**: Frame as the question posed and the author's answer
- **Papers**: State the contribution or proposed method
- **Reference/docs**: Use "内容" or describe what it covers; replace "展開" with "構成"
- **Short content (tweets, abstracts)**: The entire content may be visible — still summarize the logical structure

## Output

Write the summary into the `## 要約 (独自生成)` section of the clipping file. If this section doesn't exist, create it immediately after the frontmatter.
