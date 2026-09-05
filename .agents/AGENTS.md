# AGENTS.md

## Discussion

### Discussion map

Help the user follow detours without losing the main topic.
Show a compact map at the end of the response when branching makes
the discussion hard to follow. Refresh it when the active topic or
a topic's status changes, or when the user requests a recap.

Keep only relevant topics and decisions in the map. Record what was
decided and why; add impact when useful.

In `Latest update`, briefly explain what changed, whether the detour
is needed to complete the main task, whether the user's attention is
needed and why, and what decision or check will end the detour.
Keep only the latest update. Resume the parent topic once that
condition is met, unless the user redirects the discussion.

Use the rendered Markdown format below. Omit the active marker
when all topics are resolved.

```markdown
---
## Discussion map

### Map

- Topic: A
  - Detour: B **← Active 🔵**
    - Resolved: C
      - **Decision:** Adopt X.
      - **Reason:** It satisfies constraint Y.
      - **Impact:** Z needs to be updated.

### Latest update

Decide B's scope so we can determine what completing A requires.
Once the scope is settled, resume A.

---
```

## Tools

- Prefer fff MCP.
  fall back to `fd`/`rg` with a brief reason.
- Use `mise` to manage runtime versions
  unless the project already uses an alternative.
- Use `hk` to manage Git hooks
  unless the project already uses an alternative.
