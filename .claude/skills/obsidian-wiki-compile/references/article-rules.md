# Article Rules

Detailed rules for each wiki article type. The SKILL.md references this file — read it when writing or updating articles.

## Frontmatter (all types)

```yaml
---
author: llm
created: {YYYY-MM-DD}
updated: {YYYY-MM-DDThh:mm}
wiki-type: explanation | how-to | reference | tutorial | micro
---
```

## Explanation

An Explanation article discusses *why* something matters — its origin, theory, trade-offs, and debates around it.

### Structure
1. Opening paragraph: what this concept is and why it matters (2-3 sentences)
2. Body sections: background, theory, evidence, trade-offs
3. `## 関連する議論` section (required, only for Explanation):

```markdown
## 関連する議論

### 支持する
- [[article or note link]]
  - one-line description

### 対立する
- [[article or note link]]
  - one-line description

### 拡張する
- [[article or note link]]
  - one-line description
```

### Rules
- Discuss *why*, not *how* — link to How-to articles for procedures
- Present multiple viewpoints when they exist in the source material
- Cite raw clippings as sources: `[[clipping title]]`

## How-to

A How-to article gives goal-oriented directions for solving a specific problem. It assumes the reader already knows the basics.

### Structure
1. One-line description of what this achieves
2. Prerequisites (if any)
3. Numbered steps
4. Common pitfalls or variations

### Rules
- Do not explain *why* — link to Explanation articles for background
- Each step should be actionable and concrete
- Include code examples or configuration snippets when relevant

## Reference

A Reference article provides structured, lookup-oriented information — tables, specs, metrics, comparisons.

### Structure
- Tables, lists, and structured data
- Minimal prose — just enough to label what the data means
- Group related data under clear headings

### Rules
- Describe, do not discuss — no opinions, no arguments
- Use tables for comparisons and specifications
- Keep entries consistent in format and level of detail

## Tutorial

A Tutorial is a learning-oriented lesson that takes a beginner through a series of steps to achieve a working result.

### Structure
1. What the learner will achieve (one sentence)
2. Prerequisites
3. Sequential steps, each building on the previous
4. What to try next (links to other articles)

### Rules
- Minimize explanation — link to Explanation for *why*
- Each step must produce a visible or verifiable result
- Only create when there's genuine beginner-to-intermediate material

## Micro

A Micro article is a short dictionary entry for a single concept. It has no filename prefix — just the concept name (e.g., `Context Anxiety.md`), so any note in the vault can link to it naturally with `[[Context Anxiety]]`.

### Structure
1. `## 定義` — context-independent core definition (2-3 sentences)
2. `## 文脈による用法` — subsections for each context where the concept is used differently
3. `## 関連概念` — links to related Micro articles and other wiki articles

### Template

```markdown
---
author: llm
created: {date}
updated: {date}
wiki-type: micro
---

# {Concept Name}

## 定義

{Core definition that holds across all contexts. 2-3 sentences.}

## 文脈による用法

### {Context A} (e.g., UX / UI設計)

{Meaning, usage, and examples in this context.}
[[related clipping]]

### {Context B} (e.g., エージェントハーネス)

{Meaning, usage, and examples in this context.}
[[related clipping]]

## 関連概念

- [[Concept A]]
  - one-line description
- [[Concept B]]
  - one-line description
```

### Rules
- 300-500 words total
- One concept per file
- No filename prefix — the filename IS the concept name
- When a concept appears in only one context, the 文脈による用法 section can have a single subsection — that's fine, it leaves room for future contexts to be added
- Link to raw clippings that discuss this concept
