---
description: Generate English flashcards from Literature Note on Obsidian
argument-hint: <literature note path>
allowed-tools: Read(*), WebFetch(*), Write(*), Bash(*), Edit(*), AskUserQuestion(*), Skill(*)
---

<purpose>
Generate English vocabulary flashcards from Literature Notes.
Extract words from the "### 英語" section and create Cloze Deletion format cards
using example sentences from the original article.
</purpose>

<principles>
1. **Context Preservation** - Find sentences from the original article, not generated ones
2. **Deictic Resolution** - Replace pronouns/demonstratives with concrete referents
3. **Self-Contained Sentences** - Each sentence must be understandable without context
4. **Spaced Repetition Format** - Follow Obsidian Spaced Repetition plugin format
</principles>

<skill_integration>
When creating flashcard output with Obsidian-specific syntax (wikilinks in
source field, etc.), check for available Obsidian skills:

1. Use Glob to check if skills exist: `.claude/skills/*/SKILL.md`
2. If Obsidian-related skills found:
   - Invoke the relevant skill via Skill tool for syntax guidance
   - Ensure proper wikilink format in source frontmatter
3. If no skills available:
   - Proceed with standard wikilink format `[[Note Name]]`
   - Use CommonMark conventions

This ensures correct Obsidian Flavored Markdown when skills are installed.
</skill_integration>

<argument_handling>
The user provides: $ARGUMENTS

This should be the relative path to a Literature Note in the Obsidian vault.
Example: "Tech Article Summary.md"
</argument_handling>

## Phase 1: Read Literature Note and Resolve Source

<instructions>
1. Read the Literature Note at path `$ARGUMENTS`
2. Extract the `source` field from YAML frontmatter
3. **Determine source type**:
   - If starts with `http://` or `https://` → Direct URL
   - If matches `[[...]]` pattern → Wiki-link to another note
   - Otherwise → Treat as direct URL
4. **If wiki-link, resolve to actual URL or content**:
   a. Extract note name from `[[Note Name]]`
   b. Search for the note file using multiple strategies (see below)
   c. Read the found note and extract its `source` field
   d. If that source is also a wiki-link, repeat (max 3 levels to prevent infinite loops)
   e. Store the Clipping file path for potential use as content source
5. Extract the word list from the `### 英語` section
   - Format: `- word - meaning` (e.g., "- uptick - 上昇する")
6. If no `### 英語` section exists, inform the user and stop
</instructions>

<wiki_link_resolution>
When source is a wiki-link (e.g., `[[Cognitive Hygiene Why You Need to Make Thinking Hard Again]]`):

**Step 1: Extract note name**
- Pattern: Remove `[[` and `]]` from the source value
- Example: `[[Cognitive Hygiene]]` → `Cognitive Hygiene`

**Step 2: Search for file (try in priority order)**
Use Glob tool to search:
1. Current directory: `{note_name}.md`
2. Clippings directory: `Clippings/**/{note_name}.md`
3. Vault-wide search: `**/{note_name}.md`

Take the first match found.

