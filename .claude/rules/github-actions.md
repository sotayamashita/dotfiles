---
paths: ["**/.github/workflows/**", "**/.github/actions/**"]
---
# GitHub Actions

- Pin actions to SHA hashes with version comments: `actions/checkout@<full-sha>  # vX.Y.Z`.
- Use `persist-credentials: false` on checkout.
- Scan workflows with `zizmor` before committing.
- Configure Dependabot with 7-day cooldowns and grouped updates.
- Use `uv` ecosystem (not `pip`) for Python so Dependabot updates `uv.lock`.
