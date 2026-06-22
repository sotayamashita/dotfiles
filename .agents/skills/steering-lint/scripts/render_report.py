#!/usr/bin/env python3
"""Render a steering-lint findings report as a self-contained HTML file.

This is the deterministic half of the report: it owns every aggregate (counts,
percentages, ordering) and every pixel. The agent supplies only judgment leaves
-- per-surface status and per-finding facts -- and this script derives the rest.
Because the contract has no count/percent/score field, two figures can never
disagree (the "83% vs 1 finding" class of bug is unrepresentable).

Visual identity mirrors ../references/report-design.md; the TOKENS dict below is
the enforced copy of its YAML. Change both together.

Usage:
    python3 render_report.py findings.json      # or: ... < findings.json
Writes <tmpdir>/steering-lint-report-<timestamp>.html and prints its path.

Contract (findings JSON):
    {
      "target": "/path/audited",
      "headline": "one qualitative sentence, NO numbers",   # optional
      "surfaces": [
        {"path": "CLAUDE.md", "kind": "memory-root", "lines": 88,
         "status": "finding|clean|cleared", "note": "<why> (required iff cleared)"}
      ],
      "findings": [
        {"id": "F1", "surface": "CLAUDE.md", "rule": "automation-as-prose",
         "title": "...", "location": "CLAUDE.md:12-14", "instruction": "...",
         "why": "<axis> -- <clause>", "home": "hook", "fix": "...",
         "before": "...", "after": "...", "change_kind": "move"}   # change_kind optional
      ]
    }
Severity is NOT supplied; it is derived from `rule`.
"""

from __future__ import annotations

import html
import json
import os
import sys
from datetime import datetime
from pathlib import Path

# --- enforced copy of references/report-design.md -------------------------
TOKENS = {
    "ink": "#1e293b",
    "muted": "#64748b",
    "hairline": "#e2e8f0",
    "surface": "#ffffff",
    "canvas": "#f8fafc",
    "inplace": "#10b981",
    "cleared": "#14b8a6",
}

# severity -> (accent, tint background, text-on-tint, label)
SEVERITY_STYLE = {
    "high": ("#ef4444", "#fef2f2", "#991b1b", "High"),
    "medium": ("#f59e0b", "#fffbeb", "#92400e", "Medium"),
    "low": ("#3b82f6", "#eff6ff", "#1e40af", "Low"),
}
SEVERITY_ORDER = ["high", "medium", "low"]

# Each lint rule has a fixed severity (mirrors SKILL.md Rules / mechanisms.md).
# Severity is derived here so the agent cannot author an inconsistent pair.
RULE_SEVERITY = {
    "automation-as-prose": "high",
    "prohibition-as-prose": "high",
    "procedure-in-memory": "high",
    "unscoped-narrow-rule": "medium",
    "personal-pref-in-shared": "medium",
    "memory-bloat": "medium",
    "output-style-overreach": "medium",
    "skill-vs-subagent-mismatch": "low",
}

# Recommended homes (mirrors references/mechanisms.md). Validated to catch typos.
HOMES = {
    "root-memory",
    "nested-memory",
    "user-memory",
    "path-scoped-rule",
    "skill",
    "subagent",
    "hook",
    "permission",
    "managed-settings",
    "built-in-output-style",
    "append-system-prompt",
}

VALID_STATUS = {"clean", "finding", "cleared"}


class ContractError(ValueError):
    """Raised when the findings JSON violates the contract. Fail loud."""


# --- load & validate ------------------------------------------------------
def load(argv: list[str]) -> dict:
    raw = (
        Path(argv[1]).read_text(encoding="utf-8") if len(argv) > 1 else sys.stdin.read()
    )
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ContractError(f"input is not valid JSON: {exc}") from exc
    if not isinstance(data, dict):
        raise ContractError("top-level value must be an object")
    return data


