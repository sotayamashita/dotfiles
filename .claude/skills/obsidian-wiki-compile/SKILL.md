---
name: obsidian-wiki-compile
description: >
  Compile raw clippings (40-raw/) into a structured wiki (45-wiki/) following the
  Diátaxis + Britannica Micro hybrid pattern. Use this skill whenever the user asks to
  "compile wiki", "update wiki", "wiki をコンパイル", "wiki を更新", "raw を wiki に反映",
  or when a cron job triggers wiki compilation. Also use when the user adds new clippings
  and wants them integrated into the wiki, or asks about the wiki compilation process.
---

# Wiki Compile

Compile raw clippings into a structured, interlinked wiki. The wiki serves as a knowledge base that the user references when writing their own notes in 50-notes/.

## Vault Layout

```
40-raw/    ← Source clippings (Obsidian Web Clipper output, articles, tweets, papers)
45-wiki/   ← Wiki output (this skill writes here)
50-notes/  ← User's own thinking (read-only for this skill, link to when relevant)
```

## Compilation Workflow

### Step 1: Read the current wiki state

Read `45-wiki/INDEX.md`. If it doesn't exist, this is a fresh compilation — create it at the end.

### Step 2: Scan raw clippings

Read all `.md` files in `40-raw/`. For each clipping, extract:
- Title and author (from frontmatter)
- Main claims and concepts
- Key terms that might need Micro articles

### Step 3: Cluster clippings by theme

Group related clippings. Look for:
- Clippings that discuss the same concept from different angles
- Clippings that support, contradict, or extend each other
- New concepts not yet covered in the wiki

### Step 4: Decide what to create or update

For each theme cluster, determine which article types are needed. Not every theme needs all types — create only what the content supports:

- **Explanation** — when 3+ clippings discuss *why* something matters, its background, or debate around it
- **How-to** — when clippings contain actionable procedures or step-by-step guidance
- **Reference** — when clippings contain structured data, metrics, comparisons, or specifications
- **Tutorial** — when content supports a progressive learning path (rare, only when there's clear beginner-to-intermediate material)
- **Micro** — when a specific term or concept appears across multiple clippings and needs a short definition

### Step 5: Write or update articles

Follow the rules in [references/article-rules.md](references/article-rules.md) for each article type. Key principles:

- **Write in Japanese** — 日本語の書き方は [references/japanese-writing.md](references/japanese-writing.md) を参照
- **Never mix Diátaxis types** — if an Explanation wants to include steps, link to a How-to instead
- **Link profusely** — first mention of any concept gets `[[internal links]]`. Keep unresolved links for concepts that don't have articles yet
- **Cite sources** — link to the raw clipping when quoting or paraphrasing: `[[clipping title]]`
- **Link to 50-notes/** — when a wiki topic relates to an existing user note, link to it

### Step 6: Update INDEX.md

After writing all articles, regenerate `45-wiki/INDEX.md` with every article and a one-line summary. Group by type:

```markdown
# 45-wiki Index

## Explanation
- [[Explanation - Topic]]
  - one-line summary

## How-to
- [[How-to - Topic]]
  - one-line summary

## Reference
- [[Reference - Topic]]
  - one-line summary

## Tutorial
- [[Tutorial - Topic]]
  - one-line summary

## Micro
- [[Concept Name]]
  - one-line definition
```

## What NOT to do

- Do not write content in 50-notes/ — that is the user's space for their own thinking
- Do not delete or modify files in 40-raw/
- Do not create subdirectories in 45-wiki/ — keep everything flat
- Do not create articles with insufficient source material — better to leave a `[[concept]]` as an unresolved link than to write a thin article
- Do not duplicate content across article types — each fact lives in one place, other articles link to it
