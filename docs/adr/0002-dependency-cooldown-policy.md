# ADR-0002: Dependency Cooldown Policy

## Status

Accepted

## Date

2026-03-31 (initial), 2026-04-01 (deno added)

## Context

Supply chain attacks on package registries frequently follow a pattern: a
malicious version is published, exploited for a short window, then removed or
reported. [Woodruff's analysis][cooldown-analysis] found that 8 out of 10
studied attacks had exploitation windows shorter than 7 days.

By refusing to install packages published less than 7 days ago, we avoid the
most dangerous period while keeping the delay short enough that security
patches remain accessible in a reasonable timeframe. A 14-day window would
block ~90% of attacks but was rejected as too aggressive for patch adoption.

Not all package managers support a native cooldown setting. Where no built-in
mechanism exists, alternative approaches were evaluated.

## Decision

Set a 7-day minimum release age across all package managers used in this
environment.

### Implementation per package manager

| Package manager | Config file             | Setting                            | Mechanism       |
|-----------------|-------------------------|------------------------------------|-----------------|
| npm             | `.npmrc`                | `min-release-age=7`                | Native (days)   |
| pnpm            | `.config/pnpm/rc`       | `minimumReleaseAge: 10080`         | Native (minutes)|
| bun             | `bunfig.toml`           | `minimumReleaseAge = "7d"`         | Native          |
| uv (Python)     | `.config/uv/uv.toml`   | `exclude-newer = "7 days"`         | Native          |
| deno            | `.config/fish/aliases.fish` | `--minimum-dependency-age=P7D` | Fish function wrapper (no config file support) |

### Why 7 days

- Blocks ~80% of known attacks based on empirical data.
- 14 days would block ~90% but delays security patches unacceptably.
- 3 days was considered too short — still within the exploitation window of
  several documented attacks.

### Rejected alternatives

#### 1. No cooldown (status quo ante)

**Reason:** Leaves the environment fully exposed to the most common attack
window. Zero cost to enable where native support exists.

#### 2. 14-day cooldown

**Reason:** Blocks security patches for two weeks. The marginal gain (~10%
more attacks blocked) does not justify the delay in receiving critical fixes.

#### 3. Cooldown only for npm/pnpm (skip other ecosystems)

**Reason:** Supply chain attacks are not limited to the npm ecosystem. Python
(PyPI) and Rust (crates.io) have seen similar incidents. Consistent policy
across all managers reduces cognitive overhead and eliminates gaps.

#### 4. Global `--before` flag via shell alias for npm

**Reason:** npm's `--before` flag accepts an absolute date, not a relative
duration. It would require dynamic date computation on every invocation.
`min-release-age` is the correct native mechanism (available since npm v11).

## Consequences

- Newly published packages are unavailable for 7 days after release across
  all ecosystems.
- Emergency situations requiring a zero-day package can override per-invocation
  (e.g., `npm install --min-release-age=0`).
- Deno's cooldown is enforced via a fish function wrapper, which only applies
  to interactive terminal use. Coding agents calling `deno install` via bash
  bypass this — a limitation accepted because Deno's import model (URL-based)
  is less susceptible to registry-based attacks.
- Each package manager uses different units (days, minutes, duration strings),
  requiring per-manager documentation in config comments.

## References

- [Woodruff — We should all be using dependency cooldowns][cooldown-analysis]
- [npm Security Best Practices][npm-best-practices]
- [axios npm package compromised][axios-incident]

## Changed files

- `.npmrc` — `min-release-age=7`
- `.config/pnpm/rc` — `minimumReleaseAge: 10080`
- `bunfig.toml` — `minimumReleaseAge = "7d"`
- `.config/uv/uv.toml` — `exclude-newer = "7 days"`
- `.config/fish/aliases.fish` — deno fish function wrapper with `--minimum-dependency-age=P7D`

## Commit history

- `7ba4bc4` feat(security): add 7-day dependency cooldown configs
- `7e2c969` fix(pnpm): correct minimumReleaseAge syntax
- `1f558e4` style(security): unwrap cooldown comments to single lines
- `77a507e` feat(fish): add deno dependency age cooldown

[cooldown-analysis]: https://blog.yossarian.net/2025/11/21/We-should-all-be-using-dependency-cooldowns
[npm-best-practices]: https://github.com/lirantal/npm-security-best-practices/blob/main/README.md
[axios-incident]: https://socket.dev/blog/axios-npm-package-compromised
