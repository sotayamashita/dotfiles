---
name: obsidian-wiki-lint
description: >
  Run health checks on the Obsidian wiki (45-wiki/) to find broken links, missing INDEX entries,
  uncovered raw clippings, frontmatter issues, and Diátaxis type violations. Use this skill whenever
  the user asks to "check the wiki", "wiki health check", "wiki の健全性チェック", "wiki をチェック",
  "wiki lint", or when a cron job triggers periodic maintenance. Also use when the user suspects
  something is wrong with the wiki structure, or after a large batch of wiki compilation.
---

# Wiki Health Check

Inspect the wiki for structural problems and improvement opportunities. This skill reads files but never modifies them — it produces a diagnostic report that the user reviews. Fixes are done manually or by running `obsidian-wiki-compile`.

## Vault Layout

```
40-raw/    ← Source clippings
45-wiki/   ← Wiki articles (what this skill inspects)
50-notes/  ← User's notes (checked for link targets only)
```

## Health Check Workflow

Run all 6 checks, then output a single report.

### Check 1: INDEX.md の同期

Compare `45-wiki/INDEX.md` entries against actual files in `45-wiki/`.

Find:
- Files in 45-wiki/ that are not listed in INDEX.md (excluding INDEX.md itself and temporary files like パターン比較.md)
- Entries in INDEX.md whose target files don't exist

Why this matters: INDEX.md is the LLM's entry point to the wiki. If it's out of sync, the LLM can't find articles or will try to read files that don't exist.

### Check 2: 壊れたリンク

Scan all `[[wikilinks]]` in wiki articles. For each link, check if a matching file exists in 45-wiki/, 40-raw/, or 50-notes/.

Report links where no matching file is found. Distinguish between:
- **Intentional unresolved links** — concepts that don't have articles yet (these are fine, just note them)
- **Likely broken links** — misspelled names, files that were moved or deleted

Why this matters: broken links create dead ends. Unresolved links are expected (future article candidates), but misspellings waste the reader's time.

### Check 3: Micro 記事の候補

Find unresolved `[[wikilinks]]` that appear in 2+ wiki articles. These are strong candidates for new Micro articles because multiple articles reference them.

Rank by frequency (most referenced first).

Why this matters: frequently referenced concepts without their own article create repeated context gaps. A Micro article would serve all referencing articles at once.

### Check 4: フロントマターの検証

Check every `.md` file in 45-wiki/ (except INDEX.md) for:
- `author: llm` is present
- `wiki-type:` is present and is one of: `explanation`, `how-to`, `reference`, `tutorial`, `micro`
- `created:` and `updated:` dates are present

Why this matters: frontmatter drives search, filtering, and automation. Missing or wrong values break downstream tools.

### Check 5: 未反映の raw

Find files in 40-raw/ that are not linked from any wiki article (i.e., no `[[clipping title]]` points to them from 45-wiki/).

Group by potential theme if possible (look at the clipping's title and tags).

Why this matters: uncovered clippings represent knowledge that hasn't been integrated into the wiki yet. They're candidates for the next compilation run.

### Check 6: Diátaxis の型混在

For Explanation articles (`wiki-type: explanation`):
- Look for numbered step-by-step instructions (signs of How-to content leaking in)

For How-to articles (`wiki-type: how-to`):
- Look for theoretical discussion, debate, or "why" sections (signs of Explanation content leaking in)

For Reference articles (`wiki-type: reference`):
- Look for persuasive language or opinion (signs of Explanation leaking in)

Why this matters: mixing types defeats the purpose of Diátaxis. Readers expect a How-to to be actionable, not theoretical. The fix is usually to extract the misplaced content into its own article and link to it.

## Report Format

Output the report as markdown. Use Japanese. Follow the writing rules in the compile skill's [japanese-writing.md](../obsidian-wiki-compile/references/japanese-writing.md).

```markdown
# Wiki Health Check Report

実行日: {date}

## 1. INDEX.md の同期

### INDEX に未登録のファイル
- [ ] `{filename}`

### INDEX にあるが存在しないファイル
- [ ] `{filename}`

## 2. 壊れたリンク

- [ ] `{source file}` → `[[{broken link}]]`

## 3. Micro 記事の候補

| 概念 | 参照元の数 | 参照元 |
| --- | --- | --- |
| [[{concept}]] | {count} | {file1}, {file2}, ... |

## 4. フロントマターの不備

- [ ] `{filename}`
  - {何が欠けているか}

## 5. 未反映の raw

{count} 件の clipping が wiki からリンクされていない

- [ ] `{clipping title}`

## 6. Diátaxis の型混在

- [ ] `{filename}` ({wiki-type})
  - {何が混在しているか}

## サマリー

| チェック | 件数 |
| --- | --- |
| INDEX 未登録 | {n} |
| 壊れたリンク | {n} |
| Micro 候補 | {n} |
| フロントマター不備 | {n} |
| 未反映 raw | {n} |
| 型混在 | {n} |
```

Use `- [ ]` checkboxes so the user can track what they've addressed.

## What NOT to do

- Do not modify any files — this is a read-only diagnostic skill
- Do not fix problems automatically — report them and let the user decide
- Do not report experimental/temporary files (like pattern comparison files in 45-wiki/) as problems
