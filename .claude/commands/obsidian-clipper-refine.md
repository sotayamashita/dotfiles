---
description: Clean and fix Web Clipper markdown using original article for Obsidian
argument-hint: <clipping filename>
allowed-tools: Task(*), Read(*), WebFetch(*), Edit(*), Glob(*), AskUserQuestion(*), Skill(*)
---

<purpose>
Fix markdown saved by Obsidian Web Clipper by referencing the original article.
Perform structure fixes (heading hierarchy, lists, code blocks) and content completion.
</purpose>

<principles>
1. **Preserve Intent** - Accurately reproduce the intent and structure of the original article
2. **Confirm Before Apply** - Always get user approval before applying fixes
3. **Minimal Changes** - Only make necessary fixes, avoid excessive changes
4. **Source of Truth** - Treat the original article as authoritative, fix the Clipping accordingly
</principles>

<investigate_before_answering>
Never speculate about the Clipping's content or structure without reading it first.
Always use the Read tool to examine the actual file before identifying issues.
Always fetch the original article via WebFetch before comparing content.
</investigate_before_answering>

<skill_integration>
When applying fixes that involve Obsidian-specific syntax (wikilinks, callouts,
embeds, properties, etc.), check for available Obsidian skills:

1. Use Glob to check if skills exist: `.claude/skills/*/SKILL.md`
2. If Obsidian-related skills found:
   - Invoke the relevant skill via Skill tool for syntax guidance
   - Follow skill instructions for proper Obsidian formatting
3. If no skills available:
   - Proceed with standard markdown fixes
   - Use CommonMark + GFM conventions

This ensures correct Obsidian Flavored Markdown when skills are installed,
while maintaining functionality without them.
</skill_integration>

<argument_handling>
The user provides: $ARGUMENTS

Resolve the file path:
1. If path starts with "Clippings/", use as-is
2. Otherwise, prepend "Clippings/"
3. If path doesn't end with ".md", append ".md"
4. The base directory is the current working directory (Obsidian vault)
</argument_handling>

## Phase 1: Read Clipping and Extract Source

<instructions>
1. Read the Clipping file at path `$ARGUMENTS`
2. Extract the `source` field from YAML frontmatter
3. Analyze current markdown structure:
   - Count heading levels (H1, H2, H3, etc.)
   - Identify list structures (nested depth)
   - Find code blocks (with/without language)
</instructions>

<validation>
- Verify the file exists and is readable
- Verify YAML frontmatter contains `source` field with URL
- If no source URL, ask user via AskUserQuestion
</validation>

## Phase 2: Fetch Original Article

<instructions>
1. Use WebFetch to retrieve the original article from `source` URL
2. Parse the article structure
3. If WebFetch fails, use AskUserQuestion to:
   - Ask for alternative URL
   - Or proceed with structure-only fixes (no content comparison)
</instructions>

<tools>
- WebFetch - Retrieve web content
  - Prompt: "Extract the full article content preserving structure"
</tools>

<footnote_patterns>
Web Clipper が生成する非標準形式と Obsidian 変換ルール:

| 検出パターン | 変換後 |
|-------------|--------|
| `[N](/path#anchor)` | `[^N]` (参照) |
| `<sup>N</sup>` | `[^N]` (参照) |
| `[N]` (リンクなし) | `[^N]` (参照) |
| `[N] Definition text` (末尾) | `[^N]: Definition text` |

N = 数字または識別子
</footnote_patterns>

## Phase 3: Compare and Identify Issues

<parallel_execution>
Execute Tasks 1-3 simultaneously using parallel tool calls.
</parallel_execution>

### Task 1: Structure Analysis
Create a subagent to compare structures:
- Heading hierarchy (original vs clipping)
- List nesting depth
- Code block language specifications
- Table formatting

<output_format>
- `heading_issues: { line: number, current: string, expected: string }[]`
- `list_issues: { line: number, issue: string }[]`
- `code_issues: { line: number, issue: string, suggested_lang: string }[]`
</output_format>

### Task 2: Content Analysis
Create a subagent to analyze content:
- Missing sections (in original but not in clipping)
- Extra content (ads, nav, footer in clipping)
- Broken links (relative URLs that need fixing)

<output_format>
- `missing_sections: { heading: string, content_preview: string }[]`
- `extra_content: { line_start: number, line_end: number, type: string }[]`
- `link_issues: { line: number, current: string, suggested: string }[]`
</output_format>

### Task 3: Footnote Analysis
Create a subagent to analyze footnote formats:
- Detect non-Obsidian footnote patterns (see <footnote_patterns>)
- Map to Obsidian-compatible format
- Verify reference-definition consistency

<output_format>
- `footnote_ref_issues: { line: number, current: string, obsidian: string }[]`
- `footnote_def_issues: { line: number, current: string, obsidian: string }[]`
- `orphan_refs: string[]` (references without definitions)
- `orphan_defs: string[]` (definitions without references)
</output_format>

## Phase 4: Present Fixes to User

<decision_flow>
1. Compile all issues from subagents
2. Present summary to user:
   ```
   ## Issues Detected

   ### Structure Issues (N total)
   - Heading hierarchy: X issues
   - List structure: Y issues
   - Code blocks: Z issues

   ### Content Issues (M total)
   - Missing sections: A issues
   - Extra content: B issues
   - Links: C issues

   ### Footnote Issues (F total)
   - Reference format: X issues
   - Definition format: Y issues
   - Orphan references: Z issues
   ```

3. Use AskUserQuestion to confirm:
   - "Apply structure fixes?" (Yes/No/Select specific)
   - "Apply content fixes?" (Yes/No/Select specific)
   - "Apply footnote fixes?" (Yes/No/Select specific)
</decision_flow>

## Phase 5: Apply Fixes

<instructions>
For each approved fix category:
1. Check for Obsidian skills if fixes involve Obsidian-specific syntax
2. Apply structural fixes (heading levels, lists, code blocks)
3. Apply content fixes (add missing, remove extra)
4. Fix links if approved
   - Convert to wikilinks if Obsidian skill available and appropriate
5. Apply footnote fixes if approved
   - Convert inline references to `[^N]` format
   - Convert definitions to `[^N]: text` format
   - Report orphan refs/defs for manual review
6. Use Edit tool for each modification
</instructions>

<completion_report>
```
## Fixes Applied

### Changes Made
- Heading hierarchy: X fixes
- List structure: Y fixes
- Code blocks: Z fixes
- Missing sections: A added
- Extra content: B removed
- Links: C fixed
- Footnotes: F fixed (R orphan refs, D orphan defs reported)

File: [path]
```
</completion_report>

## Success Criteria

<success_criteria>
- [ ] Clipping file successfully read
- [ ] Source URL extracted from frontmatter
- [ ] Original article fetched (or user chose alternative)
- [ ] Structure issues identified
- [ ] Content issues identified
- [ ] Footnote issues identified
- [ ] Issues presented to user
- [ ] User approval obtained via AskUserQuestion
- [ ] Approved fixes applied via Edit tool
- [ ] Obsidian skills checked (optional enhancement applied if available)
- [ ] Completion report shown
</success_criteria>

## Error Handling

<common_errors>
1. **File not found**: Report exact path tried
2. **No source URL**: Ask user via AskUserQuestion
3. **WebFetch fails**: Offer alternatives (new URL, structure-only)
4. **Edit fails**: Report error, suggest manual fix
</common_errors>
