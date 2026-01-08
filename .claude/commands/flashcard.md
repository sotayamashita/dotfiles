---
description: Generate English flashcards from Literature Note
argument-hint: <literature note path>
allowed-tools: Read(*), WebFetch(*), Write(*), Bash(*), Edit(*), AskUserQuestion(*)
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

<argument_handling>
The user provides: $ARGUMENTS

This should be the relative path to a Literature Note in the Obsidian vault.
Example: "Tech Article Summary.md"
</argument_handling>

## Phase 1: Read Literature Note

<instructions>
1. Read the Literature Note at path `$ARGUMENTS`
2. Extract the `source` URL from YAML frontmatter
3. Extract the word list from the `### 英語` section
   - Format: `- word - meaning` (e.g., "- uptick - 上昇する")
4. If no `### 英語` section exists, inform the user and stop
</instructions>

<validation>
- Verify the file exists and is readable
- Verify YAML frontmatter contains `source` field
- Verify `### 英語` section exists and contains words
- If validation fails, report the specific issue and stop
</validation>

## Phase 2: Fetch Original Article

<instructions>
1. Use WebFetch to retrieve the article from the `source` URL
2. Extract the main text content
3. If WebFetch fails, ask the user if they want to:
   - Provide alternative URL
   - Generate generic example sentences instead
   - Cancel the operation
</instructions>

<tools>
- WebFetch - Retrieve web content and convert to markdown
  - Prompt: "Extract the full article text, preserving all sentences"
</tools>

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
---

# 英語学習フラッシュカード

## [Literature Note Title]

[Sentence with target word replaced by [...]]
?
word（meaning）- [Complete sentence with target word in **bold**]
Source: [[$ARGUMENTS]]

---

[Next card...]
```

**For appending to existing file:**
```markdown
[existing content]

---

## [Literature Note Title]

[Sentence with target word replaced by [...]]
?
word（meaning）- [Complete sentence with target word in **bold**]
Source: [[$ARGUMENTS]]

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
4. **Source Link**: Use Obsidian wiki-link format `[[Literature Note Name]]`
5. **Card Separator**: Three hyphens `---` between cards
</format_rules>

<metadata>
- tags: Always include `flashcards` tag
- source: Wiki-link to the Literature Note
- created: Current date in ISO format (YYYY-MM-DD) (only add if creating new file)
- title: Use "# 英語学習フラッシュカード" as the main heading (only add if creating new file)
- When appending: Add a separator and section heading like "## [Literature Note Title]" before the new cards
</metadata>

## Phase 5: Write Output File

<file_handling>
1. **Determine filename**:
   - Fixed filename: `英語学習フラッシュカード.md`
   - Fixed location: Obsidian vault root directory (current working directory)
2. **Check for existing file**:
   - If file exists, ask user: "File exists. Overwrite or append? (overwrite/append)"
   - If overwrite: Replace entire file content
   - If append: Add new flashcards at the end of the file
3. **Write the file** using the Write or Edit tool
4. **Confirm success**: Report the number of cards added and the file path
</file_handling>

<output_path_example>
Input: Any Literature Note path
Output: Always `英語学習フラッシュカード.md` in vault root
</output_path_example>

## Success Criteria

<success_criteria>
- [ ] Literature Note successfully read
- [ ] Source URL extracted from frontmatter
- [ ] Word list extracted from ### 英語 section
- [ ] Original article fetched via WebFetch
- [ ] For each word:
  - [ ] Example sentence found or generated
  - [ ] Deictic references resolved (if needed)
  - [ ] Long sentences shortened (if needed)
  - [ ] Cloze deletion card created
- [ ] All cards formatted correctly
- [ ] Output file written successfully
- [ ] File path reported to user
</success_criteria>

## Error Handling

<common_errors>
1. **File not found**: Report exact path that was tried
2. **No source URL**: Ask user if they want to manually provide one
3. **No ### 英語 section**: Suggest checking the note format
4. **WebFetch fails**: Offer alternatives (manual URL, generated sentences)
5. **No sentences found**: Generate examples and mark them clearly
6. **Write permission error**: Report the issue and suggest alternative location
</common_errors>

<user_guidance>
After completion, inform the user:
1. Number of flashcards created
2. Output file location: `英語学習フラッシュカード.md` (vault root)
3. Mode used: New file created or cards appended
4. Next steps:
   - Open `英語学習フラッシュカード.md` in Obsidian
   - Review the cards for accuracy
   - Start using Spaced Repetition plugin
</user_guidance>
