---
paths: ["**/*.csv", "**/*.tsv"]
---
# CSV / TSV

- Prefer `xan` over `grep`/`awk`/`sed` or one-off pandas scripts for CSV/TSV work.
- Inspect: `xan view` (pretty preview), `xan headers`, `xan count`, `xan stats`.
- Filter & search: `xan search <pattern>`, `xan filter <expr>`, `xan slice`, `xan top`.
- Columns: `xan select` / `xan drop`, `xan map` / `xan transform` (expression-based).
- Aggregate: `xan groupby`, `xan frequency`, `xan agg`.
- Combine & convert: `xan join`, `xan cat`, `xan from <fmt>` / `xan to <fmt>`.
- TSV or headerless input: pass `-d '\t'` or `--no-headers`.