def validate(model: dict) -> None:
    """Reject any contract violation with a specific message (this is a linter)."""
    if not isinstance(model.get("target"), str) or not model["target"].strip():
        raise ContractError("`target` must be a non-empty string")
    surfaces = model.get("surfaces")
    findings = model.get("findings")
    if not isinstance(surfaces, list) or not surfaces:
        raise ContractError("`surfaces` must be a non-empty array")
    if not isinstance(findings, list):
        raise ContractError("`findings` must be an array")

    seen_paths: set[str] = set()
    finding_surface_paths: set[str] = set()
    for i, s in enumerate(surfaces):
        where = f"surfaces[{i}]"
        for key in ("path", "kind", "status"):
            if not isinstance(s.get(key), str) or not s[key].strip():
                raise ContractError(f"{where}.{key} must be a non-empty string")
        if not isinstance(s.get("lines"), int):
            raise ContractError(f"{where}.lines must be an integer")
        if s["status"] not in VALID_STATUS:
            raise ContractError(
                f"{where}.status {s['status']!r} not in {sorted(VALID_STATUS)}"
            )
        if s["path"] in seen_paths:
            raise ContractError(f"{where}.path {s['path']!r} is duplicated")
        seen_paths.add(s["path"])
        note = s.get("note")
        if s["status"] == "cleared":
            if not isinstance(note, str) or not note.strip():
                raise ContractError(
                    f"{where} is cleared but has no `note` explaining why"
                )
        elif note:
            raise ContractError(f"{where}.note must be empty unless status is cleared")
        if s["status"] == "finding":
            finding_surface_paths.add(s["path"])

    referenced: set[str] = set()
    for i, f in enumerate(findings):
        where = f"findings[{i}]"
        for key in (
            "id",
            "surface",
            "rule",
            "title",
            "location",
            "instruction",
            "why",
            "home",
            "fix",
            "before",
            "after",
        ):
            if not isinstance(f.get(key), str) or not f[key].strip():
                raise ContractError(f"{where}.{key} must be a non-empty string")
        if f["surface"] not in seen_paths:
            raise ContractError(f"{where}.surface {f['surface']!r} matches no surface")
        if f["surface"] not in finding_surface_paths:
            raise ContractError(
                f"{where}.surface {f['surface']!r} is not marked status=finding"
            )
        if f["rule"] not in RULE_SEVERITY:
            raise ContractError(
                f"{where}.rule {f['rule']!r} not in {sorted(RULE_SEVERITY)}"
            )
        if f["home"] not in HOMES:
            raise ContractError(f"{where}.home {f['home']!r} not in {sorted(HOMES)}")
        referenced.add(f["surface"])

    orphans = finding_surface_paths - referenced
    if orphans:
        raise ContractError(
            f"surfaces marked status=finding with no finding detail: {sorted(orphans)}"
        )


# --- derive (every aggregate lives here, nowhere in the contract) ---------
def derive(model: dict) -> dict:
    surfaces = model["surfaces"]
    findings = model["findings"]
    total = len(surfaces)
    clean = [s for s in surfaces if s["status"] == "clean"]
    cleared = [s for s in surfaces if s["status"] == "cleared"]
    in_place = len(clean) + len(cleared)
    by_severity: dict[str, list[dict]] = {sev: [] for sev in SEVERITY_ORDER}
    for f in findings:
        by_severity[RULE_SEVERITY[f["rule"]]].append(f)
    ordered = sorted(
        findings,
        key=lambda f: (SEVERITY_ORDER.index(RULE_SEVERITY[f["rule"]]), f["id"]),
    )
    kinds: dict[str, int] = {}
    for s in surfaces:
        kinds[s["kind"]] = kinds.get(s["kind"], 0) + 1
    top_severity = next((sev for sev in SEVERITY_ORDER if by_severity[sev]), None)
    return {
        "total": total,
        "clean": clean,
        "cleared": cleared,
        "in_place": in_place,
        "percent": round(in_place / total * 100) if total else 100,
        "by_severity": by_severity,
        "ordered_findings": ordered,
        "kinds": kinds,
        "top_severity": top_severity,
    }


