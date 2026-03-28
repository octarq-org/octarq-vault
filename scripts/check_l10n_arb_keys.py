#!/usr/bin/env python3
"""Compare lib/l10n ARB files against app_en.arb.

Default: message keys only (exclude @@locale and @metadata). This matches what
the app resolves at runtime.

Use --strict to require identical JSON keys including @description / @placeholders
blocks (app_zh.arb currently omits some of these vs app_en.arb).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / "lib" / "l10n"
BASE = "app_en.arb"
OTHERS = ("app_zh.arb", "app_es.arb")


def load(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def message_keys(data: dict) -> set[str]:
    return {k for k in data if k != "@@locale" and not k.startswith("@")}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Require full key parity including @metadata (not just message keys).",
    )
    args = parser.parse_args()

    base_path = L10N / BASE
    if not base_path.is_file():
        print(f"Missing {base_path}", file=sys.stderr)
        return 2

    base_data = load(base_path)
    base_keys = set(base_data) if args.strict else message_keys(base_data)
    failed = False

    for name in OTHERS:
        p = L10N / name
        if not p.is_file():
            print(f"Missing {p}", file=sys.stderr)
            failed = True
            continue
        other_data = load(p)
        other_keys = set(other_data) if args.strict else message_keys(other_data)
        missing = sorted(base_keys - other_keys)
        extra = sorted(other_keys - base_keys)
        if missing or extra:
            failed = True
            mode = "strict" if args.strict else "message keys"
            print(f"{name} vs {BASE} ({mode}):")
            if missing:
                print(f"  missing ({len(missing)}): {missing}")
            if extra:
                print(f"  extra ({len(extra)}): {extra}")

    if not failed:
        mode = "strict" if args.strict else "message keys"
        print(
            f"OK: {', '.join(OTHERS)} {mode} match {BASE} ({len(base_keys)} keys)."
        )
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
