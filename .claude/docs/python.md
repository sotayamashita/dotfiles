## Python Environment & Package Management
- Use virtual environment created by uv venv
- Use uv add to install additional libraries
- Use uv sync to install dependencies
- Do not use old fashioned methods for package management like poetry, pip, easy_install or uv pip.

## Test-Driven Development following RED-GREEN-REFACTOR cycle
- Write ONE failing test: `test_should_<behavior>_when_<condition>`
- Run: `uv run pytest -xvs tests/test_file.py::test_name`
- Run: `uv run pytest -xvs` (all tests must pass)
