# Feature Writing Guide

Complete framework and rules for writing about features.

Source: [GitLab Handbook — Writing about features](https://handbook.gitlab.com/handbook/product/product-processes/)

## Table of contents

1. [The 4-part framework](#1-the-4-part-framework)
   - 1.1 Context and problem statement
   - 1.2 Solution description
   - 1.3 Usage instructions
   - 1.4 Supporting resources
2. [Writing rules](#2-writing-rules)
   - 2.1 Lead with pain, not features
   - 2.2 Be specific and concrete
   - 2.3 Avoid unexplained acronyms
   - 2.4 Use active voice
   - 2.5 Focus on benefits, not capabilities
   - 2.6 Write scannable content
   - 2.7 Match tone to audience
3. [Output type adaptations](#3-output-type-adaptations)
   - 3.1 Blog post
   - 3.2 Release note
   - 3.3 Changelog entry
   - 3.4 Customer email
   - 3.5 Internal communication

---

## 1. The 4-part framework

Every feature announcement must cover four parts. Missing any part leaves the reader with unanswered questions.

### 1.1 Context and problem statement

Establish the current situation without the feature. Describe the pain points users face and connect them to real-world consequences.

- **Do**: Describe the problem from the user's perspective and explain why it matters now
- **Don't**: Jump straight into the feature without establishing why it exists

Examples:

- **Do**: "When sensitive credentials are accidentally committed to a repository, every developer who clones that repo inherits the security risk. Teams spend hours auditing commit history to find and rotate exposed secrets."
- **Don't**: "We're excited to announce our new secrets detection feature."

### 1.2 Solution description

Explain what was shipped to address the problem. Keep the description focused on the remedy provided, not on internal implementation details.

- **Do**: Clearly state what the feature does and how it resolves the problem described in Context
- **Don't**: List technical specifications without connecting them back to the problem

Examples:

- **Do**: "Push rules now automatically block commits that contain patterns matching known secret formats, preventing credentials from ever reaching the repository."
- **Don't**: "We added regex-based pattern matching to the pre-receive hook pipeline with configurable rule sets."

### 1.3 Usage instructions

Describe how to use the feature in simple, accessible language. Walk the reader through getting started.

- **Do**: Provide clear steps that a new user can follow immediately
- **Don't**: Assume knowledge of related features, internal tooling, or undocumented prerequisites

Examples:

- **Do**: "To enable secrets detection, go to Settings > Repository > Push Rules and toggle 'Prevent pushing secret files'. The rule applies to all future pushes immediately."
- **Don't**: "Configure the push rules as documented in the admin settings."

### 1.4 Supporting resources

Point readers toward documentation, related blog posts, and reference materials for deeper learning.

- **Do**: Link to specific pages that help the reader take the next step
- **Don't**: Provide bare URLs or generic "learn more" links without context

Examples:

- **Do**: "Read the [push rules documentation](https://docs.example.com/push-rules) for the full list of configurable patterns. See also: [How we secured our own repositories](https://blog.example.com/securing-repos) for a walkthrough of the feature in practice."
- **Don't**: "For more information, see the docs."

---

## 2. Writing rules

### 2.1 Lead with pain, not features

Open with the problem the audience experiences, not the feature name or a company announcement.

- **Do**: Start with a scenario, frustration, or consequence the reader recognizes
- **Don't**: Start with "We're excited to announce" or the feature name as the first word

Examples:

- **Do**: "Reviewing merge requests across multiple projects means switching between tabs, losing context, and missing critical changes."
- **Don't**: "Introducing Multi-Project Merge Request View, a new feature that..."

### 2.2 Be specific and concrete

Replace vague claims with measurable outcomes, exact steps, or real scenarios.

- **Do**: Use numbers, named actions, and observable results
- **Don't**: Use abstract adjectives like "powerful", "seamless", or "robust"

Examples:

- **Do**: "Reduces pipeline run time from 45 minutes to 12 minutes by caching dependency layers between jobs."
- **Don't**: "Dramatically improves pipeline performance with our powerful caching solution."

### 2.3 Avoid unexplained acronyms

Spell out acronyms on first use. If the acronym is not widely known outside the team, avoid it entirely.

- **Do**: Spell out on first use with the abbreviation in parentheses, then use the short form
- **Don't**: Use internal shorthand or assume the reader knows domain-specific abbreviations

Examples:

- **Do**: "The minimum viable change (MVC) ships the smallest useful improvement."
- **Don't**: "We shipped the MVC last week." (reader may not know what MVC means)

### 2.4 Use active voice

Write sentences where the subject performs the action. Active voice is clearer and more direct.

- **Do**: Make the user or the feature the subject of the sentence
- **Don't**: Use passive constructions that obscure who does what

Examples:

- **Do**: "You can now filter issues by health status directly from the board view."
- **Don't**: "Issues can now be filtered by health status from the board view."

### 2.5 Focus on benefits, not capabilities

Describe what the user gains, not what the system can do. Connect capabilities to outcomes.

- **Do**: State the user benefit first, then mention the mechanism if helpful
- **Don't**: List technical capabilities without explaining the user impact

Examples:

- **Do**: "Ship fixes faster by deploying directly from a merge request without leaving your review workflow."
- **Don't**: "Supports one-click deployment from merge request pages."

### 2.6 Write scannable content

Structure content so readers can find what they need without reading every word.

- **Do**: Use headings, bullet points, short paragraphs (3-4 sentences max), and bold key terms
- **Don't**: Write long unbroken paragraphs or bury important details in the middle of text

Examples:

- **Do**:
  > **What changed**: Pipeline jobs now cache dependencies automatically.
  >
  > **Why it matters**: Teams running CI/CD pipelines save 10-30 minutes per run.
  >
  > **How to enable**: Go to Settings > CI/CD > Caching and select "Auto-cache dependencies."

- **Don't**: "We've made a change to how pipeline jobs handle dependencies. Previously, each job would download all dependencies from scratch, which could take a long time depending on the project size. Now, dependencies are cached automatically between runs, so subsequent pipeline jobs will be faster. You can enable this by going to Settings, then CI/CD, then Caching, and selecting the auto-cache option."

### 2.7 Match tone to audience

Adjust vocabulary, detail level, and emphasis based on who will read the text.

- **Do**: Use technical specifics for developers; use outcome and business language for executives and customers
- **Don't**: Use the same tone for every audience

Examples:

- **Developer audience**: "The new `--parallel` flag in the CLI splits test suites across available runners, distributing spec files by estimated duration."
- **Executive audience**: "Engineering teams can now run their test suites in parallel, reducing wait times and shipping releases faster."
- **Customer email**: "Your CI/CD pipelines just got faster. Tests now run in parallel automatically, so your team spends less time waiting and more time building."

---

## 3. Output type adaptations

### 3.1 Blog post

- **Length**: 400-800 words
- **Tone**: Conversational, informative
- **Structure**: Hook (problem) > Context > Solution > Usage > Call to action
- **Tips**:
  - Use a compelling title that states the benefit, not the feature name
  - Include at least one concrete example or scenario
  - End with a clear next step for the reader

Template outline:

```
Title: [Benefit-focused headline]

[Opening: 1-2 sentences describing the problem]

[Context: Why this problem matters and who it affects]

[Solution: What we built and how it addresses the problem]

[Usage: How to get started, with steps or a screenshot]

[Resources: Links to docs, related posts, and feedback channels]
```

### 3.2 Release note

- **Length**: 50-150 words per feature
- **Tone**: Concise, factual
- **Structure**: Problem > Solution > How to use > Link to docs
- **Tips**:
  - One paragraph per feature
  - Lead with the user benefit
  - Always link to documentation

Template outline:

```
**[Feature name]**

[1 sentence: problem it solves]. [1-2 sentences: what it does].
[1 sentence: how to use or enable]. [Link to documentation].
```

### 3.3 Changelog entry

- **Length**: 1-3 sentences
- **Tone**: Terse, technical
- **Structure**: Action verb > what changed > why it matters
- **Tips**:
  - Start with a verb (Added, Fixed, Changed, Removed, Improved)
  - Include the scope (component, area, or feature name)
  - Skip marketing language

Template outline:

```
- **Added**: [Feature name] — [what it does and why]. ([#issue](link))
- **Fixed**: [Bug description] — [what was wrong and what now works]. ([#issue](link))
```

### 3.4 Customer email

- **Length**: 150-300 words
- **Tone**: Warm, professional, outcome-focused
- **Structure**: Greeting > Why this matters to you > What's new > How to start > Support link
- **Tips**:
  - Personalize when possible
  - Focus on the benefit to the recipient's workflow
  - Include a single, clear call to action
  - Keep it scannable with short paragraphs

Template outline:

```
Subject: [Benefit in 6-8 words]

Hi [Name],

[1-2 sentences: problem they face or goal they have]

[1-2 sentences: what's now available and how it helps]

[1-2 sentences: how to get started]

[Call to action: button or link]

[Sign-off]
```

### 3.5 Internal communication

- **Length**: 100-250 words
- **Tone**: Direct, informal, team-oriented
- **Structure**: What shipped > Why it matters > How to talk about it > Resources
- **Tips**:
  - Assume the reader knows the product but not this specific feature
  - Include key talking points for customer-facing teams
  - Link to the external announcement if one exists

Template outline:

```
## [Feature name] shipped

**What**: [1-2 sentences describing the feature]

**Why**: [1-2 sentences on the problem it solves and who benefits]

**Talking points**:
- [Key benefit 1]
- [Key benefit 2]
- [Key benefit 3]

**Resources**: [Links to docs, blog post, demo]
```

---

## License

Content adapted from the [GitLab Handbook](https://handbook.gitlab.com/handbook/product/product-processes/).

- [MIT License](https://gitlab.com/gitlab-com/content-sites/handbook/-/blob/main/LICENSE)
