# Python

## Package Management

- **CRITICAL**: Use `uv` exclusively - NEVER pip, poetry, or easy_install
- **FORBIDDEN**: `uv pip` commands - use `uv add` instead
- **FORBIDDEN**: `@latest` syntax in package specifications
- **FORBIDDEN**: Update `pyproject.toml` directly

## Essential Commands

- Install packages: `uv add <package>`
- Run tools: `uv run <tool>`
- Ensure `pyproject.toml` exists in root directory

## Key Reminders

- Always use `uv add`, not `uv pip install`
- Specify exact versions when needed
- Check for `pyproject.toml` before any operations