**Step 3: Read and extract source**
- Read the found file using Read tool
- Extract `source` field from YAML frontmatter
- If source is a URL (starts with http:// or https://) → Use it as final URL
- If source is a wiki-link → Repeat resolution (track depth to prevent loops, max depth: 3)
- If no source field → Ask user for manual URL

**Step 4: Store Clipping file path**
- Keep track of the Clipping file path
- This can be used as alternative content source if WebFetch fails

**Error handling**:
- Max resolution depth: 3 levels
- If file not found after all search attempts: Report search patterns tried and ask user to provide manual URL or file path
- If circular reference detected: Report the circular path and ask for manual URL
- If max depth exceeded: Report and ask for manual URL
</wiki_link_resolution>

<validation>
- Verify the file exists and is readable
- Verify YAML frontmatter contains `source` field
- Verify `### 英語` section exists and contains words
- If validation fails, report the specific issue and stop
</validation>

## Phase 2: Fetch Original Article Content

<instructions>
1. If source URL was successfully resolved, use WebFetch to retrieve the article
2. Extract the main text content
3. If WebFetch fails, offer alternatives based on context:
   - If a Clipping file was found during wiki-link resolution: Offer to use its content directly
   - Offer to let user provide alternative URL
   - Offer to generate generic example sentences instead
   - Offer to cancel the operation
</instructions>

<tools>
- WebFetch - Retrieve web content and convert to markdown
  - Prompt: "Extract the full article text, preserving all sentences"
</tools>

<alternative_content_source>
**If WebFetch fails and a Clipping file exists:**

Clipping files (e.g., in `Clippings/processed/`) typically contain the full article content.
You can use this content directly instead of fetching from the web.

Steps:
1. Inform user: "WebFetch failed, but I found a Clipping file at {path}. Use this content instead?"
2. If user agrees:
   - Read the Clipping file
   - Extract the main content (skip YAML frontmatter)
   - Use this as the article text for finding example sentences
3. If user declines:
   - Ask for alternative URL or other options

This approach is often MORE reliable than WebFetch for Obsidian workflows where
Clippings are already saved locally.
</alternative_content_source>

## Phase 3: Generate Flashcards

<for_each_word>
For each word in the word list, execute the following steps:

### Step 1: Find Example Sentence

<search_strategy>
1. Search for the exact word (case-insensitive)
2. Search for common inflections:
   - Plural forms (word + "s", word + "es")
   - Past tense (word + "ed", word + "d")
   - Present participle (word + "ing")
   - Comparative/superlative (word + "er", word + "est")
3. Search for the word as part of compounds or phrases
</search_strategy>

<sentence_selection_criteria>
- Prefer sentences that clearly demonstrate the word's meaning
- Avoid overly technical or complex sentences
- Prefer sentences between 10-30 words
- If multiple matches, select the most representative one
</sentence_selection_criteria>

### Step 2: Resolve Deictic References

<deictic_indicators>
A sentence needs resolution if it:
- Starts with: this, that, these, those, it, they, such, here, there, he, she
- Contains pronouns without clear antecedents in the sentence
- References concepts not defined in the sentence itself
</deictic_indicators>

<resolution_process>
1. Identify the deictic element (pronoun/demonstrative)
2. Look at the previous 1-2 sentences for the antecedent
3. Replace the deictic with the concrete referent
4. Ensure the modified sentence is grammatically correct
5. Verify the sentence is now self-contained and understandable
</resolution_process>

<examples>
Before: "This led to a significant increase in revenue."
After: "The new pricing strategy led to a significant increase in revenue."

Before: "It became the industry standard within months."
After: "The GraphQL API became the industry standard within months."

Before: "They implemented the solution across all departments."
After: "The engineering team implemented the solution across all departments."
</examples>

### Step 3: Handle Sentence Not Found

<if_no_sentence_found>
If no sentence containing the word is found in the article:
1. Report to the user: "Word '[word]' not found in the article"
2. Generate a simple, natural example sentence that:
   - Uses the word correctly in context
   - Reflects the provided meaning
   - Is appropriate for the user's learning level
   - Is between 10-20 words
3. Mark this card with a note: "(Generated example - not from source)"
</if_no_sentence_found>

### Step 4: Shorten Long Sentences

<if_sentence_too_long>
If the sentence exceeds 50 words:
1. Identify the main clause containing the target word
2. Remove subordinate clauses that don't affect the word's meaning
3. Preserve the essential context for understanding the word
4. Ensure grammatical correctness after shortening
</if_sentence_too_long>

</for_each_word>

## Phase 4: Create Flashcard Output

<output_format>
Create flashcards in the following format:

**For new file:**
```markdown
---
tags:
  - flashcards
created: [YYYY-MM-DD]
source: [[$ARGUMENTS]]
---

# [Literature Note Title] - Flashcards

[Sentence with target word replaced by [...]]
?
word（meaning）- [Complete sentence with target word in **bold**]

---

[Next card...]
```

**For appending to existing file:**
```markdown
[existing content]

---

[Sentence with target word replaced by [...]]
?
word（meaning）- [Complete sentence with target word in **bold**]

---

[Next card...]
```
</output_format>

<format_rules>
1. **Cloze Deletion Line**: Replace the target word with `[...]`
   - Keep all other words and punctuation intact
2. **Separator**: Single line with `?`
3. **Answer Line**: Format as `word（meaning）- Sentence`
   - Word in lowercase (unless proper noun)
   - Meaning in Japanese in full-width parentheses （）
   - Target word in **bold** in the sentence
4. **Card Separator**: Three hyphens `---` between cards
</format_rules>

<metadata>
- tags: Always include `flashcards` tag
- source: Wiki-link to the Literature Note (in YAML frontmatter, only for new files)
- created: Current date in ISO format (YYYY-MM-DD) (only for new files)
- title: Use "# [Literature Note Title] - Flashcards" as the main heading (only for new files)
- When appending: Just add a separator `---` and continue with new cards
</metadata>

## Phase 5: Write Output File

<file_handling>
1. **Determine filename**:
   - Extract the base name from the Literature Note path (without extension)
   - Format: `Flashcards/[Literature Note Name] - Flashcards.md`
   - Example: Input `Tech Article Summary.md` → Output `Flashcards/Tech Article Summary - Flashcards.md`
2. **Ensure Flashcards directory exists**:
   - Check if `Flashcards/` directory exists using Bash `test -d Flashcards`
   - If not exists, create it using Bash `mkdir -p Flashcards`
3. **Check for existing file**:
   - If file exists, ask user: "File exists. Overwrite or append? (overwrite/append)"
   - If overwrite: Replace entire file content
   - If append: Add new flashcards at the end of the file
4. **Write the file** using the Write or Edit tool
5. **Confirm success**: Report the number of cards added and the file path
</file_handling>

<output_path_example>
Input: `Tech Article Summary.md`
Output: `Flashcards/Tech Article Summary - Flashcards.md`

Input: `Notes/Deep Learning Paper.md`
Output: `Flashcards/Deep Learning Paper - Flashcards.md`
</output_path_example>

## Success Criteria

<success_criteria>
- [ ] Literature Note successfully read
- [ ] Source field extracted from frontmatter
- [ ] If source is wiki-link:
  - [ ] Wiki-linked note found and read
  - [ ] Source URL resolved (or Clipping file identified)
- [ ] Word list extracted from ### 英語 section
- [ ] Original article content obtained (via WebFetch or Clipping file)
- [ ] For each word:
  - [ ] Example sentence found or generated
  - [ ] Deictic references resolved (if needed)
  - [ ] Long sentences shortened (if needed)
  - [ ] Cloze deletion card created
- [ ] All cards formatted correctly
- [ ] Flashcards directory created (if needed)
- [ ] Output file written successfully
- [ ] Obsidian skills checked for wikilink formatting (optional)
- [ ] File path reported to user
</success_criteria>

## Error Handling

<common_errors>
1. **Literature Note file not found**: Report exact path that was tried
2. **No source field in frontmatter**: Ask user if they want to manually provide URL
3. **Wiki-link resolution failed**: Report search patterns tried (`{name}.md`, `Clippings/**/{name}.md`, `**/{name}.md`), ask user to provide manual file path or URL
4. **Circular wiki-link reference**: Report the circular path (e.g., A→B→A) and ask for manual URL
5. **Max wiki-link resolution depth exceeded**: Report the chain and ask for manual URL
6. **No ### 英語 section**: Suggest checking the note format
7. **WebFetch fails**:
   - If Clipping file available: Offer to use Clipping content directly (recommended)
   - Otherwise offer: manual URL, generated sentences, or cancel
8. **No sentences found for a word**: Generate example and mark with "(Generated example - not from source)"
9. **Flashcards directory creation fails**: Report permission issue
10. **Write permission error**: Report the issue and suggest alternative location
</common_errors>

<user_guidance>
After completion, inform the user:
1. Number of flashcards created
2. Output file location: `Flashcards/[Literature Note Name] - Flashcards.md`
3. Mode used: New file created or cards appended
4. Next steps:
   - Open the flashcard file in Obsidian
   - Review the cards for accuracy
   - Start using Spaced Repetition plugin
</user_guidance>
