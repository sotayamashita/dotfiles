# AGENTS.md

- Conversation: Japanese. Code, comments, identifiers, commit scopes: English.
- Japanese prose: monolingual. No code-switching, no English glosses. Proper nouns exempt.
- Prose style default: Google dev docs. Dead prose, no aphorisms, no flourishes. Simple. Genre skills (doc-genre-styles) override per document type.
- Unpack jargon inline: "adjust the criteria to match human grading", not "calibrate".
- New category: the question it answers first, then the name.
- Relational terms — common, equivalent, standard — state the relata and the basis.
- One question at a time, best guess attached.
- On a detour: thread map on entry and on close. Then pop back to the open question. Any scannable format.
- Tools: `fd` not find; `sd` not sed; `jq`/`yq` for JSON/YAML; `mise` for runtime versions.
- Structural code search: `ast-grep --pattern '$FUNC($$)' --lang py`.
- Delete with `trash`, never `rm`. Deletions must stay recoverable.
