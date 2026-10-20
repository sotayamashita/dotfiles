# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///
"""Lint a show-plan HTML page for the checks that do not need judgment."""

import argparse
import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

EXIT_PASS = 0
EXIT_FAIL = 1
EXIT_USAGE = 2

MAX_CJK_CHARS = 3000
MAX_WORDS = 600
MAX_KEY_POINTS = 3

CONTEXT_WORDS = re.compile(
    r"今回|先ほど|さきほど|前の案|前回|上で話した|前述|ご指摘|案\s?[A-ZＡ-Ｚ](?![A-Za-z])"
    r"|\b(?:this time|the earlier (?:idea|option)|as (?:you said|discussed)|since we decided|option [A-Z])\b",
    re.IGNORECASE,
)
EXTERNAL = re.compile(
    r"<script|(?:src|href)\s*=\s*[\"']?(?:https?:)?//|@import|url\(\s*[\"']?(?:https?:)?//", re.IGNORECASE
)
VOID_TAGS = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}
ITEM_CLASSES = {"card", "option"}

HELP_EPILOG = """\
checks:
  length         visible text is at most 3,000 characters, counting each CJK character
                 and each word as one, or 600 words for a page with more words than CJK characters
  key-points     a key-points box exists with 1 to 3 points
  headings       numbered headings count from 1 with no gaps
  context-words  no words that refer to the conversation, such as 今回 or "option B"
  marks          at most one <mark> in each list item, card, or option
  placeholders   no template placeholder such as 〔...〕 is left
  self-contained no <script> and no load from the network

output:
  JSON on stdout: {"file", "passed", "checks": [{"name", "passed", "detail"}]}

exit codes:
  0  all checks pass
  1  one or more checks fail
  2  the file is missing or is not HTML

examples:
  uv run scripts/lint.py /tmp/show-plan-photo-backup.html
  uv run scripts/lint.py /tmp/show-plan-photo-backup.html | jq '.checks[] | select(.passed | not)'
"""


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.text: list[str] = []
        self.headings: list[int] = []
        self.crowded_items: list[str] = []
        self._stack: list[dict] = []
        self._skip = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in VOID_TAGS:
            return

        classes = set((dict(attrs).get("class") or "").split())
        self._stack.append(
            {
                "tag": tag,
                "item": tag == "li" or bool(classes & ITEM_CLASSES),
                "marks": 0,
                "text": [],
                "num": "num" in classes,
            }
        )
        if tag in {"style", "script"}:
            self._skip += 1
        if tag == "mark":
            item = next((entry for entry in reversed(self._stack) if entry["item"]), None)
            if item is not None:
                item["marks"] += 1

    def handle_endtag(self, tag: str) -> None:
        if tag in VOID_TAGS or not self._stack:
            return

        while self._stack:
            entry = self._stack.pop()
            self._close(entry)
            if entry["tag"] == tag:
                break

    def handle_data(self, data: str) -> None:
        if self._skip:
            return

        self.text.append(data)
        for entry in self._stack:
            entry["text"].append(data)

    def _close(self, entry: dict) -> None:
        if entry["tag"] in {"style", "script"}:
            self._skip -= 1
        if entry["num"] and "".join(entry["text"]).strip().isdigit():
            self.headings.append(int("".join(entry["text"]).strip()))
        if entry["item"] and entry["marks"] > 1:
            self.crowded_items.append(snippet("".join(entry["text"]), 0, 30))


def snippet(text: str, start: int, width: int) -> str:
    flat = re.sub(r"\s+", " ", text).strip()
    return flat[max(0, start - width // 2) : start + width // 2 + 1].strip()


def count_key_points(html: str) -> int | None:
    box = re.search(r'class="[^"]*\bkeypoints\b[^"]*".*?</(?:section|div)>', html, re.S)
    return len(re.findall(r"<li[\s>]", box.group(0))) if box else None


def check(name: str, passed: bool, detail: str) -> dict:
    return {"name": name, "passed": passed, "detail": detail}


def lint(html: str) -> list[dict]:
    parser = PageParser()
    parser.feed(html)
    parser.close()

    text = re.sub(r"\s+", " ", "".join(parser.text))
    cjk = len(re.findall(r"[぀-ヿ㐀-鿿＀-￯]", text))
    words = len(re.findall(r"[A-Za-z0-9][\w'-]*", text))
    if cjk >= words:
        length_ok, length = cjk + words <= MAX_CJK_CHARS, f"{cjk + words} characters (limit {MAX_CJK_CHARS})"
    else:
        length_ok, length = words <= MAX_WORDS, f"{words} words (limit {MAX_WORDS})"

    key_points = count_key_points(html)
    expected = list(range(1, len(parser.headings) + 1))
    context = [snippet(text, match.start(), 30) for match in CONTEXT_WORDS.finditer(text)]
    placeholders = re.findall(r"〔[^〕]*〕", text)
    external = sorted({match.group(0) for match in EXTERNAL.finditer(html)})

    return [
        check("length", length_ok, length),
        check(
            "key-points",
            key_points is not None and 1 <= key_points <= MAX_KEY_POINTS,
            "no key-points box" if key_points is None else f"{key_points} points (limit {MAX_KEY_POINTS})",
        ),
        check(
            "headings",
            bool(parser.headings) and parser.headings == expected,
            f"found {parser.headings}, expected {expected or [1]}",
        ),
        check("context-words", not context, "; ".join(context) or "none"),
        check("marks", not parser.crowded_items, "; ".join(parser.crowded_items) or "at most one in each item"),
        check("placeholders", not placeholders, ", ".join(placeholders[:5]) or "none"),
        check("self-contained", not external, ", ".join(external) or "no script and no network load"),
    ]


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="scripts/lint.py",
        description=__doc__,
        epilog=HELP_EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("page", type=Path, help="path of the HTML page to lint")
    args = parser.parse_args()

    if not args.page.is_file():
        print(f"Error: {args.page} does not exist. Give the path of the saved HTML page.", file=sys.stderr)
        return EXIT_USAGE

    html = args.page.read_text(encoding="utf-8")
    if "<html" not in html.lower():
        print(f"Error: {args.page} is not an HTML page. Give the page made from assets/plan.html.", file=sys.stderr)
        return EXIT_USAGE

    checks = lint(html)
    passed = all(item["passed"] for item in checks)
    print(json.dumps({"file": str(args.page), "passed": passed, "checks": checks}, ensure_ascii=False, indent=2))
    return EXIT_PASS if passed else EXIT_FAIL


if __name__ == "__main__":
    sys.exit(main())
