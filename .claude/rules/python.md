---
paths: ["**/*.py", "**/pyproject.toml"]
---
# Python

## Toolchain

| purpose | tool |
|---------|------|
| deps & venv | `uv` (NEVER pip, poetry, or easy_install) |
| lint & format | `ruff check` / `ruff format` |
| static types | `ty check` |
| tests | `pytest -q` |

## Rules

- Use `uv add <package>` to install. Never use `uv pip` commands.
- Never use `@latest` syntax in package specifications.
- Never edit `pyproject.toml` directly for dependencies.
- Ensure `pyproject.toml` exists in root directory before any operations.
- Specify exact versions when needed.
- Configure type-checking rigor through `[tool.ty.rules]` in pyproject.toml.
- Place tests in a `tests/` directory mirroring package structure.
- Runtime: Python 3.13 with `uv venv`.
- Use `uv_build` for pure Python, `hatchling` for extensions.
- Supply chain: `pip-audit` before deploying, pin exact versions (`==`), verify hashes with `uv pip install --require-hashes`.
