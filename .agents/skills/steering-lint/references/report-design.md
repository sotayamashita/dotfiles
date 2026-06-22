---
name: steering-lint report
colors:
  ink: "#1e293b"          # all body text, headings, diagram strokes
  muted: "#64748b"        # labels, metadata, secondary text
  hairline: "#e2e8f0"     # dividers, card borders
  surface: "#ffffff"      # card background
  canvas: "#f8fafc"       # page background
  inplace: "#10b981"      # clean surfaces (emerald) — the "in place" family
  cleared: "#14b8a6"      # cleared/borderline surfaces (teal) — same cool family as clean
  sev-high: "#ef4444"     # finding severity: high
  sev-medium: "#f59e0b"   # finding severity: medium
  sev-low: "#3b82f6"      # finding severity: low
typography:
  display:                # report title
    size: 1.5rem
    weight: 700
  title:                  # section headers
    size: 1.125rem
    weight: 600
  body:
    size: 0.875rem
  label:                  # meta, uppercase
    size: 0.6875rem
    tracking: 0.06em
  mono: ui-monospace, SFMono-Regular, Menlo, monospace
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
rounded:
  sm: 6px
  md: 12px
  lg: 16px
---

## Overview

A **calm, verdict-first health-check report** in the register of a Linear / Vercel
status panel: the reader is a developer auditing their own agent config, low-stress,
who wants one sentence of verdict and then *the single thing to fix*. The report's
job is to make the actionable item unmissable and let everything that's fine recede.

The defining move is a clean split between two visual families:

- **In place** (clean + cleared) wears the **cool green family** — `{colors.inplace}`
  and `{colors.cleared}`. These surfaces are fine; they should read as a quiet
  background, not as items demanding attention.
- **Needs action** (findings) wears the **warm severity family** — `{colors.sev-high}`,
  `{colors.sev-medium}`, `{colors.sev-low}`. These are the only warm colors on the page,
  so the eye lands on them first.

`render_report.py` holds the **enforced copy** of these tokens (a `TOKENS` dict near the
top of the file) and computes every aggregate. This file is the human source of truth for
*intent*; when you change a token, change both. Do not have the script parse this file.

## Colors

A single accent rule governs the page: **warm = needs action, cool = fine.** The reader
should be able to tell, from color alone, how many things actually need their attention.

- **In place** {colors.inplace} and **cleared** {colors.cleared} are both cool greens.
  Cleared is a *deliberately not-flagged borderline* — it is fine, so it groups visually
  with clean, never with findings. (The earlier report colored cleared violet, which read
  as a third problem. It is not a problem.)
- **Severity** {colors.sev-high} / {colors.sev-medium} / {colors.sev-low} appears only on
  findings — their badge, their card's left edge, their place in the health bar. Never on
  clean rows, never on metadata, never as decoration.
- **Ink** {colors.ink} carries all typography and the dark verdict band. **Muted**
  {colors.muted} is for labels and metadata only.

## Typography

One family, modest size jumps. `display` for the report title, `title` for section
headers, `body` for everything else, `label` (uppercase, tracked) for metadata and
section eyebrows, `mono` for paths, code, and `file:line` locations.

## Do's and Don'ts

- **Do** lead with the verdict: a dark band stating, in one qualitative sentence, the
  single most-actionable move. The headline carries **no numbers** — every quantity is
  computed and shown in the stat cards / health bar instead, so prose and figures can
  never disagree.
- **Do** count cleared surfaces as **in place**. "% in place" = `(clean + cleared) / total`.
  A cleared surface is correctly placed; penalizing it understates correctness.
- **Do** collapse the clean surfaces into **one** "N in place" summary that expands on
  demand. The passing rows are the least important; they get the least ink.
- **Do** give each finding a dominant card (severity-colored left edge, full detail) and
  render before/after as a **diagram** — a before-card, an arrow, an after-card — not two
  prose columns.
- **Do** signal a clean surface **once** (a single dot). Not dot + badge + "Correctly placed."
- **Don't** render a severity with **zero** findings in color. Zero-count severities are
  omitted from the colored chips entirely — never a red "high 0" drawing the eye to a
  non-problem.
- **Don't** use a second accent. There is one warm family (severity) and one dark hero
  (the verdict band). Blue is a severity color (`low`) and nothing else — not links, not
  "recommended", not chrome.
- **Don't** put a percentage, count, or score anywhere the agent authors text. Those live
  only in the script's computed output.
