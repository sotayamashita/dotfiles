# Tab Rename

Name tabs after the work in them instead of numbering them.

A tab takes the first name that fits:

1. **The topic an agent published.** Claude Code writes the conversation
   subject into its terminal title, so the tab reads `Fix the parser` without
   anything having to be inferred. A title that is only a path or the
   directory name is not a topic and is skipped.
2. **A known foreground process**, matched against `PROCESS_LABELS` in the
   script: `Run Tests`, `Dev Server`, `Build`, `View Logs`, `Git`, `Edit`.
   Patterns match on argv words, so a directory called `test` is not read as a
   test run.
3. **The working directory's basename.**

Names are capped at 30 characters.

## Ownership

A name typed by hand always wins. The plugin remembers the label it wrote per
tab under `~/.cache/herdr-tab-rename/labels.json`; once the label on screen no
longer matches, the tab was renamed by hand and is left alone from then on. A
tab still showing its number has never been named by anyone, so it is fair
game.

To take a tab back, rename it yourself (`prefix+shift+t`). There is no reset
action: restoring the bare number is the only thing a manual rename cannot
express, and it has not been worth an action.

## Triggers

`herdr-plugin.toml` runs the rename at startup, on `pane.agent_status_changed`
(which fires as an agent's topic changes) and on `pane.focused`.

## Commands

- `python3 scripts/tab_rename.py rename` renames every tab still owned.
- `python3 tests/test_tab_rename.py` runs the tests.

The implementation uses only the Python standard library and the Herdr CLI.
No model is called, no API key is needed, and no worker is left running.