# --- render ---------------------------------------------------------------
def esc(value: object) -> str:
    return html.escape(str(value))


def severity_chips(d: dict) -> str:
    """Colored chips only for severities with count > 0; zero-count omitted."""
    chips = []
    for sev in SEVERITY_ORDER:
        n = len(d["by_severity"][sev])
        if n == 0:
            continue
        color, _, fg, label = SEVERITY_STYLE[sev]
        chips.append(
            f'<span class="chip" style="color:{fg};border-color:{color}55">{label} {n}</span>'
        )
    if not chips:
        return '<span class="muted">no findings</span>'
    return "".join(chips)


def health_bar(d: dict) -> str:
    action_color = (
        SEVERITY_STYLE[d["top_severity"]][0]
        if d["top_severity"]
        else TOKENS["hairline"]
    )
    pct = d["percent"]
    return (
        f'<div class="bar">'
        f'<div style="width:{pct}%;background:{TOKENS["inplace"]}"></div>'
        f'<div style="width:{100 - pct}%;background:{action_color}"></div>'
        f"</div>"
    )


def finding_card(f: dict) -> str:
    sev = RULE_SEVERITY[f["rule"]]
    color, bg, fg, label = SEVERITY_STYLE[sev]
    change = f.get("change_kind", "change")
    return f"""
    <article class="card" style="border-left:4px solid {color}">
      <div class="card-head" style="background:{bg}">
        <span class="badge" style="color:{fg};border-color:{color}55">{esc(label)}</span>
        <span class="mono muted">{esc(f["id"])}</span>
        <span class="rule">{esc(f["rule"])}</span>
        <span class="card-title">{esc(f["title"])}</span>
      </div>
      <div class="card-body">
        <div class="grid">
          <div class="k">Location</div><div><code>{esc(f["location"])}</code></div>
          <div class="k">Instruction</div><div class="quote">"{esc(f["instruction"])}"</div>
          <div class="k">Why</div><div>{esc(f["why"])}</div>
          <div class="k">Home</div><div><span class="home">{esc(f["home"])}</span></div>
          <div class="k">Fix</div><div>{esc(f["fix"])}</div>
        </div>
        <div class="ba">
          <div class="ba-card"><div class="ba-h">Now</div><pre>{esc(f["before"])}</pre></div>
          <div class="ba-arrow"><span>{esc(change)}</span>→</div>
          <div class="ba-card after" style="border-color:{color}"><div class="ba-h" style="color:{fg}">After</div><pre>{esc(f["after"])}</pre></div>
        </div>
      </div>
    </article>"""


def inplace_section(d: dict) -> str:
    rows = []
    for s in d["clean"]:
        rows.append(
            f'<li><span class="dot" style="background:{TOKENS["inplace"]}"></span>'
            f'<code>{esc(s["path"])}</code> <span class="meta">{esc(s["kind"])} · {s["lines"]} lines</span></li>'
        )
    for s in d["cleared"]:
        rows.append(
            f'<li><span class="dot" style="background:{TOKENS["cleared"]}"></span>'
            f'<code>{esc(s["path"])}</code> <span class="meta">{esc(s["kind"])} · {s["lines"]} lines · cleared</span>'
            f'<div class="note">{esc(s["note"])}</div></li>'
        )
    cleared_hint = (
        f" ({len(d['cleared'])} cleared, noted below)" if d["cleared"] else ""
    )
    return f"""
    <details class="inplace">
      <summary><span class="dot" style="background:{TOKENS["inplace"]}"></span>
        {d["in_place"]} surfaces in place{esc(cleared_hint)} — click to expand</summary>
      <ul>{"".join(rows)}</ul>
    </details>"""


