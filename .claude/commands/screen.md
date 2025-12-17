---
description: Screen Clippings to decide if worth reading
argument-hint: <clipping filename>
allowed-tools: Task(*), Read(*), Glob(*), Bash(rg:*)
---

<purpose>
You are screening a Clipping to help the user decide if it's worth reading in depth.
Your goal is to present the article's structure and find related notes in the vault,
NOT to judge whether it's worth reading. That decision belongs to the user.
</purpose>

<screening_principles>
1. **Present, Don't Judge** - Show structure and connections, never recommend
2. **User Decides** - The user determines if the article is worth their time
3. **Context Window Aware** - Use subagents for Obsidian search to save context
4. **No "Understanding Illusion"** - This is for filtering, not for gaining knowledge
</screening_principles>

<investigate_before_answering>
Never speculate about the article's content without reading it first.
Always use the Read tool to examine the actual file before making claims.
</investigate_before_answering>

<argument_handling>
The user provides: $ARGUMENTS

Resolve the file path:
1. If path starts with "Clippings/", use as-is
2. Otherwise, prepend "Clippings/"
3. If path doesn't end with ".md", append ".md"
4. The base directory is the current working directory (Obsidian vault)
</argument_handling>

## Phase 1: Parallel Analysis

<use_parallel_tool_calls>
Execute Tasks 1-2 simultaneously using parallel tool calls.
These tasks have no dependencies and can run concurrently.
</use_parallel_tool_calls>

<parallel_execution>

### Task 1: Article Structure Analysis

<context>
Understanding the article's structure helps the user quickly assess
if the content aligns with their interests and existing knowledge.
</context>

<instructions>
Create a subagent to analyze the article structure:
- Read the full article using Read tool
- Extract the core claim (what the author most wants to convey, in 1 sentence)
- Identify the logical structure (claim → evidence → conclusion)
- Determine the target audience and prerequisite knowledge
- Note the article length and complexity
</instructions>

<output_format>
- `core_claim: string` - The central argument in one sentence
- `structure: { claim: string, evidence: string[], conclusion: string }`
- `target_audience: string` - Who this article is written for
- `prerequisites: string[]` - Knowledge needed to understand the article
</output_format>

### Task 2: Related Notes Search

<context>
Finding related notes helps the user understand how this article
connects to their existing knowledge network in Obsidian.
</context>

<instructions>
Create a subagent to search for related notes in the vault:
- Extract 3-5 key concepts/keywords from the article title and content
- Search for related files using Glob (filename patterns)
- Search for related content using rg (ripgrep)
- Exclude the Clippings folder from results (focus on processed notes)
- Return up to 5 most relevant notes with connection reasons
</instructions>

<tools>
- Glob - Find files by name pattern (e.g., "*agent*.md", "*LLM*.md")
- rg (ripgrep) - Fast content search
  - Example: `rg -l "keyword" --glob "*.md" --glob "!Clippings/*"`
  - Use `-l` for file list only, `-i` for case-insensitive
</tools>

<search_scope>
- Include: All .md files in the vault
- Exclude: Clippings/, Assets/, Templates/
- Priority: Permanent notes (zettelkasten/permanent tag) > Literature notes > Others
</search_scope>

<output_format>
- `keywords: string[]` - Key concepts extracted for search
- `related_notes: { path: string, reason: string }[]` - Up to 5 related notes
</output_format>

</parallel_execution>

## Phase 2: Present Results

<synthesis>
Combine the results from both tasks into a structured format.
Do NOT add any recommendations or judgments.
</synthesis>

<output_format>
Present results in the following format:

```
## Screening Result: [filename]

### Core Claim (1 sentence)
> [Author's central argument]

### Logical Structure
- **Claim**: 
  - [main argument (around 50 chars)]
- **Evidence**:
  - [point 1 (around 50 chars)]
  - [point 2 (around 50 chars)]
  - [point 3 (around 50 chars)]
- **Conclusion**: 
  - [final takeaway]

### Target Audience & Prerequisites
- **Target audience**: [...]
- **Required knowledge**:
  - [prerequisite 1 (around 50 chars)]
  - [prerequisite 2 (around 50 chars)]
  ...

### Related Notes in Your Vault
- [[note1]] 
  - [reason (around 50 chars)]
- [[note2]] 
  - [reason (around 50 chars)]
- [[note3]] 
  - [reason (around 50 chars)]
...

---
**The decision is yours.**
1. Read → Proceed to create Literature Note
2. Skip → Archive this Clipping
3. Later → Keep in inbox for now
```
</output_format>

<wait_for_user>
STOP after presenting the screening results.
Do NOT proceed with any action until the user decides.
The user will choose: Read / Skip / Later
</wait_for_user>

## Success Criteria

<success_criteria>
- [ ] Article file was successfully read
- [ ] Core claim extracted in one sentence
- [ ] Logical structure identified (claim, evidence, conclusion)
- [ ] Target audience and prerequisites determined
- [ ] Related notes searched (using subagent)
- [ ] Results presented in structured format
- [ ] NO recommendation or judgment made by AI
- [ ] User decision awaited
</success_criteria>
