---
paths: ["**/*.rs", "**/Cargo.toml", "**/Cargo.lock"]
---
# Rust

## Toolchain

| purpose | tool |
|---------|------|
| build & deps | `cargo` |
| lint | `cargo clippy --all-targets --all-features -- -D warnings` |
| format | `cargo fmt` |
| test | `cargo test` |
| supply chain | `cargo deny check` |
| safety check | `cargo careful test` |

## Rules

- Use latest stable Rust via `rustup`.
- Favor `for` loops with mutable accumulators over complex iterator chains.
- Shadow variables through transformations without prefixes like `raw_x`.
- Avoid wildcard matches; use explicit destructuring to catch field changes.
- Use `let...else` for early returns, keeping the primary path unindented.
- Use newtypes over raw primitives, enums for state machines instead of booleans.
- Use `thiserror` for libraries and `anyhow` for applications.
- Use `tracing` for logging (`error!`, `warn!`, `info!`, `debug!`), not println.
- Enable clippy pedantic via Cargo.toml:
  ```toml
  [lints.clippy]
  pedantic = { level = "warn", priority = -1 }
  unwrap_used = "deny"
  expect_used = "warn"
  panic = "deny"
  panic_in_result_fn = "deny"
  unimplemented = "deny"
  allow_attributes = "deny"
  dbg_macro = "deny"
  todo = "deny"
  print_stdout = "deny"
  print_stderr = "deny"
  await_holding_lock = "deny"
  large_futures = "deny"
  exit = "deny"
  mem_forget = "deny"
  module_name_repetitions = "allow"
  similar_names = "allow"
  ```
- Avoid `matches!` macro -- explicit destructuring catches field changes.
- Use newtypes with concrete types: `UserId(u64)` not raw `u64`.
- `cargo deny check` scope: advisories, licenses, bans.
- Profile before micro-optimizing; measure after.