def render_html(model: dict, d: dict) -> str:
    findings = d["ordered_findings"]
    headline = model.get("headline", "").strip()
    if not headline:
        headline = (
            f"{d['total']} surfaces scanned — all in place."
            if not findings
            else findings[0]["fix"]
        )
    kind_summary = ", ".join(f"{v} {k}" for k, v in sorted(d["kinds"].items()))
    findings_html = (
        "".join(finding_card(f) for f in findings)
        if findings
        else '<p class="muted">No findings — every surface is in the right home.</p>'
    )
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>steering-lint report — {esc(model["target"])}</title>
<style>
  :root {{ color-scheme: light; }}
  * {{ box-sizing: border-box; }}
  body {{ margin:0; background:{TOKENS["canvas"]}; color:{TOKENS["ink"]};
    font:400 0.875rem/1.55 ui-sans-serif,-apple-system,"Segoe UI",sans-serif; }}
  .wrap {{ max-width: 880px; margin:0 auto; padding:40px 24px; }}
  .mono, code, pre {{ font-family: ui-monospace,SFMono-Regular,Menlo,monospace; }}
  .muted {{ color:{TOKENS["muted"]}; }}
  .label {{ font-size:0.6875rem; letter-spacing:0.06em; text-transform:uppercase; color:{TOKENS["muted"]}; }}
  h1 {{ font-size:1.5rem; font-weight:700; margin:0; letter-spacing:-0.01em; }}
  h2 {{ font-size:1.125rem; font-weight:600; margin:0 0 16px; display:flex; align-items:center; gap:8px; }}
  h2::before {{ content:""; width:4px; height:18px; border-radius:2px; background:{TOKENS["ink"]}; }}
  .pill {{ font-size:0.6875rem; font-weight:600; letter-spacing:0.04em; text-transform:uppercase;
    padding:4px 8px; border-radius:999px; background:#ecfdf5; color:#047857; }}
  .head-row {{ display:flex; align-items:center; gap:12px; margin-bottom:6px; }}
  .cards {{ display:grid; grid-template-columns:repeat(3,1fr); gap:16px; margin:24px 0; }}
  .stat {{ background:{TOKENS["surface"]}; border:1px solid {TOKENS["hairline"]}; border-radius:12px; padding:20px; }}
  .stat .n {{ font-size:1.75rem; font-weight:700; }}
  .chip {{ font-size:0.6875rem; font-weight:600; border:1px solid; border-radius:999px; padding:2px 8px; margin-right:6px; }}
  .bar {{ display:flex; height:8px; border-radius:999px; overflow:hidden; margin-top:10px; background:{TOKENS["hairline"]}; }}
  .verdict {{ background:linear-gradient(135deg,#1e293b,#334155); color:#fff; border-radius:16px; padding:22px 24px; margin-bottom:36px; }}
  .verdict .label {{ color:#cbd5e1; }}
  .verdict p {{ margin:4px 0 0; font-size:0.95rem; line-height:1.5; }}
  .card {{ background:{TOKENS["surface"]}; border:1px solid {TOKENS["hairline"]}; border-radius:14px; overflow:hidden; margin-bottom:20px; }}
  .card-head {{ display:flex; align-items:center; gap:10px; padding:14px 18px; border-bottom:1px solid {TOKENS["hairline"]}; flex-wrap:wrap; }}
  .badge {{ font-size:0.6875rem; font-weight:700; text-transform:uppercase; letter-spacing:0.04em; border:1px solid; border-radius:999px; padding:3px 9px; }}
  .rule {{ font-size:0.75rem; font-weight:600; background:#f1f5f9; color:{TOKENS["muted"]}; padding:2px 8px; border-radius:6px; }}
  .card-title {{ font-weight:600; }}
  .card-body {{ padding:18px; }}
  .grid {{ display:grid; grid-template-columns:96px 1fr; gap:8px 16px; margin-bottom:16px; }}
  .grid .k {{ color:{TOKENS["muted"]}; font-weight:500; }}
  .grid code {{ background:#f1f5f9; padding:1px 6px; border-radius:6px; font-size:0.8125rem; }}
  .quote {{ font-style:italic; }}
  .home {{ font-weight:600; background:#eef2ff; color:#3730a3; padding:2px 8px; border-radius:6px; }}
  .ba {{ display:flex; align-items:stretch; gap:10px; }}
  .ba-card {{ flex:1; border:1px solid {TOKENS["hairline"]}; border-radius:10px; padding:12px; }}
  .ba-card.after {{ border-width:2px; }}
  .ba-h {{ font-size:0.6875rem; letter-spacing:0.06em; text-transform:uppercase; color:{TOKENS["muted"]}; margin-bottom:6px; }}
  .ba pre {{ margin:0; white-space:pre-wrap; font-size:0.75rem; line-height:1.5; color:#475569; }}
  .ba-arrow {{ display:flex; flex-direction:column; align-items:center; justify-content:center; color:{TOKENS["muted"]}; font-size:1.25rem; }}
  .ba-arrow span {{ font-size:0.625rem; text-transform:uppercase; letter-spacing:0.04em; }}
  details.inplace {{ background:{TOKENS["surface"]}; border:1px solid {TOKENS["hairline"]}; border-radius:14px; padding:14px 18px; }}
  details.inplace summary {{ cursor:pointer; font-weight:600; display:flex; align-items:center; gap:8px; }}
  details.inplace ul {{ list-style:none; margin:14px 0 0; padding:0; }}
  details.inplace li {{ padding:7px 0; border-top:1px solid {TOKENS["hairline"]}; }}
  details.inplace code {{ font-size:0.8125rem; }}
  .dot {{ display:inline-block; width:9px; height:9px; border-radius:999px; vertical-align:middle; }}
  .meta {{ font-size:0.6875rem; color:{TOKENS["muted"]}; }}
  .note {{ font-size:0.8125rem; color:{TOKENS["muted"]}; margin-top:3px; padding-left:17px; }}
  footer {{ text-align:center; color:{TOKENS["muted"]}; font-size:0.75rem; border-top:1px solid {TOKENS["hairline"]}; margin-top:32px; padding-top:20px; }}
  section {{ margin-bottom:32px; }}
</style></head>
<body><div class="wrap">

  <header>
    <div class="head-row"><h1>steering-lint report</h1>
      <span class="pill">read-only · no files modified</span></div>
    <div class="muted">Target <code>{esc(model["target"])}</code> · {esc(ts)}</div>
  </header>

  <div class="cards">
    <div class="stat"><div class="n">{d["total"]}</div><div class="label">surfaces scanned</div>
      <div class="meta" style="margin-top:8px">{esc(kind_summary)}</div></div>
    <div class="stat"><div class="n">{len(model["findings"])}</div><div class="label">findings</div>
      <div style="margin-top:10px">{severity_chips(d)}</div></div>
    <div class="stat"><div class="n" style="color:{TOKENS["inplace"]}">{d["percent"]}%</div>
      <div class="label">in place</div>{health_bar(d)}</div>
  </div>

  <div class="verdict"><div class="label">Headline</div><p>{esc(headline)}</p></div>

  <section><h2>Findings</h2>{findings_html}</section>

  <section><h2>In place</h2>{inplace_section(d)}</section>

  <footer>Generated by steering-lint · read-only · recommends moves, edits nothing.</footer>
</div></body></html>"""


def main(argv: list[str]) -> int:
    try:
        model = load(argv)
        validate(model)
    except ContractError as exc:
        print(f"render_report: contract error: {exc}", file=sys.stderr)
        return 2
    derived = derive(model)
    out = (
        Path(os.environ.get("TMPDIR", "/tmp"))
        / f"steering-lint-report-{datetime.now():%Y%m%d-%H%M%S}.html"
    )
    out.write_text(render_html(model, derived), encoding="utf-8")
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
