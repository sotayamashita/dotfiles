# tools/textlint

Repo-local textlint setup used by the `Edit | MultiEdit | Write` PostToolUse
hook `.claude/hooks/textlint-md.sh`. The hook lints **Japanese** Markdown with
[`textlint-rule-preset-ja-technical-writing`][preset] after each edit and feeds
any findings back to the coding agent. It is scoped to Japanese
technical-writing prose only; English-only Markdown is skipped.

This directory is intentionally **not** symlinked into `$HOME`; the hook locates
it by resolving its own symlink back into this repository.

## Setup

Install dependencies once, **from the repository root** (the `-C` path is
relative to the current directory). Supply-chain protected via `sfw`:

```sh
# from the dotfiles repo root
sfw pnpm -C tools/textlint install
```

Equivalently, from inside this directory:

```sh
cd tools/textlint && sfw pnpm install
```

`node_modules/` is git-ignored; `package.json` and `pnpm-lock.yaml` are
tracked for reproducibility.

## Configuration

Rules live in `.textlintrc.json`. The preset bundles the standard
ja-technical-writing rules; tweak or disable individual rules there.

[preset]: https://github.com/textlint-ja/textlint-rule-preset-ja-technical-writing
