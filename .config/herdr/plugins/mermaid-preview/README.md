# Mermaid Preview

Render the latest complete Mermaid block from the active Codex or Claude Code
session in a Herdr side pane. For terminal applications that preserve Markdown
fences in their output, the plugin also checks the recent pane transcript.

## Requirements

- Herdr 0.8.0 or later
- A Kitty graphics-compatible terminal
- Mermaid CLI (`mmdc`)
- Python 3.9 or later

Enable Herdr graphics and bind the action in `~/.config/herdr/config.toml`:

```toml
[experimental]
kitty_graphics = true

[[keys.command]]
key = "prefix+shift+m"
type = "plugin_action"
command = "sotayamashita.mermaid-preview.show"
description = "show latest Mermaid diagram"
```

Link the working tree during local development:

```bash
herdr plugin link ~/.config/herdr/plugins/mermaid-preview
```
