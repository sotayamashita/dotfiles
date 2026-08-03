# Current Model Policy

Role names express responsibility, not model identity. Update this file and the
corresponding custom-agent TOML values when a more suitable model becomes
available. Do not rename the skill, files, or agent types.

| Role | Model | Reasoning effort | Service tier | Sandbox |
|---|---|---|---|---|
| Primary architect | `gpt-5.6-sol` | `high` | `default` | Session selection |
| Routine worker | `gpt-5.6-luna` | `max` | `fast` | Inherited |
| Complex worker | `gpt-5.6-terra` | `max` | `fast` | Inherited |
| Critical worker | `gpt-5.6-sol` | `high` | `default` | Inherited |
| Independent verifier | `gpt-5.6-sol` | `high` | `default` | `read-only` |
| Independent validator | `gpt-5.6-sol` | `high` | `default` | `read-only` |

Fast service uses faster priority processing and more credits than Standard.
Use it for Luna and Terra to reduce Max-effort latency, not as a quota-saving
claim. The quota strategy is delegating suitable work away from the architect
model.

## Upgrade procedure

1. Choose models by the responsibility and measured completion cost of each role.
2. Update `model`, `model_reasoning_effort`, and `service_tier` in the affected
   custom-agent TOML files.
3. Update the table above in the same change.
4. Start a new Codex task so custom agent definitions reload.
5. Verify runtime details when exposed and run a representative task before
   trusting the new mapping.
