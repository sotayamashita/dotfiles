# ADR-0001: Supply Chain Protection with Socket Firewall

## Status

Accepted

## Date

2026-04-01

## Context

The [axios npm package was compromised][axios-incident] via a supply chain
attack, demonstrating that even widely-used packages can be hijacked to execute
malicious code at install time. This incident motivated a review of our
development environment's defenses against similar attacks.

Our dotfiles configure global settings for multiple package managers (npm, pnpm,
bun, uv) and are symlinked into `$HOME`, making them the natural place to
enforce supply chain protections across all projects.

We evaluated the practices outlined in the
[npm Security Best Practices][npm-best-practices] guide and assessed which
could be applied at the dotfiles (global) level versus project or account level.

### Threat model

Coding agents (Claude Code, OpenAI Codex CLI) autonomously install packages by:

1. Directly editing `package.json` with specific versions, then running
   `npm install`.
2. Running `npm install <package>` or `pnpm add <package>` directly.

Both paths bypass manual review. Protections must be enforced mechanically,
not through instructions alone.

## Decision

### Adopted

#### 1. Socket Firewall (sfw) as install-time gate

[Socket Firewall Free][sfw-free] acts as an HTTP/HTTPS proxy between the
package manager and the registry, blocking confirmed malware before download.

**Fish shell wrappers** (`aliases.fish`): transparently replace bare package
manager commands with `sfw`-wrapped equivalents for interactive use.

```fish
# Wraps: npm, pnpm, pip, uv, cargo
function npm --wraps=npm --description "Run npm through Socket Firewall"
    command sfw npm $argv
end
```

**Claude Code PreToolUse hook** (`sfw-gate.sh`): blocks bare install commands
executed by the agent's Bash tool and returns feedback instructing it to use
`sfw`. This is a hard block — the command is rejected before execution.

**Claude Code PostToolUse hook** (`sfw-post-edit.sh`): detects when the agent
edits dependency manifests (`package.json`, `Cargo.toml`, `pyproject.toml`,
etc.) and instructs it to run the install through `sfw`.

#### 2. Dependency cooldown (min-release-age)

Configured across all package managers to delay installing newly published
packages by 7 days. This blocks ~80% of supply chain attacks whose malicious
windows are shorter than 7 days ([Woodruff's analysis][cooldown-analysis]).

| Package manager | Config file           | Setting                  |
|-----------------|-----------------------|--------------------------|
| npm             | `.npmrc`              | `min-release-age=7`      |
| pnpm            | `.config/pnpm/rc`     | `minimumReleaseAge: 10080` |
| bun             | `bunfig.toml`         | `minimumReleaseAge = "7d"` |
| deno            | `aliases.fish`        | `--minimum-dependency-age=P7D` (fish function wrapper) |

#### 3. sfw installed via mise

`sfw` is managed as a global tool through mise (`"npm:sfw" = "latest"` in
`.config/mise/config.toml`), ensuring it is available in all environments
without per-project setup.

### Rejected

#### 1. Global `ignore-scripts=true` in `.npmrc`

**Reason:** Too disruptive for a global setting. Many packages (`esbuild`,
`sharp`, `playwright`, `node-sass`) require post-install scripts to function.
Every project would need overrides, defeating the purpose of a global default.
This is better handled per-project via pnpm's `onlyBuiltDependencies` allowlist.

#### 2. Blocking all `Edit`/`Write` to `package.json`

**Reason:** Not deterministically enforceable without also blocking legitimate
edits (scripts, metadata, configuration). The PostToolUse hook approach
(notify + instruct to install via sfw) achieves the security goal without
restricting valid workflows.

#### 3. CLAUDE.md-only enforcement

**Reason:** Instructions in `CLAUDE.md` and equivalent files (`.cursorrules`,
`.github/copilot-instructions.md`, `.windsurfrules`) are advisory — they are
injected into the prompt but can be ignored by the model. Of the agents
evaluated, only Claude Code (via `permissions.deny`) and OpenAI Codex CLI
(via `forbidden` rules) support hard enforcement of command restrictions.
Cursor, GitHub Copilot, and Windsurf rely entirely on prompt-level instructions.

#### 4. Shell alias `npm="sfw npm"` as sole defense

**Reason:** Fish function wrappers only protect interactive terminal use.
Coding agents execute commands via bash (not fish), so the wrappers are
bypassed entirely. The Claude Code hook layer is necessary to cover agent
execution paths.

#### 5. lockfile-lint and npm audit in global config

**Reason:** These are CI/project-level tools. Running them globally on every
install adds latency without clear benefit, as they require project-specific
configuration (trusted registries, known vulnerabilities).

## Consequences

- Every `npm install`, `pnpm add`, `pip install`, `uv add`, and
  `cargo install` in the terminal goes through Socket Firewall automatically.
- Claude Code cannot run bare install commands — the PreToolUse hook blocks
  them and the agent self-corrects to use `sfw`.
- When Claude Code edits a dependency manifest, the PostToolUse hook reminds
  it to install via `sfw`.
- New package manager support requires updates in three places: `aliases.fish`,
  `sfw-gate.sh`, and `sfw-post-edit.sh`.
- sfw Free tier is wrapper-only (no transparent proxy). Enterprise tier would
  eliminate the need for wrapper functions but is not currently justified.

## References

- [axios npm package compromised][axios-incident]
- [npm Security Best Practices][npm-best-practices]
- [Socket Firewall Free][sfw-free]
- [Woodruff — We should all be using dependency cooldowns][cooldown-analysis]
- [Feross Aboukhadijeh on AI agents and supply chain risk (Risky Biz, Feb 2026)][feross-riskybiz]
- [Liran Tal — ToxicSkills: AI Agent Skills security audit (Feb 2026)][toxicskills]

## Changed files

- `.config/fish/aliases.fish` — sfw wrapper functions for npm, pnpm, pip, uv, cargo
- `.config/mise/config.toml` — added `"npm:sfw" = "latest"`
- `.claude/hooks/sfw-gate.sh` — PreToolUse hook blocking bare install commands
- `.claude/hooks/sfw-post-edit.sh` — PostToolUse hook detecting manifest edits
- `.claude/settings.json` — hook registration

[axios-incident]: https://socket.dev/blog/axios-npm-package-compromised
[npm-best-practices]: https://github.com/lirantal/npm-security-best-practices/blob/main/README.md
[sfw-free]: https://github.com/SocketDev/sfw-free
[cooldown-analysis]: https://blog.yossarian.net/2025/11/21/We-should-all-be-using-dependency-cooldowns
[feross-riskybiz]: https://socket.dev/blog/risky-biz-podcast-ai-agents-open-source-risk
[toxicskills]: https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub/
